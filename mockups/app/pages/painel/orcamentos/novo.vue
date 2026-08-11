<script setup lang="ts">
import quotesData from '../../../../data/quotes.json'
import professionalsData from '../../../../data/professionals.json'
import type { Professional, Quote } from '~/types'
import { useMockupApp } from '~/composables/useMockupApp'

const { showToast } = useMockupApp()
const professional = (professionalsData as Professional[])[0]!
const quote = quotesData.default as Quote

useSeoMeta({ title: 'Novo orçamento' })

function handleShared() {
  showToast({ title: 'Abrindo o WhatsApp', description: 'O link seguro foi criado; a Berufe não confirma a entrega.' })
}
</script>

<template>
  <div class="quote-workspace">
    <section class="quote-workspace__heading">
      <div class="page-container">
        <NuxtLink to="/painel"><UIcon name="i-lucide-arrow-left" /> Voltar ao painel</NuxtLink>
        <div><div><p class="eyebrow">Berufe Ferramentas</p><h1>Novo orçamento <em>#{{ quote.number }}</em></h1><p>Crie, revise e compartilhe um link seguro com seu cliente.</p></div><span><i /> Rascunho</span></div>
      </div>
    </section>
    <div class="page-container quote-workspace__content">
      <DashboardQuoteBuilder :initial-quote="quote" :professional="professional" @shared="handleShared" />
    </div>
  </div>
</template>

<style scoped>
.quote-workspace { min-height: 100vh; padding-bottom: 80px; background: #f3f1eb; }.quote-workspace__heading { padding: 28px 0 34px; background: #17352f; color: white; }.quote-workspace__heading a { display: flex; align-items: center; gap: 5px; margin-bottom: 20px; color: rgba(255,255,255,.58); font-size: .75rem; font-weight: 700; text-decoration: none; }.quote-workspace__heading .page-container > div { display: flex; justify-content: space-between; align-items: end; gap: 20px; }.quote-workspace__heading .eyebrow { margin-bottom: 7px; color: #a7d7c8; }.quote-workspace__heading h1 { margin: 0; font-family: Georgia, serif; font-size: 2.5rem; font-weight: 500; letter-spacing: -.04em; }.quote-workspace__heading h1 em { color: #a7d7c8; font-size: .55em; font-style: normal; }.quote-workspace__heading p:last-child { margin: 7px 0 0; color: rgba(255,255,255,.58); font-size: .7rem; }.quote-workspace__heading .page-container > div > span { display: flex; align-items: center; gap: 6px; padding: 7px 10px; border: 1px solid rgba(255,255,255,.15); border-radius: 8px; color: #d5ddd9; font-size: .75rem; font-weight: 850; }.quote-workspace__heading .page-container > div > span i { width: 7px; height: 7px; border-radius: 99px; background: #c7c8c4; }.quote-workspace__content { padding-top: 24px; }
</style>
