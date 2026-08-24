import { computed, shallowRef, watch } from "vue";
import type {
  Neighborhood,
  PublicProfessionalCard,
  Service,
  ServiceSearchPayload,
} from "~/types";
import { searchPublicProfessionals } from "~/services/api/public-discovery";
import { useApiClient } from "~/services/api/client";
import { findService } from "~/utils/services";
import { normalizeSearchText } from "~/utils/text";

interface ProfessionalSearchOptions {
  services: Service[];
  neighborhoods: Neighborhood[];
}

export async function useProfessionalSearch(
  options: ProfessionalSearchOptions,
) {
  const route = useRoute();
  const router = useRouter();
  const client = useApiClient();
  const professionalNameInput = shallowRef("");
  const serviceInput = shallowRef("");
  const neighborhoodInput = shallowRef("all");
  // Pages after the first are appended here; the async data always holds page 1.
  const additionalResults = shallowRef<PublicProfessionalCard[]>([]);
  const loadedPage = shallowRef(1);
  const loadingMore = shallowRef(false);

  const serviceQuery = computed(() => String(route.query.servico ?? "").trim());
  const professionalNameQuery = computed(() =>
    String(route.query.nome ?? "").trim(),
  );
  const hasSearchTerm = computed(() => serviceQuery.value.length > 0);
  const neighborhoodCode = computed(() => String(route.query.bairro ?? "all"));
  const selectedNeighborhood = computed(
    () =>
      options.neighborhoods.find(
        (item) => item.code === neighborhoodCode.value,
      ) ?? options.neighborhoods[0],
  );
  const effectiveNeighborhoodCode = computed(
    () => selectedNeighborhood.value?.code ?? "all",
  );
  const { data, error, status, refresh, clear } = await useAsyncData(
    "public-professional-search",
    () =>
      searchPublicProfessionals(client, {
        service: serviceQuery.value,
        professionalName: professionalNameQuery.value || null,
        neighborhoodCode:
          effectiveNeighborhoodCode.value === "all"
            ? null
            : effectiveNeighborhoodCode.value,
      }),
    {
      enabled: hasSearchTerm,
    },
  );

  watch(
    [serviceQuery, professionalNameQuery, effectiveNeighborhoodCode],
    () => {
      resetPaging();
      if (!hasSearchTerm.value) {
        clear();
        return;
      }

      void refresh();
    },
  );

  function resetPaging() {
    additionalResults.value = [];
    loadedPage.value = 1;
    loadingMore.value = false;
  }

  if (!hasSearchTerm.value) clear();

  const currentResult = computed(() => {
    if (!hasSearchTerm.value) return null;

    const result = data.value;
    if (!result) return null;
    if (
      result.normalizedTerm !== normalizeSearchText(serviceQuery.value) ||
      normalizeSearchText(result.professionalName ?? "") !==
        normalizeSearchText(professionalNameQuery.value) ||
      (result.neighborhood?.code ?? "all") !== effectiveNeighborhoodCode.value
    ) {
      return null;
    }

    return result;
  });
  const selectedService = computed(() => {
    if (!hasSearchTerm.value) return undefined;

    const resolvedService = currentResult.value?.resolvedService;
    if (resolvedService) {
      return options.services.find(
        (service) => service.id === resolvedService.id,
      );
    }

    return currentResult.value
      ? undefined
      : findService(options.services, serviceQuery.value);
  });

  const results = computed(() =>
    currentResult.value
      ? [...currentResult.value.professionals, ...additionalResults.value]
      : [],
  );
  const totalCount = computed(() => currentResult.value?.totalCount ?? 0);
  const hasMoreResults = computed(
    () => results.value.length < totalCount.value,
  );

  async function loadMoreResults() {
    if (loadingMore.value || !hasMoreResults.value) return;

    loadingMore.value = true;
    try {
      const nextPage = loadedPage.value + 1;
      const page = await searchPublicProfessionals(client, {
        service: serviceQuery.value,
        professionalName: professionalNameQuery.value || null,
        neighborhoodCode:
          effectiveNeighborhoodCode.value === "all"
            ? null
            : effectiveNeighborhoodCode.value,
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
  const relatedServices = computed(
    () => currentResult.value?.relatedServices ?? [],
  );
  const interaction = computed(() => currentResult.value?.interaction ?? null);
  const isSearching = computed(
    () => hasSearchTerm.value && currentResult.value === null && !error.value,
  );

  watch(
    [serviceQuery, professionalNameQuery, neighborhoodCode],
    () => {
      professionalNameInput.value = professionalNameQuery.value;
      serviceInput.value = selectedService.value?.name ?? serviceQuery.value;
      neighborhoodInput.value = effectiveNeighborhoodCode.value;
    },
    { immediate: true },
  );

  async function submitSearch(payload: ServiceSearchPayload) {
    const serviceTerm = payload.service.trim();
    if (!serviceTerm) return;

    const service = findService(options.services, serviceTerm);
    const professionalName = payload.professionalName.trim();
    await router.push({
      path: "/encontrar",
      query: {
        ...(professionalName ? { nome: professionalName } : {}),
        servico: service?.slug ?? serviceTerm,
        bairro: payload.neighborhood,
      },
    });
  }

  return {
    professionalNameInput,
    serviceInput,
    neighborhoodInput,
    professionalNameQuery,
    serviceQuery,
    hasSearchTerm,
    neighborhoodCode,
    selectedService,
    selectedNeighborhood,
    results,
    totalCount,
    hasMoreResults,
    loadingMore,
    loadMoreResults,
    relatedServices,
    interaction,
    isSearching,
    error,
    status,
    refresh,
    submitSearch,
  };
}
