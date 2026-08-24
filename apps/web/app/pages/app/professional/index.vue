<script setup lang="ts">
import type { OnboardingChecklistItem } from "~/types";
import { useProfessionalWorkspace } from "~/composables/useProfessionalWorkspace";
import { useApplicationSession } from "~/composables/useApplicationSession";
import { useCatalogs } from "~/composables/useCatalogs";
import { useShare } from "~/composables/useShare";
import { useToast } from "~/composables/useToast";
import type { ProfessionalRelationshipResponse } from "~/services/api/professional-relationships";

const runtimeConfig = useRuntimeConfig();
const { share } = useShare();
const { showToast } = useToast();
const { account } = useApplicationSession();
const { data: relationshipCatalog } = await useCatalogs();
const professionalWorkspace = await useProfessionalWorkspace();
const relationshipOpen = shallowRef(false);
const relationshipServices = computed(
  () => relationshipCatalog.value?.services ?? [],
);
const relationshipNeighborhoods = computed(() =>
  (relationshipCatalog.value?.neighborhoods ?? []).filter(
    (item) => item.code !== "all",
  ),
);
const relationshipEligible = computed(
  () => account.value?.relationshipEligible ?? false,
);
const workspace = computed(() => professionalWorkspace.data.value);
const professionalFirstName = computed(
  () =>
    workspace.value?.profile.identity.name.trim().split(" ")[0] ??
    "profissional",
);
const siteUrl = String(
  runtimeConfig.public.siteUrl || "http://localhost:3000",
).replace(/\/$/, "");
const publicProfileUrl = computed(() =>
  workspace.value
    ? `${siteUrl}/profissionais/${workspace.value.profile.publicSlug}`
    : "",
);
const localDateLabel = computed(() => {
  const value = workspace.value?.dashboard.localDate;
  if (!value) return "";
  return new Intl.DateTimeFormat("pt-BR", {
    weekday: "long",
    day: "numeric",
    month: "long",
    timeZone: "UTC",
  }).format(new Date(`${value}T12:00:00Z`));
});
const checklist = computed<OnboardingChecklistItem[]>(() => {
  const steps = workspace.value?.dashboard.readiness.steps;
  return [
    {
      id: "profile",
      label: "Base do perfil",
      description: "Nome, foto, nascimento e contato",
      icon: "i-lucide-user-round",
      done: steps?.identityContact ?? false,
      to: "/app/professional/profile",
    },
    {
      id: "services",
      label: "Serviços e bairros",
      description: "Serviço e cobertura de Joinville",
      icon: "i-lucide-briefcase-business",
      done: steps?.serviceCoverage ?? false,
      to: "/app/professional/profile",
    },
    {
      id: "portfolio",
      label: "Primeiro trabalho",
      description: "Um trabalho em análise ou aprovado",
      icon: "i-lucide-image-plus",
      done: steps?.reviewablePortfolio ?? false,
      to: "/app/professional/profile?tab=portfolio",
    },
    {
      id: "verification",
      label: "Identidade verificada",
      description: "Sua evidência foi aprovada pela equipe",
      icon: "i-lucide-shield-check",
      done: steps?.approvedIdentity ?? false,
      to: "/app/professional/profile?tab=verificacoes",
    },
  ];
});
const progress = computed(
  () => workspace.value?.dashboard.readiness.percentage ?? 0,
);
const canPublish = computed(() => {
  const profile = workspace.value?.profile;
  if (!profile) return false;

  return (
    !profile.hasPublishedRevision &&
    profile.revisionStatus === "draft" &&
    profile.publicationBlockers.length === 0
  );
});
const dashboardStatus = computed(() => {
  const profile = workspace.value?.profile;
  if (!profile) {
    return {
      title: "Painel profissional",
      description: "Carregando seus dados.",
      icon: "i-lucide-clock-3",
      tone: "pending",
      publicAvailable: false,
    };
  }
  if (profile.isPublic) {
    if (profile.presentationType === "external") {
      return {
        title: "Seu perfil básico está publicado",
        description:
          "Complete os dados para publicar sua versão profissional completa.",
        icon: "i-lucide-user-round-check",
        tone: "published",
        publicAvailable: true,
      };
    }
    return {
      title: "Seu perfil está publicado",
      description: "Clientes já podem encontrar e entrar em contato com você.",
      icon: "i-lucide-badge-check",
      tone: "published",
      publicAvailable: true,
    };
  }
  if (profile.status === "suspended") {
    return {
      title: "Seu perfil está temporariamente oculto",
      description: "Revise as pendências antes de voltar a divulgá-lo.",
      icon: "i-lucide-circle-alert",
      tone: "attention",
      publicAvailable: false,
    };
  }
  if (profile.status === "published") {
    const blockerLabels = {
      identity: "nome e data de nascimento",
      photo: "foto profissional",
      services: "serviço principal",
      coverage: "cobertura em Joinville",
    } as const;
    const missing = profile.publicationBlockers.map(
      (blocker) => blockerLabels[blocker],
    );
    return {
      title: "Seu perfil está temporariamente indisponível",
      description: missing.length
        ? `Complete: ${missing.join(", ")}.`
        : "Edite o conteúdo indicado pela equipe para voltar ao ar.",
      icon: "i-lucide-circle-alert",
      tone: "attention",
      publicAvailable: false,
    };
  }
  if (canPublish.value) {
    return {
      title: "Seu perfil está pronto para publicar",
      description:
        "Os dados obrigatórios estão completos. Publique agora para aparecer aos clientes.",
      icon: "i-lucide-megaphone",
      tone: "pending",
      publicAvailable: false,
    };
  }
  if (profile.revisionStatus === "rejected") {
    return {
      title: "Seu perfil precisa de ajustes",
      description:
        profile.revisionRejectionReason ??
        "Edite os dados indicados e envie o perfil novamente.",
      icon: "i-lucide-circle-alert",
      tone: "attention",
      publicAvailable: false,
    };
  }
  if (
    profile.status === "pending_review" ||
    profile.revisionStatus === "pending_review"
  ) {
    return {
      title: "Seu perfil está em análise",
      description:
        "A equipe está conferindo os dados; conteúdo válido já fica público.",
      icon: "i-lucide-clock-3",
      tone: "pending",
      publicAvailable: false,
    };
  }
  return {
    title: "Seu perfil ainda não está publicado",
    description: "Complete nome, foto, serviço e cobertura para publicar.",
    icon: "i-lucide-circle-alert",
    tone: "attention",
    publicAvailable: false,
  };
});
const recentQuotes = computed(
  () => workspace.value?.dashboard.recentQuotes ?? [],
);
const recentServices = computed(
  () => workspace.value?.dashboard.recentServiceJobs ?? [],
);

definePageMeta({ layout: "workspace" });

useSeoMeta({
  title: "Painel profissional",
  robots: "noindex, nofollow",
});

async function shareProfile() {
  const data = workspace.value;
  if (!data || !dashboardStatus.value.publicAvailable) return;
  await share({
    title: `${data.profile.identity.name} na Berufe`,
    text: "Conheça meu trabalho na Berufe.",
    url: publicProfileUrl.value,
  });
}

async function publishProfile() {
  if (!canPublish.value) return;

  try {
    await professionalWorkspace.submitProfile();
    showToast({
      title: "Perfil publicado",
      description: "Clientes já podem encontrar e entrar em contato com você.",
    });
  } catch {
    showToast({
      title: "Não foi possível publicar",
      description:
        professionalWorkspace.submissionError.value ||
        "Tente novamente em instantes.",
    });
  }
}

async function respondRelationship(
  id: string,
  response: ProfessionalRelationshipResponse,
) {
  try {
    await professionalWorkspace.respondToRelationship(id, response);
    showToast({
      title:
        response === "accepted"
          ? "Vocês estão conectados"
          : "Solicitação de conexão recusada",
      description:
        response === "accepted"
          ? "A conexão já pode aparecer nos perfis públicos."
          : "A solicitação de conexão recusada não aparecerá publicamente.",
    });
  } catch {
    // The actionable activity section keeps the normalized API error visible.
  }
}
</script>

<template>
  <div class="dashboard-page">
    <section class="dashboard-welcome">
      <DesignSystemContainer class="dashboard-welcome__inner">
        <div>
          <p>{{ localDateLabel || "Painel profissional" }}</p>
          <h1>Olá, {{ professionalFirstName }}.</h1>
        </div>
        <div class="dashboard-welcome__actions">
          <UButton
            color="neutral"
            variant="outline"
            icon="i-lucide-share-2"
            :disabled="!dashboardStatus.publicAvailable"
            @click="shareProfile"
            >Compartilhar perfil</UButton
          >
          <UButton
            to="/app/professional/quotes/new"
            color="secondary"
            icon="i-lucide-plus"
            >Novo orçamento</UButton
          >
        </div>
      </DesignSystemContainer>
    </section>

    <DesignSystemContainer
      v-if="professionalWorkspace.status.value === 'pending'"
      class="dashboard-content dashboard-state"
    >
      <p aria-live="polite">Carregando seu painel profissional…</p>
    </DesignSystemContainer>
    <DesignSystemContainer
      v-else-if="professionalWorkspace.error.value || !workspace"
      class="dashboard-content dashboard-state dashboard-state--error"
    >
      <p role="alert">
        Não foi possível carregar seu painel. Atualize a página para tentar
        novamente.
      </p>
    </DesignSystemContainer>
    <DesignSystemContainer v-else class="dashboard-content">
      <div class="dashboard-layout">
        <section
          class="status-banner"
          :class="`status-banner--${dashboardStatus.tone}`"
        >
          <span class="status-banner__icon">
            <UIcon :name="dashboardStatus.icon" />
          </span>
          <div class="status-banner__content">
            <strong>{{ dashboardStatus.title }}</strong>
            <p>{{ dashboardStatus.description }}</p>
          </div>
          <UButton
            v-if="canPublish"
            class="status-banner__action"
            type="button"
            color="primary"
            icon="i-lucide-megaphone"
            :loading="professionalWorkspace.submissionSaving.value"
            :disabled="professionalWorkspace.submissionSaving.value"
            @click="publishProfile"
          >
            Publicar perfil
          </UButton>
          <NuxtLink
            v-else-if="dashboardStatus.publicAvailable"
            class="status-banner__action"
            :to="`/profissionais/${workspace.profile.publicSlug}`"
            target="_blank"
          >
            Ver perfil público <UIcon name="i-lucide-arrow-up-right" />
          </NuxtLink>
        </section>

        <div class="dashboard-operational">
          <DashboardActivitySections
            :workspace="workspace"
            :responding-id="
              professionalWorkspace.relationshipRespondingId.value
            "
            :relationship-error="professionalWorkspace.relationshipError.value"
            @respond="respondRelationship"
          />
          <DashboardRecentWork
            :quotes="recentQuotes"
            :services="recentServices"
          />
        </div>

        <aside class="dashboard-sidebar" aria-label="Ferramentas do perfil">
          <DashboardChecklist
            :readiness="progress"
            :items="checklist"
            :can-publish="canPublish"
            :publishing="professionalWorkspace.submissionSaving.value"
            @publish="publishProfile"
          />
          <DashboardQuickActions @recommend="relationshipOpen = true" />
        </aside>
      </div>
    </DesignSystemContainer>
    <RelationshipCreateDialog
      v-model:open="relationshipOpen"
      :services="relationshipServices"
      :neighborhoods="relationshipNeighborhoods"
      :eligible="relationshipEligible"
    />
  </div>
</template>

<style scoped lang="scss">
.dashboard-page {
  min-height: 100vh;
  background: var(--color-surface-canvas);
}
.dashboard-welcome {
  padding: 40px 0 44px;
  background: var(--color-brand-strong);
  color: white;
  &__inner {
    display: flex;
    justify-content: space-between;
    align-items: end;
    gap: 25px;
  }
  & p {
    margin: 0 0 8px;
    color: #9fcbc0;
    font-size: 0.86rem;
    font-weight: 800;
    text-transform: uppercase;
  }
  & h1 {
    margin: 0;
    font-family: var(--font-display);
    font-size: clamp(2.2rem, 4vw, 3.8rem);
    font-weight: 500;
    letter-spacing: -0.04em;
  }
  & h1 em {
    color: var(--color-brand-muted);
    font-weight: inherit;
  }
  &__actions {
    display: flex;
    gap: 9px;
  }
}
.dashboard-content {
  padding-top: 24px;
  padding-bottom: 80px;
}
.dashboard-state {
  & p {
    margin: 0;
    padding: 24px;
    border: 1px solid var(--line);
    border-radius: 16px;
    background: white;
    color: var(--ink-soft);
  }
  &--error p {
    border-color: #efc5bd;
    color: var(--color-danger);
    font-weight: 700;
  }
}
.dashboard-layout {
  display: grid;
  grid-template-columns: minmax(260px, 1fr) minmax(0, 2fr);
  grid-template-rows: max-content minmax(0, 1fr);
  gap: 12px 28px;
  align-items: start;
}
.dashboard-operational {
  grid-row: 1 / span 2;
  grid-column: 2;
  display: grid;
  gap: 48px;
  min-width: 0;
}
.dashboard-sidebar {
  grid-row: 2;
  grid-column: 1;
  display: grid;
  gap: 12px;
  min-width: 0;
}
.status-banner {
  grid-row: 1;
  grid-column: 1;
  display: grid;
  grid-template-columns: auto minmax(0, 1fr);
  align-items: start;
  gap: 11px;
  padding: 14px;
  border: 1px solid #b6d9cd;
  border-radius: 16px;
  background: #e6f4ef;
  &__icon {
    display: grid;
    place-items: center;
    width: 38px;
    height: 38px;
    border-radius: 11px;
    background: white;
    color: var(--color-brand);
  }
  &__content {
    min-width: 0;
  }
  & strong,
  & p {
    display: block;
    margin: 0;
  }
  & strong {
    font-size: 0.84rem;
  }
  & p {
    margin-top: 3px;
    color: var(--ink-soft);
    font-size: 0.86rem;
  }
  & a {
    display: flex;
    align-items: center;
    gap: 4px;
    color: var(--color-brand);
    font-size: 0.86rem;
    font-weight: 850;
    text-decoration: none;
  }
  &__action {
    grid-column: 2;
    justify-self: start;
  }
  &--pending {
    border-color: #ead9a5;
    background: #fff7dd;
  }
  &--attention {
    border-color: #efc5bd;
    background: #fff0ed;
  }
  &--attention .status-banner__icon {
    color: var(--color-danger);
  }
}
@media (width <= 900px) {
  .dashboard-layout {
    grid-template-columns: 1fr;
    grid-template-rows: auto;
    gap: 40px;
  }
  .status-banner,
  .dashboard-operational,
  .dashboard-sidebar {
    grid-row: auto;
    grid-column: 1;
  }
}
@media (width <= 700px) {
  .dashboard-welcome {
    &__inner {
      display: grid;
    }
    &__actions {
      flex-wrap: wrap;
    }
  }
}
</style>
