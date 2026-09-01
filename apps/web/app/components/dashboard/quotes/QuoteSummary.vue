<script setup lang="ts">
import { computed } from "vue";
import type { QuoteCommercialSummary } from "~/types";
import { formatCurrency } from "~/utils/formatters";

const props = defineProps<{
  summary: QuoteCommercialSummary;
}>();

interface SummaryCard {
  key: string;
  label: string;
  value: string;
  detail: string;
  icon: string;
  tone: "forest" | "coral" | "gold";
}

function quoteCountLabel(count: number) {
  return `${count} ${count === 1 ? "orçamento" : "orçamentos"}`;
}

function reviewCountLabel(count: number) {
  return count === 1 ? "orçamento para revisar" : "orçamentos para revisar";
}

const cards = computed<SummaryCard[]>(() => [
  {
    key: "awaiting-response",
    label: "Enviado ao cliente",
    value: formatCurrency(props.summary.awaitingResponse.total),
    detail: quoteCountLabel(props.summary.awaitingResponse.count),
    icon: "i-lucide-clock-3",
    tone: "gold",
  },
  {
    key: "changes-requested",
    label: "Alterações solicitadas",
    value: `${props.summary.changesRequested.count}`,
    detail: reviewCountLabel(props.summary.changesRequested.count),
    icon: "i-lucide-message-square-warning",
    tone: "coral",
  },
  {
    key: "approved-this-month",
    label: "Aprovados este mês",
    value: formatCurrency(props.summary.approvedThisMonth.total),
    detail: quoteCountLabel(props.summary.approvedThisMonth.count),
    icon: "i-lucide-circle-check-big",
    tone: "forest",
  },
]);
</script>

<template>
  <section class="quote-summary" aria-label="Resumo comercial dos orçamentos">
    <div class="quote-summary__grid">
      <article
        v-for="card in cards"
        :key="card.key"
        :aria-label="card.label"
        :class="['summary-card', `summary-card--${card.tone}`]"
      >
        <div class="summary-card__top">
          <span class="summary-card__icon" aria-hidden="true">
            <UIcon :name="card.icon" />
          </span>
          <span class="summary-card__label">{{ card.label }}</span>
        </div>
        <strong>{{ card.value }}</strong>
        <small>{{ card.detail }}</small>
      </article>
    </div>

    <p class="quote-summary__disclaimer">
      <UIcon name="i-lucide-info" aria-hidden="true" />
      Os valores correspondem aos orçamentos e não indicam pagamentos recebidos.
    </p>
  </section>
</template>

<style scoped lang="scss">
.quote-summary {
  display: grid;
  gap: 8px;

  &__grid {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 9px;
  }

  &__disclaimer {
    display: flex;
    align-items: center;
    gap: 5px;
    margin: 0;
    padding: 0 3px;
    color: var(--ink-soft);
    font-size: 0.72rem;
  }
}

.summary-card {
  --card-accent: var(--color-brand);
  --card-soft: var(--color-brand-tint);

  min-width: 0;
  padding: 15px;
  border: 1px solid var(--line);
  border-radius: 16px;
  background: rgb(255 255 255 / 88%);
  box-shadow: 0 8px 24px rgb(30 50 44 / 4.5%);

  &--coral {
    --card-accent: #bd563f;
    --card-soft: var(--color-accent-tint);
  }

  &--gold {
    --card-accent: #927019;
    --card-soft: #fff5d9;
  }

  &__top {
    display: flex;
    align-items: center;
    gap: 8px;
    min-height: 30px;
  }

  &__icon {
    display: grid;
    flex: 0 0 auto;
    width: 30px;
    height: 30px;
    place-items: center;
    border-radius: 9px;
    background: var(--card-soft);
    color: var(--card-accent);
  }

  &__label {
    flex: 1;
    color: var(--ink-soft);
    font-size: var(--font-size-min);
    font-weight: 750;
    line-height: 1.25;
  }

  & > strong {
    display: block;
    margin-top: 10px;
    font-family: var(--font-display);
    font-size: 1.75rem;
    font-weight: 500;
    letter-spacing: -0.035em;
    line-height: 1;
  }

  & > small {
    display: block;
    margin-top: 4px;
    color: var(--ink-soft);
    font-size: var(--font-size-min);
    line-height: 1.3;
  }
}

@media (width <= 680px) {
  .quote-summary__grid {
    grid-template-columns: 1fr;
  }

  .summary-card {
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    align-items: center;
    gap: 2px 16px;

    &__top {
      grid-row: 1;
      grid-column: 1;
    }

    & > strong {
      grid-row: 1 / span 2;
      grid-column: 2;
      margin: 0;
      text-align: right;
    }

    & > small {
      grid-row: 2;
      grid-column: 1;
      padding-left: 38px;
    }
  }
}
</style>
