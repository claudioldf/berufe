import { readonly, shallowRef } from "vue";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import {
  createProfessionalRelationship,
  searchProfessionalRelationshipCandidates,
  type ProfessionalRelationship,
  type ProfessionalRelationshipCandidate,
  type ProfessionalRelationshipRequestInput,
} from "~/services/api/professional-relationships";

interface ProfessionalRelationshipDependencies {
  create?: (
    input: ProfessionalRelationshipRequestInput,
  ) => Promise<ProfessionalRelationship>;
  search?: (query: string) => Promise<ProfessionalRelationshipCandidate[]>;
}

export function useProfessionalRelationships(
  dependencies: ProfessionalRelationshipDependencies = {},
) {
  const client = useApiClient();
  const isSubmitting = shallowRef(false);
  const error = shallowRef("");
  const searchError = shallowRef("");
  const candidates = shallowRef<ProfessionalRelationshipCandidate[]>([]);
  const isSearching = shallowRef(false);
  const searchedQuery = shallowRef("");
  let latestSearch = 0;
  const create =
    dependencies.create ??
    ((input: ProfessionalRelationshipRequestInput) =>
      createProfessionalRelationship(client, input));
  const search =
    dependencies.search ??
    ((query: string) =>
      searchProfessionalRelationshipCandidates(client, query));

  async function searchCandidates(query: string) {
    const normalized = query.trim();
    const searchId = ++latestSearch;
    if (normalized.length < 2) {
      candidates.value = [];
      isSearching.value = false;
      searchedQuery.value = "";
      searchError.value = "";
      return [];
    }

    isSearching.value = true;
    searchError.value = "";
    try {
      const result = await search(normalized);
      if (searchId === latestSearch) {
        candidates.value = result;
        searchedQuery.value = normalized;
      }
      return result;
    } catch (failure) {
      if (searchId === latestSearch) {
        candidates.value = [];
        searchedQuery.value = normalized;
        searchError.value =
          failure instanceof ApiRequestError
            ? failure.message
            : "Não foi possível buscar profissionais agora.";
      }
      throw failure;
    } finally {
      if (searchId === latestSearch) isSearching.value = false;
    }
  }

  async function requestRelationship(
    input: ProfessionalRelationshipRequestInput,
  ) {
    if (isSubmitting.value) return undefined;

    isSubmitting.value = true;
    error.value = "";
    try {
      return await create(input);
    } catch (failure) {
      error.value =
        failure instanceof ApiRequestError
          ? failure.message
          : "Não foi possível enviar a solicitação agora. Tente novamente.";
      throw failure;
    } finally {
      isSubmitting.value = false;
    }
  }

  function clearError() {
    error.value = "";
  }

  function clearCandidates() {
    latestSearch += 1;
    candidates.value = [];
    isSearching.value = false;
    searchedQuery.value = "";
    searchError.value = "";
  }

  return {
    isSubmitting: readonly(isSubmitting),
    error: readonly(error),
    searchError: readonly(searchError),
    candidates: readonly(candidates),
    isSearching: readonly(isSearching),
    searchedQuery: readonly(searchedQuery),
    searchCandidates,
    clearCandidates,
    requestRelationship,
    clearError,
  };
}
