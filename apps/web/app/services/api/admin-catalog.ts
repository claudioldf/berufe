import type { AdminCatalog } from "~/types";
import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { components } from "~/services/api/schema";

type AdminCatalogData = components["schemas"]["AdminCatalogData"];
export type AdminCatalogServiceCreateInput =
  components["schemas"]["AdminCatalogServiceCreateRequest"];
export type AdminCatalogServiceUpdateInput =
  components["schemas"]["AdminCatalogServiceUpdateRequest"];

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
      category: service.category_slug,
      active: service.is_active,
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
