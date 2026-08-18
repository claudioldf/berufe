import { readonly, shallowRef } from "vue";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import {
  createProfessionalRelationship,
  type ProfessionalRelationship,
  type ProfessionalRelationshipRequestInput,
} from "~/services/api/professional-relationships";

interface ProfessionalRelationshipDependencies {
  create?: (
    input: ProfessionalRelationshipRequestInput,
  ) => Promise<ProfessionalRelationship>;
}

export function useProfessionalRelationships(
  dependencies: ProfessionalRelationshipDependencies = {},
) {
  const client = useApiClient();
  const isSubmitting = shallowRef(false);
  const error = shallowRef("");
  const create =
    dependencies.create ??
    ((input: ProfessionalRelationshipRequestInput) =>
      createProfessionalRelationship(client, input));

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

  return {
    isSubmitting: readonly(isSubmitting),
    error: readonly(error),
    requestRelationship,
    clearError,
  };
}
