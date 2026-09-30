import { computed, onScopeDispose, shallowRef, watch } from "vue";
import {
  ProfessionalOtpRequestError,
  requestProfessionalOtp,
  verifyProfessionalOtp,
  type ProfessionalAuthMethod,
  type RequestedProfessionalOtp,
  type RequestProfessionalOtpInput,
  type VerifyProfessionalOtpInput,
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

export type ProfessionalAuthStep = 1 | 2 | 3;

interface ProfessionalAuthFlowDependencies {
  requestOtp?: (
    input: RequestProfessionalOtpInput,
  ) => Promise<RequestedProfessionalOtp>;
  verifyOtp?: (input: VerifyProfessionalOtpInput) => Promise<void>;
  completeRegistration?: (
    input: CompleteProfessionalRegistrationInput,
  ) => Promise<unknown>;
}

export function useProfessionalAuthFlow(
  dependencies: ProfessionalAuthFlowDependencies = {},
) {
  const step = shallowRef<ProfessionalAuthStep>(1);
  const method = shallowRef<ProfessionalAuthMethod>("phone");
  const phone = shallowRef("");
  const email = shallowRef("");
  const code = shallowRef("");
  const name = shallowRef("");
  const accepted = shallowRef(false);
  const isLoading = shallowRef(false);
  const error = shallowRef("");
  const registrationFieldErrors = shallowRef<Record<string, string[]>>({});
  const cooldown = shallowRef(0);
  const challengeToken = shallowRef("");
  let cooldownTimer: ReturnType<typeof setInterval> | undefined;

  const cleanPhone = computed(() => normalizeBrazilianMobilePhone(phone.value));
  const cleanEmail = computed(() => email.value.trim().toLowerCase());
  const destination = computed(() =>
    method.value === "phone" ? phone.value : email.value,
  );
  const sendOtp =
    dependencies.requestOtp ??
    ((input: RequestProfessionalOtpInput) =>
      requestProfessionalOtp(useApiClient(), input));
  const confirmOtp =
    dependencies.verifyOtp ??
    ((input: VerifyProfessionalOtpInput) =>
      verifyProfessionalOtp(useApiClient(), input));
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

  function validEmail(value: string) {
    return (
      value.length >= 3 &&
      value.length <= 254 &&
      /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
    );
  }

  async function requestCode() {
    if (isLoading.value || (step.value === 2 && cooldown.value > 0)) return;

    error.value = "";
    const identifier =
      method.value === "phone" ? (cleanPhone.value ?? "") : cleanEmail.value;
    if (method.value === "phone" && !cleanPhone.value) {
      error.value = "Digite um número de celular válido.";
      return;
    }
    if (method.value === "email" && !validEmail(cleanEmail.value)) {
      error.value = "Digite um e-mail válido.";
      return;
    }

    isLoading.value = true;
    try {
      const requestedOtp = await sendOtp({ method: method.value, identifier });
      challengeToken.value = requestedOtp.challengeToken;
      if (method.value === "phone") {
        phone.value = formatBrazilianMobilePhone(cleanPhone.value ?? "");
      } else {
        email.value = cleanEmail.value;
      }
      step.value = 2;
      startCooldown(requestedOtp.resendAvailableIn);
    } catch (requestError) {
      if (
        requestError instanceof ProfessionalOtpRequestError &&
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

  async function verifyCode(): Promise<boolean> {
    if (isLoading.value) return false;

    error.value = "";
    if (!challengeToken.value || !/^\d{6}$/.test(code.value)) {
      error.value = "Código inválido ou expirado.";
      return false;
    }

    isLoading.value = true;
    try {
      await confirmOtp({
        challengeToken: challengeToken.value,
        code: code.value,
      });
      challengeToken.value = "";
      return true;
    } catch (verificationError) {
      error.value =
        verificationError instanceof ApiRequestError
          ? verificationError.message
          : "Não foi possível confirmar o código agora. Tente novamente em instantes.";
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  function changeDestination() {
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
    registrationFieldErrors.value = {};
    if (name.value.trim().length < 3) {
      error.value = "Informe seu nome profissional.";
      return false;
    }
    if (method.value === "phone" && !validEmail(cleanEmail.value)) {
      error.value = "Digite um e-mail válido.";
      return false;
    }
    if (method.value === "email" && !cleanPhone.value) {
      error.value = "Digite um número de celular válido.";
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
      const baseInput = {
        displayName: name.value.trim(),
        accepted: accepted.value,
      };
      await submitRegistration(
        method.value === "phone"
          ? { ...baseInput, method: "phone", email: cleanEmail.value }
          : { ...baseInput, method: "email", phone: cleanPhone.value ?? "" },
      );
      return true;
    } catch (registrationError) {
      if (registrationError instanceof ApiRequestError) {
        registrationFieldErrors.value = registrationError.fieldErrors;
        error.value = Object.keys(registrationError.fieldErrors).length
          ? ""
          : registrationError.message;
      } else {
        registrationFieldErrors.value = {};
        error.value =
          "Não foi possível criar seu perfil agora. Tente novamente em instantes.";
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  watch(method, () => {
    clearTimers();
    error.value = "";
    code.value = "";
    cooldown.value = 0;
    challengeToken.value = "";
    registrationFieldErrors.value = {};
  });

  watch([name, phone, email, accepted], () => {
    registrationFieldErrors.value = {};
  });

  onScopeDispose(clearTimers);

  return {
    step,
    method,
    phone,
    email,
    destination,
    code,
    name,
    accepted,
    isLoading,
    error,
    registrationFieldErrors,
    cooldown,
    challengeToken,
    requestCode,
    verifyCode,
    changeDestination,
    resumeRegistration,
    validateRegistration,
    registerProfessional,
  };
}
