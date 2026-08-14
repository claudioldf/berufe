<script setup lang="ts">
import { computed, shallowRef } from "vue";
import { useMockupApp } from "~/composables/useMockupApp";

const route = useRoute();
const router = useRouter();
const { activeRole } = useMockupApp();
const isMenuOpen = shallowRef(false);

const isProfessional = computed(() => route.path.startsWith("/painel"));
const isAdmin = computed(() => route.path.startsWith("/admin"));
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
      { label: "Visão geral", to: "/painel" },
      { label: "Meu perfil", to: "/painel/perfil" },
      { label: "Orçamentos", to: "/painel/orcamentos/novo" },
    ];
  }
  if (isAdmin.value) {
    return [
      { label: "Moderação", to: "/admin" },
      { label: "Catálogo", to: "/admin/catalogo" },
      { label: "Relatórios", to: "/admin/relatorios" },
    ];
  }
  return [
    { label: "Encontrar profissional", to: "/encontrar" },
    { label: "Como funciona", to: "/#como-funciona" },
    { label: "Para profissionais", to: "/entrar" },
  ];
});

async function changeRole(event: Event) {
  const role = (event.target as HTMLSelectElement)
    .value as typeof activeRole.value;
  activeRole.value = role;
  isMenuOpen.value = false;
  await router.push(
    role === "professional" ? "/painel" : role === "admin" ? "/admin" : "/",
  );
}

function isLinkActive(to: string) {
  if (to === "/admin") {
    return route.path === "/admin";
  }
  if (to === "/admin/relatorios") {
    return route.path === "/admin/relatorios";
  }
  if (to === "/admin/catalogo") {
    return route.path === "/admin/catalogo";
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
        <label class="role-switcher">
          <span>Explorar como</span>
          <select :value="currentRole" @change="changeRole">
            <option value="visitor">Visitante</option>
            <option value="professional">Profissional</option>
            <option value="admin">Administrador</option>
          </select>
          <UIcon name="i-lucide-chevron-down" />
        </label>
        <UButton
          v-if="!isProfessional && !isAdmin"
          to="/entrar"
          color="primary"
          label="Entrar"
          class="header__login"
        />
        <button
          class="header__menu"
          type="button"
          :aria-expanded="isMenuOpen"
          aria-label="Abrir menu"
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
    </nav>
  </header>
</template>

<style scoped lang="scss">
.header {
  position: relative;
  z-index: 40;
  border-bottom: 1px solid var(--line);
  background: rgba(247, 245, 239, 0.9);
  backdrop-filter: blur(18px);
  &--workspace {
    background: #17352f;
    color: white;
    border-color: rgba(255, 255, 255, 0.12);
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
  border: 1px solid currentColor;
  border-radius: 10px;
  background: transparent;
  color: inherit;
  font-size: 0.82rem;
  font-weight: 800;
  cursor: pointer;
}
.role-switcher select option {
  color: #17352f;
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
    border: 1px solid currentColor;
    border-radius: 12px;
    background: transparent;
    color: inherit;
    font-size: 1.2rem;
  }
  &__mobile-nav {
    display: none;
  }
}

@media (max-width: 900px) {
  .header {
    &__inner {
      grid-template-columns: 1fr auto;
    }
    &__nav,
    &__login {
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
  }
  .role-switcher span {
    display: none;
  }
}

@media (max-width: 520px) {
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
