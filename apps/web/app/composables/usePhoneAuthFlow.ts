import { computed, onScopeDispose, shallowRef } from "vue";
import {
  PhoneOtpRequestError,
  requestPhoneOtp,
  type RequestedPhoneOtp,
} from "~/services/api/phone-auth";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import {
  formatBrazilianMobilePhone,
  normalizeBrazilianMobilePhone,
} from "~/utils/brazilian-phone";

export type PhoneAuthStep = 1 | 2 | 3;

interface PhoneAuthFlowDependencies {
  requestOtp?: (phone: string) => Promise<RequestedPhoneOtp>;
}

export function usePhoneAuthFlow(dependencies: PhoneAuthFlowDependencies = {}) {
  const step = shallowRef<PhoneAuthStep>(1);
  const phone = shallowRef("");
  const code = shallowRef("");
  const name = shallowRef("");
  const accepted = shallowRef(false);
  const isLoading = shallowRef(false);
  const error = shallowRef("");
  const cooldown = shallowRef(0);
  const challengeToken = shallowRef("");
  let loadingTimer: ReturnType<typeof setTimeout> | undefined;
  let cooldownTimer: ReturnType<typeof setInterval> | undefined;

  const cleanPhone = computed(() => normalizeBrazilianMobilePhone(phone.value));
  const sendOtp =
    dependencies.requestOtp ??
    ((phoneE164: string) => requestPhoneOtp(useApiClient(), phoneE164));

  function clearTimers() {
    if (loadingTimer) clearTimeout(loadingTimer);
    if (cooldownTimer) clearInterval(cooldownTimer);
    loadingTimer = undefined;
    cooldownTimer = undefined;
  }

  function simulateLoading(action: () => void) {
    if (loadingTimer) clearTimeout(loadingTimer);
    isLoading.value = true;
    loadingTimer = setTimeout(() => {
      loadingTimer = undefined;
      isLoading.value = false;
      action();
    }, 650);
  }

  function startCooldown(seconds: number) {
    if (cooldownTimer) clearInterval(cooldownTimer);
    cooldown.value = seconds;
    cooldownTimer = setInterval(() => {
      cooldown.value -= 1;
      if (cooldown.value <= 0 && cooldownTimer) {
        clearInterval(cooldownTimer);
        cooldownTimer = undefined;
      }
    }, 1000);
  }

  async function requestCode() {
    if (isLoading.value || (step.value === 2 && cooldown.value > 0)) return;

    error.value = "";
    if (!cleanPhone.value) {
      error.value = "Digite um número brasileiro válido.";
      return;
    }

    isLoading.value = true;
    try {
      const requestedOtp = await sendOtp(cleanPhone.value);
      challengeToken.value = requestedOtp.challengeToken;
      phone.value = formatBrazilianMobilePhone(cleanPhone.value);
      step.value = 2;
      startCooldown(requestedOtp.resendAvailableIn);
    } catch (requestError) {
      if (
        requestError instanceof PhoneOtpRequestError &&
        requestError.retryAfter
      ) {
        startCooldown(requestError.retryAfter);
      }
      error.value =
        requestError instanceof ApiRequestError
          ? requestError.message
          : "Não foi possível enviar o código agora. Tente novamente em instantes.";
    } finally {
      isLoading.value = false;
    }
  }

  function verifyCode() {
    error.value = "";
    if (code.value !== "123456") {
      error.value = "Código inválido ou expirado.";
      return;
    }
    simulateLoading(() => {
      step.value = 3;
    });
  }

  function changePhone() {
    error.value = "";
    code.value = "";
    challengeToken.value = "";
    step.value = 1;
  }

  function validateRegistration() {
    error.value = "";
    if (name.value.trim().length < 3) {
      error.value = "Informe seu nome profissional.";
      return false;
    }
    if (!accepted.value) {
      error.value = "Você precisa aceitar os termos e o aviso de privacidade.";
      return false;
    }
    return true;
  }

  onScopeDispose(clearTimers);

  return {
    step,
    phone,
    code,
    name,
    accepted,
    isLoading,
    error,
    cooldown,
    challengeToken,
    requestCode,
    verifyCode,
    changePhone,
    validateRegistration,
  };
}
