<script setup lang="ts">
import { computed, shallowRef } from "vue";

const route = useRoute();
const isMenuOpen = shallowRef(false);

const professionalLoginPath = "/app/professional/login";
const adminLoginPath = "/app/admin/login";
const isProfessional = computed(
  () =>
    route.path.startsWith("/app/professional") &&
    route.path !== professionalLoginPath,
);
const isAdmin = computed(
  () => route.path.startsWith("/app/admin") && route.path !== adminLoginPath,
);

const links = computed(() => {
  if (isProfessional.value) {
    return [
      { label: "Visão geral", to: "/app/professional" },
      { label: "Gerenciar", to: "/app/professional/profile" },
      { label: "Orçamentos", to: "/app/professional/quotes" },
    ];
  }
  if (isAdmin.value) {
    return [
      { label: "Moderação", to: "/app/admin" },
      { label: "Catálogo", to: "/app/admin/catalog" },
      { label: "Relatórios", to: "/app/admin/reports" },
    ];
  }
  return [
    { label: "Encontrar profissional", to: "/encontrar" },
    { label: "Como funciona", to: "/#como-funciona" },
    { label: "Sou um profissional", to: professionalLoginPath },
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
  if (to === "/app/professional/quotes") {
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
        <UButton
          v-if="!isProfessional && !isAdmin"
          :to="professionalLoginPath"
          color="primary"
          label="Entrar"
          class="header__login"
        />
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
          <UIcon :name="isMenuOpen ? 'i-lucide-x' : 'i-lucide-menu'" />
        </button>
      </div>
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
    gap: 28px;
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
}
.header {
  &__menu {
    display: none;
    place-items: center;
    width: 42px;
    height: 42px;
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
    &__login,
    &__logout {
      display: none;
    }
    &__menu {
      display: grid;
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
