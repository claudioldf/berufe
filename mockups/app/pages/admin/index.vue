<script setup lang="ts">
import { computed } from 'vue'
import moderationData from '../../../data/moderation.json'

const route = useRoute()
const view = computed(() => String(route.query.view ?? 'moderacao'))
useSeoMeta({ title: 'Operações e moderação' })
</script>

<template>
  <div class="admin-page">
    <section class="admin-heading">
      <div class="page-container admin-heading__inner">
        <div><p class="eyebrow">Berufe Operações</p><h1>{{ view === 'catalogos' ? 'Catálogos' : view === 'relatorios' ? 'Visão do produto' : 'Fila de moderação' }}</h1><p>{{ view === 'catalogos' ? 'Gerencie a linguagem controlada da plataforma.' : view === 'relatorios' ? 'Sinais agregados, sem identificar visitantes.' : 'Analise evidências e conteúdo na ordem de chegada.' }}</p></div>
        <div class="admin-heading__user"><span>CD</span><div><strong>Cláudio Dias</strong><small>Administrador · MFA ativo</small></div><UIcon name="i-lucide-shield-check" /></div>
      </div>
    </section>

    <div class="page-container admin-content">
      <div v-if="view === 'moderacao'" class="admin-summary">
        <article v-for="item in moderationData.summary" :key="item.label" :class="`admin-summary--${item.tone}`"><span><UIcon :name="item.icon" /></span><div><strong>{{ item.value }}</strong><small>{{ item.label }}</small></div></article>
      </div>

      <AdminModerationQueue v-if="view === 'moderacao'" />
      <AdminCatalogManager v-else-if="view === 'catalogos'" />

      <section v-else class="product-report">
        <div class="product-report__principle"><UIcon name="i-lucide-user-round-x" /><div><strong>Sem identidade de visitante</strong><p>As métricas abaixo são agregadas por dia. Não criamos perfis de navegação.</p></div></div>
        <div class="product-report__metrics">
          <article><span>Buscas nos últimos 30 dias</span><strong>1.284</strong><em>+14%</em></article>
          <article><span>Busca → perfil aberto</span><strong>42,8%</strong><em>+3,2 pp</em></article>
          <article><span>Perfil → WhatsApp</span><strong>18,6%</strong><em>+1,7 pp</em></article>
          <article><span>Perfis publicados</span><strong>43</strong><em>de 50</em></article>
        </div>
        <div class="product-report__grid">
          <section class="surface-card"><header><div><h2>Demanda por serviço</h2><p>Buscas agregadas</p></div><span>30 dias</span></header><div class="bar-list"><div v-for="item in [{ label: 'Eletricista', value: 286, width: 100 }, { label: 'Encanador', value: 221, width: 77 }, { label: 'Pintor', value: 198, width: 69 }, { label: 'Pedreiro', value: 164, width: 57 }, { label: 'Marido de aluguel', value: 118, width: 41 }]" :key="item.label"><span>{{ item.label }}</span><i><b :style="{ width: `${item.width}%` }" /></i><strong>{{ item.value }}</strong></div></div></section>
          <section class="surface-card"><header><div><h2>Gaps de oferta</h2><p>Buscas sem resultado</p></div><span>Priorizar rede</span></header><div class="gap-list"><div><span><UIcon name="i-lucide-trending-up" /></span><div><strong>Instalação de ar-condicionado</strong><small>42 buscas · fora do catálogo MVP</small></div></div><div><span><UIcon name="i-lucide-users" /></span><div><strong>Drywall no Aventureiro</strong><small>28 buscas · 0 profissionais</small></div></div><div><span><UIcon name="i-lucide-map-pin" /></span><div><strong>Marceneiro no Iririú</strong><small>19 buscas · 1 profissional</small></div></div></div></section>
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped>
.admin-page { min-height: 100vh; padding-bottom: 80px; background: #f2f0ea; }.admin-heading { padding: 32px 0 36px; background: #17352f; color: white; }.admin-heading__inner { display: flex; justify-content: space-between; align-items: end; gap: 20px; }.admin-heading .eyebrow { margin-bottom: 7px; color: #a7d7c8; }.admin-heading h1 { margin: 0; font-family: Georgia, serif; font-size: 2.6rem; font-weight: 500; letter-spacing: -.04em; }.admin-heading__inner > div:first-child > p:last-child { margin: 7px 0 0; color: rgba(255,255,255,.58); font-size: .7rem; }.admin-heading__user { display: grid; grid-template-columns: auto 1fr auto; align-items: center; gap: 9px; padding: 9px 11px; border: 1px solid rgba(255,255,255,.14); border-radius: 12px; background: rgba(255,255,255,.06); }.admin-heading__user > span { display: grid; place-items: center; width: 34px; height: 34px; border-radius: 9px; background: var(--coral); font-size: .65rem; font-weight: 900; }.admin-heading__user strong, .admin-heading__user small { display: block; }.admin-heading__user strong { font-size: .67rem; }.admin-heading__user small { margin-top: 2px; color: rgba(255,255,255,.55); font-size: .53rem; }.admin-heading__user > svg { color: #a7d7c8; }.admin-content { padding-top: 22px; }.admin-summary { display: grid; grid-template-columns: repeat(3, 1fr); gap: 9px; margin-bottom: 18px; }.admin-summary article { display: flex; align-items: center; gap: 10px; padding: 15px; border: 1px solid var(--line); border-radius: 14px; background: white; }.admin-summary article > span { display: grid; place-items: center; width: 36px; height: 36px; border-radius: 10px; background: #f0eee8; }.admin-summary strong, .admin-summary small { display: block; }.admin-summary strong { font-family: Georgia, serif; font-size: 1.3rem; }.admin-summary small { color: var(--ink-soft); font-size: .58rem; }.admin-summary--warning > span { background: #fff2cf !important; color: #947019; }.admin-summary--success > span { background: var(--mint) !important; color: #397a69; }.admin-summary--error > span { background: #ffe8e4 !important; color: #b54b39; }.product-report { display: grid; gap: 16px; }.product-report__principle { display: flex; align-items: center; gap: 10px; padding: 14px; border: 1px solid #a7ccc0; border-radius: 13px; background: #e8f4f0; color: #397a69; }.product-report__principle > svg { font-size: 1.3rem; }.product-report__principle strong, .product-report__principle p { margin: 0; }.product-report__principle strong { font-size: .68rem; }.product-report__principle p { margin-top: 2px; color: var(--ink-soft); font-size: .57rem; }.product-report__metrics { display: grid; grid-template-columns: repeat(4, 1fr); gap: 9px; }.product-report__metrics article { padding: 17px; border: 1px solid var(--line); border-radius: 14px; background: white; }.product-report__metrics span, .product-report__metrics strong, .product-report__metrics em { display: block; }.product-report__metrics span { color: var(--ink-soft); font-size: .57rem; }.product-report__metrics strong { margin-top: 10px; font-family: Georgia, serif; font-size: 1.7rem; }.product-report__metrics em { margin-top: 5px; color: #397a69; font-size: .56rem; font-style: normal; font-weight: 850; }.product-report__grid { display: grid; grid-template-columns: 1.15fr .85fr; gap: 12px; }.product-report__grid > section { padding: 20px; }.product-report__grid header { display: flex; justify-content: space-between; gap: 10px; }.product-report__grid h2, .product-report__grid p { margin: 0; }.product-report__grid h2 { font-family: Georgia, serif; font-size: 1.25rem; }.product-report__grid p { margin-top: 3px; color: var(--ink-soft); font-size: .57rem; }.product-report__grid header > span { color: var(--ink-soft); font-size: .56rem; }.bar-list { display: grid; gap: 13px; margin-top: 22px; }.bar-list > div { display: grid; grid-template-columns: 105px 1fr 30px; gap: 8px; align-items: center; font-size: .58rem; }.bar-list i { overflow: hidden; height: 7px; border-radius: 99px; background: #e8e7e2; }.bar-list b { display: block; height: 100%; border-radius: inherit; background: #397a69; }.bar-list strong { text-align: right; }.gap-list { display: grid; gap: 11px; margin-top: 18px; }.gap-list > div { display: grid; grid-template-columns: auto 1fr; gap: 9px; align-items: center; padding: 11px; border-radius: 10px; background: #f7f5f0; }.gap-list > div > span { display: grid; place-items: center; width: 32px; height: 32px; border-radius: 9px; background: #fff0ec; color: #bf5944; }.gap-list strong, .gap-list small { display: block; }.gap-list strong { font-size: .62rem; }.gap-list small { margin-top: 3px; color: var(--ink-soft); font-size: .54rem; }
@media (max-width: 800px) { .admin-heading__user { display: none; }.admin-summary, .product-report__metrics { grid-template-columns: repeat(2, 1fr); }.product-report__grid { grid-template-columns: 1fr; } } @media (max-width: 500px) { .admin-summary, .product-report__metrics { grid-template-columns: 1fr; } }
</style>
