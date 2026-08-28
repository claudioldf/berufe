import type { LocationCity, LocationState, Neighborhood } from "~/types";
import type { BerufeApiClient } from "./client";
import { ApiRequestError, normalizeApiError } from "./errors";

function requestError(error: unknown, response: Response) {
  return new ApiRequestError(
    normalizeApiError(error, response.headers.get("X-Request-Id") ?? "client"),
  );
}

export async function fetchLocationStates(
  client: BerufeApiClient,
): Promise<LocationState[]> {
  const { data, error, response } = await client.GET(
    "/api/v1/locations/states",
  );
  if (error || !data) throw requestError(error, response);
  return data.data.map((state) => ({
    code: state.code,
    abbreviation: state.abbreviation,
    name: state.name,
  }));
}

export async function fetchLocationCities(
  client: BerufeApiClient,
  stateAbbreviation: string,
): Promise<LocationCity[]> {
  const { data, error, response } = await client.GET(
    "/api/v1/locations/states/{state_abbreviation}/cities",
    { params: { path: { state_abbreviation: stateAbbreviation } } },
  );
  if (error || !data) throw requestError(error, response);
  return data.data.map((city) => ({
    code: city.code,
    name: city.name,
    slug: city.slug,
    stateCode: city.state_code,
    stateAbbreviation: city.state_abbreviation,
    stateName: city.state_name,
  }));
}

export async function fetchLocationNeighborhoods(
  client: BerufeApiClient,
  cityCode: string,
): Promise<Neighborhood[]> {
  const { data, error, response } = await client.GET(
    "/api/v1/locations/cities/{city_code}/neighborhoods",
    { params: { path: { city_code: cityCode } } },
  );
  if (error || !data) throw requestError(error, response);
  return data.data.map((neighborhood) => ({
    code: neighborhood.code,
    cityCode: neighborhood.city_code,
    name: neighborhood.name,
  }));
}
