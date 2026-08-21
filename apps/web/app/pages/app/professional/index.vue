<script setup lang="ts">
import type { OnboardingChecklistItem } from "~/types";
import { useProfessionalWorkspace } from "~/composables/useProfessionalWorkspace";
import { useApplicationSession } from "~/composables/useApplicationSession";
import { useCatalogs } from "~/composables/useCatalogs";
import { useShare } from "~/composables/useShare";
import { useToast } from "~/composables/useToast";
import type { ProfessionalRelationshipResponse } from "~/services/api/professional-relationships";
import { formatCurrency, formatDateTime } from "~/utils/formatters";

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
const verificationDescription = computed(() => {
  const status = workspace.value?.profile.verification.current?.status;
  if (status === "approved")
    return "Perfeito! Sua identidade foi verificada e aprovada pela nossa equipe.";
  if (status === "pending_review")
    return "Seus documentos estão em análise. Em breve, avisaremos você por aqui.";
  if (status === "rejected" || status === "expired")
    return "Reenvie sua identidade";
  return "Seus documentos estão em análise. Em breve, avisaremos você por aqui.";
});
const recentQuotes = computed(
  () => workspace.value?.dashboard.recentQuotes ?? [],
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
      <section
        class="status-banner"
        :class="`status-banner--${dashboardStatus.tone}`"
      >
        <span class="status-banner__icon"
          ><UIcon :name="dashboardStatus.icon"
        /></span>
        <div>
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
          >Ver perfil público <UIcon name="i-lucide-arrow-up-right"
        /></NuxtLink>
      </section>

      <div class="dashboard-grid">
        <DashboardChecklist
          :readiness="progress"
          :items="checklist"
          :can-publish="canPublish"
          :publishing="professionalWorkspace.submissionSaving.value"
          @publish="publishProfile"
        />

        <DesignSystemSurfaceCard as="section" class="actions-card">
          <header>
            <span>Ações rápidas</span><small>Fortaleça seu perfil</small>
          </header>
          <div class="actions-card__grid">
            <NuxtLink to="/app/professional/profile">
              <span><UIcon name="i-lucide-pencil" /></span>
              <strong>Editar perfil</strong>
              <small
                >Edite seus dados, serviços e região que atende.</small
              ></NuxtLink
            >
            <NuxtLink to="/app/professional/profile?tab=portfolio">
              <span><UIcon name="i-lucide-image-plus" /></span>
              <strong>Novo trabalho</strong>
              <small
                >Demonstre seus trabalhos já feitos e aumente sua
                credibilidade.</small
              >
            </NuxtLink>
            <NuxtLink to="/app/professional/profile?tab=verificacoes">
              <span><UIcon name="i-lucide-id-card" /></span>
              <strong>Ver verificações</strong>
              <small>{{ verificationDescription }}</small></NuxtLink
            >
            <button type="button" @click="relationshipOpen = true">
              <span><UIcon name="i-lucide-handshake" /></span>
              <strong>Recomendar um profissional</strong>
              <small
                >Amplie sua rede e fortaleça sua credibilidade. Quem
                compartilha, cresce.</small
              >
            </button>
          </div>
        </DesignSystemSurfaceCard>
      </div>

      <DashboardActivitySections
        :workspace="workspace"
        :responding-id="professionalWorkspace.relationshipRespondingId.value"
        :relationship-error="professionalWorkspace.relationshipError.value"
        @respond="respondRelationship"
      />

      <section class="dashboard-section quotes-section">
        <div class="dashboard-section__heading">
          <div>
            <DesignSystemEyebrow>Ferramentas</DesignSystemEyebrow>
            <h2>Orçamentos recentes.</h2>
          </div>
          <UButton
            to="/app/professional/quotes/new"
            variant="link"
            trailing-icon="i-lucide-arrow-right"
            >Criar orçamento</UButton
          >
        </div>
        <DesignSystemSurfaceCard class="quotes-table">
          <div class="quotes-table__head">
            <span>Orçamento</span><span>Cliente</span><span>Valor</span
            ><span>Status</span><span>Data</span>
          </div>
          <NuxtLink
            v-for="quote in recentQuotes"
            :key="quote.id"
            :to="`/app/professional/quotes/new?quote=${quote.id}`"
          >
            <span
              ><strong>#{{ quote.number }}</strong
              ><small>{{ quote.serviceDescription }}</small></span
            >
            <span>{{ quote.customerName }}</span>
            <span
              ><strong>{{ formatCurrency(quote.total) }}</strong></span
            >
            <span
              ><em :class="quote.status">{{
                quote.status === "shared" ? "Compartilhado" : "Rascunho"
              }}</em></span
            >
            <span
              >{{ formatDateTime(quote.createdAt) }}
              <UIcon name="i-lucide-chevron-right"
            /></span>
          </NuxtLink>
          <p v-if="recentQuotes.length === 0" class="quotes-table__empty">
            Nenhum orçamento criado ainda.
          </p>
        </DesignSystemSurfaceCard>
      </section>
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
.status-banner {
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 13px;
  padding: 15px 18px;
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
.dashboard-section {
  margin-top: 48px;
  &__heading {
    display: flex;
    justify-content: space-between;
    align-items: end;
    gap: 20px;
    margin-bottom: 20px;
  }
  &__heading .eyebrow {
    margin-bottom: 8px;
  }
  &__heading h2 {
    margin: 0;
    font-family: var(--font-display);
    font-size: 2rem;
    font-weight: 500;
    letter-spacing: -0.035em;
  }
  &__heading > span {
    color: var(--ink-soft);
    font-size: 0.86rem;
  }
}
.dashboard-grid {
  display: grid;
  grid-template-columns: 0.9fr 1.1fr;
  gap: 12px;
  margin-top: 48px;
}
.actions-card {
  padding: 22px;
  & header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;
  }
  & header span {
    font-family: var(--font-display);
    font-size: 1.4rem;
    font-weight: 600;
  }
  & header small {
    color: var(--ink-soft);
    font-size: 0.84rem;
  }
  &__grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 9px;
  }
  &__grid a,
  &__grid button {
    display: grid;
    grid-template-columns: auto 1fr;
    column-gap: 10px;
    min-height: 94px;
    padding: 15px;
    border: 1px solid var(--line);
    border-radius: 14px;
    background: #faf9f6;
    color: var(--ink);
    text-align: left;
    text-decoration: none;
    cursor: pointer;
    transition: 0.15s ease;
  }
  &__grid a:hover,
  &__grid button:hover {
    border-color: #9fc8bb;
    background: var(--color-brand-tint-subtle);
  }
  &__grid a > span,
  &__grid button > span {
    align-self: center;
    grid-row: 1 / 3;
    display: grid;
    place-items: center;
    width: 34px;
    height: 34px;
    border-radius: 10px;
    background: var(--mint);
    color: var(--color-brand);
  }
  &__grid strong {
    align-self: end;
    font-size: 0.82rem;
  }
  &__grid small {
    color: var(--ink-soft);
    font-size: 0.84rem;
  }
}
.quotes-table {
  overflow: hidden;
  &__head,
  & > a {
    display: grid;
    grid-template-columns: 1.2fr 1fr 0.7fr 0.8fr 0.55fr;
    gap: 12px;
    align-items: center;
    padding: 13px 16px;
  }
  &__head {
    background: #f6f4ef;
    color: var(--ink-soft);
    font-size: 0.82rem;
    font-weight: 850;
    text-transform: uppercase;
  }
  & > a {
    border-top: 1px solid var(--line);
    color: var(--ink);
    font-size: 0.84rem;
    text-decoration: none;
  }
  & > a:hover {
    background: #faf9f6;
  }
  & strong,
  & small {
    display: block;
  }
  & small {
    margin-top: 3px;
    color: var(--ink-soft);
  }
  & em {
    display: inline-flex;
    padding: 5px 7px;
    border-radius: 7px;
    background: #eceae4;
    color: var(--ink-soft);
    font-size: 0.82rem;
    font-style: normal;
    font-weight: 800;
  }
  & em.shared {
    background: var(--mint);
    color: var(--color-brand);
  }
  & > a > span:last-child {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  &__empty {
    margin: 0;
    padding: 24px 16px;
    border-top: 1px solid var(--line);
    color: var(--ink-soft);
    font-size: 0.86rem;
    text-align: center;
  }
}
@media (width <= 900px) {
  .dashboard-grid {
    grid-template-columns: 1fr;
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
  .dashboard-section {
    &__heading {
      display: grid;
    }
  }
  .status-banner {
    grid-template-columns: auto 1fr;
  }
  .status-banner__action {
    grid-column: 2;
    justify-self: start;
  }
  .quotes-table {
    &__head {
      display: none;
    }
    & > a {
      grid-template-columns: 1fr auto auto;
    }
    & > a > span:nth-child(2),
    & > a > span:nth-child(5) {
      display: none;
    }
  }
}
</style>
