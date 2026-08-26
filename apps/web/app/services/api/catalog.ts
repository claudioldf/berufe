import type { PublicCatalog } from "~/types";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { BerufeApiClient } from "~/services/api/client";
import type { components } from "~/services/api/schema";

type CatalogData = components["schemas"]["CatalogData"];

export function mapPublicCatalog(data: CatalogData): PublicCatalog {
  return {
    categories: data.categories.map((category) => ({
      id: category.slug,
      name: category.name,
      icon: category.icon,
    })),
    services: data.services.map((service) => ({
      id: service.id,
      name: service.name,
      slug: service.slug,
      category: service.category_slug,
      icon: service.icon,
      description: service.description,
      aliases: service.aliases,
    })),
    cities: data.cities.map((city) => ({
      stateCode: city.state_code,
      city: city.city,
      stateSlug: city.state_slug,
      citySlug: city.city_slug,
    })),
    neighborhoods: [
      {
        code: "all",
        name: "Toda Joinville",
        stateCode: "SC",
        city: "Joinville",
      },
      ...data.neighborhoods.map((neighborhood) => ({
        code: neighborhood.code,
        name: neighborhood.name,
        stateCode: neighborhood.state_code,
        city: neighborhood.city,
      })),
    ],
  };
}

export async function fetchPublicCatalog(
  client: BerufeApiClient,
): Promise<PublicCatalog> {
  const { data, error, response } = await client.GET("/api/v1/catalog");
  if (error || !data) {
    throw new ApiRequestError(
      normalizeApiError(
        error,
        response.headers.get("X-Request-Id") ?? "client",
      ),
    );
  }

  return mapPublicCatalog(data.data);
}
