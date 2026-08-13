<script setup lang="ts">
import { computed } from 'vue'
import type { Professional, Quote } from '~/types'
import { useMockupApp } from '~/composables/useMockupApp'

const props = defineProps<{
  quote: Quote
  professional: Professional
  customerFacing?: boolean
}>()
const { money } = useMockupApp()
const subtotal = computed(() => props.quote.items.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0))
const total = computed(() => Math.max(0, subtotal.value - props.quote.discount))

function formatDate(value?: string) {
  if (!value) return '—'
  return new Intl.DateTimeFormat('pt-BR', { timeZone: 'UTC' }).format(new Date(`${value}T12:00:00Z`))
}
</script>

<template>
  <article class="quote-preview" :class="{ 'quote-preview--customer': customerFacing }">
    <header>
      <div class="quote-preview__brand">berufe<span>.</span></div>
      <div><span>Orçamento</span><strong>#{{ quote.number }}</strong></div>
    </header>
    <section class="quote-preview__professional">
      <img :src="professional.avatar" :alt="`Foto de ${professional.name}`">
      <div><strong>{{ professional.name }}</strong><span>{{ professional.primaryService }} · Joinville</span><small><UIcon name="i-lucide-badge-check" /> Identidade verificada</small></div>
    </section>
    <section class="quote-preview__intro">
      <div><span>Preparado para</span><strong>{{ quote.customerName || 'Nome do cliente' }}</strong></div>
      <div><span>Válido até</span><strong>{{ formatDate(quote.validUntil) }}</strong></div>
    </section>
    <section class="quote-preview__service"><span>Serviço</span><h1>{{ quote.serviceDescription || 'Descrição do serviço' }}</h1></section>
    <section class="quote-preview__items">
      <div class="quote-preview__item quote-preview__item--head"><span>Descrição</span><span>Qtd.</span><span>Valor</span></div>
      <div v-for="item in quote.items" :key="item.id" class="quote-preview__item">
        <span><strong>{{ item.description || 'Novo item' }}</strong><small>{{ money(item.unitPrice) }} / {{ item.unit }}</small></span>
        <span>{{ item.quantity }}</span>
        <span>{{ money(item.quantity * item.unitPrice) }}</span>
      </div>
    </section>
    <section class="quote-preview__totals">
      <div><span>Subtotal</span><strong>{{ money(subtotal) }}</strong></div>
      <div v-if="quote.discount"><span>Desconto</span><strong>− {{ money(quote.discount) }}</strong></div>
      <div><span>Total</span><strong>{{ money(total) }}</strong></div>
    </section>
    <section v-if="quote.notes" class="quote-preview__notes"><span>Observações</span><p>{{ quote.notes }}</p></section>
    <footer><span><UIcon name="i-lucide-shield-check" /> Identidade profissional conferida</span><small>Este orçamento não representa aceite ou pagamento.</small></footer>
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
    background: #17352f;
    color: white;
  }
  &__brand {
    font-family: Georgia, serif;
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
    color: rgba(255, 255, 255, 0.55);
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
  &__professional img {
    width: 44px;
    height: 44px;
    border-radius: 12px;
    object-fit: cover;
  }
  &__professional strong,
  &__professional span,
  &__professional small {
    display: block;
  }
  &__professional strong {
    font-family: Georgia, serif;
    font-size: 0.9rem;
  }
  &__professional span {
    margin-top: 2px;
    color: var(--ink-soft);
    font-size: 0.82rem;
  }
  &__professional small {
    margin-top: 3px;
    color: #397a69;
    font-size: 0.82rem;
    font-weight: 850;
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
    font-family: Georgia, serif;
    font-size: 1.3rem;
    font-weight: 500;
    line-height: 1.25;
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
    background: #e7f3ef;
    color: #397a69;
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
  &--customer {
    max-width: 720px;
    margin: 0 auto;
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
