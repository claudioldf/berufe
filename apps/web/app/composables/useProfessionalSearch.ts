import { computed, shallowRef, watch } from "vue";
import type { Neighborhood, Professional, Service } from "~/types";
import { findService, professionalRelevance } from "~/utils/services";

interface ProfessionalSearchOptions {
  services: Service[];
  neighborhoods: Neighborhood[];
  professionals: Professional[];
  defaultService?: string;
}

export function useProfessionalSearch(options: ProfessionalSearchOptions) {
  const route = useRoute();
  const router = useRouter();
  const serviceInput = shallowRef("");
  const neighborhoodInput = shallowRef("all");

  const serviceQuery = computed(() =>
    String(route.query.servico ?? options.defaultService ?? "eletricista"),
  );
  const neighborhoodCode = computed(() => String(route.query.bairro ?? "all"));
  const selectedService = computed(() =>
    findService(options.services, serviceQuery.value),
  );
  const selectedNeighborhood = computed(
    () =>
      options.neighborhoods.find(
        (item) => item.code === neighborhoodCode.value,
      ) ?? options.neighborhoods[0],
  );

  const results = computed(() => {
    const service = selectedService.value;
    const neighborhood = selectedNeighborhood.value;
    if (!service) return [];

    return options.professionals
      .filter((professional) => professional.services.includes(service.name))
      .filter(
        (professional) =>
          neighborhood?.code === "all" ||
          professional.allJoinville ||
          professional.neighborhoods.includes(neighborhood?.name ?? ""),
      )
      .toSorted(
        (a, b) =>
          professionalRelevance(b, service, neighborhood) -
            professionalRelevance(a, service, neighborhood) ||
          b.updatedAt.localeCompare(a.updatedAt),
      );
  });

  const relatedServices = computed(() => {
    const service = selectedService.value;
    if (!service) return options.services.slice(0, 3);
    return options.services
      .filter(
        (item) => item.category === service.category && item.id !== service.id,
      )
      .slice(0, 3);
  });

  watch(
    [serviceQuery, neighborhoodCode],
    () => {
      serviceInput.value = selectedService.value?.name ?? serviceQuery.value;
      neighborhoodInput.value = neighborhoodCode.value;
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
    submitSearch,
  };
}
