<script setup lang="ts">
import { computed } from "vue";
import type { ProfessionalServiceJob } from "~/types";
import { formatCurrency } from "~/utils/formatters";

type StatusTone = "brand" | "warning" | "success" | "neutral";

const props = defineProps<{
  service: ProfessionalServiceJob;
  statusLabel: string;
  statusTone: StatusTone;
}>();

const customerInitials = computed(() =>
  props.service.quote.customerName
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((part) => part.charAt(0))
    .join("")
    .toUpperCase(),
);
const phoneHref = computed(
  () => `tel:${props.service.quote.customerPhone.replace(/\D/g, "")}`,
);
</script>

<template>
  <header class="service-hero">
    <div class="service-hero__main">
      <DesignSystemEyebrow tone="inverse">
        Orçamento #{{ service.quote.number }}
      </DesignSystemEyebrow>
      <h1>{{ service.quote.serviceDescription }}</h1>

      <div class="service-hero__customer">
        <span class="service-hero__avatar" aria-hidden="true">
          {{ customerInitials }}
        </span>
        <span class="service-hero__customer-copy">
          <small>Cliente</small>
          <strong>{{ service.quote.customerName }}</strong>
          <a :href="phoneHref">{{ service.quote.customerPhone }}</a>
        </span>
      </div>
    </div>

    <aside class="service-hero__summary" aria-label="Resumo do serviço">
      <span
        class="service-hero__status"
        :class="`service-hero__status--${statusTone}`"
      >
        <span aria-hidden="true" />
        {{ statusLabel }}
      </span>
      <span class="service-hero__value-label">Valor combinado</span>
      <strong class="service-hero__value">
        {{ formatCurrency(service.quote.total) }}
      </strong>
      <small>Orçamento aprovado pelo cliente</small>
    </aside>
  </header>
</template>

<style scoped lang="scss">
.service-hero {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 56px;
  align-items: end;
  color: var(--color-text-inverse);

  &__main {
    min-width: 0;
  }

  &__main :deep(.eyebrow) {
    margin-bottom: 11px;
  }

  &__main h1 {
    max-width: 700px;
    margin: 0;
    font-family: var(--font-display);
    font-size: clamp(2.5rem, 5vw, 4.5rem);
    font-weight: 500;
    letter-spacing: -0.052em;
    line-height: 0.98;
  }

  &__customer {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-top: 28px;
  }

  &__avatar {
    display: grid;
    flex: 0 0 auto;
    place-items: center;
    width: 46px;
    height: 46px;
    border: 1px solid rgb(255 255 255 / 15%);
    border-radius: 15px;
    background: rgb(255 255 255 / 10%);
    color: #c7e9dd;
    font-size: 0.78rem;
    font-weight: 900;
    letter-spacing: 0.06em;
  }

  &__customer-copy {
    display: grid;
    grid-template-columns: auto 1fr;
    column-gap: 9px;
    align-items: baseline;
  }

  &__customer-copy small {
    grid-column: 1 / -1;
    color: rgb(255 255 255 / 55%);
    font-size: 0.72rem;
    font-weight: 800;
    letter-spacing: 0.08em;
    text-transform: uppercase;
  }

  &__customer-copy strong {
    font-size: 0.95rem;
  }

  &__customer-copy a {
    color: rgb(255 255 255 / 65%);
    font-size: 0.86rem;
    text-decoration: none;
  }

  &__customer-copy a:hover {
    color: white;
    text-decoration: underline;
    text-underline-offset: 3px;
  }

  &__summary {
    display: grid;
    min-width: 252px;
    padding: 21px 23px;
    border: 1px solid rgb(255 255 255 / 13%);
    border-radius: 20px;
    background: rgb(255 255 255 / 8%);
    box-shadow: 0 22px 48px rgb(0 0 0 / 12%);
    backdrop-filter: blur(8px);
  }

  &__status {
    display: inline-flex;
    justify-self: start;
    align-items: center;
    gap: 7px;
    margin-bottom: 24px;
    padding: 6px 10px;
    border: 1px solid rgb(255 255 255 / 12%);
    border-radius: var(--radius-pill);
    background: rgb(255 255 255 / 9%);
    color: #d9f1e8;
    font-size: 0.7rem;
    font-weight: 850;
    letter-spacing: 0.05em;
    text-transform: uppercase;
  }

  &__status > span {
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background: #8ed8bf;
    box-shadow: 0 0 0 4px rgb(142 216 191 / 12%);
  }

  &__status--warning > span {
    background: #f6bd60;
    box-shadow: 0 0 0 4px rgb(246 189 96 / 13%);
  }

  &__status--success > span {
    background: #a7e0bb;
  }

  &__status--neutral > span {
    background: #c4cbc8;
    box-shadow: 0 0 0 4px rgb(196 203 200 / 12%);
  }

  &__value-label {
    color: rgb(255 255 255 / 56%);
    font-size: 0.75rem;
    font-weight: 750;
    letter-spacing: 0.06em;
    text-transform: uppercase;
  }

  &__value {
    margin-top: 5px;
    font-family: var(--font-display);
    font-size: 2rem;
    font-weight: 600;
    letter-spacing: -0.035em;
  }

  &__summary > small {
    margin-top: 4px;
    color: rgb(255 255 255 / 48%);
  }
}

@media (width <= 720px) {
  .service-hero {
    grid-template-columns: 1fr;
    gap: 28px;

    &__main h1 {
      font-size: clamp(2.4rem, 12vw, 3.5rem);
    }

    &__summary {
      grid-template-columns: 1fr auto;
      min-width: 0;
      align-items: end;
    }

    &__status {
      grid-column: 1 / -1;
      margin-bottom: 17px;
    }

    &__value-label,
    &__summary > small {
      grid-column: 1;
    }

    &__value {
      grid-column: 2;
      grid-row: 2 / 4;
      align-self: center;
      margin: 0;
    }
  }
}

@media (width <= 460px) {
  .service-hero__customer-copy {
    grid-template-columns: 1fr;
  }
}
</style>
