<script setup lang="ts">
import { computed } from "vue";
import type { Quote, QuoteProfessional } from "~/types";
import { formatCurrency, formatDate } from "~/utils/formatters";
import { quoteSubtotal, quoteTotal } from "~/utils/quotes";

const props = defineProps<{
  quote: Quote;
  professional: QuoteProfessional;
  customerFacing?: boolean;
  authoritativeTotals?: boolean;
}>();
const subtotal = computed(() =>
  props.authoritativeTotals ? props.quote.subtotal : quoteSubtotal(props.quote),
);
const total = computed(() =>
  props.authoritativeTotals ? props.quote.total : quoteTotal(props.quote),
);
const isLumpSum = computed(() => props.quote.pricingMode === "lump_sum");
// In `itemized` mode the items are already the customer-facing content. In
// `lump_sum` mode they are the professional's private calculation and show
// here — as a priceless scope list, never with a unit price or line total —
// only when the owner opted in.
const showItems = computed(
  () => !isLumpSum.value || props.quote.itemsVisibleToCustomer,
);

function itemTotal(index: number) {
  const item = props.quote.items[index];
  if (!item) return 0;
  return props.authoritativeTotals
    ? item.lineTotal
    : item.quantity * item.unitPrice;
}
</script>

<template>
  <article
    class="quote-preview"
    :class="{ 'quote-preview--customer': customerFacing }"
  >
    <header>
      <div class="quote-preview__brand">berufe<span>.</span></div>
      <div>
        <span>Orçamento</span
        ><strong v-if="quote.number">#{{ quote.number }}</strong>
      </div>
    </header>
    <section class="quote-preview__professional">
      <DesignSystemAvatar
        :name="professional.name"
        :src="professional.avatar ?? undefined"
        size="sm"
        shape="rounded"
      />
      <div>
        <strong>{{ professional.name }}</strong
        ><span>{{ professional.primaryService }}</span
        ><small
          v-if="professional.identityVerified"
          class="quote-preview__verification"
          ><UIcon name="i-lucide-badge-check" size="1rem" /> Identidade
          verificada</small
        >
      </div>
    </section>
    <section class="quote-preview__intro">
      <div>
        <span>Cliente</span
        ><strong>{{ quote.customerName || "Nome do cliente" }}</strong>
      </div>
      <div>
        <span>Válido até</span
        ><strong>{{ formatDate(quote.validUntil) }}</strong>
      </div>
    </section>
    <section class="quote-preview__service">
      <span>Serviço</span>
      <h1>{{ quote.serviceDescription || "Descrição do serviço" }}</h1>
      <dl v-if="quote.scheduledOn || quote.serviceAddress">
        <div v-if="quote.scheduledOn">
          <dt>Data prevista do serviço</dt>
          <dd>{{ formatDate(quote.scheduledOn) }}</dd>
        </div>
        <div v-if="quote.serviceAddress">
          <dt>Local</dt>
          <dd>{{ quote.serviceAddress }}</dd>
        </div>
      </dl>
    </section>
    <section
      v-if="showItems"
      class="quote-preview__items"
      :class="{ 'quote-preview__items--scope': isLumpSum }"
    >
      <div class="quote-preview__item quote-preview__item--head">
        <span>{{ isLumpSum ? "Escopo do serviço" : "Descrição" }}</span
        ><span>Qtd.</span><span v-if="!isLumpSum">Valor</span>
      </div>
      <div
        v-for="(item, index) in quote.items"
        :key="item.id"
        class="quote-preview__item"
      >
        <span
          ><strong>{{ item.description || "Novo item" }}</strong
          ><small v-if="!isLumpSum"
            >{{ formatCurrency(item.unitPrice) }} / {{ item.unit }}</small
          ><small v-else>{{ item.unit }}</small></span
        >
        <span>{{ item.quantity }}</span>
        <span v-if="!isLumpSum">{{ formatCurrency(itemTotal(index)) }}</span>
      </div>
    </section>
    <section class="quote-preview__totals">
      <template v-if="isLumpSum">
        <div>
          <span>Valor do serviço</span
          ><strong>{{ formatCurrency(total) }}</strong>
        </div>
      </template>
      <template v-else>
        <div>
          <span>Subtotal</span><strong>{{ formatCurrency(subtotal) }}</strong>
        </div>
        <div v-if="quote.discount">
          <span>Desconto</span
          ><strong>− {{ formatCurrency(quote.discount) }}</strong>
        </div>
        <div>
          <span>Total</span><strong>{{ formatCurrency(total) }}</strong>
        </div>
      </template>
    </section>
    <section v-if="quote.materials.length" class="quote-preview__materials">
      <span>Materiais por conta do cliente</span>
      <ul>
        <li v-for="material in quote.materials" :key="material.id">
          <strong>{{ material.description || "Novo material" }}</strong>
          <small>{{ material.quantity }} {{ material.unit }}</small>
        </li>
      </ul>
      <p>A compra dos materiais é por conta do cliente.</p>
    </section>
    <section v-if="quote.notes" class="quote-preview__notes">
      <span>Observações</span>
      <p>{{ quote.notes }}</p>
    </section>
    <footer>
      <span v-if="professional.identityVerified"
        ><UIcon name="i-lucide-shield-check" /> Identidade verificada</span
      ><small
        >Este orçamento não é um contrato nem um comprovante de
        pagamento.</small
      >
    </footer>
  </article>
</template>

<style scoped lang="scss">
.quote-preview {
  overflow: hidden;
  border: 1px solid var(--line);
  border-radius: 18px;
  background: white;
  color: var(--ink);
  box-shadow: var(--shadow-sm);
  & > header {
    display: flex;
    justify-content: space-between;
    align-items: center;
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
  & > header > div:last-child {
    text-align: right;
  }
  & > header > div:last-child span,
  & > header > div:last-child strong {
    display: block;
  }
  & > header > div:last-child span {
    color: rgb(255 255 255 / 55%);
    font-size: 0.82rem;
    text-transform: uppercase;
  }
  & > header > div:last-child strong {
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
  &__notes > span {
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
  &__service {
    padding: 2px 22px 18px;
  }
  &__service h1 {
    margin: 5px 0 0;
    font-family: var(--font-display);
    font-size: 1.3rem;
    font-weight: 500;
    line-height: 1.25;
  }
  &__service dl {
    display: grid;
    gap: 7px;
    margin: 12px 0 0;
  }
  &__service dl > div {
    display: grid;
    grid-template-columns: 110px 1fr;
    gap: 8px;
    font-size: 0.82rem;
  }
  &__service dt {
    color: var(--ink-soft);
    font-weight: 800;
  }
  &__service dd {
    margin: 0;
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
    font-size: 0.84rem;
  }
  &__item small {
    margin-top: 3px;
    color: var(--ink-soft);
    font-size: 0.82rem;
  }
  &__items--scope &__item {
    grid-template-columns: 1fr 60px;
  }
  &__totals {
    margin: 12px 22px 0 auto;
    width: 190px;
    padding-bottom: 15px;
  }
  &__totals > div {
    display: flex;
    justify-content: space-between;
    padding: 4px 0;
    font-size: 0.82rem;
  }
  &__totals > div:last-child {
    margin-top: 5px;
    padding-top: 10px;
    border-top: 2px solid var(--ink);
    font-size: 0.84rem;
  }
  &__materials {
    margin: 0 22px 18px;
    padding: 13px;
    border-radius: 10px;
    background: #f5f3ed;
  }
  &__materials > span {
    display: block;
    color: var(--ink-soft);
    font-size: 0.82rem;
    font-weight: 850;
    letter-spacing: 0.06em;
    text-transform: uppercase;
  }
  &__materials ul {
    display: grid;
    gap: 6px;
    margin: 8px 0 0;
    padding: 0;
    list-style: none;
  }
  &__materials li {
    display: flex;
    justify-content: space-between;
    gap: 12px;
    font-size: 0.84rem;
  }
  &__materials li small {
    flex: 0 0 auto;
    color: var(--ink-soft);
    font-size: 0.82rem;
  }
  &__materials p {
    margin: 10px 0 0;
    color: var(--ink-soft);
    font-size: 0.78rem;
    line-height: 1.4;
  }
  &__notes {
    margin: 0 22px 18px;
    padding: 13px;
    border-radius: 10px;
    background: #f5f3ed;
  }
  &__notes p {
    margin: 5px 0 0;
    color: var(--ink-soft);
    font-size: 0.82rem;
    line-height: 1.5;
    white-space: pre-line;
  }
  & > footer {
    display: flex;
    justify-content: space-between;
    gap: 12px;
    padding: 12px 22px;
    background: var(--color-brand-tint-muted);
    color: var(--color-brand);
    font-size: 0.82rem;
  }
  & > footer span {
    display: flex;
    align-items: center;
    gap: 4px;
    font-weight: 850;
  }
  & > footer small {
    color: var(--ink-soft);
  }
  &--customer &__service h1 {
    font-size: 1.65rem;
  }
}
@media print {
  .quote-preview {
    border: 0;
    box-shadow: none;
  }
}
</style>
