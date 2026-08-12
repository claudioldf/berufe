<script setup lang="ts">
import dashboardData from '../../../data/dashboard.json'
import professionalsData from '../../../data/professionals.json'
import type { Professional } from '~/types'
import { useMockupApp } from '~/composables/useMockupApp'

const { share, showToast, money } = useMockupApp()
const professional = (professionalsData as Professional[]).find((item) => item.id === dashboardData.professionalId)!

useSeoMeta({ title: 'Painel profissional' })

async function shareProfile() {
  await share({ title: `${professional.name} na Berufe`, text: 'Conheça meu trabalho na Berufe.', url: dashboardData.publicUrl })
}

function respondRelationship(accepted: boolean) {
  showToast({
    title: accepted ? 'Colaboração confirmada' : 'Solicitação recusada',
    description: accepted ? 'Agora ela seguirá para moderação.' : 'Essa relação continuará privada.',
  })
}
</script>

<template>
  <div class="dashboard-page">
    <section class="dashboard-welcome">
      <div class="page-container dashboard-welcome__inner">
        <div>
          <p>Terça-feira, 11 de agosto</p>
          <h1>Olá, Marina. <em>Vamos em frente?</em></h1>
        </div>
        <div class="dashboard-welcome__actions">
          <UButton color="neutral" variant="outline" icon="i-lucide-share-2" @click="shareProfile">Compartilhar perfil</UButton>
          <UButton to="/painel/orcamentos/novo" color="secondary" icon="i-lucide-plus">Novo orçamento</UButton>
        </div>
      </div>
    </section>

    <div class="page-container dashboard-content">
      <section class="status-banner">
        <span class="status-banner__icon"><UIcon name="i-lucide-badge-check" /></span>
        <div><strong>Seu perfil está publicado</strong><p>Clientes já podem encontrar e entrar em contato com você.</p></div>
        <NuxtLink :to="`/profissionais/${professional.slug}`" target="_blank">Ver perfil público <UIcon name="i-lucide-arrow-up-right" /></NuxtLink>
      </section>

      <section class="dashboard-section metrics-section">
        <div class="dashboard-section__heading">
          <div><p class="eyebrow">Últimos 30 dias</p><h2>Sua presença em movimento.</h2></div>
          <span>Atualizado hoje, 07:00</span>
        </div>
        <div class="metrics-grid">
          <article v-for="metric in dashboardData.metrics" :key="metric.label">
            <span class="metric-icon"><UIcon :name="metric.icon" /></span>
            <div><strong>{{ metric.value }}</strong><small>{{ metric.label }}</small></div>
            <em>{{ metric.change }}</em>
          </article>
        </div>
        <p class="privacy-note"><UIcon name="i-lucide-lock-keyhole" /> Contagens agregadas e anônimas. A Berufe não identifica quem visitou seu perfil.</p>
      </section>

      <div class="dashboard-grid">
        <DashboardChecklist :readiness="dashboardData.readiness" :items="dashboardData.checklist" />

        <section class="actions-card surface-card">
          <header><span>Ações rápidas</span><small>Fortaleça seu perfil</small></header>
          <div class="actions-card__grid">
            <NuxtLink to="/painel/perfil"><span><UIcon name="i-lucide-pencil" /></span><strong>Editar perfil</strong><small>Dados e serviços</small></NuxtLink>
            <NuxtLink to="/painel/perfil?tab=portfolio"><span><UIcon name="i-lucide-image-plus" /></span><strong>Novo trabalho</strong><small>Adicionar ao portfólio</small></NuxtLink>
            <button type="button" @click="showToast({ title: 'Link de recomendação criado', description: 'Pronto para compartilhar no WhatsApp.' })"><span><UIcon name="i-lucide-heart-handshake" /></span><strong>Pedir recomendação</strong><small>Cliente anterior</small></button>
            <button type="button" @click="showToast({ title: 'Convite criado', description: 'Compartilhe o link com seu colaborador.' })"><span><UIcon name="i-lucide-user-plus" /></span><strong>Convidar parceiro</strong><small>Fortaleça sua rede</small></button>
          </div>
        </section>
      </div>

      <section class="dashboard-section pending-section">
        <div class="dashboard-section__heading"><div><p class="eyebrow">Precisa de atenção</p><h2>Pendências e análises.</h2></div><span>{{ dashboardData.pending.length }} itens</span></div>
        <div class="pending-list">
          <article v-for="item in dashboardData.pending" :key="item.id">
            <span class="pending-list__icon"><UIcon :name="item.type === 'portfolio' ? 'i-lucide-image' : 'i-lucide-handshake'" /></span>
            <div><strong>{{ item.title }}</strong><small>{{ item.date }}</small></div>
            <span class="pending-list__status">{{ item.status }}</span>
            <div v-if="item.type === 'relationship'" class="pending-list__actions">
              <UButton size="sm" color="neutral" variant="ghost" @click="respondRelationship(false)">Recusar</UButton>
              <UButton size="sm" color="primary" @click="respondRelationship(true)">Confirmar</UButton>
            </div>
          </article>
        </div>
      </section>

      <section class="dashboard-section quotes-section">
        <div class="dashboard-section__heading"><div><p class="eyebrow">Ferramentas</p><h2>Orçamentos recentes.</h2></div><UButton to="/painel/orcamentos/novo" variant="link" trailing-icon="i-lucide-arrow-right">Ver todos</UButton></div>
        <div class="quotes-table surface-card">
          <div class="quotes-table__head"><span>Orçamento</span><span>Cliente</span><span>Valor</span><span>Status</span><span>Data</span></div>
          <NuxtLink v-for="quote in dashboardData.recentQuotes" :key="quote.id" to="/painel/orcamentos/novo">
            <span><strong>#{{ quote.number }}</strong><small>{{ quote.service }}</small></span>
            <span>{{ quote.customer }}</span>
            <span><strong>{{ money(quote.total) }}</strong></span>
            <span><em :class="quote.status">{{ quote.status === 'shared' ? 'Compartilhado' : 'Rascunho' }}</em></span>
            <span>{{ quote.date }} <UIcon name="i-lucide-chevron-right" /></span>
          </NuxtLink>
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped>
.dashboard-page { min-height: 100vh; background: #f3f1eb; }.dashboard-welcome { padding: 40px 0 44px; background: #17352f; color: white; }.dashboard-welcome__inner { display: flex; justify-content: space-between; align-items: end; gap: 25px; }.dashboard-welcome p { margin: 0 0 8px; color: #9fcbc0; font-size: .86rem; font-weight: 800; text-transform: uppercase; }.dashboard-welcome h1 { margin: 0; font-family: Georgia, serif; font-size: clamp(2.2rem, 4vw, 3.8rem); font-weight: 500; letter-spacing: -.04em; }.dashboard-welcome h1 em { color: #a7d7c8; font-weight: inherit; }.dashboard-welcome__actions { display: flex; gap: 9px; }
.dashboard-content { padding-top: 24px; padding-bottom: 80px; }.status-banner { display: grid; grid-template-columns: auto 1fr auto; align-items: center; gap: 13px; padding: 15px 18px; border: 1px solid #b6d9cd; border-radius: 16px; background: #e6f4ef; }.status-banner__icon { display: grid; place-items: center; width: 38px; height: 38px; border-radius: 11px; background: white; color: #397a69; }.status-banner strong, .status-banner p { display: block; margin: 0; }.status-banner strong { font-size: .84rem; }.status-banner p { margin-top: 3px; color: var(--ink-soft); font-size: .86rem; }.status-banner a { display: flex; align-items: center; gap: 4px; color: #397a69; font-size: .86rem; font-weight: 850; text-decoration: none; }
.dashboard-section { margin-top: 48px; }.dashboard-section__heading { display: flex; justify-content: space-between; align-items: end; gap: 20px; margin-bottom: 20px; }.dashboard-section__heading .eyebrow { margin-bottom: 8px; }.dashboard-section__heading h2 { margin: 0; font-family: Georgia, serif; font-size: 2rem; font-weight: 500; letter-spacing: -.035em; }.dashboard-section__heading > span { color: var(--ink-soft); font-size: .86rem; }.metrics-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; }.metrics-grid article { display: grid; grid-template-columns: auto 1fr auto; align-items: center; gap: 11px; padding: 18px; border: 1px solid var(--line); border-radius: 17px; background: white; }.metric-icon { display: grid; place-items: center; width: 40px; height: 40px; border-radius: 12px; background: var(--mint); color: #397a69; }.metrics-grid strong, .metrics-grid small { display: block; }.metrics-grid strong { font-family: Georgia, serif; font-size: 1.45rem; }.metrics-grid small { color: var(--ink-soft); font-size: .84rem; }.metrics-grid em { align-self: start; padding: 4px 6px; border-radius: 6px; background: #e4f4ed; color: #32705f; font-size: .82rem; font-style: normal; font-weight: 900; }.privacy-note { display: flex; align-items: center; gap: 5px; margin: 10px 0 0; color: var(--ink-soft); font-size: .82rem; }
.dashboard-grid { display: grid; grid-template-columns: .9fr 1.1fr; gap: 12px; margin-top: 48px; }.actions-card { padding: 22px; }.actions-card header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }.actions-card header span { font-family: Georgia, serif; font-size: 1.4rem; font-weight: 600; }.actions-card header small { color: var(--ink-soft); font-size: .84rem; }.actions-card__grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 9px; }.actions-card__grid a, .actions-card__grid button { display: grid; grid-template-columns: auto 1fr; column-gap: 10px; min-height: 94px; padding: 15px; border: 1px solid var(--line); border-radius: 14px; background: #faf9f6; color: var(--ink); text-align: left; text-decoration: none; cursor: pointer; transition: .15s ease; }.actions-card__grid a:hover, .actions-card__grid button:hover { border-color: #9fc8bb; background: #eff7f4; }.actions-card__grid a > span, .actions-card__grid button > span { grid-row: 1 / 3; display: grid; place-items: center; width: 34px; height: 34px; border-radius: 10px; background: var(--mint); color: #397a69; }.actions-card__grid strong { align-self: end; font-size: .82rem; }.actions-card__grid small { color: var(--ink-soft); font-size: .84rem; }
.pending-list { display: grid; gap: 8px; }.pending-list article { display: grid; grid-template-columns: auto 1fr auto auto; align-items: center; gap: 12px; padding: 13px 16px; border: 1px solid var(--line); border-radius: 14px; background: white; }.pending-list__icon { display: grid; place-items: center; width: 38px; height: 38px; border-radius: 11px; background: #fff0ec; color: #be553f; }.pending-list strong, .pending-list small { display: block; }.pending-list strong { font-size: .82rem; }.pending-list small { margin-top: 3px; color: var(--ink-soft); font-size: .82rem; }.pending-list__status { padding: 5px 8px; border-radius: 7px; background: #fff7dd; color: #926916; font-size: .82rem; font-weight: 850; }.pending-list__actions { display: flex; gap: 5px; }
.quotes-table { overflow: hidden; }.quotes-table__head, .quotes-table > a { display: grid; grid-template-columns: 1.4fr 1fr .7fr .8fr .55fr; gap: 12px; align-items: center; padding: 13px 17px; }.quotes-table__head { background: #e9e7e0; color: var(--ink-soft); font-size: .82rem; font-weight: 900; text-transform: uppercase; }.quotes-table > a { border-top: 1px solid var(--line); color: var(--ink); font-size: .86rem; text-decoration: none; }.quotes-table > a:hover { background: #faf9f6; }.quotes-table > a strong, .quotes-table > a small { display: block; }.quotes-table > a small { margin-top: 3px; color: var(--ink-soft); font-size: .82rem; }.quotes-table em { display: inline-flex; padding: 5px 7px; border-radius: 7px; font-size: .82rem; font-style: normal; font-weight: 850; }.quotes-table em.shared { background: #e3f2ec; color: #2d6e5c; }.quotes-table em.draft { background: #edece7; color: #68736f; }.quotes-table > a > span:last-child { display: flex; align-items: center; justify-content: space-between; }
@media (max-width: 900px) { .metrics-grid { grid-template-columns: repeat(2, 1fr); }.dashboard-grid { grid-template-columns: 1fr; } }
@media (max-width: 700px) { .dashboard-welcome__inner, .dashboard-section__heading { display: grid; }.dashboard-welcome__actions { flex-wrap: wrap; }.status-banner { grid-template-columns: auto 1fr; }.status-banner a { grid-column: 2; }.metrics-grid { grid-template-columns: 1fr; }.pending-list article { grid-template-columns: auto 1fr auto; }.pending-list__actions { grid-column: 2 / -1; }.quotes-table__head { display: none; }.quotes-table > a { grid-template-columns: 1fr auto; }.quotes-table > a > span:nth-child(2), .quotes-table > a > span:nth-child(5) { display: none; } }
</style>
