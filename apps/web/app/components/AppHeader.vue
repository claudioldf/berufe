<script setup lang="ts">
import { computed, shallowRef } from "vue";
import { useAppRole } from "~/composables/useAppRole";
import type { AppRole } from "~/types";

const route = useRoute();
const router = useRouter();
const runtimeConfig = useRuntimeConfig();
const { role: activeRole, setRole } = useAppRole();
const isMenuOpen = shallowRef(false);
const isPrototypeMode = computed(
  () => runtimeConfig.public.prototypeMode === true,
);

const professionalLoginPath = "/app/professional/login";
const isProfessional = computed(
  () =>
    route.path.startsWith("/app/professional") &&
    route.path !== professionalLoginPath,
);
const isAdmin = computed(() => route.path.startsWith("/app/admin"));
const currentRole = computed(() =>
  isProfessional.value
    ? "professional"
    : isAdmin.value
      ? "admin"
      : activeRole.value,
);

const links = computed(() => {
  if (isProfessional.value) {
    return [
      { label: "Visão geral", to: "/app/professional" },
      { label: "Meu perfil", to: "/app/professional/profile" },
      { label: "Orçamentos", to: "/app/professional/quotes/new" },
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
    { label: "Para profissionais", to: professionalLoginPath },
  ];
});

async function changeRole(event: Event) {
  const role = (event.target as HTMLSelectElement).value as AppRole;
  setRole(role);
  isMenuOpen.value = false;
  await router.push(
    role === "professional"
      ? "/app/professional"
      : role === "admin"
        ? "/app/admin"
        : "/",
  );
}

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
        <label v-if="isPrototypeMode" class="role-switcher">
          <span>Explorar como</span>
          <select name="preview-role" :value="currentRole" @change="changeRole">
            <option value="visitor">Visitante</option>
            <option value="professional">Profissional</option>
            <option value="admin">Administrador</option>
          </select>
          <UIcon name="i-lucide-chevron-down" />
        </label>
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
.role-switcher {
  position: relative;
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.82rem;
  font-weight: 700;
  opacity: 0.78;
}
.role-switcher span {
  white-space: nowrap;
}
.role-switcher select {
  appearance: none;
  padding: 9px 28px 9px 10px;
  border: 1px solid currentcolor;
  border-radius: 10px;
  background: transparent;
  color: inherit;
  font-size: 0.82rem;
  font-weight: 800;
  cursor: pointer;
}
.role-switcher select option {
  color: var(--color-brand-strong);
}
.role-switcher svg {
  position: absolute;
  right: 8px;
  pointer-events: none;
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
  .role-switcher span {
    display: none;
  }
}

@media (width <= 520px) {
  .header {
    &__inner {
      min-height: 68px;
    }
  }
  .role-switcher {
    display: none;
  }
}
</style>
