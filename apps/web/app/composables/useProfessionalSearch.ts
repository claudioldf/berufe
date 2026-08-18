import { computed, shallowRef, watch } from "vue";
import type { Neighborhood, Service } from "~/types";
import { searchPublicProfessionals } from "~/services/api/public-discovery";
import { useApiClient } from "~/services/api/client";
import { findService } from "~/utils/services";
import { normalizeSearchText } from "~/utils/text";

interface ProfessionalSearchOptions {
  services: Service[];
  neighborhoods: Neighborhood[];
  defaultService?: string;
}

export async function useProfessionalSearch(
  options: ProfessionalSearchOptions,
) {
  const route = useRoute();
  const router = useRouter();
  const client = useApiClient();
  const serviceInput = shallowRef("");
  const neighborhoodInput = shallowRef("all");

  const serviceQuery = computed(() =>
    String(route.query.servico ?? options.defaultService ?? "eletricista"),
  );
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
  const { data, error, status, refresh } = await useAsyncData(
    "public-professional-search",
    () =>
      searchPublicProfessionals(client, {
        service: serviceQuery.value,
        neighborhoodCode:
          effectiveNeighborhoodCode.value === "all"
            ? null
            : effectiveNeighborhoodCode.value,
      }),
    { watch: [serviceQuery, effectiveNeighborhoodCode] },
  );
  const currentResult = computed(() => {
    const result = data.value;
    if (!result) return null;
    if (
      result.normalizedTerm !== normalizeSearchText(serviceQuery.value) ||
      (result.neighborhood?.code ?? "all") !== effectiveNeighborhoodCode.value
    ) {
      return null;
    }

    return result;
  });
  const selectedService = computed(() => {
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

  const results = computed(() => currentResult.value?.professionals ?? []);
  const relatedServices = computed(
    () => currentResult.value?.relatedServices ?? [],
  );
  const interaction = computed(() => currentResult.value?.interaction ?? null);

  watch(
    [serviceQuery, neighborhoodCode],
    () => {
      serviceInput.value = selectedService.value?.name ?? serviceQuery.value;
      neighborhoodInput.value = effectiveNeighborhoodCode.value;
    },
    { immediate: true },
  );

  async function submitSearch(payload: {
    service: string;
    neighborhood: string;
  }) {
    const service = findService(options.services, payload.service);
    await router.push({
      path: "/encontrar",
      query: {
        servico: service?.slug ?? payload.service,
        bairro: payload.neighborhood,
      },
    });
  }

  return {
    serviceInput,
    neighborhoodInput,
    serviceQuery,
    neighborhoodCode,
    selectedService,
    selectedNeighborhood,
    results,
    relatedServices,
    interaction,
    error,
    status,
    refresh,
    submitSearch,
  };
}
