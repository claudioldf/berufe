<script setup lang="ts">
import { computed, onMounted, shallowRef } from "vue";
import { useApplicationSession } from "~/composables/useApplicationSession";
import { useAppRole } from "~/composables/useAppRole";
import { usePhoneAuthFlow } from "~/composables/usePhoneAuthFlow";
import { useProfessionalOnboarding } from "~/composables/useProfessionalOnboarding";
import { useToast } from "~/composables/useToast";
import {
  professionalPhoneStepContent,
  resolveProfessionalEntryPath,
  resolveProfessionalAuthIntent,
} from "~/utils/professional-auth";

const router = useRouter();
const route = useRoute();
const { setRole } = useAppRole();
const { showToast } = useToast();
const { initializeFromAuth } = useProfessionalOnboarding();
const { account, restoreSession, refreshSession } = useApplicationSession();
const {
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
  resumeRegistration,
  registerProfessional,
} = usePhoneAuthFlow();

const authIntent = computed(() =>
  resolveProfessionalAuthIntent(route.query.intent),
);
const phoneStepContent = computed(
  () => professionalPhoneStepContent[authIntent.value],
);
const sessionResolving = shallowRef(false);
const otpVerified = shallowRef(false);
const authLoading = computed(() => isLoading.value || sessionResolving.value);

useSeoMeta({
  title: () => phoneStepContent.value.pageTitle,
  robots: "noindex, nofollow",
});

async function enterProfessionalWorkspace() {
  const currentAccount = account.value;
  if (!currentAccount) return;
  await router.replace(resolveProfessionalEntryPath(currentAccount));
}

async function continueAuthenticatedFlow() {
  const currentAccount = account.value;
  if (!currentAccount) return;

  if (currentAccount.role !== "professional") return;

  if (currentAccount.registrationCompleted) {
    await enterProfessionalWorkspace();
  } else {
    if (currentAccount.registrationDisplayName) {
      name.value = currentAccount.registrationDisplayName;
    }
    resumeRegistration();
  }
}

async function confirmCode() {
  if (sessionResolving.value) return;
  sessionResolving.value = true;

  try {
    if (!otpVerified.value) {
      if (!(await verifyCode())) return;
      otpVerified.value = true;
    }
    if (!(await refreshSession())) {
      error.value =
        "Não foi possível confirmar sua sessão agora. Tente novamente em instantes.";
      return;
    }
    await continueAuthenticatedFlow();
  } catch {
    error.value =
      "Não foi possível confirmar sua sessão agora. Tente novamente em instantes.";
  } finally {
    sessionResolving.value = false;
  }
}

function restartPhoneEntry() {
  if (sessionResolving.value) return;
  otpVerified.value = false;
  changePhone();
}

async function register() {
  if (!(await registerProfessional())) return;

  try {
    if (!(await refreshSession())) {
      error.value =
        "Não foi possível confirmar sua sessão agora. Tente novamente em instantes.";
      return;
    }
  } catch {
    error.value =
      "Não foi possível confirmar sua sessão agora. Tente novamente em instantes.";
    return;
  }

  initializeFromAuth({ name: name.value, phone: phone.value });
  setRole("professional");
  const onboardingCompleted = account.value?.onboardingCompleted ?? false;
  showToast({
    title: onboardingCompleted ? "Acesso confirmado" : "Sucesso!",
    description: onboardingCompleted
      ? "Que bom ter você de volta."
      : "Vamos completar seu perfil na Berufe.",
  });
  await enterProfessionalWorkspace();
}

onMounted(async () => {
  try {
    if (await restoreSession()) {
      await continueAuthenticatedFlow();
    }
  } catch {
    // The OTP flow remains available when a prior session cannot be restored.
  }
});
</script>

<template>
  <div class="auth-page">
    <div class="auth-page__art">
      <div class="auth-page__art-content">
        <DesignSystemBrand />
        <div>
          <span class="auth-page__quote-icon"
            ><UIcon name="i-lucide-quote"
          /></span>
          <blockquote>
            “Meu trabalho já falava por mim. A Berufe ajudou mais gente a
            escutar.”
          </blockquote>
          <div class="auth-page__person">
            <DesignSystemAvatar
              name="João Vitor Santos"
              src="/images/professional-joao-vitor-santos-bricklayer.jpg"
              alt=""
              size="sm"
            />
            <span
              ><strong>João Vitor Santos</strong
              ><small>Pedreiro · membro fundador</small></span
            >
          </div>
        </div>
        <p>
          <UIcon name="i-lucide-shield-check" /> Perfil básico e contato direto.
        </p>
      </div>
    </div>

    <div class="auth-page__main">
      <NuxtLink class="auth-page__back" to="/"
        ><UIcon name="i-lucide-arrow-left" /> Voltar para o site</NuxtLink
      >

      <div class="auth-card">
        <div class="auth-progress">
          <span
            v-for="item in 3"
            :key="item"
            :class="{ active: item <= step }"
          />
        </div>

        <AuthPhoneStep
          v-if="step === 1"
          v-model="phone"
          :loading="authLoading"
          :error="error"
          :content="phoneStepContent"
          @submit="requestCode"
        />
        <AuthCodeStep
          v-else-if="step === 2"
          v-model="code"
          :phone="phone"
          :loading="authLoading"
          :error="error"
          :cooldown="cooldown"
          @change-phone="restartPhoneEntry"
          @resend="requestCode"
          @submit="confirmCode"
        />
        <AuthRegistrationStep
          v-else
          v-model:name="name"
          v-model:accepted="accepted"
          :error="error"
          :loading="authLoading"
          @submit="register"
        />
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.auth-page {
  min-height: calc(100vh - 76px);
  display: grid;
  grid-template-columns: 0.9fr 1.1fr;
  background: var(--color-surface-warm);
}

@media (width <= 850px) {
  .auth-page {
    grid-template-columns: 1fr;
  }
}

:deep() {
  .auth-page {
    min-height: calc(100vh - 76px);
    display: grid;
    grid-template-columns: 0.9fr 1.1fr;
    background: var(--color-surface-warm);
    &__art {
      position: relative;
      min-height: 720px;
      padding: 44px;
      background:
        linear-gradient(180deg, rgb(14 45 39 / 20%), rgb(14 45 39 / 90%)),
        url("/images/photo-1503387762-592deb58ef4e.jpg") center/cover;
      color: white;
    }
    &__art-content {
      position: relative;
      z-index: 2;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      height: 100%;
      max-width: 490px;
    }
    &__quote-icon {
      color: var(--coral);
      font-size: 2rem;
    }
    & blockquote {
      margin: 14px 0 22px;
      font-family: var(--font-display);
      font-size: clamp(2rem, 4vw, 3.6rem);
      letter-spacing: -0.04em;
      line-height: 1.05;
    }
    &__person {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    &__person strong,
    &__person small {
      display: block;
    }
    &__person strong {
      font-size: 0.84rem;
    }
    &__person small {
      margin-top: 3px;
      color: rgb(255 255 255 / 60%);
      font-size: 0.84rem;
    }
    &__art-content > p {
      display: flex;
      align-items: center;
      gap: 7px;
      color: rgb(255 255 255 / 70%);
      font-size: 0.86rem;
      font-weight: 700;
    }
    &__main {
      position: relative;
      display: grid;
      place-items: center;
      padding: 75px 50px;
    }
    &__back {
      position: absolute;
      top: 28px;
      right: 36px;
      display: flex;
      align-items: center;
      gap: 6px;
      color: var(--ink-soft);
      font-size: 0.86rem;
      font-weight: 700;
      text-decoration: none;
    }
  }
  .auth-card {
    width: min(100%, 480px);
  }
  .auth-progress {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 5px;
    margin-bottom: 54px;
  }
  .auth-progress span {
    height: 3px;
    border-radius: 99px;
    background: #d9d9d3;
  }
  .auth-progress span.active {
    background: var(--color-brand);
  }
  .auth-card {
    & h1 {
      margin: 0;
      font-family: var(--font-display);
      font-size: clamp(2.6rem, 5vw, 4.2rem);
      font-weight: 500;
      letter-spacing: -0.05em;
      line-height: 0.98;
      text-wrap: balance;
    }
    &__lead {
      margin: 18px 0 28px;
      color: var(--ink-soft);
      font-size: 0.85rem;
      line-height: 1.65;
    }
    & form {
      display: grid;
      gap: 15px;
    }
  }
  .auth-field {
    display: grid;
    gap: 7px;
  }
  .auth-field > span {
    color: var(--ink);
    font-size: 0.86rem;
    font-weight: 850;
  }
  .auth-field > div {
    display: grid;
    grid-template-columns: auto 1fr;
    align-items: center;
    overflow: hidden;
    border: 1px solid var(--line);
    border-radius: 12px;
    background: white;
  }
  .auth-field > div > span {
    padding: 14px;
    border-right: 1px solid var(--line);
    color: var(--ink-soft);
    font-size: 0.86rem;
  }
  .auth-field input {
    width: 100%;
    padding: 14px;
    border: 1px solid var(--line);
    border-radius: 12px;
    background: white;
    color: var(--ink);
    font-weight: 750;
  }
  .auth-field > div input {
    border: 0;
  }
  .auth-field input:focus,
  .auth-field > div:focus-within {
    border-color: var(--color-brand);
    box-shadow: 0 0 0 3px rgb(57 122 105 / 12%);
  }
  .auth-card {
    &__fineprint {
      margin: 14px 0 0;
      color: #88958f;
      font-size: 0.84rem;
      line-height: 1.55;
    }
  }
  .auth-error {
    display: flex;
    align-items: center;
    gap: 6px;
    margin: 0;
    color: #b33b31;
    font-size: 0.86rem;
    font-weight: 700;
  }
  .auth-code {
    font-size: 1.8rem !important;
    letter-spacing: 0.35em;
    text-align: center;
  }
  .resend {
    justify-self: center;
    border: 0;
    background: transparent;
    color: var(--color-brand);
    font-size: 0.86rem;
    font-weight: 800;
    cursor: pointer;
  }
  .resend:disabled {
    color: #88958f;
    cursor: default;
  }
  .auth-card {
    &__step-back {
      display: flex;
      align-items: center;
      gap: 5px;
      margin-bottom: 25px;
      padding: 0;
      border: 0;
      background: transparent;
      color: var(--ink-soft);
      font-size: 0.86rem;
      cursor: pointer;
    }
    &__success {
      display: grid;
      place-items: center;
      width: 50px;
      height: 50px;
      margin-bottom: 20px;
      border-radius: 16px;
      background: var(--mint);
      color: var(--color-brand);
      font-size: 1.35rem;
    }
  }
  .auth-check {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 9px;
    color: var(--ink-soft);
    font-size: 0.86rem;
    line-height: 1.5;
  }
  .auth-check input {
    margin-top: 2px;
    accent-color: var(--color-brand);
  }
  .auth-check a {
    color: var(--color-brand);
    font-weight: 800;
  }
  @media (width <= 850px) {
    .auth-page {
      grid-template-columns: 1fr;
      &__art {
        display: none;
      }
      &__main {
        min-height: 720px;
        padding: 90px 24px 60px;
      }
      &__back {
        top: 25px;
        left: 24px;
        right: auto;
      }
    }
  }
}
</style>
