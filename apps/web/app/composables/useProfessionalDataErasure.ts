import { computed, onScopeDispose, readonly, shallowRef } from "vue";
import {
  requestProfessionalDataErasure,
  type SubmittedDataErasureRequest,
} from "~/services/api/professional-data-erasure";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import { useApplicationSession } from "~/composables/useApplicationSession";

const recentVerificationWindowMs = 30 * 60 * 1000;

interface ProfessionalDataErasureDependencies {
  request?: (confirmation: string) => Promise<SubmittedDataErasureRequest>;
  now?: () => number;
}

export function useProfessionalDataErasure(
  dependencies: ProfessionalDataErasureDependencies = {},
) {
  const { session, clearSession } = useApplicationSession();
  const submitting = shallowRef(false);
  const error = shallowRef("");
  const sendRequest =
    dependencies.request ??
    ((confirmation: string) =>
      requestProfessionalDataErasure(useApiClient(), confirmation));
  const now = dependencies.now ?? Date.now;
  const currentTime = shallowRef(now());
  if (import.meta.client) {
    const verificationClock = window.setInterval(() => {
      currentTime.value = now();
    }, 1_000);
    onScopeDispose(() => window.clearInterval(verificationClock));
  }
  const isRecentlyVerified = computed(() => {
    if (session.value?.authenticationMethod !== "sms_otp") return false;

    const authenticatedAt = Date.parse(session.value.authenticatedAt);
    const elapsed = currentTime.value - authenticatedAt;
    return (
      Number.isFinite(authenticatedAt) &&
      elapsed >= 0 &&
      elapsed <= recentVerificationWindowMs
    );
  });

  async function submit(
    confirmation: string,
  ): Promise<SubmittedDataErasureRequest | null> {
    if (submitting.value) return null;

    error.value = "";
    submitting.value = true;
    try {
      const result = await sendRequest(confirmation);
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
    isRecentlyVerified,
    submitting: readonly(submitting),
    error: readonly(error),
    submit,
  };
}
