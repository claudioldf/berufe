<script setup lang="ts">
import quotesData from '../../../data/quotes.json'
import professionalsData from '../../../data/professionals.json'
import type { Professional, Quote } from '~/types'

const route = useRoute()
const professional = (professionalsData as Professional[])[0]!
const valid = route.params.token === quotesData.shared.token
const quote = quotesData.shared as Quote

if (!valid) throw createError({ statusCode: 404, statusMessage: 'Orçamento não encontrado' })
useSeoMeta({ title: `Orçamento #${quote.number}`, robots: 'noindex, nofollow' })

function printQuote() {
  if (import.meta.client) window.print()
}
</script>

<template>
  <div class="shared-quote-page">
    <DesignSystemContainer as="header" class="shared-quote-page__header"><DesignSystemBrand size="sm" /><div><UIcon name="i-lucide-lock-keyhole" /> Link privado do orçamento</div></DesignSystemContainer>
    <DesignSystemContainer as="main" class="shared-quote-page__content">
      <div class="shared-quote-page__heading"><div><p>Olá, {{ quote.customerName }}.</p><h1>Aqui está seu orçamento.</h1><span>Revise os itens e converse diretamente com {{ professional.name.split(' ')[0] }} se tiver alguma dúvida.</span></div><UButton color="neutral" variant="outline" icon="i-lucide-printer" @click="printQuote">Imprimir</UButton></div>
      <QuotesQuotePreview :quote="quote" :professional="professional" customer-facing />
      <p class="shared-quote-page__notice"><UIcon name="i-lucide-info" /> Este link permite visualizar o orçamento, mas não representa aceite, assinatura ou pagamento.</p>
    </DesignSystemContainer>
  </div>
</template>

<style scoped>
.shared-quote-page { min-height: 100vh; padding-bottom: 70px; background: #eeeae1; }.shared-quote-page__header { display: flex; justify-content: space-between; align-items: center; min-height: 70px; }.shared-quote-page__header > div { display: flex; align-items: center; gap: 5px; color: var(--ink-soft); font-size: .84rem; font-weight: 750; }.shared-quote-page__content { max-width: 760px; }.shared-quote-page__heading { display: flex; justify-content: space-between; align-items: end; gap: 20px; margin: 42px 0 24px; }.shared-quote-page__heading p { margin: 0 0 6px; color: #397a69; font-size: .86rem; font-weight: 850; }.shared-quote-page__heading h1 { margin: 0; font-family: Georgia, serif; font-size: 2.5rem; font-weight: 500; letter-spacing: -.04em; }.shared-quote-page__heading span { display: block; max-width: 500px; margin-top: 7px; color: var(--ink-soft); font-size: .86rem; line-height: 1.5; }.shared-quote-page__notice { display: flex; align-items: flex-start; justify-content: center; gap: 5px; margin: 16px 0 0; color: var(--ink-soft); font-size: .84rem; text-align: center; }
@media (max-width: 600px) { .shared-quote-page__heading { display: grid; }.shared-quote-page__heading h1 { font-size: 2rem; } } @media print { .shared-quote-page__header, .shared-quote-page__heading, .shared-quote-page__notice { display: none; }.shared-quote-page { padding: 0; background: white; }.shared-quote-page__content { width: 100%; max-width: none; } }
</style>
