import type { AdminCatalog } from "~/types";
import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { components } from "~/services/api/schema";

type AdminCatalogData = components["schemas"]["AdminCatalogData"];
export type AdminCatalogServiceCreateInput =
  components["schemas"]["AdminCatalogServiceCreateRequest"];
export type AdminCatalogServiceUpdateInput =
  components["schemas"]["AdminCatalogServiceUpdateRequest"];
export type AdminCatalogNeighborhoodCreateInput =
  components["schemas"]["AdminCatalogNeighborhoodCreateRequest"];
export type AdminCatalogNeighborhoodUpdateInput =
  components["schemas"]["AdminCatalogNeighborhoodUpdateRequest"];

interface ApiResult {
  data?: { data: AdminCatalogData };
  error?: unknown;
  response: Response;
}

export function mapAdminCatalog(data: AdminCatalogData): AdminCatalog {
  return {
    categories: data.categories.map((category) => ({
      id: category.slug,
      name: category.name,
    })),
    services: data.services.map((service) => ({
      id: service.id,
      name: service.name,
      identifier: service.slug,
      description: service.description,
      category: service.categorySlug,
      active: service.isActive,
    })),
    neighborhoods: data.neighborhoods.map((neighborhood) => ({
      id: neighborhood.code,
      name: neighborhood.name,
      identifier: neighborhood.code,
      description: "",
      stateCode: neighborhood.stateCode,
      city: neighborhood.city,
      active: neighborhood.isActive,
    })),
  };
}

function requireAdminCatalog(result: ApiResult): AdminCatalog {
  if (result.error || !result.data) {
    throw new ApiRequestError(
      normalizeApiError(
        result.error,
        result.response.headers.get("X-Request-Id") ?? "client",
      ),
    );
  }

  return mapAdminCatalog(result.data.data);
}

export async function fetchAdminCatalog(
  client: BerufeApiClient,
): Promise<AdminCatalog> {
  return requireAdminCatalog(await client.GET("/api/v1/admin/catalog"));
}

export async function createAdminCatalogService(
  client: BerufeApiClient,
  input: AdminCatalogServiceCreateInput,
): Promise<AdminCatalog> {
  return requireAdminCatalog(
    await client.POST("/api/v1/admin/catalog/services", { body: input }),
  );
}

export async function updateAdminCatalogService(
  client: BerufeApiClient,
  id: string,
  input: AdminCatalogServiceUpdateInput,
): Promise<AdminCatalog> {
  return requireAdminCatalog(
    await client.PATCH("/api/v1/admin/catalog/services/{id}", {
      params: { path: { id } },
      body: input,
    }),
  );
}

export async function reorderAdminCatalogServices(
  client: BerufeApiClient,
  ids: string[],
): Promise<AdminCatalog> {
  return requireAdminCatalog(
    await client.PUT("/api/v1/admin/catalog/services/order", {
      body: { ids },
    }),
  );
}

export async function createAdminCatalogNeighborhood(
  client: BerufeApiClient,
  input: AdminCatalogNeighborhoodCreateInput,
): Promise<AdminCatalog> {
  return requireAdminCatalog(
    await client.POST("/api/v1/admin/catalog/neighborhoods", { body: input }),
  );
}

export async function updateAdminCatalogNeighborhood(
  client: BerufeApiClient,
  code: string,
  input: AdminCatalogNeighborhoodUpdateInput,
): Promise<AdminCatalog> {
  return requireAdminCatalog(
    await client.PATCH("/api/v1/admin/catalog/neighborhoods/{code}", {
      params: { path: { code } },
      body: input,
    }),
  );
}

export async function reorderAdminCatalogNeighborhoods(
  client: BerufeApiClient,
  codes: string[],
): Promise<AdminCatalog> {
  return requireAdminCatalog(
    await client.PUT("/api/v1/admin/catalog/neighborhoods/order", {
      body: { codes },
    }),
  );
}
