<script setup lang="ts">
import dashboardData from "@data/dashboard.json";
import professionalsData from "@data/professionals.json";
import type { Professional } from "~/types";
import { useProfessionalOnboarding } from "~/composables/useProfessionalOnboarding";
import { useShare } from "~/composables/useShare";
import { useToast } from "~/composables/useToast";
import { formatCurrency } from "~/utils/formatters";

const { share } = useShare();
const { showToast } = useToast();
const { state: onboarding, checklist, progress } = useProfessionalOnboarding();
const professional = (professionalsData as Professional[]).find(
  (item) => item.id === dashboardData.professionalId,
)!;
const professionalFirstName = computed(
  () =>
    onboarding.value.profile.name.trim().split(" ")[0] ||
    professional.name.split(" ")[0],
);

useSeoMeta({
  title: "Painel profissional",
  robots: "noindex, nofollow",
});

async function shareProfile() {
  await share({
    title: `${professional.name} na Berufe`,
    text: "Conheça meu trabalho na Berufe.",
    url: dashboardData.publicUrl,
  });
}

function respondRelationship(accepted: boolean) {
  showToast({
    title: accepted ? "Colaboração confirmada" : "Solicitação recusada",
    description: accepted
      ? "Agora ela seguirá para moderação."
      : "Essa relação continuará privada.",
  });
}
</script>

<template>
  <div class="dashboard-page">
    <section class="dashboard-welcome">
      <DesignSystemContainer class="dashboard-welcome__inner">
        <div>
          <p>Terça-feira, 11 de agosto</p>
          <h1>Olá, {{ professionalFirstName }}. <em>Vamos em frente?</em></h1>
        </div>
        <div class="dashboard-welcome__actions">
          <UButton
            color="neutral"
            variant="outline"
            icon="i-lucide-share-2"
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

    <DesignSystemContainer class="dashboard-content">
      <section class="status-banner">
        <span class="status-banner__icon"
          ><UIcon name="i-lucide-badge-check"
        /></span>
        <div>
          <strong>Seu perfil está publicado</strong>
          <p>Clientes já podem encontrar e entrar em contato com você.</p>
        </div>
        <NuxtLink :to="`/profissionais/${professional.slug}`" target="_blank"
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
              ><small>Identidade aprovada</small></NuxtLink
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
          <span>{{ dashboardData.pending.length }} itens</span>
        </div>
        <div class="pending-list">
          <article v-for="item in dashboardData.pending" :key="item.id">
            <span class="pending-list__icon"
              ><UIcon
                :name="
                  item.type === 'portfolio'
                    ? 'i-lucide-image'
                    : 'i-lucide-handshake'
                "
            /></span>
            <div>
              <strong>{{ item.title }}</strong
              ><small>{{ item.date }}</small>
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
                @click="respondRelationship(false)"
                >Recusar</UButton
              >
              <UButton
                size="sm"
                color="primary"
                @click="respondRelationship(true)"
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
            v-for="quote in dashboardData.recentQuotes"
            :key="quote.id"
            to="/app/professional/quotes/new"
          >
            <span
              ><strong>#{{ quote.number }}</strong
              ><small>{{ quote.service }}</small></span
            >
            <span>{{ quote.customer }}</span>
            <span
              ><strong>{{ formatCurrency(quote.total) }}</strong></span
            >
            <span
              ><em :class="quote.status">{{
                quote.status === "shared" ? "Compartilhado" : "Rascunho"
              }}</em></span
            >
            <span
              >{{ quote.date }} <UIcon name="i-lucide-chevron-right"
            /></span>
          </NuxtLink>
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
