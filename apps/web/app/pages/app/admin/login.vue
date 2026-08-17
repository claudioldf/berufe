<script setup lang="ts">
import { onMounted } from "vue";
import { useAdminAuthFlow } from "~/composables/useAdminAuthFlow";
import { useApplicationSession } from "~/composables/useApplicationSession";

const router = useRouter();
const { account, session, restoreSession, refreshSession } =
  useApplicationSession();
const { email, password, isLoading, error, login } = useAdminAuthFlow();

useSeoMeta({
  title: "Acesso administrativo",
  robots: "noindex, nofollow",
});

async function enterAdminWorkspace(): Promise<boolean> {
  if (
    account.value?.role !== "admin" ||
    session.value?.authenticationMethod !== "password"
  ) {
    return false;
  }

  await router.replace("/app/admin");
  return true;
}

async function submitLogin() {
  if (!(await login())) return;

  try {
    if (!(await refreshSession()) || !(await enterAdminWorkspace())) {
      error.value = "Não foi possível confirmar sua sessão administrativa.";
    }
  } catch {
    error.value =
      "Não foi possível confirmar sua sessão agora. Tente novamente em instantes.";
  }
}

onMounted(async () => {
  try {
    if (await restoreSession()) await enterAdminWorkspace();
  } catch {
    // The administrator login remains available when a prior session cannot be restored.
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
        <AuthAdminLoginForm
          v-model:email="email"
          v-model:password="password"
          :loading="isLoading"
          :error="error"
          @submit="submitLogin"
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
    & h1 {
      margin: 0;
      font-family: var(--font-display);
      font-size: clamp(2.6rem, 5vw, 4.2rem);
      font-weight: 500;
      letter-spacing: -0.05em;
      line-height: 0.98;
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
  .auth-field input {
    width: 100%;
    padding: 14px;
    border: 1px solid var(--line);
    border-radius: 12px;
    background: white;
    color: var(--ink);
    font-weight: 750;
  }
  .auth-field input:focus {
    border-color: var(--color-brand);
    box-shadow: 0 0 0 3px rgb(57 122 105 / 12%);
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
