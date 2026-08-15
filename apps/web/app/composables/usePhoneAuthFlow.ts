import { computed, onScopeDispose, shallowRef } from "vue";

export type PhoneAuthStep = 1 | 2 | 3;

export function usePhoneAuthFlow() {
  const step = shallowRef<PhoneAuthStep>(1);
  const phone = shallowRef("(47) 99999-1111");
  const code = shallowRef("");
  const name = shallowRef("Marcos Alves");
  const accepted = shallowRef(false);
  const isLoading = shallowRef(false);
  const error = shallowRef("");
  const cooldown = shallowRef(0);
  let loadingTimer: ReturnType<typeof setTimeout> | undefined;
  let cooldownTimer: ReturnType<typeof setInterval> | undefined;

  const cleanPhone = computed(() => phone.value.replace(/\D/g, ""));

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

  function startCooldown() {
    if (cooldownTimer) clearInterval(cooldownTimer);
    cooldown.value = 30;
    cooldownTimer = setInterval(() => {
      cooldown.value -= 1;
      if (cooldown.value <= 0 && cooldownTimer) {
        clearInterval(cooldownTimer);
        cooldownTimer = undefined;
      }
    }, 1000);
  }

  function requestCode() {
    error.value = "";
    if (cleanPhone.value.length < 10) {
      error.value = "Digite um número brasileiro válido.";
      return;
    }
    simulateLoading(() => {
      step.value = 2;
      startCooldown();
    });
  }

  function verifyCode() {
    error.value = "";
    if (code.value !== "123456") {
      error.value = "Código inválido ou expirado. Neste protótipo, use 123456.";
      return;
    }
    simulateLoading(() => {
      step.value = 3;
    });
  }

  function changePhone() {
    error.value = "";
    code.value = "";
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
    requestCode,
    verifyCode,
    changePhone,
    validateRegistration,
  };
}
