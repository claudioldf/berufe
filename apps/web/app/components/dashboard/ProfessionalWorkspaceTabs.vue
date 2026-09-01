<script setup lang="ts">
import { computed } from "vue";

const props = defineProps<{
  portfolioCount?: number;
  relationshipCount?: number;
}>();

const route = useRoute();
const tabs = [
  {
    id: "dados",
    label: "Dados do perfil",
    icon: "i-lucide-user-round",
    to: "/app/professional/profile",
  },
  {
    id: "portfolio",
    label: "Meus trabalhos",
    icon: "i-lucide-images",
    to: "/app/professional/profile?tab=portfolio",
  },
  {
    id: "clientes",
    label: "Clientes",
    icon: "i-lucide-contact-round",
    to: "/app/professional/customers",
  },
  {
    id: "recomendacoes",
    label: "Recomendações",
    icon: "i-lucide-message-square-heart",
    to: "/app/professional/recommendations",
  },
  {
    id: "relacoes",
    label: "Minha rede",
    icon: "i-lucide-handshake",
    to: "/app/professional/profile?tab=relacoes",
  },
  {
    id: "verificacoes",
    label: "Verificações",
    icon: "i-lucide-shield-check",
    to: "/app/professional/profile?tab=verificacoes",
  },
] as const;

const activeTab = computed(() => {
  if (route.path.startsWith("/app/professional/customers")) return "clientes";
  if (route.path.startsWith("/app/professional/recommendations"))
    return "recomendacoes";
  const requested = Array.isArray(route.query.tab)
    ? route.query.tab[0]
    : route.query.tab;
  return tabs.some(
    (tab) =>
      tab.id === requested && !["clientes", "recomendacoes"].includes(tab.id),
  )
    ? requested
    : "dados";
});

function countFor(tabId: string) {
  if (tabId === "portfolio") return props.portfolioCount;
  if (tabId === "relacoes") return props.relationshipCount;
  return undefined;
}
</script>

<template>
  <nav class="workspace-tabs" aria-label="Área profissional">
    <NuxtLink
      v-for="tab in tabs"
      :key="tab.id"
      :to="tab.to"
      :class="{ active: activeTab === tab.id }"
      :aria-current="activeTab === tab.id ? 'page' : undefined"
    >
      <UIcon :name="tab.icon" aria-hidden="true" />
      {{ tab.label }}
      <span v-if="countFor(tab.id) !== undefined" class="workspace-tabs__count">
        {{ countFor(tab.id) }}
      </span>
    </NuxtLink>
  </nav>
</template>

<style scoped lang="scss">
.workspace-tabs {
  position: sticky;
  top: 20px;
  align-self: start;
  display: grid;
  gap: 4px;

  & a {
    display: flex;
    align-items: center;
    gap: 8px;
    width: 100%;
    padding: 11px 12px;
    border-radius: 10px;
    color: var(--ink-soft);
    font-size: 0.86rem;
    font-weight: 800;
    text-align: left;
    text-decoration: none;
  }

  & a.active {
    background: white;
    color: var(--color-brand);
    box-shadow: 0 5px 15px rgb(23 53 47 / 6%);
  }

  &__count {
    margin-left: auto;
    padding: 3px 6px;
    border-radius: 6px;
    background: var(--paper-strong);
    font-size: 0.82rem;
  }
}

@media (width <= 760px) {
  .workspace-tabs {
    position: static;
    display: flex;
    overflow-x: auto;

    & a {
      width: auto;
      white-space: nowrap;
    }
  }
}
</style>
