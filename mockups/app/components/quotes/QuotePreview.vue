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

<style scoped>
.quote-preview { overflow: hidden; border: 1px solid var(--line); border-radius: 18px; background: white; color: var(--ink); box-shadow: var(--shadow-sm); }.quote-preview > header { display: flex; justify-content: space-between; align-items: center; padding: 21px 23px; background: #17352f; color: white; }.quote-preview__brand { font-family: Georgia, serif; font-size: 1.25rem; font-weight: 700; letter-spacing: -.04em; }.quote-preview__brand span { color: var(--coral); }.quote-preview > header > div:last-child { text-align: right; }.quote-preview > header > div:last-child span, .quote-preview > header > div:last-child strong { display: block; }.quote-preview > header > div:last-child span { color: rgba(255,255,255,.55); font-size: .53rem; text-transform: uppercase; }.quote-preview > header > div:last-child strong { margin-top: 2px; font-size: .75rem; }.quote-preview__professional { display: flex; align-items: center; gap: 10px; padding: 16px 22px; border-bottom: 1px solid var(--line); }.quote-preview__professional img { width: 44px; height: 44px; border-radius: 12px; object-fit: cover; }.quote-preview__professional strong, .quote-preview__professional span, .quote-preview__professional small { display: block; }.quote-preview__professional strong { font-family: Georgia, serif; font-size: .9rem; }.quote-preview__professional span { margin-top: 2px; color: var(--ink-soft); font-size: .55rem; }.quote-preview__professional small { margin-top: 3px; color: #397a69; font-size: .52rem; font-weight: 850; }.quote-preview__intro { display: grid; grid-template-columns: 1fr auto; gap: 18px; padding: 19px 22px; }.quote-preview__intro span, .quote-preview__intro strong { display: block; }.quote-preview__intro span, .quote-preview__service > span, .quote-preview__notes > span { color: var(--ink-soft); font-size: .53rem; font-weight: 850; letter-spacing: .06em; text-transform: uppercase; }.quote-preview__intro strong { margin-top: 3px; font-size: .68rem; }.quote-preview__intro > div:last-child { text-align: right; }.quote-preview__service { padding: 2px 22px 18px; }.quote-preview__service h1 { margin: 5px 0 0; font-family: Georgia, serif; font-size: 1.3rem; font-weight: 500; line-height: 1.25; }.quote-preview__items { padding: 0 22px; }.quote-preview__item { display: grid; grid-template-columns: 1fr 40px 86px; gap: 8px; align-items: center; padding: 11px 0; border-top: 1px solid var(--line); font-size: .6rem; }.quote-preview__item--head { color: var(--ink-soft); font-size: .5rem; font-weight: 850; text-transform: uppercase; }.quote-preview__item > span:nth-child(n+2) { text-align: right; }.quote-preview__item strong, .quote-preview__item small { display: block; }.quote-preview__item strong { font-size: .62rem; }.quote-preview__item small { margin-top: 3px; color: var(--ink-soft); font-size: .52rem; }.quote-preview__totals { margin: 12px 22px 0 auto; width: 190px; padding-bottom: 15px; }.quote-preview__totals > div { display: flex; justify-content: space-between; padding: 4px 0; font-size: .59rem; }.quote-preview__totals > div:last-child { margin-top: 5px; padding-top: 10px; border-top: 2px solid var(--ink); font-size: .76rem; }.quote-preview__notes { margin: 0 22px 18px; padding: 13px; border-radius: 10px; background: #f5f3ed; }.quote-preview__notes p { margin: 5px 0 0; color: var(--ink-soft); font-size: .55rem; line-height: 1.5; white-space: pre-line; }.quote-preview > footer { display: flex; justify-content: space-between; gap: 12px; padding: 12px 22px; background: #e7f3ef; color: #397a69; font-size: .5rem; }.quote-preview > footer span { display: flex; align-items: center; gap: 4px; font-weight: 850; }.quote-preview > footer small { color: var(--ink-soft); }.quote-preview--customer { max-width: 720px; margin: 0 auto; }.quote-preview--customer .quote-preview__service h1 { font-size: 1.65rem; }
@media print { .quote-preview { border: 0; box-shadow: none; } }
</style>
