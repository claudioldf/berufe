import { readonly, shallowRef } from "vue";
import type { SearchLocation, SearchLocationSource } from "~/types";
import { fetchPublicSearchLocation } from "~/services/api/search-location";
import { useApiClient } from "~/services/api/client";
import { fallbackSearchLocation } from "~/utils/searchLocation";

export function useDetectedSearchLocation() {
  const client = useApiClient();
  const location = shallowRef<SearchLocation>(fallbackSearchLocation);
  const source = shallowRef<SearchLocationSource>("fallback");
  const resolving = shallowRef(false);

  async function resolve() {
    if (resolving.value) return;

    resolving.value = true;
    try {
      const result = await fetchPublicSearchLocation(client);
      location.value = result.location;
      source.value = result.source;
    } catch {
      location.value = fallbackSearchLocation;
      source.value = "fallback";
    } finally {
      resolving.value = false;
    }
  }

  function select(nextLocation: SearchLocation) {
    location.value = nextLocation;
    source.value = "manual";
  }

  return {
    location: readonly(location),
    source: readonly(source),
    resolving: readonly(resolving),
    resolve,
    select,
  };
}
