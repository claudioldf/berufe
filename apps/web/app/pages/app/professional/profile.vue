<script setup lang="ts">
import { computed } from "vue";
import professionalsData from "@data/professionals.json";
import type { Professional, ProfessionalProfileDraft } from "~/types";
import { useCatalogs } from "~/composables/useCatalogs";
import { useToast } from "~/composables/useToast";
import { ApiRequestError } from "~/services/api/errors";

const route = useRoute();
const router = useRouter();
const { showToast } = useToast();
const mockProfessional = (professionalsData as Professional[])[0]!;
const { data: catalog, error: catalogError } = await useCatalogs();
if (catalogError.value || !catalog.value) {
  throw createError({
    statusCode: 503,
    statusMessage: "Catálogo temporariamente indisponível.",
  });
}
const services = computed(() => catalog.value?.services ?? []);
const neighborhoods = computed(() =>
  (catalog.value?.neighborhoods ?? []).filter((item) => item.code !== "all"),
);
const {
  data: workspace,
  error: workspaceError,
  saveProfile: saveWorkspaceProfile,
} = await useProfessionalWorkspace();
if (workspaceError.value || !workspace.value) {
  throw createError({
    statusCode: 503,
    statusMessage: "Seu perfil está temporariamente indisponível.",
  });
}
const saving = shallowRef(false);
const professional = computed<Professional>(() => ({
  ...mockProfessional,
  id: workspace.value!.profile.id,
  slug: workspace.value!.profile.publicSlug,
  name: workspace.value!.profile.identity.name,
  headline: workspace.value!.profile.identity.headline,
  bio: workspace.value!.profile.identity.bio,
  yearsExperience: workspace.value!.profile.identity.yearsExperience,
  whatsapp: workspace.value!.profile.identity.whatsapp,
  instagram: workspace.value!.profile.identity.instagram || undefined,
  youtube: workspace.value!.profile.identity.youtube || undefined,
  primaryService:
    workspace.value!.profile.services.find((service) => service.isPrimary)
      ?.name ?? "",
  services: workspace.value!.profile.services.map((service) => service.name),
  serviceNotes: workspace
    .value!.profile.services.map((service) => service.note)
    .filter(Boolean),
  allJoinville: workspace.value!.profile.coverage.allJoinville,
  neighborhoods: workspace.value!.profile.coverage.neighborhoods.map(
    (neighborhood) => neighborhood.name,
  ),
}));
const statusLabels = {
  draft: "Rascunho",
  pending_review: "Em análise",
  published: "Publicado",
  suspended: "Suspenso",
} as const;
const statusLabel = computed(() =>
  workspace.value!.profile.hasPublishedRevision &&
  workspace.value!.profile.revisionStatus === "pending_review"
    ? "Alterações em análise"
    : statusLabels[workspace.value!.profile.status],
);
const tabs = [
  { id: "dados", label: "Dados do perfil", icon: "i-lucide-user-round" },
  { id: "portfolio", label: "Portfólio", icon: "i-lucide-images" },
  { id: "verificacoes", label: "Verificações", icon: "i-lucide-shield-check" },
];
const activeTab = computed(() =>
  tabs.some((tab) => tab.id === route.query.tab)
    ? String(route.query.tab)
    : "dados",
);

definePageMeta({ layout: "workspace" });

useSeoMeta({
  title: "Editar perfil profissional",
  robots: "noindex, nofollow",
});

async function selectTab(id: string) {
  await router.replace({ query: id === "dados" ? {} : { tab: id } });
}

async function saveProfile(
  draft: ProfessionalProfileDraft,
  confirm: () => void,
) {
  if (saving.value) return;

  saving.value = true;
  try {
    await saveWorkspaceProfile(draft, services.value, neighborhoods.value);
    confirm();
    showToast({
      title: "Perfil atualizado",
      description: "As alterações foram salvas.",
    });
  } catch (error) {
    showToast({
      title: "Não foi possível salvar",
      description:
        error instanceof ApiRequestError
          ? error.message
          : "Tente novamente em instantes.",
    });
  } finally {
    saving.value = false;
  }
}
</script>

<template>
  <div class="profile-workspace">
    <section class="workspace-heading">
      <DesignSystemContainer class="workspace-heading__inner">
        <div>
          <NuxtLink to="/app/professional"
            ><UIcon name="i-lucide-arrow-left" /> Painel</NuxtLink
          >
          <h1>Meu perfil</h1>
          <p>Organize as informações e evidências que clientes verão.</p>
        </div>
        <span><DesignSystemStatusDot tone="success" /> {{ statusLabel }}</span>
      </DesignSystemContainer>
    </section>
    <DesignSystemContainer class="profile-workspace__content">
      <nav class="workspace-tabs" aria-label="Seções do perfil">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          type="button"
          :class="{ active: activeTab === tab.id }"
          @click="selectTab(tab.id)"
        >
          <UIcon :name="tab.icon" />{{ tab.label
          }}<span v-if="tab.id === 'portfolio'" class="workspace-tabs__count">{{
            professional.portfolio.length
          }}</span>
        </button>
      </nav>
      <DashboardProfileEditor
        v-if="activeTab === 'dados'"
        :professional="professional"
        :services="services"
        :neighborhoods="neighborhoods"
        :saving="saving"
        @save="saveProfile"
      />
      <DashboardPortfolioManager
        v-else-if="activeTab === 'portfolio'"
        :items="professional.portfolio"
        @added="
          showToast({
            title: 'Trabalho enviado',
            description: 'Ele aparecerá no perfil depois da análise.',
          })
        "
      />
      <DashboardVerificationPanel
        v-else
        :evidence="professional.evidence"
        @submitted="
          showToast({
            title: 'Verificação enviada',
            description: 'A equipe Berufe fará a conferência manual.',
          })
        "
      />
    </DesignSystemContainer>
  </div>
</template>

<style scoped lang="scss">
.profile-workspace {
  min-height: 100vh;
  padding-bottom: 80px;
  background: var(--color-surface-canvas);
}
.workspace-heading {
  padding: 34px 0 38px;
  background: var(--color-brand-strong);
  color: white;
  &__inner {
    display: flex;
    justify-content: space-between;
    align-items: end;
  }
  & a {
    display: flex;
    align-items: center;
    gap: 5px;
    margin-bottom: 20px;
    color: rgb(255 255 255 / 58%);
    font-size: 0.86rem;
    font-weight: 700;
    text-decoration: none;
  }
  & h1 {
    margin: 0;
    font-family: var(--font-display);
    font-size: 2.7rem;
    font-weight: 500;
    letter-spacing: -0.04em;
  }
  & p {
    margin: 7px 0 0;
    color: rgb(255 255 255 / 59%);
    font-size: 0.84rem;
  }
  &__inner > span {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 7px 10px;
    border: 1px solid rgb(255 255 255 / 16%);
    border-radius: 9px;
    color: #b7dfd3;
    font-size: 0.84rem;
    font-weight: 850;
  }
}
.profile-workspace {
  &__content {
    display: grid;
    grid-template-columns: 190px minmax(0, 1fr);
    gap: 28px;
    padding-top: 26px;
  }
}
.workspace-tabs {
  position: sticky;
  top: 20px;
  align-self: start;
  display: grid;
  gap: 4px;
  & button {
    display: flex;
    align-items: center;
    gap: 8px;
    width: 100%;
    padding: 11px 12px;
    border: 0;
    border-radius: 10px;
    background: transparent;
    color: var(--ink-soft);
    font-size: 0.86rem;
    font-weight: 800;
    text-align: left;
    cursor: pointer;
  }
  & button.active {
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
  .profile-workspace {
    &__content {
      grid-template-columns: 1fr;
    }
  }
  .workspace-tabs {
    position: static;
    display: flex;
    overflow-x: auto;
  }
  .workspace-tabs button {
    width: auto;
    white-space: nowrap;
  }
  .workspace-heading {
    &__inner > span {
      display: none;
    }
  }
}
</style>
