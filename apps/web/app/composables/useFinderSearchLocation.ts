import { readonly, shallowRef, toValue, watch } from "vue";
import type { MaybeRefOrGetter } from "vue";
import type { LocationCity, SearchLocation } from "~/types";
import { useApiClient } from "~/services/api/client";
import { fetchLocationCities } from "~/services/api/locations";
import {
  fallbackSearchLocation,
  findSearchLocationByRoute,
} from "~/utils/searchLocation";

function searchLocationFromCity(city: LocationCity): SearchLocation {
  return {
    cityCode: city.code,
    stateCode: city.stateAbbreviation,
    city: city.name,
    stateSlug: city.stateAbbreviation.toLowerCase(),
    citySlug: city.slug,
  };
}

export async function useFinderSearchLocation(options: {
  catalogLocations: MaybeRefOrGetter<SearchLocation[]>;
}) {
  const route = useRoute();
  const client = useApiClient();

  async function resolveRouteLocation() {
    const catalogLocation = findSearchLocationByRoute(
      [...toValue(options.catalogLocations), fallbackSearchLocation],
      route.params.state_code,
      route.params.city,
    );
    if (catalogLocation) return catalogLocation;

    const stateSlug = String(route.params.state_code ?? "").toLowerCase();
    const citySlug = String(route.params.city ?? "").toLowerCase();
    if (!/^[a-z]{2}$/.test(stateSlug) || !citySlug) return null;

    try {
      const cities = await fetchLocationCities(client, stateSlug.toUpperCase());
      const city = cities.find((candidate) => candidate.slug === citySlug);
      return city ? searchLocationFromCity(city) : null;
    } catch {
      return null;
    }
  }

  const initialLocation = await resolveRouteLocation();
  if (!initialLocation) {
    throw createError({
      statusCode: 404,
      statusMessage: "Cidade não atendida.",
    });
  }

  const location = shallowRef<SearchLocation>(initialLocation);
  let latestResolution = 0;

  watch(
    () => [route.params.state_code, route.params.city],
    async () => {
      const resolution = ++latestResolution;
      const nextLocation = await resolveRouteLocation();
      if (resolution !== latestResolution) return;
      if (!nextLocation) {
        showError({ statusCode: 404, statusMessage: "Cidade não atendida." });
        return;
      }

      location.value = nextLocation;
    },
  );

  function adopt(nextLocation: SearchLocation) {
    latestResolution += 1;
    location.value = nextLocation;
  }

  return {
    location: readonly(location),
    adopt,
  };
}
