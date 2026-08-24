<script setup lang="ts">
import type { ProfessionalWorkspace } from "~/types";
import { formatCurrency, formatDateTime } from "~/utils/formatters";

type RecentQuote = ProfessionalWorkspace["dashboard"]["recentQuotes"][number];
type RecentService =
  ProfessionalWorkspace["dashboard"]["recentServiceJobs"][number];

const props = defineProps<{
  quotes: RecentQuote[];
  services: RecentService[];
}>();

const sortedQuotes = computed(() =>
  [...props.quotes].sort(
    (left, right) =>
      new Date(right.createdAt).getTime() - new Date(left.createdAt).getTime(),
  ),
);

const quoteStatusLabel = {
  draft: "Rascunho",
  shared: "Aguardando resposta",
  change_requested: "Alteração solicitada",
  approved: "Aprovado",
  declined: "Recusado",
} as const;
const serviceStatusLabel = {
  approved: "Aprovado",
  completion_requested: "Aguardando confirmação",
  completion_issue: "Pendência",
  completed: "Concluído",
  cancelled: "Cancelado",
} as const;
</script>

<template>
  <div class="recent-work">
    <section class="dashboard-section quotes-section">
      <div v-if="quotes.length" class="dashboard-section__heading">
        <div>
          <DesignSystemEyebrow>Ferramentas</DesignSystemEyebrow>
          <h2>Orçamentos recentes.</h2>
        </div>
        <UButton
          to="/app/professional/quotes"
          variant="link"
          trailing-icon="i-lucide-arrow-right"
          >Ver todos</UButton
        >
      </div>
      <DashboardQuoteEmptyState v-if="quotes.length === 0" />
      <DesignSystemSurfaceCard v-else class="quotes-table quotes-table--quotes">
        <div class="quotes-table__head">
          <span>Orçamento</span><span>Cliente</span><span>Valor</span
          ><span>Data</span>
        </div>
        <NuxtLink
          v-for="quote in sortedQuotes"
          :key="quote.id"
          :to="`/app/professional/quotes/new?quote=${quote.id}`"
        >
          <span class="quotes-table__quote">
            <span class="quotes-table__quote-heading">
              <strong>#{{ quote.number }}</strong>
              <em :class="quote.status">{{
                quoteStatusLabel[quote.status]
              }}</em>
            </span>
          </span>
          <span>{{ quote.customerName }}</span>
          <span>
            <strong>{{ formatCurrency(quote.total) }}</strong>
          </span>
          <span class="quotes-table__date quotes-table__row-action">
            {{ formatDateTime(quote.createdAt) }}
            <UIcon name="i-lucide-chevron-right" />
          </span>
          <small class="quotes-table__description">
            {{ quote.serviceDescription }}
          </small>
        </NuxtLink>
      </DesignSystemSurfaceCard>
    </section>

    <section v-if="services.length" class="dashboard-section quotes-section">
      <div class="dashboard-section__heading">
        <div>
          <DesignSystemEyebrow>Execução</DesignSystemEyebrow>
          <h2>Serviços em andamento.</h2>
        </div>
        <UButton
          to="/app/professional/services"
          variant="link"
          trailing-icon="i-lucide-arrow-right"
          >Ver todos</UButton
        >
      </div>
      <DesignSystemSurfaceCard class="quotes-table">
        <NuxtLink
          v-for="service in services"
          :key="service.id"
          :to="`/app/professional/services/${service.id}`"
        >
          <span>
            <strong>#{{ service.quote.number }}</strong>
            <small>{{ service.quote.serviceDescription }}</small>
          </span>
          <span>{{ service.quote.customerName }}</span>
          <span
            ><strong>{{ formatCurrency(service.quote.total) }}</strong></span
          >
          <span>
            <em :class="service.status">{{
              serviceStatusLabel[service.status]
            }}</em>
          </span>
          <span class="quotes-table__row-action">
            {{ formatDateTime(service.updatedAt) }}
            <UIcon name="i-lucide-chevron-right" />
          </span>
        </NuxtLink>
      </DesignSystemSurfaceCard>
    </section>
  </div>
</template>

<style scoped lang="scss">
.recent-work {
  display: grid;
  gap: 48px;
}

.dashboard-section {
  min-width: 0;

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

  &--quotes &__head,
  &--quotes > a {
    grid-template-columns: 1.5fr 1fr 0.7fr 0.7fr;
  }

  &--quotes > a {
    align-items: start;
    row-gap: 5px;
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

  &__date {
    color: var(--ink-soft);
    font-variant-numeric: tabular-nums;
  }

  &__quote-heading {
    display: flex;
    flex-wrap: wrap;
    align-items: baseline;
    gap: 6px;
  }

  &__quote-heading strong {
    display: inline;
  }

  & &__description {
    grid-column: 1 / -1;
    margin-top: 0;
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

  &__row-action {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 8px;
  }
}

@media (width <= 700px) {
  .dashboard-section__heading {
    display: grid;
  }

  .quotes-table {
    &__head {
      display: none;
    }

    & > a {
      grid-template-columns: 1fr auto auto;
    }

    &:not(.quotes-table--quotes) > a > span:nth-child(2),
    &:not(.quotes-table--quotes) > a > span:nth-child(5) {
      display: none;
    }

    &--quotes > a {
      grid-template-columns: minmax(0, 1fr) auto;
    }

    &--quotes > a > span:nth-child(2),
    &--quotes > a > span:nth-child(4) {
      display: none;
    }
  }
}
</style>
