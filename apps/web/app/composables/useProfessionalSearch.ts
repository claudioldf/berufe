import { computed, shallowRef, watch } from "vue";
import type {
  ExpressionSearchPayload,
  PublicProfessionalCard,
  PublicProfessionalSearchResult,
  StructuredSearchPayload,
} from "~/types";
import {
  searchPublicProfessionals,
  searchStructuredProfessionals,
} from "~/services/api/public-discovery";
import { useApiClient } from "~/services/api/client";
import {
  ApiRequestError,
  type NormalizedApiError,
} from "~/services/api/errors";
import {
  decodeSearchExpression,
  encodeSearchExpression,
} from "~/utils/searchExpression";

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

export async function useProfessionalSearch() {
  const route = useRoute();
  const router = useRouter();
  const client = useApiClient();
  const expressionInput = shallowRef("");
  const additionalResults = shallowRef<PublicProfessionalCard[]>([]);
  const loadedPage = shallowRef(1);
  const loadingMore = shallowRef(false);
  const structuredResponse = shallowRef<SearchResponse | null>(null);
  const isStructuredSearching = shallowRef(false);
  const structuredRouteExpression = shallowRef("");

  const encodedExpression = computed(() => {
    const value = route.query.expressao;
    return String(Array.isArray(value) ? (value[0] ?? "") : (value ?? ""));
  });
  const expressionQuery = computed(() =>
    decodeSearchExpression(encodedExpression.value),
  );
  const hasSearchTerm = computed(() => expressionQuery.value.length > 0);

  const {
    data,
    error: unexpectedError,
    status,
    refresh,
    clear,
  } = await useAsyncData(
    "public-professional-search",
    async (): Promise<SearchResponse> => {
      const expression = expressionQuery.value;
      try {
        const result = await searchPublicProfessionals(client, { expression });
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
    { enabled: hasSearchTerm },
  );

  function resetPaging() {
    additionalResults.value = [];
    loadedPage.value = 1;
    loadingMore.value = false;
  }

  watch(encodedExpression, () => {
    if (expressionQuery.value === structuredRouteExpression.value) {
      structuredRouteExpression.value = "";
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
  const isSearching = computed(
    () =>
      isStructuredSearching.value ||
      (hasSearchTerm.value &&
        currentResponse.value === null &&
        !unexpectedError.value),
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
    if (!expression) return;

    await router.push({
      path: "/encontrar",
      query: { expressao: encodeSearchExpression(expression) },
    });
  }

  async function submitStructuredSearch(payload: StructuredSearchPayload) {
    resetPaging();
    isStructuredSearching.value = true;
    const expression = `${payload.serviceName.trim()} em ${payload.city}`;
    structuredRouteExpression.value = expression;
    expressionInput.value = expression;
    try {
      await router.push({
        path: "/encontrar",
        query: { expressao: encodeSearchExpression(expression) },
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
      structuredRouteExpression.value = "";
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
