import { readonly, shallowRef } from "vue";
import {
  requestProfessionalDataErasure,
  type SubmittedDataErasureRequest,
} from "~/services/api/professional-data-erasure";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import { useApplicationSession } from "~/composables/useApplicationSession";

interface ProfessionalDataErasureDependencies {
  request?: () => Promise<SubmittedDataErasureRequest>;
}

export function useProfessionalDataErasure(
  dependencies: ProfessionalDataErasureDependencies = {},
) {
  const { clearSession } = useApplicationSession();
  const submitting = shallowRef(false);
  const error = shallowRef("");
  const sendRequest =
    dependencies.request ??
    (() => requestProfessionalDataErasure(useApiClient()));

  async function submit(): Promise<SubmittedDataErasureRequest | null> {
    if (submitting.value) return null;

    error.value = "";
    submitting.value = true;
    try {
      const result = await sendRequest();
      clearSession();
      return result;
    } catch (requestError) {
      error.value =
        requestError instanceof ApiRequestError
          ? requestError.message
          : "Não foi possível registrar a solicitação agora. Tente novamente.";
      return null;
    } finally {
      submitting.value = false;
    }
  }

  return {
    submitting: readonly(submitting),
    error: readonly(error),
    submit,
  };
}
