<script setup lang="ts">
import type { OnboardingChecklistItem } from "~/types";
import { useProfessionalWorkspace } from "~/composables/useProfessionalWorkspace";
import { useShare } from "~/composables/useShare";
import { useToast } from "~/composables/useToast";
import { formatCurrency, formatDateTime } from "~/utils/formatters";

type PendingItemType =
  "profile" | "photo" | "portfolio" | "verification" | "relationship";

interface PendingItem {
  id: string;
  type: PendingItemType;
  title: string;
  status: string;
  detail: string;
  sortAt: string;
}

const runtimeConfig = useRuntimeConfig();
const { share } = useShare();
const { showToast } = useToast();
const professionalWorkspace = await useProfessionalWorkspace();
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
      label: "Identidade e contato",
      description: "Nome, apresentação e WhatsApp",
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
  if (profile.status === "published") {
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
      description: "A equipe está conferindo os dados enviados.",
      icon: "i-lucide-clock-3",
      tone: "pending",
      publicAvailable: false,
    };
  }
  return {
    title: "Seu perfil ainda não está publicado",
    description: "Complete as etapas abaixo e envie o perfil para análise.",
    icon: "i-lucide-circle-alert",
    tone: "attention",
    publicAvailable: false,
  };
});
const verificationDescription = computed(() => {
  const status = workspace.value?.profile.verification.current?.status;
  if (status === "approved") return "Identidade aprovada";
  if (status === "pending_review") return "Identidade em análise";
  if (status === "rejected" || status === "expired") {
    return "Reenvie sua identidade";
  }
  return "Enviar identidade";
});
const pendingItems = computed<PendingItem[]>(() => {
  const data = workspace.value;
  if (!data) return [];

  const items: PendingItem[] = [];
  const profile = data.profile;
  if (profile.revisionStatus === "pending_review") {
    items.push({
      id: `profile-${profile.id}`,
      type: "profile",
      title: "Perfil profissional",
      status: "Em análise",
      detail: "Perfil enviado para conferência da equipe.",
      sortAt: "",
    });
  } else if (profile.revisionStatus === "rejected") {
    items.push({
      id: `profile-${profile.id}`,
      type: "profile",
      title: "Perfil profissional",
      status: "Precisa de ajustes",
      detail: `${profile.revisionRejectionReason ?? "Revise os dados informados."} Edite e envie novamente.`,
      sortAt: "",
    });
  }

  const photo = profile.photo.current;
  if (photo?.status === "pending_review") {
    items.push({
      id: photo.id,
      type: "photo",
      title: "Foto do perfil",
      status: "Em análise",
      detail: `Enviada em ${formatDateTime(photo.submittedAt)}`,
      sortAt: photo.submittedAt,
    });
  } else if (photo?.status === "rejected" || photo?.status === "hidden") {
    items.push({
      id: photo.id,
      type: "photo",
      title: "Foto do perfil",
      status: photo.status === "hidden" ? "Oculta" : "Precisa de ajustes",
      detail: `${photo.rejectionReason ?? "A foto não pode ser exibida."} Envie uma nova foto.`,
      sortAt: photo.submittedAt,
    });
  }

  for (const item of profile.portfolioItems) {
    if (item.status === "pending_review") {
      items.push({
        id: item.id,
        type: "portfolio",
        title: item.title,
        status: "Em análise",
        detail: `Enviado em ${formatDateTime(item.submittedAt)}`,
        sortAt: item.submittedAt,
      });
    } else if (item.status === "rejected" || item.status === "hidden") {
      items.push({
        id: item.id,
        type: "portfolio",
        title: item.title,
        status: item.status === "hidden" ? "Oculto" : "Precisa de ajustes",
        detail: `${item.rejectionReason ?? "O trabalho não pode ser exibido."} Adicione um novo trabalho.`,
        sortAt: item.submittedAt,
      });
    }
  }

  const verification = profile.verification.current;
  if (verification?.status === "pending_review") {
    items.push({
      id: verification.id,
      type: "verification",
      title: "Verificação de identidade",
      status: "Em análise",
      detail: `Enviada em ${formatDateTime(verification.submittedAt)}`,
      sortAt: verification.submittedAt,
    });
  } else if (
    verification?.status === "rejected" ||
    verification?.status === "expired"
  ) {
    items.push({
      id: verification.id,
      type: "verification",
      title: "Verificação de identidade",
      status:
        verification.status === "expired" ? "Expirada" : "Precisa de ajustes",
      detail: `${verification.rejectionReason ?? "A evidência precisa ser substituída."} Envie uma nova evidência.`,
      sortAt: verification.submittedAt,
    });
  }

  items.push(
    ...data.pendingRelationships.map((relationship) => ({
      id: relationship.id,
      type: "relationship" as const,
      title:
        relationship.relationshipType === "worked_together"
          ? `${relationship.initiator.displayName} trabalhou com você`
          : `${relationship.initiator.displayName} recomendou você`,
      status: "Aguardando sua resposta",
      detail: `Recebido em ${formatDateTime(relationship.createdAt)}`,
      sortAt: relationship.createdAt,
    })),
  );

  return items.sort((left, right) => right.sortAt.localeCompare(left.sortAt));
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

function pendingIcon(type: PendingItemType) {
  return {
    profile: "i-lucide-user-round",
    photo: "i-lucide-image",
    portfolio: "i-lucide-image",
    verification: "i-lucide-id-card",
    relationship: "i-lucide-handshake",
  }[type];
}

async function respondRelationship(id: string, accepted: boolean) {
  try {
    await professionalWorkspace.respondToRelationship(
      id,
      accepted ? "accepted" : "declined",
    );
    showToast({
      title: accepted ? "Colaboração confirmada" : "Solicitação recusada",
      description: accepted
        ? "Agora ela seguirá para moderação."
        : "Essa relação continuará privada.",
    });
  } catch {
    // The pending section keeps the normalized API error visible for retry.
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
        <NuxtLink
          v-if="dashboardStatus.publicAvailable"
          :to="`/profissionais/${workspace.profile.publicSlug}`"
          target="_blank"
          >Ver perfil público <UIcon name="i-lucide-arrow-up-right"
        /></NuxtLink>
      </section>

      <div class="dashboard-grid">
        <DashboardChecklist :readiness="progress" :items="checklist" />

        <DesignSystemSurfaceCard as="section" class="actions-card">
          <header>
            <span>Ações rápidas</span><small>Fortaleça seu perfil</small>
          </header>
          <div class="actions-card__grid">
            <NuxtLink to="/app/professional/profile"
              ><span><UIcon name="i-lucide-pencil" /></span
              ><strong>Editar perfil</strong
              ><small>Dados e serviços</small></NuxtLink
            >
            <NuxtLink to="/app/professional/profile?tab=portfolio"
              ><span><UIcon name="i-lucide-image-plus" /></span
              ><strong>Novo trabalho</strong
              ><small>Adicionar ao portfólio</small></NuxtLink
            >
            <NuxtLink to="/app/professional/profile?tab=verificacoes"
              ><span><UIcon name="i-lucide-id-card" /></span
              ><strong>Ver verificações</strong
              ><small>{{ verificationDescription }}</small></NuxtLink
            >
            <NuxtLink to="/encontrar"
              ><span><UIcon name="i-lucide-handshake" /></span
              ><strong>Adicionar relação</strong
              ><small>Profissional já cadastrado</small></NuxtLink
            >
          </div>
        </DesignSystemSurfaceCard>
      </div>

      <section class="dashboard-section pending-section">
        <div class="dashboard-section__heading">
          <div>
            <DesignSystemEyebrow>Precisa de atenção</DesignSystemEyebrow>
            <h2>Pendências e análises.</h2>
          </div>
          <span>{{ pendingItems.length }} itens</span>
        </div>
        <p v-if="pendingItems.length === 0" class="pending-list__feedback">
          Nenhuma pendência precisa da sua atenção agora.
        </p>
        <p
          v-if="professionalWorkspace.relationshipError.value"
          class="pending-list__feedback pending-list__feedback--error"
          role="alert"
        >
          {{ professionalWorkspace.relationshipError.value }}
        </p>
        <div class="pending-list">
          <article v-for="item in pendingItems" :key="item.id">
            <span class="pending-list__icon"
              ><UIcon :name="pendingIcon(item.type)"
            /></span>
            <div>
              <strong>{{ item.title }}</strong
              ><small>{{ item.detail }}</small>
            </div>
            <span class="pending-list__status">{{ item.status }}</span>
            <div
              v-if="item.type === 'relationship'"
              class="pending-list__actions"
            >
              <UButton
                size="sm"
                color="neutral"
                variant="ghost"
                :loading="
                  professionalWorkspace.relationshipRespondingId.value ===
                  item.id
                "
                :disabled="
                  Boolean(professionalWorkspace.relationshipRespondingId.value)
                "
                @click="respondRelationship(item.id, false)"
                >Recusar</UButton
              >
              <UButton
                size="sm"
                color="primary"
                :loading="
                  professionalWorkspace.relationshipRespondingId.value ===
                  item.id
                "
                :disabled="
                  Boolean(professionalWorkspace.relationshipRespondingId.value)
                "
                @click="respondRelationship(item.id, true)"
                >Confirmar</UButton
              >
            </div>
          </article>
        </div>
      </section>

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
.pending-list {
  display: grid;
  gap: 8px;
  & article {
    display: grid;
    grid-template-columns: auto 1fr auto auto;
    align-items: center;
    gap: 12px;
    padding: 13px 16px;
    border: 1px solid var(--line);
    border-radius: 14px;
    background: white;
  }
  &__icon {
    display: grid;
    place-items: center;
    width: 38px;
    height: 38px;
    border-radius: 11px;
    background: var(--color-accent-tint);
    color: #be553f;
  }
  & strong,
  & small {
    display: block;
  }
  & strong {
    font-size: 0.82rem;
  }
  & small {
    margin-top: 3px;
    color: var(--ink-soft);
    font-size: 0.82rem;
  }
  &__status {
    padding: 5px 8px;
    border-radius: 7px;
    background: #fff7dd;
    color: #926916;
    font-size: 0.82rem;
    font-weight: 850;
  }
  &__actions {
    display: flex;
    gap: 5px;
  }
  &__feedback {
    margin: 0 0 12px;
    color: var(--ink-soft);
    font-size: 0.86rem;

    &--error {
      color: var(--color-danger);
      font-weight: 700;
    }
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
  .status-banner a {
    grid-column: 2;
  }
  .pending-list {
    & article {
      grid-template-columns: auto 1fr auto;
    }
    &__actions {
      grid-column: 2 / -1;
    }
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
