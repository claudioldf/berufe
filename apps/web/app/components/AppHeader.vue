<script setup lang="ts">
import { computed, onMounted, shallowRef } from "vue";
import { useApplicationSession } from "~/composables/useApplicationSession";
import {
  professionalLoginPath,
  professionalSignupPath,
  resolveProfessionalEntryPath,
} from "~/utils/professional-auth";

const route = useRoute();
const isMenuOpen = shallowRef(false);
const { account, status, restoreSession } = useApplicationSession();

const adminLoginPath = "/app/admin/login";
const isProfessional = computed(
  () =>
    route.path.startsWith("/app/professional") &&
    route.path !== professionalLoginPath,
);
const isAdmin = computed(
  () => route.path.startsWith("/app/admin") && route.path !== adminLoginPath,
);
const showPublicAuthActions = computed(() => !route.path.startsWith("/app/"));
const isAuthenticatedProfessional = computed(
  () =>
    status.value === "authenticated" && account.value?.role === "professional",
);
const showProfessionalNotifications = computed(
  () =>
    isProfessional.value &&
    isAuthenticatedProfessional.value &&
    account.value?.registrationCompleted,
);
const publicProfessionalEntryPath = computed(() =>
  account.value
    ? resolveProfessionalEntryPath(account.value)
    : professionalLoginPath,
);
const publicProfessionalEntryLabel = computed(() =>
  account.value?.registrationCompleted ? "Ir ao painel" : "Continuar cadastro",
);

onMounted(() => {
  if (!showPublicAuthActions.value) return;
  void restoreSession().catch(() => {
    // Keep the visitor actions available when session restoration fails.
  });
});

const links = computed(() => {
  if (isProfessional.value) {
    return [
      { label: "Início", to: "/app/professional" },
      { label: "Orçamentos", to: "/app/professional/quotes" },
      { label: "Serviços", to: "/app/professional/services" },
      { label: "Gerenciar Perfil", to: "/app/professional/profile" },
    ];
  }
  if (isAdmin.value) {
    return [
      { label: "Moderação", to: "/app/admin" },
      { label: "Profissionais", to: "/app/admin/professionals" },
      { label: "Catálogo", to: "/app/admin/catalog" },
      { label: "Relatórios", to: "/app/admin/reports" },
      { label: "Auditoria de buscas", to: "/app/admin/search-audits" },
    ];
  }
  return [
    { label: "Buscar profissionais", to: "/encontrar" },
    { label: "Como funciona", to: "/#como-funciona" },
    { label: "Para profissionais", to: "/para-profissionais" },
  ];
});

function isLinkActive(to: string) {
  if (to === "/app/admin") {
    return route.path === "/app/admin";
  }
  if (to === "/app/admin/reports") {
    return route.path === "/app/admin/reports";
  }
  if (to === "/app/admin/catalog") {
    return route.path === "/app/admin/catalog";
  }
  if (to === "/app/admin/professionals") {
    return route.path === "/app/admin/professionals";
  }
  if (to === "/app/admin/search-audits") {
    return route.path === "/app/admin/search-audits";
  }
  if (to === "/app/professional/quotes" || to === "/para-profissionais") {
    return route.path === to || route.path.startsWith(`${to}/`);
  }
  return route.path === to;
}
</script>

<template>
  <header
    class="header"
    :class="{ 'header--workspace': isProfessional || isAdmin }"
  >
    <DesignSystemContainer class="header__inner">
      <DesignSystemBrand />

      <nav class="header__nav" aria-label="Navegação principal">
        <NuxtLink
          v-for="link in links"
          :key="link.to"
          class="header__link"
          :class="{ 'header__link--active': isLinkActive(link.to) }"
          :to="link.to"
          active-class=""
          exact-active-class=""
        >
          {{ link.label }}
        </NuxtLink>
      </nav>

      <div class="header__actions">
        <div v-if="showPublicAuthActions" class="header__desktop-auth">
          <UButton
            v-if="isAuthenticatedProfessional"
            :to="publicProfessionalEntryPath"
            color="primary"
            :label="publicProfessionalEntryLabel"
          />
          <UButton
            v-else
            :to="professionalLoginPath"
            color="neutral"
            variant="outline"
            label="Entrar"
          />
          <UButton
            v-if="!isAuthenticatedProfessional"
            :to="professionalSignupPath"
            color="primary"
            label="Criar perfil grátis"
          />
        </div>
        <UButton
          v-if="showPublicAuthActions && isAuthenticatedProfessional"
          :to="publicProfessionalEntryPath"
          color="primary"
          :label="publicProfessionalEntryLabel"
          class="header__mobile-login"
        />
        <UButton
          v-else-if="showPublicAuthActions"
          :to="professionalLoginPath"
          color="neutral"
          variant="ghost"
          label="Entrar"
          class="header__mobile-login"
        />
        <DashboardNotificationsHub v-if="showProfessionalNotifications" />
        <AuthSessionLogoutButton
          v-if="isProfessional || isAdmin"
          class="header__logout"
        />
        <button
          class="header__menu"
          type="button"
          :aria-expanded="isMenuOpen"
          :aria-label="isMenuOpen ? 'Fechar menu' : 'Abrir menu'"
          @click="isMenuOpen = !isMenuOpen"
        >
          <UIcon
            :name="isMenuOpen ? 'i-lucide-x' : 'i-lucide-menu'"
            aria-hidden="true"
          />
        </button>
      </div>
    </DesignSystemContainer>

    <DesignSystemContainer
      v-if="showPublicAuthActions && !isAuthenticatedProfessional"
      class="header__mobile-signup"
    >
      <UButton
        :to="professionalSignupPath"
        color="primary"
        label="Criar perfil grátis"
        class="header__mobile-signup-button"
      />
    </DesignSystemContainer>

    <nav
      v-if="isMenuOpen"
      class="header__mobile-nav"
      aria-label="Navegação móvel"
    >
      <NuxtLink
        v-for="link in links"
        :key="link.to"
        :to="link.to"
        @click="isMenuOpen = false"
      >
        {{ link.label }}
      </NuxtLink>
      <AuthSessionLogoutButton
        v-if="isProfessional || isAdmin"
        class="header__mobile-logout"
      />
    </nav>
  </header>
</template>

<style scoped lang="scss">
.header {
  position: relative;
  z-index: 40;
  border-bottom: 1px solid var(--line);
  background: rgb(247 245 239 / 90%);
  backdrop-filter: blur(18px);
  &--workspace {
    background: var(--color-brand-strong);
    color: white;
    border-color: rgb(255 255 255 / 12%);
  }
  &__inner {
    min-height: 76px;
    display: grid;
    grid-template-columns: 1fr auto 1fr;
    align-items: center;
    gap: 24px;
  }
  &__nav {
    display: flex;
    align-items: center;
    gap: 36px;
  }
  &__link {
    position: relative;
    color: inherit;
    font-size: 0.84rem;
    font-weight: 700;
    text-decoration: none;
    opacity: 0.72;
    transition: opacity 0.15s ease;
  }
  &__link:hover,
  &__link--active {
    opacity: 1;
  }
  &__link--active::after {
    content: "";
    position: absolute;
    left: 0;
    right: 0;
    bottom: -12px;
    height: 2px;
    border-radius: 99px;
    background: var(--coral);
  }
  &__actions {
    justify-self: end;
    display: flex;
    align-items: center;
    gap: 12px;
  }
  &__desktop-auth {
    display: flex;
    align-items: center;
    gap: 10px;
  }
  &__mobile-login,
  &__mobile-signup {
    display: none;
  }
}
.header {
  &__menu {
    display: none;
    place-items: center;
    width: 44px;
    height: 44px;
    border: 1px solid currentcolor;
    border-radius: 12px;
    background: transparent;
    color: inherit;
    font-size: 1.2rem;
  }
  &__mobile-nav {
    display: none;
  }
  &__mobile-logout {
    display: none;
  }
}

@media (width <= 900px) {
  .header {
    &__inner {
      grid-template-columns: 1fr auto;
    }
    &__nav,
    &__desktop-auth,
    &__logout {
      display: none;
    }
    &__mobile-login {
      display: inline-flex;
    }
    &__menu {
      display: grid;
    }
    &__mobile-signup {
      display: flex;
      padding-bottom: 14px;
    }
    &__mobile-signup-button {
      justify-content: center;
      width: 100%;
      min-height: 44px;
    }
    &__mobile-nav {
      display: grid;
      padding: 4px 20px 20px;
      border-top: 1px solid var(--line);
      background: inherit;
    }
    &__mobile-nav a {
      padding: 14px 4px;
      border-bottom: 1px solid var(--line);
      color: inherit;
      font-weight: 700;
      text-decoration: none;
    }
    &__mobile-logout {
      display: flex;
      justify-content: flex-start;
      margin-top: 8px;
      border-color: currentcolor;
    }
  }
}

@media (width <= 520px) {
  .header {
    &__inner {
      min-height: 68px;
    }
  }
}
</style>
