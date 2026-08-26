import type { SearchLocation, SearchLocationSource } from "~/types";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { BerufeApiClient } from "~/services/api/client";

export interface ResolvedSearchLocation {
  location: SearchLocation;
  source: Extract<SearchLocationSource, "ip" | "fallback">;
}

export async function fetchPublicSearchLocation(
  client: BerufeApiClient,
): Promise<ResolvedSearchLocation> {
  const result = await client.GET("/api/v1/public/search-location");
  if (!result.data) {
    const failedResult = result as unknown as {
      error?: unknown;
      response: Response;
    };
    throw new ApiRequestError(
      normalizeApiError(
        failedResult.error,
        failedResult.response.headers.get("X-Request-Id") ?? "client",
      ),
    );
  }

  const { data } = result;

  return {
    location: {
      stateCode: data.data.state_code,
      city: data.data.city,
      stateSlug: data.data.state_slug,
      citySlug: data.data.city_slug,
    },
    source: data.data.source,
  };
}
