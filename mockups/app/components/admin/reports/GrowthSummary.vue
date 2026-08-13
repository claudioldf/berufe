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
  help: {
    meaning: string
    goal: string
    reading: string
  }
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
    tone: 'forest',
    help: {
      meaning: 'Profissionais cujo perfil foi aprovado e ficou pesquisável no período selecionado.',
      goal: `Formar a rede fundadora de ${props.report.supply.targetMinimum}–${props.report.supply.targetMaximum} profissionais publicados, com oferta distribuída entre serviços e bairros.`,
      reading: 'Leia junto do funil: muitos cadastros e poucas publicações indicam bloqueio em verificação, preenchimento ou moderação.'
    }
  },
  {
    key: 'activated',
    label: 'Perfis ativados',
    value: `${activated.value}/${published.value}`,
    detail: `${percent(activated.value, published.value)} dos publicados`,
    change: props.report.summaryChanges.activated,
    icon: 'i-lucide-badge-check',
    tone: 'purple',
    help: {
      meaning: 'Perfis publicados com identidade aprovada, pelo menos três trabalhos no portfólio e duas relações profissionais confirmadas.',
      goal: 'Aumentar continuamente a parcela de publicados que cumpre todos os critérios de ativação, sem criar uma nota de confiança opaca.',
      reading: 'O numerador mostra ativados e o denominador, publicados. Consulte “Qualidade da oferta” para descobrir qual critério está faltando.'
    }
  },
  {
    key: 'coverage',
    label: 'Buscas com resultado',
    value: `${props.report.discovery.searchesWithResults}/${props.report.discovery.searches}`,
    detail: `${percent(props.report.discovery.searchesWithResults, props.report.discovery.searches)} de cobertura`,
    change: props.report.summaryChanges.searchCoverage,
    icon: 'i-lucide-search-check',
    tone: 'blue',
    help: {
      meaning: 'Buscas válidas que retornaram ao menos um profissional relevante no serviço e região procurados.',
      goal: 'Cobrir todas as buscas válidas; os casos recorrentes sem resultado devem orientar recrutamento ou revisão do catálogo.',
      reading: 'Uma taxa alta com poucas opções ainda pode ser frágil. Compare também com buscas que oferecem três ou mais profissionais.'
    }
  },
  {
    key: 'handoffs',
    label: 'Contatos iniciados',
    value: `${props.report.discovery.whatsappHandoffs}`,
    detail: `${percent(props.report.discovery.whatsappHandoffs, props.report.discovery.profileViews)} dos perfis abertos`,
    change: props.report.summaryChanges.handoffs,
    icon: 'i-lucide-message-circle-more',
    tone: 'coral',
    help: {
      meaning: 'Cliques deduplicados para iniciar uma conversa no WhatsApp a partir de um perfil ou resultado de busca.',
      goal: 'Fazer o volume crescer junto com buscas bem atendidas e perfis abertos, mostrando que a descoberta gera intenção de contato.',
      reading: 'É uma oportunidade observável, não uma contratação. A Berufe não lê mensagens nem conhece o resultado da conversa.'
    }
  },
  {
    key: 'returning',
    label: 'Profissionais recorrentes',
    value: `${props.report.engagement.returningProfessionals}/${props.report.engagement.eligibleProfessionals}`,
    detail: `${percent(props.report.engagement.returningProfessionals, props.report.engagement.eligibleProfessionals)} da base publicada`,
    change: props.report.summaryChanges.returning,
    icon: 'i-lucide-refresh-cw',
    tone: 'gold',
    help: {
      meaning: 'Profissionais da base publicada que voltaram e realizaram uma ação útil, como atualizar o perfil, criar evidência, interagir com a rede ou gerar orçamento.',
      goal: 'Elevar a recorrência semanal e a retenção W1/W4; login isolado não conta como valor gerado.',
      reading: 'Use o total com as coortes de retenção. Em bases pequenas, n/N é mais confiável que comparar variações percentuais.'
    }
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
          <AdminReportsMetricHelp :title="card.label" v-bind="card.help" />
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
.summary__heading > p { max-width: 390px; color: var(--ink-soft); font-size: var(--font-size-min); line-height: 1.5; text-align: right; }
.section-kicker { color: #397a69; font-size: var(--font-size-min); font-weight: 900; letter-spacing: .12em; text-transform: uppercase; }
.summary__grid { display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 9px; }
.summary-card { --card-accent: #397a69; --card-soft: #e8f4f0; min-width: 0; padding: 15px; border: 1px solid var(--line); border-radius: 16px; background: rgba(255,255,255,.88); box-shadow: 0 8px 24px rgba(30,50,44,.045); }
.summary-card--coral { --card-accent: #bd563f; --card-soft: #fff0ec; }
.summary-card--gold { --card-accent: #927019; --card-soft: #fff5d9; }
.summary-card--blue { --card-accent: #356e84; --card-soft: #e8f3f7; }
.summary-card--purple { --card-accent: #705e93; --card-soft: #f0ecf7; }
.summary-card__top { display: flex; align-items: center; gap: 8px; min-height: 34px; }
.summary-card__icon { display: grid; flex: 0 0 auto; place-items: center; width: 30px; height: 30px; border-radius: 9px; background: var(--card-soft); color: var(--card-accent); }
.summary-card__label { flex: 1; color: var(--ink-soft); font-size: var(--font-size-min); font-weight: 750; line-height: 1.25; }
.summary-card > strong { display: block; margin-top: 13px; font-family: Georgia, serif; font-size: 1.75rem; font-weight: 500; letter-spacing: -.035em; }
.summary-card > small { display: block; min-height: 31px; margin-top: 2px; color: var(--ink-soft); font-size: var(--font-size-min); line-height: 1.35; }
.summary-card > p { display: flex; align-items: center; gap: 4px; margin: 10px 0 0; color: var(--card-accent); font-size: var(--font-size-min); font-weight: 850; }
.section-kicker { color: #2f6b5f; }
@media (max-width: 1020px) { .summary__grid { grid-template-columns: repeat(3, 1fr); } }
@media (max-width: 680px) { .summary__heading { align-items: start; flex-direction: column; }.summary__heading > p { text-align: left; }.summary__grid { grid-template-columns: 1fr 1fr; } }
@media (max-width: 430px) { .summary__grid { grid-template-columns: 1fr; } }
</style>
