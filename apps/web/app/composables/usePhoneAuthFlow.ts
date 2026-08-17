import { computed, onScopeDispose, shallowRef } from "vue";
import {
  PhoneOtpRequestError,
  requestPhoneOtp,
  verifyPhoneOtp,
  type RequestedPhoneOtp,
  type VerifyPhoneOtpInput,
} from "~/services/api/phone-auth";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import {
  completeProfessionalRegistration,
  type CompleteProfessionalRegistrationInput,
} from "~/services/api/professional-registration";
import {
  formatBrazilianMobilePhone,
  normalizeBrazilianMobilePhone,
} from "~/utils/brazilian-phone";

export type PhoneAuthStep = 1 | 2 | 3;

interface PhoneAuthFlowDependencies {
  requestOtp?: (phone: string) => Promise<RequestedPhoneOtp>;
  verifyOtp?: (input: VerifyPhoneOtpInput) => Promise<void>;
  completeRegistration?: (
    input: CompleteProfessionalRegistrationInput,
  ) => Promise<unknown>;
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
  let cooldownTimer: ReturnType<typeof setInterval> | undefined;

  const cleanPhone = computed(() => normalizeBrazilianMobilePhone(phone.value));
  const sendOtp =
    dependencies.requestOtp ??
    ((phoneE164: string) => requestPhoneOtp(useApiClient(), phoneE164));
  const confirmOtp =
    dependencies.verifyOtp ??
    ((input: VerifyPhoneOtpInput) => verifyPhoneOtp(useApiClient(), input));
  const submitRegistration =
    dependencies.completeRegistration ??
    ((input: CompleteProfessionalRegistrationInput) =>
      completeProfessionalRegistration(useApiClient(), input));

  function clearTimers() {
    if (cooldownTimer) clearInterval(cooldownTimer);
    cooldownTimer = undefined;
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

  async function verifyCode() {
    if (isLoading.value) return;

    error.value = "";
    if (!challengeToken.value || !/^\d{6}$/.test(code.value)) {
      error.value = "Código inválido ou expirado.";
      return;
    }

    isLoading.value = true;
    try {
      await confirmOtp({
        challengeToken: challengeToken.value,
        code: code.value,
      });
      challengeToken.value = "";
      step.value = 3;
    } catch (verificationError) {
      error.value =
        verificationError instanceof ApiRequestError
          ? verificationError.message
          : "Não foi possível confirmar o código agora. Tente novamente em instantes.";
    } finally {
      isLoading.value = false;
    }
  }

  function changePhone() {
    error.value = "";
    code.value = "";
    challengeToken.value = "";
    step.value = 1;
  }

  function resumeRegistration() {
    clearTimers();
    error.value = "";
    code.value = "";
    challengeToken.value = "";
    step.value = 3;
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

  async function registerProfessional(): Promise<boolean> {
    if (isLoading.value || !validateRegistration()) return false;

    isLoading.value = true;
    try {
      await submitRegistration({
        displayName: name.value.trim(),
        accepted: accepted.value,
      });
      return true;
    } catch (registrationError) {
      error.value =
        registrationError instanceof ApiRequestError
          ? registrationError.message
          : "Não foi possível criar seu perfil agora. Tente novamente em instantes.";
      return false;
    } finally {
      isLoading.value = false;
    }
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
    resumeRegistration,
    validateRegistration,
    registerProfessional,
  };
}
