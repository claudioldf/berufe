import { computed, shallowRef, toValue, watch } from "vue";
import type { MaybeRefOrGetter } from "vue";
import type {
  ExpressionSearchPayload,
  PublicProfessionalCard,
  PublicProfessionalSearchResult,
  SearchLocation,
  StructuredSearchPayload,
} from "~/types";
import { useAnalyticsEvent } from "~/composables/useAnalyticsEvent";
import {
  searchPublicProfessionals,
  searchStructuredProfessionals,
} from "~/services/api/public-discovery";
import { useApiClient } from "~/services/api/client";
import {
  ApiRequestError,
  type NormalizedApiError,
} from "~/services/api/errors";
import { analyticsSearchTerm } from "~/utils/analytics";
import {
  decodeSearchExpression,
  encodeSearchExpression,
  readEncodedSearchExpression,
  searchExpressionQuery,
} from "~/utils/searchExpression";
import { searchLocationPath } from "~/utils/searchLocation";

type SearchSource =
  | { type: "expression" }
  | { type: "structured"; filters: StructuredSearchPayload };

interface SearchResponse {
  expression: string;
  source: SearchSource;
  result: PublicProfessionalSearchResult | null;
  failure: NormalizedApiError | null;
}

function normalizeSearchFailure(failure: ApiRequestError): NormalizedApiError {
  return {
    code: failure.code,
    message: failure.message,
    fieldErrors: failure.fieldErrors,
    requestId: failure.requestId,
  };
}

function unexpectedSearchFailure(): NormalizedApiError {
  return {
    code: "unexpected_error",
    message: "Não foi possível concluir a solicitação.",
    fieldErrors: {},
    requestId: "client",
  };
}

export async function useProfessionalSearch(options: {
  location: MaybeRefOrGetter<SearchLocation>;
  onLocationResolved?: (location: SearchLocation) => void;
}) {
  const route = useRoute();
  const router = useRouter();
  const client = useApiClient();
  const expressionInput = shallowRef("");
  const additionalResults = shallowRef<PublicProfessionalCard[]>([]);
  const loadedPage = shallowRef(1);
  const loadingMore = shallowRef(false);
  const structuredResponse = shallowRef<SearchResponse | null>(null);
  const isSubmittingSearch = shallowRef(false);
  const isStructuredSearching = shallowRef(false);
  const suppressedRouteState = shallowRef("");

  const encodedExpression = computed(() => {
    return readEncodedSearchExpression(route.query);
  });
  const expressionQuery = computed(() =>
    decodeSearchExpression(encodedExpression.value),
  );
  const hasSearchTerm = computed(() => expressionQuery.value.length > 0);
  const locationKey = computed(() => {
    const location = toValue(options.location);
    return `${location.stateSlug}/${location.citySlug}`;
  });

  function routeState(expression: string, location: SearchLocation) {
    return `${expression}\0${location.stateSlug}/${location.citySlug}`;
  }

  const {
    data,
    error: unexpectedError,
    status,
    refresh,
    clear,
  } = await useAsyncData(
    `public-professional-search:${locationKey.value}`,
    async (): Promise<SearchResponse> => {
      const expression = expressionQuery.value;
      try {
        const result = await searchPublicProfessionals(client, {
          expression,
          defaultLocation: toValue(options.location),
        });
        return {
          expression,
          source: { type: "expression" },
          result,
          failure: null,
        };
      } catch (failure) {
        if (!(failure instanceof ApiRequestError)) throw failure;

        return {
          expression,
          source: { type: "expression" },
          result: null,
          failure: normalizeSearchFailure(failure),
        };
      }
    },
    { enabled: hasSearchTerm, lazy: true },
  );

  function resetPaging() {
    additionalResults.value = [];
    loadedPage.value = 1;
    loadingMore.value = false;
  }

  watch([encodedExpression, locationKey], () => {
    const currentRouteState = routeState(
      expressionQuery.value,
      toValue(options.location),
    );
    if (currentRouteState === suppressedRouteState.value) {
      suppressedRouteState.value = "";
      expressionInput.value = expressionQuery.value;
      return;
    }

    resetPaging();
    structuredResponse.value = null;
    expressionInput.value = expressionQuery.value;
    if (!hasSearchTerm.value) {
      clear();
      return;
    }

    void refresh();
  });

  if (!hasSearchTerm.value) clear();
  expressionInput.value = expressionQuery.value;

  const currentResponse = computed(() => {
    if (!hasSearchTerm.value || isStructuredSearching.value) return null;
    if (structuredResponse.value?.expression === expressionQuery.value) {
      return structuredResponse.value;
    }
    if (!data.value) return null;
    return data.value.expression === expressionQuery.value ? data.value : null;
  });
  const currentResult = computed(() => currentResponse.value?.result ?? null);
  const error = computed<NormalizedApiError | null>(() => {
    if (currentResponse.value?.failure) return currentResponse.value.failure;
    if (!unexpectedError.value) return null;

    return unexpectedSearchFailure();
  });
  const results = computed(() =>
    currentResult.value
      ? [...currentResult.value.professionals, ...additionalResults.value]
      : [],
  );
  const totalCount = computed(() => currentResult.value?.totalCount ?? 0);
  const interpretation = computed(
    () => currentResult.value?.interpretation ?? null,
  );
  const relatedServices = computed(
    () => currentResult.value?.relatedServices ?? [],
  );
  const hasMoreResults = computed(
    () => results.value.length < totalCount.value,
  );
  const interaction = computed(() => currentResult.value?.interaction ?? null);

  // Fires once per completed search — expression or structured — since both
  // resolve into `currentResult`. Only the matched catalog service names and
  // resolved city are sent, never the visitor's raw free-text query.
  const { trackEvent } = useAnalyticsEvent();
  watch(currentResult, (result) => {
    if (!result) return;
    trackEvent("search", {
      search_term: analyticsSearchTerm(
        result.interpretation.services.map((service) => service.name),
        result.interpretation.effectiveLocation.city,
      ),
      result_count: result.totalCount,
    });
  });

  const isSearching = computed(
    () =>
      isSubmittingSearch.value ||
      isStructuredSearching.value ||
      (hasSearchTerm.value &&
        currentResponse.value === null &&
        !unexpectedError.value),
  );

  async function adoptEffectiveLocation(location: SearchLocation) {
    if (!import.meta.client) return;

    const currentLocation = toValue(options.location);
    const targetPath = searchLocationPath(location);
    if (
      currentLocation.cityCode === location.cityCode &&
      route.path === targetPath
    ) {
      return;
    }

    suppressedRouteState.value = routeState(expressionQuery.value, location);
    options.onLocationResolved?.(location);
    await router.replace({
      path: targetPath,
      query: searchExpressionQuery(encodedExpression.value),
    });
  }

  watch(
    () => interpretation.value?.effectiveLocation ?? null,
    (location) => {
      if (location) void adoptEffectiveLocation(location);
    },
    { immediate: true },
  );

  async function loadMoreResults() {
    if (loadingMore.value || !hasMoreResults.value) return;

    loadingMore.value = true;
    try {
      const nextPage = loadedPage.value + 1;
      const source = currentResponse.value?.source;
      const page =
        source?.type === "structured"
          ? await searchStructuredProfessionals(client, {
              ...source.filters,
              page: nextPage,
            })
          : await searchPublicProfessionals(client, {
              expression: expressionQuery.value,
              defaultLocation: toValue(options.location),
              page: nextPage,
            });
      additionalResults.value = [
        ...additionalResults.value,
        ...page.professionals,
      ];
      loadedPage.value = nextPage;
    } finally {
      loadingMore.value = false;
    }
  }

  async function submitSearch(payload: ExpressionSearchPayload) {
    const expression = payload.expression.trim();
    if (!expression || isSubmittingSearch.value) return;

    isSubmittingSearch.value = true;
    try {
      await router.push({
        path: searchLocationPath(toValue(options.location)),
        query: searchExpressionQuery(encodeSearchExpression(expression)),
      });
    } finally {
      isSubmittingSearch.value = false;
    }
  }

  async function submitStructuredSearch(payload: StructuredSearchPayload) {
    resetPaging();
    isStructuredSearching.value = true;
    const selectedLocation: SearchLocation = {
      cityCode: payload.cityCode,
      stateCode: payload.stateCode,
      city: payload.city,
      stateSlug: payload.stateSlug,
      citySlug: payload.citySlug,
    };
    const expression = `${payload.serviceName.trim()} em ${payload.city}`;
    suppressedRouteState.value = routeState(expression, selectedLocation);
    expressionInput.value = expression;
    options.onLocationResolved?.(selectedLocation);
    try {
      await router.push({
        path: searchLocationPath(selectedLocation),
        query: searchExpressionQuery(encodeSearchExpression(expression)),
      });
      const result = await searchStructuredProfessionals(client, payload);
      structuredResponse.value = {
        expression,
        source: { type: "structured", filters: payload },
        result,
        failure: null,
      };
    } catch (failure) {
      structuredResponse.value = {
        expression: expressionQuery.value,
        source: { type: "structured", filters: payload },
        result: null,
        failure:
          failure instanceof ApiRequestError
            ? normalizeSearchFailure(failure)
            : unexpectedSearchFailure(),
      };
    } finally {
      isStructuredSearching.value = false;
    }
  }

  async function refreshSearch() {
    structuredResponse.value = null;
    await refresh();
  }

  return {
    expressionInput,
    expressionQuery,
    encodedExpression,
    hasSearchTerm,
    results,
    totalCount,
    interpretation,
    relatedServices,
    hasMoreResults,
    loadingMore,
    loadMoreResults,
    interaction,
    isSearching,
    isStructuredSearching,
    error,
    status,
    refresh: refreshSearch,
    submitSearch,
    submitStructuredSearch,
  };
}
