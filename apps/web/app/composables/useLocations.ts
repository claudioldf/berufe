import { readonly, shallowRef } from "vue";
import type { LocationCity, LocationState, Neighborhood } from "~/types";
import {
  fetchLocationCities,
  fetchLocationNeighborhoods,
  fetchLocationStates,
} from "~/services/api/locations";
import { useApiClient } from "~/services/api/client";

interface LocationDependencies {
  states?: () => Promise<LocationState[]>;
  cities?: (stateAbbreviation: string) => Promise<LocationCity[]>;
  neighborhoods?: (cityCode: string) => Promise<Neighborhood[]>;
}

export function useLocations(dependencies: LocationDependencies = {}) {
  const client =
    dependencies.states && dependencies.cities && dependencies.neighborhoods
      ? undefined
      : useApiClient();
  const getStates = dependencies.states ?? (() => fetchLocationStates(client!));
  const getCities =
    dependencies.cities ??
    ((stateAbbreviation: string) =>
      fetchLocationCities(client!, stateAbbreviation));
  const getNeighborhoods =
    dependencies.neighborhoods ??
    ((cityCode: string) => fetchLocationNeighborhoods(client!, cityCode));

  const states = shallowRef<LocationState[]>([]);
  const cities = shallowRef<LocationCity[]>([]);
  const neighborhoods = shallowRef<Neighborhood[]>([]);
  const loading = shallowRef(false);
  const error = shallowRef("");

  async function loadStates() {
    loading.value = true;
    error.value = "";
    try {
      states.value = await getStates();
      return states.value;
    } catch {
      error.value = "Não foi possível carregar os estados.";
      return [];
    } finally {
      loading.value = false;
    }
  }

  async function loadCities(stateAbbreviation: string) {
    loading.value = true;
    error.value = "";
    cities.value = [];
    neighborhoods.value = [];
    try {
      cities.value = await getCities(stateAbbreviation);
      return cities.value;
    } catch {
      error.value = "Não foi possível carregar as cidades.";
      return [];
    } finally {
      loading.value = false;
    }
  }

  async function loadNeighborhoods(cityCode: string) {
    loading.value = true;
    error.value = "";
    neighborhoods.value = [];
    try {
      neighborhoods.value = await getNeighborhoods(cityCode);
      return neighborhoods.value;
    } catch {
      error.value = "Não foi possível carregar os bairros.";
      return [];
    } finally {
      loading.value = false;
    }
  }

  async function initialize(cityCode = "") {
    const loadedStates = await loadStates();
    if (!cityCode) return null;

    const state = loadedStates.find((candidate) =>
      cityCode.startsWith(candidate.code),
    );
    if (!state) return null;

    const loadedCities = await loadCities(state.abbreviation);
    const city = loadedCities.find((candidate) => candidate.code === cityCode);
    if (!city) return null;

    await loadNeighborhoods(city.code);
    return { state, city };
  }

  return {
    states: readonly(states),
    cities: readonly(cities),
    neighborhoods: readonly(neighborhoods),
    loading: readonly(loading),
    error: readonly(error),
    loadStates,
    loadCities,
    loadNeighborhoods,
    initialize,
  };
}
