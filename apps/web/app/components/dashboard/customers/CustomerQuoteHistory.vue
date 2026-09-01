<script setup lang="ts">
import type { QuotePage } from "~/types";
import { formatCurrency, formatDateTime } from "~/utils/formatters";
import CustomerPagination from "./CustomerPagination.vue";

defineProps<{
  result: QuotePage;
  loading?: boolean;
  error?: string;
}>();

defineEmits<{
  page: [value: number];
}>();

const statusLabel = {
  draft: "Rascunho",
  saved: "Aguardando envio ao cliente",
  shared: "Enviado ao cliente",
  change_requested: "Alteração solicitada",
  approved: "Aprovado",
  declined: "Recusado",
} as const;
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="customer-history">
    <header>
      <div>
        <DesignSystemEyebrow>Histórico</DesignSystemEyebrow>
        <h2>Orçamentos</h2>
      </div>
      <strong>{{ result.meta.totalCount }}</strong>
    </header>

    <p v-if="error" class="customer-history__error" role="alert">
      {{ error }}
    </p>
    <div
      class="customer-history__list"
      :class="{ 'customer-history__list--loading': loading }"
      :aria-busy="loading ? 'true' : 'false'"
    >
      <NuxtLink
        v-for="quote in result.quotes"
        :key="quote.id ?? `quote-${quote.number ?? 'draft'}`"
        :to="`/app/professional/quotes/new?quote=${quote.id}`"
      >
        <span>
          <strong>#{{ quote.number }} · {{ quote.serviceDescription }}</strong>
          <small v-if="quote.updatedAt">
            Atualizado em {{ formatDateTime(quote.updatedAt) }}
          </small>
        </span>
        <strong>{{ formatCurrency(quote.total) }}</strong>
        <em :class="quote.status">{{ statusLabel[quote.status] }}</em>
        <UIcon name="i-lucide-chevron-right" aria-hidden="true" />
      </NuxtLink>
      <p v-if="result.quotes.length === 0">
        Nenhum orçamento foi criado para este cliente.
      </p>
    </div>
    <div v-if="result.meta.totalPages > 1" class="customer-history__pagination">
      <CustomerPagination
        :page="result.meta.page"
        :total-pages="result.meta.totalPages"
        :loading="loading"
        @page="$emit('page', $event)"
      />
    </div>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.customer-history {
  overflow: hidden;

  & header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 18px;
    padding: 22px 24px 18px;
  }

  & header > strong {
    display: grid;
    place-items: center;
    min-width: 32px;
    height: 32px;
    padding: 0 9px;
    border-radius: var(--radius-pill);
    background: var(--color-brand-tint);
    color: var(--color-brand);
    font-size: 0.82rem;
  }

  & h2 {
    margin: 5px 0 0;
    font-family: var(--font-display);
    font-size: 1.7rem;
    font-weight: 550;
  }

  &__error {
    margin: 0;
    padding: 0 24px 15px;
    color: var(--color-danger);
    font-size: 0.84rem;
  }

  &__list a {
    display: grid;
    grid-template-columns: minmax(190px, 1fr) auto minmax(125px, auto) auto;
    gap: 18px;
    align-items: center;
    padding: 16px 24px;
    border-top: 1px solid var(--line);
    color: var(--ink);
    font-size: 0.84rem;
    text-decoration: none;
  }

  &__list a:hover {
    background: var(--color-surface-hover);
  }

  &__list--loading a {
    opacity: 0.55;
  }

  &__list a > span strong,
  &__list a > span small {
    display: block;
  }

  &__list a > span small {
    margin-top: 3px;
    color: var(--ink-soft);
  }

  &__list em {
    padding: 5px 8px;
    border-radius: var(--radius-pill);
    background: var(--color-brand-tint-muted);
    color: var(--color-brand);
    font-size: 0.76rem;
    font-style: normal;
    font-weight: 800;
    text-align: center;
  }

  &__list em.declined {
    background: var(--color-danger-tint);
    color: var(--color-danger);
  }

  &__list > p {
    margin: 0;
    padding: 20px 24px 24px;
    border-top: 1px solid var(--line);
    color: var(--ink-soft);
  }

  &__pagination {
    padding: 18px;
    border-top: 1px solid var(--line);
  }
}

@media (width <= 720px) {
  .customer-history__list a {
    grid-template-columns: 1fr auto;

    & > strong {
      grid-row: 2;
      grid-column: 1;
    }

    & > em {
      grid-row: 2;
      grid-column: 2;
      justify-self: start;
    }

    & > :last-child {
      grid-row: 1;
      grid-column: 2;
    }
  }
}
</style>
