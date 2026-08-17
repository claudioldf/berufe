import { readonly, shallowRef } from "vue";
import type { AdminCatalog } from "~/types";
import {
  createAdminCatalogNeighborhood,
  createAdminCatalogService,
  fetchAdminCatalog,
  reorderAdminCatalogNeighborhoods,
  reorderAdminCatalogServices,
  updateAdminCatalogNeighborhood,
  updateAdminCatalogService,
  type AdminCatalogNeighborhoodCreateInput,
  type AdminCatalogNeighborhoodUpdateInput,
  type AdminCatalogServiceCreateInput,
  type AdminCatalogServiceUpdateInput,
} from "~/services/api/admin-catalog";
import { useApiClient } from "~/services/api/client";

const emptyCatalog = (): AdminCatalog => ({
  categories: [],
  services: [],
  neighborhoods: [],
});

interface AdminCatalogDependencies {
  load?: () => Promise<AdminCatalog>;
  createService?: (
    input: AdminCatalogServiceCreateInput,
  ) => Promise<AdminCatalog>;
  updateService?: (
    id: string,
    input: AdminCatalogServiceUpdateInput,
  ) => Promise<AdminCatalog>;
  reorderServices?: (ids: string[]) => Promise<AdminCatalog>;
  createNeighborhood?: (
    input: AdminCatalogNeighborhoodCreateInput,
  ) => Promise<AdminCatalog>;
  updateNeighborhood?: (
    code: string,
    input: AdminCatalogNeighborhoodUpdateInput,
  ) => Promise<AdminCatalog>;
  reorderNeighborhoods?: (codes: string[]) => Promise<AdminCatalog>;
  invalidatePublicCatalog?: () => Promise<void>;
}

export function useAdminCatalog(dependencies: AdminCatalogDependencies = {}) {
  const client = useApiClient();
  const catalog = shallowRef<AdminCatalog>(emptyCatalog());
  const isLoading = shallowRef(false);
  const isMutating = shallowRef(false);
  const loadError = shallowRef("");
  const loadCatalog = dependencies.load ?? (() => fetchAdminCatalog(client));
  const addService =
    dependencies.createService ??
    ((input) => createAdminCatalogService(client, input));
  const changeService =
    dependencies.updateService ??
    ((id, input) => updateAdminCatalogService(client, id, input));
  const orderServices =
    dependencies.reorderServices ??
    ((ids) => reorderAdminCatalogServices(client, ids));
  const addNeighborhood =
    dependencies.createNeighborhood ??
    ((input) => createAdminCatalogNeighborhood(client, input));
  const changeNeighborhood =
    dependencies.updateNeighborhood ??
    ((code, input) => updateAdminCatalogNeighborhood(client, code, input));
  const orderNeighborhoods =
    dependencies.reorderNeighborhoods ??
    ((codes) => reorderAdminCatalogNeighborhoods(client, codes));
  const invalidatePublicCatalog =
    dependencies.invalidatePublicCatalog ??
    (async () => clearNuxtData("public-catalog"));

  async function load() {
    if (isLoading.value) return;

    isLoading.value = true;
    loadError.value = "";
    try {
      catalog.value = await loadCatalog();
    } catch (error) {
      loadError.value =
        error instanceof Error
          ? error.message
          : "Não foi possível carregar o catálogo.";
      throw error;
    } finally {
      isLoading.value = false;
    }
  }

  async function mutate(operation: () => Promise<AdminCatalog>) {
    if (isMutating.value) return;

    isMutating.value = true;
    try {
      catalog.value = await operation();
      await invalidatePublicCatalog();
    } finally {
      isMutating.value = false;
    }
  }

  return {
    catalog: readonly(catalog),
    isLoading: readonly(isLoading),
    isMutating: readonly(isMutating),
    loadError: readonly(loadError),
    load,
    createService: (input: AdminCatalogServiceCreateInput) =>
      mutate(() => addService(input)),
    updateService: (id: string, input: AdminCatalogServiceUpdateInput) =>
      mutate(() => changeService(id, input)),
    reorderServices: (ids: string[]) => mutate(() => orderServices(ids)),
    createNeighborhood: (input: AdminCatalogNeighborhoodCreateInput) =>
      mutate(() => addNeighborhood(input)),
    updateNeighborhood: (
      code: string,
      input: AdminCatalogNeighborhoodUpdateInput,
    ) => mutate(() => changeNeighborhood(code, input)),
    reorderNeighborhoods: (codes: string[]) =>
      mutate(() => orderNeighborhoods(codes)),
  };
}
