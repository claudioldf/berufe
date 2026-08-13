<script setup lang="ts">
import { computed } from 'vue'
import type { ReportPeriodData } from '~/types'

const props = defineProps<{
  report: ReportPeriodData
}>()

interface SummaryCard {
  key: string
  label: string
  value: string
  detail: string
  change: string
  icon: string
  tone: 'forest' | 'coral' | 'gold' | 'blue' | 'purple'
}

const published = computed(() => props.report.supply.funnel.find(stage => stage.key === 'published')?.value ?? 0)
const activated = computed(() => props.report.supply.funnel.find(stage => stage.key === 'activated')?.value ?? 0)

function percent(value: number, total: number) {
  if (!total) return '—'
  return `${new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 1 }).format((value / total) * 100)}%`
}

const cards = computed<SummaryCard[]>(() => [
  {
    key: 'published',
    label: 'Publicados no período',
    value: `${published.value}`,
    detail: `meta fundadora ${props.report.supply.targetMinimum}–${props.report.supply.targetMaximum}`,
    change: props.report.summaryChanges.published,
    icon: 'i-lucide-users-round',
    tone: 'forest'
  },
  {
    key: 'activated',
    label: 'Perfis ativados',
    value: `${activated.value}/${published.value}`,
    detail: `${percent(activated.value, published.value)} dos publicados`,
    change: props.report.summaryChanges.activated,
    icon: 'i-lucide-badge-check',
    tone: 'purple'
  },
  {
    key: 'coverage',
    label: 'Buscas com resultado',
    value: `${props.report.discovery.searchesWithResults}/${props.report.discovery.searches}`,
    detail: `${percent(props.report.discovery.searchesWithResults, props.report.discovery.searches)} de cobertura`,
    change: props.report.summaryChanges.searchCoverage,
    icon: 'i-lucide-search-check',
    tone: 'blue'
  },
  {
    key: 'handoffs',
    label: 'Contatos iniciados',
    value: `${props.report.discovery.whatsappHandoffs}`,
    detail: `${percent(props.report.discovery.whatsappHandoffs, props.report.discovery.profileViews)} dos perfis abertos`,
    change: props.report.summaryChanges.handoffs,
    icon: 'i-lucide-message-circle-more',
    tone: 'coral'
  },
  {
    key: 'returning',
    label: 'Profissionais recorrentes',
    value: `${props.report.engagement.returningProfessionals}/${props.report.engagement.eligibleProfessionals}`,
    detail: `${percent(props.report.engagement.returningProfessionals, props.report.engagement.eligibleProfessionals)} da base publicada`,
    change: props.report.summaryChanges.returning,
    icon: 'i-lucide-refresh-cw',
    tone: 'gold'
  }
])
</script>

<template>
  <section class="summary" aria-labelledby="weekly-health-title">
    <div class="summary__heading">
      <div>
        <p class="section-kicker">Placar de partida</p>
        <h2 id="weekly-health-title">Saúde do crescimento</h2>
      </div>
      <p>Contagens e denominadores visíveis para uma base ainda pequena.</p>
    </div>

    <div class="summary__grid">
      <article v-for="card in cards" :key="card.key" :class="['summary-card', `summary-card--${card.tone}`]">
        <div class="summary-card__top">
          <span class="summary-card__icon"><UIcon :name="card.icon" /></span>
          <span class="summary-card__label">{{ card.label }}</span>
        </div>
        <strong>{{ card.value }}</strong>
        <small>{{ card.detail }}</small>
        <p><UIcon name="i-lucide-move-up-right" />{{ card.change }}</p>
      </article>
    </div>
  </section>
</template>

<style scoped>
.summary { display: grid; gap: 13px; }
.summary__heading { display: flex; align-items: end; justify-content: space-between; gap: 20px; }
.summary__heading h2, .summary__heading p { margin: 0; }
.summary__heading h2 { margin-top: 2px; font-family: Georgia, serif; font-size: 1.55rem; font-weight: 500; letter-spacing: -.025em; }
.summary__heading > p { max-width: 390px; color: var(--ink-soft); font-size: .78rem; line-height: 1.5; text-align: right; }
.section-kicker { color: #397a69; font-size: .7rem; font-weight: 900; letter-spacing: .12em; text-transform: uppercase; }
.summary__grid { display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 9px; }
.summary-card { --card-accent: #397a69; --card-soft: #e8f4f0; min-width: 0; padding: 15px; border: 1px solid var(--line); border-radius: 16px; background: rgba(255,255,255,.88); box-shadow: 0 8px 24px rgba(30,50,44,.045); }
.summary-card--coral { --card-accent: #bd563f; --card-soft: #fff0ec; }
.summary-card--gold { --card-accent: #927019; --card-soft: #fff5d9; }
.summary-card--blue { --card-accent: #356e84; --card-soft: #e8f3f7; }
.summary-card--purple { --card-accent: #705e93; --card-soft: #f0ecf7; }
.summary-card__top { display: flex; align-items: center; gap: 8px; min-height: 34px; }
.summary-card__icon { display: grid; flex: 0 0 auto; place-items: center; width: 30px; height: 30px; border-radius: 9px; background: var(--card-soft); color: var(--card-accent); }
.summary-card__label { color: var(--ink-soft); font-size: .73rem; font-weight: 750; line-height: 1.25; }
.summary-card > strong { display: block; margin-top: 13px; font-family: Georgia, serif; font-size: 1.75rem; font-weight: 500; letter-spacing: -.035em; }
.summary-card > small { display: block; min-height: 31px; margin-top: 2px; color: var(--ink-soft); font-size: .7rem; line-height: 1.35; }
.summary-card > p { display: flex; align-items: center; gap: 4px; margin: 10px 0 0; color: var(--card-accent); font-size: .69rem; font-weight: 850; }
.section-kicker { color: #2f6b5f; }
@media (max-width: 1020px) { .summary__grid { grid-template-columns: repeat(3, 1fr); } }
@media (max-width: 680px) { .summary__heading { align-items: start; flex-direction: column; }.summary__heading > p { text-align: left; }.summary__grid { grid-template-columns: 1fr 1fr; } }
@media (max-width: 430px) { .summary__grid { grid-template-columns: 1fr; } }
</style>
