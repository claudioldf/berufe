<script setup lang="ts">
import { computed } from 'vue'
import type { ReportPeriodData } from '~/types'

const props = defineProps<{
  engagement: ReportPeriodData['engagement']
}>()

const maxAction = computed(() => Math.max(...props.engagement.actions.map(action => action.value), 1))

function retention(value: number | null, size: number) {
  if (value === null || !size) return '—'
  return `${value}/${size}`
}

function retentionWidth(value: number | null, size: number) {
  if (value === null || !size) return '0%'
  return `${Math.round((value / size) * 100)}%`
}
</script>

<template>
  <section class="engagement" aria-labelledby="engagement-title">
    <header class="section-heading">
      <div><p class="section-kicker">Frequência útil</p><h2 id="engagement-title">Retenção profissional</h2></div>
      <p>Conta quem voltou e fez algo que aumenta o valor da rede — não apenas quem entrou.</p>
    </header>

    <div class="engagement__grid">
      <article class="surface-card activity-card">
        <header><div><h3>Ações significativas</h3><p>{{ engagement.meaningfulActives }}/{{ engagement.eligibleProfessionals }} profissionais ativos no período</p></div><span><strong>{{ engagement.returningProfessionals }}</strong> recorrentes</span></header>
        <div class="action-list">
          <div v-for="action in engagement.actions" :key="action.key">
            <span>{{ action.label }}</span>
            <i><b :style="{ width: `${(action.value / maxAction) * 100}%` }" /></i>
            <strong>{{ action.value }}</strong>
          </div>
        </div>
        <div class="frequency-strip">
          <div v-for="frequency in engagement.activeWeeks" :key="frequency.key"><strong>{{ frequency.value }}</strong><small>{{ frequency.label }}</small></div>
        </div>
      </article>

      <article class="surface-card cohort-card">
        <header><div><h3>Coortes de publicação</h3><p>Retorno após o perfil entrar no ar</p></div><span>n pequeno: exibimos n/N</span></header>
        <div class="cohort-table" role="table" aria-label="Retenção por coorte de publicação">
          <div class="cohort-table__head" role="row"><span role="columnheader">Coorte</span><span role="columnheader">Perfis</span><span role="columnheader">Semana 1</span><span role="columnheader">Semana 4</span></div>
          <div v-for="cohort in engagement.cohorts" :key="cohort.cohort" class="cohort-table__row" role="row">
            <strong role="cell">{{ cohort.cohort }}</strong>
            <span role="cell">{{ cohort.size }}</span>
            <div role="cell"><i><b :style="{ width: retentionWidth(cohort.week1, cohort.size) }" /></i><em>{{ retention(cohort.week1, cohort.size) }}</em></div>
            <div role="cell"><i><b :style="{ width: retentionWidth(cohort.week4, cohort.size) }" /></i><em>{{ retention(cohort.week4, cohort.size) }}</em></div>
          </div>
        </div>
      </article>
    </div>
  </section>
</template>

<style scoped>
.engagement { display: grid; gap: 13px; }
.section-heading { display: flex; align-items: end; justify-content: space-between; gap: 20px; }.section-heading h2, .section-heading p { margin: 0; }.section-heading h2 { margin-top: 2px; font-family: Georgia, serif; font-size: 1.55rem; font-weight: 500; }.section-heading > p { max-width: 420px; color: var(--ink-soft); font-size: .75rem; line-height: 1.5; text-align: right; }.section-kicker { color: #397a69; font-size: .68rem; font-weight: 900; letter-spacing: .12em; text-transform: uppercase; }
.engagement__grid { display: grid; grid-template-columns: .88fr 1.12fr; gap: 12px; }.activity-card, .cohort-card { padding: 20px; }.activity-card header, .cohort-card header { display: flex; justify-content: space-between; gap: 12px; }.activity-card h3, .activity-card p, .cohort-card h3, .cohort-card p { margin: 0; }.activity-card h3, .cohort-card h3 { font-family: Georgia, serif; font-size: 1.15rem; font-weight: 500; }.activity-card p, .cohort-card p { margin-top: 3px; color: var(--ink-soft); font-size: .7rem; }.activity-card header > span { padding: 7px 9px; border-radius: 10px; background: #e8f4f0; color: #397a69; font-size: .65rem; text-align: center; }.activity-card header > span strong { display: block; font-family: Georgia, serif; font-size: 1.1rem; }
.action-list { display: grid; gap: 13px; margin-top: 22px; }.action-list > div { display: grid; grid-template-columns: 115px 1fr 25px; align-items: center; gap: 8px; }.action-list span, .action-list strong { font-size: .72rem; }.action-list i { height: 7px; overflow: hidden; border-radius: 99px; background: #e9e8e3; }.action-list b { display: block; height: 100%; border-radius: inherit; background: #705e93; }.action-list strong { text-align: right; }
.frequency-strip { display: grid; grid-template-columns: repeat(4, 1fr); gap: 6px; margin-top: 20px; }.frequency-strip > div { padding: 9px 5px; border-radius: 9px; background: #f7f5f0; text-align: center; }.frequency-strip strong, .frequency-strip small { display: block; }.frequency-strip strong { font-family: Georgia, serif; font-size: 1.05rem; }.frequency-strip small { margin-top: 2px; color: var(--ink-soft); font-size: .6rem; }
.cohort-card header > span { align-self: start; color: var(--ink-soft); font-size: .65rem; }.cohort-table { margin-top: 18px; }.cohort-table__head, .cohort-table__row { display: grid; grid-template-columns: 1.25fr .45fr .9fr .9fr; align-items: center; gap: 8px; }.cohort-table__head { padding: 0 8px 8px; color: var(--ink-soft); font-size: .62rem; font-weight: 850; text-transform: uppercase; }.cohort-table__row { min-height: 45px; padding: 8px; border-top: 1px solid var(--line); font-size: .7rem; }.cohort-table__row > strong { font-size: .7rem; }.cohort-table__row > div { display: grid; grid-template-columns: 1fr 25px; align-items: center; gap: 5px; }.cohort-table__row i { height: 5px; overflow: hidden; border-radius: 99px; background: #e9e8e3; }.cohort-table__row b { display: block; height: 100%; border-radius: inherit; background: #397a69; }.cohort-table__row em { color: var(--ink-soft); font-size: .62rem; font-style: normal; text-align: right; }
.section-kicker, .activity-card header > span { color: #2f6b5f; }
@media (max-width: 880px) { .engagement__grid { grid-template-columns: 1fr; } }
@media (max-width: 620px) { .section-heading { align-items: start; flex-direction: column; }.section-heading > p { text-align: left; }.cohort-table__head, .cohort-table__row { grid-template-columns: 1.2fr .4fr .8fr .8fr; }.frequency-strip { grid-template-columns: 1fr 1fr; } }
</style>
