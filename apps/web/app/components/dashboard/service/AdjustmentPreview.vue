<script setup lang="ts">
import type {
  ProfessionalServiceJob,
  QuoteProfessional,
  ServiceAdjustmentEditorForm,
  ServiceAdjustmentEditorItem,
} from "~/types";
import { formatCurrency, formatDate } from "~/utils/formatters";

defineProps<{
  form: ServiceAdjustmentEditorForm;
  service: ProfessionalServiceJob;
  professional: QuoteProfessional;
  adjustmentNumber?: number;
  total: number;
  projectedTotal: number;
}>();

const kindLabels = {
  additional_service: "Serviço adicional",
  material_charge: "Material",
  material_reimbursement: "Compra e reembolso de material",
  credit: "Crédito",
} as const;

function lineTotal(item: ServiceAdjustmentEditorItem) {
  const value = Number(item.quantity || 0) * Number(item.unitPrice || 0);
  return item.kind === "credit" ? -value : value;
}
</script>

<template>
  <article class="adjustment-preview">
    <header class="adjustment-preview__header">
      <div class="adjustment-preview__brand">berufe<span>.</span></div>
      <div>
        <span>Ajuste do serviço</span>
        <strong v-if="adjustmentNumber">#{{ adjustmentNumber }}</strong>
      </div>
    </header>

    <section class="adjustment-preview__professional">
      <DesignSystemAvatar
        :name="professional.name"
        :src="professional.avatar ?? undefined"
        size="sm"
        shape="rounded"
      />
      <div>
        <strong>{{ professional.name }}</strong>
        <span>{{ professional.primaryService }}</span>
        <small
          v-if="professional.identityVerified"
          class="adjustment-preview__verification"
        >
          <UIcon name="i-lucide-badge-check" aria-hidden="true" />
          Identidade verificada
        </small>
      </div>
    </section>

    <section class="adjustment-preview__intro">
      <div>
        <span>Cliente</span>
        <strong>{{ service.quote.customerName }}</strong>
      </div>
      <div>
        <span>Orçamento</span>
        <strong>#{{ service.quote.number }}</strong>
      </div>
    </section>

    <section class="adjustment-preview__service">
      <span>Serviço contratado</span>
      <h1>{{ service.quote.serviceDescription }}</h1>
    </section>

    <section class="adjustment-preview__change">
      <span>Novo ajuste</span>
      <h2>{{ form.title || "Resumo do ajuste" }}</h2>
      <p v-if="form.description">{{ form.description }}</p>
      <dl v-if="form.scheduleImpact || form.incurredOn">
        <div v-if="form.scheduleImpact">
          <dt>Impacto no prazo</dt>
          <dd>{{ form.scheduleImpact }}</dd>
        </div>
        <div v-if="form.incurredOn">
          <dt>Informado como realizado em</dt>
          <dd>{{ formatDate(form.incurredOn) }}</dd>
        </div>
      </dl>
    </section>

    <section v-if="form.items.length" class="adjustment-preview__items">
      <div class="adjustment-preview__item adjustment-preview__item--head">
        <span>Descrição</span><span>Qtd.</span><span>Valor</span>
      </div>
      <div
        v-for="item in form.items"
        :key="item.key"
        class="adjustment-preview__item"
      >
        <span>
          <strong>{{ item.description || "Novo item" }}</strong>
          <small>{{ kindLabels[item.kind] }}</small>
        </span>
        <span>{{ item.quantity }}</span>
        <span>{{ formatCurrency(lineTotal(item)) }}</span>
      </div>
    </section>

    <section class="adjustment-preview__totals">
      <div>
        <span>Acordo atual</span>
        <strong>{{ formatCurrency(service.agreedTotal) }}</strong>
      </div>
      <div>
        <span>Este ajuste</span>
        <strong>{{ formatCurrency(total) }}</strong>
      </div>
      <div>
        <span>Após aprovação</span>
        <strong>{{ formatCurrency(projectedTotal) }}</strong>
      </div>
    </section>

    <footer class="adjustment-preview__footer">
      <UIcon name="i-lucide-info" aria-hidden="true" />
      <small>
        O ajuste só entra no total combinado depois da aprovação do cliente.
      </small>
    </footer>
  </article>
</template>

<style scoped lang="scss">
.adjustment-preview {
  overflow: hidden;
  border: 1px solid var(--line);
  border-radius: 18px;
  background: white;
  color: var(--ink);
  box-shadow: var(--shadow-sm);

  &__header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 21px 23px;
    background: var(--color-brand-strong);
    color: white;
  }

  &__brand {
    font-family: var(--font-display);
    font-size: 1.25rem;
    font-weight: 700;
    letter-spacing: -0.04em;
  }

  &__brand span {
    color: var(--coral);
  }

  &__header > div:last-child {
    text-align: right;
  }

  &__header > div:last-child span,
  &__header > div:last-child strong {
    display: block;
  }

  &__header > div:last-child span {
    color: rgb(255 255 255 / 55%);
    font-size: 0.82rem;
    text-transform: uppercase;
  }

  &__header > div:last-child strong {
    margin-top: 2px;
    font-size: 0.84rem;
  }

  &__professional {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 16px 22px;
    border-bottom: 1px solid var(--line);
  }

  &__professional :deep(.avatar) {
    width: 44px;
    height: 44px;
  }

  &__professional strong,
  &__professional span,
  &__professional small {
    display: block;
  }

  &__professional strong {
    font-family: var(--font-display);
    font-size: 0.9rem;
  }

  &__professional span {
    margin-top: 2px;
    color: var(--ink-soft);
    font-size: 0.82rem;
  }

  &__professional small {
    margin-top: 3px;
    color: var(--color-brand);
    font-size: 0.82rem;
    font-weight: 850;
  }

  &__professional &__verification {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    white-space: nowrap;
  }

  &__intro {
    display: grid;
    grid-template-columns: 1fr auto;
    gap: 18px;
    padding: 19px 22px;
  }

  &__intro span,
  &__intro strong {
    display: block;
  }

  &__intro span,
  &__service > span,
  &__change > span {
    color: var(--ink-soft);
    font-size: 0.82rem;
    font-weight: 850;
    letter-spacing: 0.06em;
    text-transform: uppercase;
  }

  &__intro strong {
    margin-top: 3px;
    font-size: 0.86rem;
  }

  &__intro > div:last-child {
    text-align: right;
  }

  &__service,
  &__change {
    padding: 2px 22px 18px;
  }

  &__service h1,
  &__change h2 {
    margin: 5px 0 0;
    overflow-wrap: anywhere;
    font-family: var(--font-display);
    font-size: 1.3rem;
    font-weight: 500;
    line-height: 1.25;
    text-wrap: balance;
  }

  &__service h1 {
    font-family: inherit;
    font-size: 0.86rem;
    font-weight: 700;
    line-height: 1.5;
  }

  &__change {
    padding-top: 16px;
    border-top: 1px solid var(--line);
  }

  &__change p {
    margin: 7px 0 0;
    overflow-wrap: anywhere;
    color: var(--ink-soft);
    font-size: 0.82rem;
    line-height: 1.5;
    white-space: pre-line;
  }

  &__change dl {
    display: grid;
    gap: 7px;
    margin: 12px 0 0;
  }

  &__change dl > div {
    display: grid;
    grid-template-columns: 145px 1fr;
    gap: 8px;
    font-size: 0.82rem;
  }

  &__change dt {
    color: var(--ink-soft);
    font-weight: 800;
  }

  &__change dd {
    margin: 0;
    overflow-wrap: anywhere;
  }

  &__items {
    padding: 0 22px;
  }

  &__item {
    display: grid;
    grid-template-columns: 1fr 40px 86px;
    gap: 8px;
    align-items: center;
    padding: 11px 0;
    border-top: 1px solid var(--line);
    font-size: 0.84rem;
  }

  &__item--head {
    color: var(--ink-soft);
    font-size: 0.82rem;
    font-weight: 850;
    text-transform: uppercase;
  }

  &__item > span:nth-child(n + 2) {
    text-align: right;
  }

  &__item strong,
  &__item small {
    display: block;
  }

  &__item strong {
    overflow-wrap: anywhere;
    font-size: 0.84rem;
  }

  &__item small {
    margin-top: 3px;
    color: var(--ink-soft);
    font-size: 0.76rem;
  }

  &__totals {
    width: min(260px, calc(100% - 44px));
    padding-bottom: 15px;
    margin: 12px 22px 0 auto;
  }

  &__totals > div {
    display: flex;
    justify-content: space-between;
    gap: 12px;
    padding: 4px 0;
    color: var(--ink-soft);
    font-size: 0.82rem;
  }

  &__totals > div:last-child {
    margin-top: 5px;
    padding-top: 10px;
    border-top: 2px solid var(--ink);
    color: var(--ink);
    font-size: 0.84rem;
  }

  &__totals strong {
    font-variant-numeric: tabular-nums;
    white-space: nowrap;
  }

  &__footer {
    display: flex;
    align-items: flex-start;
    gap: 6px;
    padding: 12px 22px;
    background: var(--color-brand-tint-muted);
    color: var(--color-brand);
    font-size: 0.82rem;
  }

  &__footer :deep(svg) {
    flex: 0 0 auto;
    margin-top: 0.1em;
  }

  &__footer small {
    color: var(--ink-soft);
    line-height: 1.4;
  }
}
</style>
