<script setup lang="ts">
import type { QuoteCommercialSummary } from "~/types";
import { formatCurrency } from "~/utils/formatters";

const props = defineProps<{
  summary: QuoteCommercialSummary;
}>();

function quoteCountLabel(count: number) {
  return `${count} ${count === 1 ? "orçamento" : "orçamentos"}`;
}

function reviewCountLabel(count: number) {
  return count === 1 ? "orçamento para revisar" : "orçamentos para revisar";
}
</script>

<template>
  <section class="quote-summary" aria-label="Resumo comercial dos orçamentos">
    <div class="quote-summary__grid">
      <DesignSystemSurfaceCard
        as="article"
        class="quote-summary__card quote-summary__card--awaiting"
        aria-label="Aguardando resposta"
      >
        <span class="quote-summary__icon" aria-hidden="true">
          <UIcon name="i-lucide-clock-3" />
        </span>
        <p class="quote-summary__label">Aguardando resposta</p>
        <strong class="quote-summary__value">
          {{ formatCurrency(props.summary.awaitingResponse.total) }}
        </strong>
        <small class="quote-summary__count">
          {{ quoteCountLabel(props.summary.awaitingResponse.count) }}
        </small>
      </DesignSystemSurfaceCard>

      <DesignSystemSurfaceCard
        as="article"
        class="quote-summary__card quote-summary__card--requested"
        aria-label="Alterações solicitadas"
      >
        <span class="quote-summary__icon" aria-hidden="true">
          <UIcon name="i-lucide-message-square-warning" />
        </span>
        <p class="quote-summary__label">Alterações solicitadas</p>
        <strong class="quote-summary__value">
          {{ props.summary.changesRequested.count }}
        </strong>
        <small class="quote-summary__count">
          {{ reviewCountLabel(props.summary.changesRequested.count) }}
        </small>
      </DesignSystemSurfaceCard>

      <DesignSystemSurfaceCard
        as="article"
        class="quote-summary__card quote-summary__card--approved"
        aria-label="Aprovados este mês"
      >
        <span class="quote-summary__icon" aria-hidden="true">
          <UIcon name="i-lucide-circle-check-big" />
        </span>
        <p class="quote-summary__label">Aprovados este mês</p>
        <strong class="quote-summary__value">
          {{ formatCurrency(props.summary.approvedThisMonth.total) }}
        </strong>
        <small class="quote-summary__count">
          {{ quoteCountLabel(props.summary.approvedThisMonth.count) }}
        </small>
      </DesignSystemSurfaceCard>
    </div>

    <p class="quote-summary__disclaimer">
      <UIcon name="i-lucide-info" aria-hidden="true" />
      Valores de orçamentos; não representam pagamentos recebidos.
    </p>
  </section>
</template>

<style scoped lang="scss">
.quote-summary {
  display: grid;
  gap: 10px;

  &__grid {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 14px;
  }

  &__card {
    position: relative;
    display: grid;
    min-width: 0;
    padding: 20px 22px;
    overflow: hidden;
  }

  &__card::before {
    position: absolute;
    inset: 0 auto 0 0;
    width: 4px;
    background: var(--color-brand);
    content: "";
  }

  &__card--requested::before {
    background: var(--color-accent);
  }

  &__card--approved::before {
    background: var(--color-brand-soft);
  }

  &__icon {
    position: absolute;
    top: 18px;
    right: 20px;
    display: grid;
    width: 34px;
    height: 34px;
    place-items: center;
    border-radius: 50%;
    background: var(--color-brand-tint);
    color: var(--color-brand);
    font-size: 1rem;
  }

  &__card--requested &__icon {
    background: var(--color-accent-tint);
    color: var(--color-accent);
  }

  &__label,
  &__count,
  &__disclaimer {
    margin: 0;
  }

  &__label {
    padding-right: 42px;
    color: var(--ink-soft);
    font-size: 0.78rem;
    font-weight: 800;
    letter-spacing: 0.04em;
    text-transform: uppercase;
  }

  &__value {
    margin-top: 15px;
    color: var(--color-text);
    font-family: var(--font-display);
    font-size: clamp(1.75rem, 3vw, 2.25rem);
    font-weight: 500;
    line-height: 1;
  }

  &__count {
    margin-top: 9px;
    color: var(--ink-soft);
    font-size: 0.82rem;
  }

  &__disclaimer {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 0 4px;
    color: var(--ink-soft);
    font-size: 0.76rem;
  }
}

@media (width <= 720px) {
  .quote-summary__grid {
    grid-template-columns: 1fr;
  }
}
</style>
