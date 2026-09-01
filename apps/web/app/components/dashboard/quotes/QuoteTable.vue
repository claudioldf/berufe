<script setup lang="ts">
import { computed } from "vue";
import type { Quote, QuoteSortDirection, QuoteSortKey } from "~/types";
import { formatCurrency, formatDateTime } from "~/utils/formatters";

const props = defineProps<{
  quotes: Quote[];
  filtered: boolean;
  sort: QuoteSortKey;
  direction: QuoteSortDirection;
  loading?: boolean;
}>();
const emit = defineEmits<{
  sort: [column: QuoteSortKey];
}>();
const loadingReason = computed(() =>
  props.loading ? "Aguarde a atualização da lista de orçamentos." : null,
);

const statusLabel = {
  draft: "Rascunho",
  saved: "Aguardando envio ao cliente",
  shared: "Enviado ao cliente",
  change_requested: "Alteração solicitada",
  approved: "Aprovado",
  declined: "Recusado",
  completed: "Concluído",
  cancelled: "Cancelado",
} as const;

function ariaSort(column: QuoteSortKey) {
  if (props.sort !== column) return "none";
  return props.direction === "asc" ? "ascending" : "descending";
}

function sortIcon(column: QuoteSortKey) {
  if (props.sort !== column) return "i-lucide-arrow-up-down";
  return props.direction === "asc"
    ? "i-lucide-arrow-up"
    : "i-lucide-arrow-down";
}

function sortLabel(column: QuoteSortKey, label: string) {
  if (props.sort !== column) return `Ordenar ${label} em ordem crescente`;
  const nextDirection = props.direction === "asc" ? "decrescente" : "crescente";
  return `Ordenar ${label} em ordem ${nextDirection}`;
}
</script>

<template>
  <DesignSystemSurfaceCard
    as="section"
    class="quote-table"
    :class="{ 'quote-table--loading': loading }"
    :aria-busy="loading ? 'true' : 'false'"
  >
    <div v-if="quotes.length" class="quote-table__head" role="row">
      <span role="columnheader" :aria-sort="ariaSort('number')">
        <DesignSystemDisabledTooltip :reason="loadingReason">
          <button
            type="button"
            class="quote-table__sort-button"
            data-sort="number"
            :disabled="loading"
            :aria-label="sortLabel('number', 'por número')"
            @click="emit('sort', 'number')"
          >
            Orçamento
            <UIcon :name="sortIcon('number')" aria-hidden="true" />
          </button>
        </DesignSystemDisabledTooltip>
      </span>
      <span role="columnheader" :aria-sort="ariaSort('customer')">
        <DesignSystemDisabledTooltip :reason="loadingReason">
          <button
            type="button"
            class="quote-table__sort-button"
            data-sort="customer"
            :disabled="loading"
            :aria-label="sortLabel('customer', 'por cliente')"
            @click="emit('sort', 'customer')"
          >
            Cliente
            <UIcon :name="sortIcon('customer')" aria-hidden="true" />
          </button>
        </DesignSystemDisabledTooltip>
      </span>
      <span role="columnheader" :aria-sort="ariaSort('total')">
        <DesignSystemDisabledTooltip :reason="loadingReason">
          <button
            type="button"
            class="quote-table__sort-button"
            data-sort="total"
            :disabled="loading"
            :aria-label="sortLabel('total', 'por valor')"
            @click="emit('sort', 'total')"
          >
            Valor
            <UIcon :name="sortIcon('total')" aria-hidden="true" />
          </button>
        </DesignSystemDisabledTooltip>
      </span>
      <span role="columnheader" :aria-sort="ariaSort('status')">
        <DesignSystemDisabledTooltip :reason="loadingReason">
          <button
            type="button"
            class="quote-table__sort-button"
            data-sort="status"
            :disabled="loading"
            :aria-label="sortLabel('status', 'por status')"
            @click="emit('sort', 'status')"
          >
            Status
            <UIcon :name="sortIcon('status')" aria-hidden="true" />
          </button>
        </DesignSystemDisabledTooltip>
      </span>
      <span role="columnheader" :aria-sort="ariaSort('updated')">
        <DesignSystemDisabledTooltip :reason="loadingReason">
          <button
            type="button"
            class="quote-table__sort-button"
            data-sort="updated"
            :disabled="loading"
            :aria-label="sortLabel('updated', 'por atualização')"
            @click="emit('sort', 'updated')"
          >
            Atualizado
            <UIcon :name="sortIcon('updated')" aria-hidden="true" />
          </button>
        </DesignSystemDisabledTooltip>
      </span>
    </div>
    <NuxtLink
      v-for="quote in quotes"
      :key="quote.id ?? `quote-${quote.number}`"
      class="quote-table__row"
      :to="`/app/professional/quotes/new?quote=${quote.id}`"
      :aria-label="`Abrir orçamento ${quote.number} de ${quote.customerName}`"
    >
      <span class="quote-table__primary">
        <strong>#{{ quote.number }} · {{ quote.serviceDescription }}</strong>
        <small>{{ quote.customerName }}</small>
      </span>
      <span class="quote-table__customer">{{ quote.customerName }}</span>
      <strong class="quote-table__total">{{
        formatCurrency(quote.total)
      }}</strong>
      <em class="quote-table__status" :class="quote.status">
        {{ statusLabel[quote.status] }}
      </em>
      <span class="quote-table__date">
        <time v-if="quote.updatedAt" :datetime="quote.updatedAt">
          {{ formatDateTime(quote.updatedAt) }}
        </time>
        <span v-else>—</span>
        <UIcon name="i-lucide-chevron-right" aria-hidden="true" />
      </span>
    </NuxtLink>
    <div v-if="quotes.length === 0" class="quote-table__empty">
      <span><UIcon name="i-lucide-file-text" aria-hidden="true" /></span>
      <div>
        <strong>{{
          filtered ? "Nenhum orçamento encontrado" : "Nenhum orçamento criado"
        }}</strong>
        <p>
          {{
            filtered
              ? "Ajuste ou limpe os filtros para ver outros resultados."
              : "Crie seu primeiro orçamento e acompanhe a resposta do cliente."
          }}
        </p>
      </div>
    </div>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.quote-table {
  overflow: hidden;

  &__head,
  &__row {
    display: grid;
    grid-template-columns:
      minmax(220px, 1.35fr) minmax(130px, 0.8fr)
      0.55fr minmax(135px, 0.72fr) minmax(145px, 0.72fr);
    gap: 16px;
    align-items: center;
    padding: 14px 18px;
  }

  &__head {
    background: #f6f4ef;
    color: var(--ink-soft);
    font-size: 0.78rem;
    font-weight: 850;
    text-transform: uppercase;
  }

  &__sort-button {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    padding: 0;
    border: 0;
    background: transparent;
    color: inherit;
    font: inherit;
    text-transform: inherit;
    cursor: pointer;
  }

  &__sort-button:hover:not(:disabled),
  &__sort-button:focus-visible {
    color: var(--color-brand);
  }

  &__sort-button:focus-visible {
    border-radius: 3px;
    outline: 2px solid var(--color-focus);
    outline-offset: 3px;
  }

  &__sort-button:disabled {
    cursor: wait;
  }

  &__row {
    border-top: 1px solid var(--line);
    color: var(--ink);
    font-size: 0.84rem;
    text-decoration: none;
    transition: opacity var(--motion-fast) ease;
  }

  &--loading &__row {
    opacity: 0.55;
  }

  &__row:hover {
    background: var(--color-surface-hover);
  }

  &__row:focus-visible {
    outline: 0;
    box-shadow: inset var(--focus-ring);
  }

  &__primary,
  &__date {
    min-width: 0;
  }

  &__primary strong {
    overflow: hidden;
    display: block;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  &__primary small {
    display: none;
    margin-top: 3px;
    color: var(--ink-soft);
  }

  &__customer,
  &__date {
    color: var(--ink-soft);
  }

  &__total {
    font-variant-numeric: tabular-nums;
  }

  &__status {
    justify-self: start;
    padding: 5px 8px;
    border-radius: 7px;
    background: var(--color-surface-muted);
    color: var(--ink-soft);
    font-size: 0.78rem;
    font-style: normal;
    font-weight: 800;
  }

  &__status.saved,
  &__status.shared,
  &__status.approved,
  &__status.completed {
    background: var(--mint);
    color: var(--color-brand);
  }

  &__status.change_requested {
    background: var(--color-warning-tint);
    color: var(--color-warning);
  }

  &__status.declined,
  &__status.cancelled {
    background: var(--color-danger-tint);
    color: var(--color-danger);
  }

  &__date {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 8px;
  }

  &__empty {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 12px;
    min-height: 150px;
    padding: 28px;
    color: var(--ink-soft);
    text-align: left;
  }

  &__empty > span {
    display: grid;
    flex: 0 0 auto;
    place-items: center;
    width: 42px;
    height: 42px;
    border-radius: 12px;
    background: var(--mint);
    color: var(--color-brand);
    font-size: 1.2rem;
  }

  &__empty strong {
    color: var(--ink);
  }

  &__empty p {
    margin: 3px 0 0;
    font-size: 0.84rem;
  }
}

@media (width <= 850px) {
  .quote-table {
    &__head {
      display: none;
    }

    &__row {
      grid-template-columns: minmax(0, 1fr) auto;
      gap: 9px 14px;
    }

    &__primary small {
      display: block;
    }

    &__customer,
    &__date {
      display: none;
    }

    &__total {
      grid-column: 1;
      grid-row: 2;
      color: var(--ink-soft);
      font-size: 0.8rem;
    }

    &__status {
      grid-column: 2;
      grid-row: 1 / span 2;
    }
  }
}
</style>
