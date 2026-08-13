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
        <header>
          <div><h3>Ações significativas</h3><p>{{ engagement.meaningfulActives }}/{{ engagement.eligibleProfessionals }} profissionais ativos no período</p></div>
          <div class="widget-actions">
            <span class="returning-chip"><strong>{{ engagement.returningProfessionals }}</strong> recorrentes</span>
            <AdminReportsMetricHelp
              title="Ações significativas"
              meaning="Conta profissionais distintos que realizaram ações que aumentam o valor da rede: atualizar perfil, criar evidência, interagir com relações ou gerar orçamento."
              goal="Aumentar profissionais ativos e recorrentes, além da quantidade de semanas em que cada um gera valor."
              reading="Uma pessoa pode realizar mais de um tipo de ação, então as barras não devem ser somadas. Login sem ação útil não entra nesta métrica."
            />
          </div>
        </header>
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
        <header>
          <div><h3>Coortes de publicação</h3><p>Retorno após o perfil entrar no ar</p></div>
          <div class="widget-actions">
            <span class="sample-note">n pequeno: exibimos n/N</span>
            <AdminReportsMetricHelp
              title="Coortes de retenção W1/W4"
              meaning="Agrupa profissionais pela semana em que o perfil foi publicado e mostra quantos voltaram com uma ação útil após uma e quatro semanas."
              goal="Melhorar a retenção W1 e, principalmente, W4 à medida que os fluxos de confiança e orçamento se tornam hábitos."
              reading="“—” significa que a coorte ainda não teve tempo de chegar à semana medida. Com poucos profissionais, compare n/N, não apenas percentuais."
            />
          </div>
        </header>
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
.section-heading { display: flex; align-items: end; justify-content: space-between; gap: 20px; }.section-heading h2, .section-heading p { margin: 0; }.section-heading h2 { margin-top: 2px; font-family: Georgia, serif; font-size: 1.55rem; font-weight: 500; }.section-heading > p { max-width: 420px; color: var(--ink-soft); font-size: var(--font-size-min); line-height: 1.5; text-align: right; }.section-kicker { color: #397a69; font-size: var(--font-size-min); font-weight: 900; letter-spacing: .12em; text-transform: uppercase; }
.engagement__grid { display: grid; grid-template-columns: .88fr 1.12fr; gap: 12px; }.activity-card, .cohort-card { padding: 20px; }.activity-card header, .cohort-card header { display: flex; justify-content: space-between; gap: 12px; }.activity-card h3, .activity-card p, .cohort-card h3, .cohort-card p { margin: 0; }.activity-card h3, .cohort-card h3 { font-family: Georgia, serif; font-size: 1.15rem; font-weight: 500; }.activity-card p, .cohort-card p { margin-top: 3px; color: var(--ink-soft); font-size: var(--font-size-min); }.activity-card header > span { padding: 7px 9px; border-radius: 10px; background: #e8f4f0; color: #397a69; font-size: var(--font-size-min); text-align: center; }.activity-card header > span strong { display: block; font-family: Georgia, serif; font-size: 1.1rem; }
.action-list { display: grid; gap: 13px; margin-top: 22px; }.action-list > div { display: grid; grid-template-columns: 115px 1fr 25px; align-items: center; gap: 8px; }.action-list span, .action-list strong { font-size: var(--font-size-min); }.action-list i { height: 7px; overflow: hidden; border-radius: 99px; background: #e9e8e3; }.action-list b { display: block; height: 100%; border-radius: inherit; background: #705e93; }.action-list strong { text-align: right; }
.frequency-strip { display: grid; grid-template-columns: repeat(4, 1fr); gap: 6px; margin-top: 20px; }.frequency-strip > div { padding: 9px 5px; border-radius: 9px; background: #f7f5f0; text-align: center; }.frequency-strip strong, .frequency-strip small { display: block; }.frequency-strip strong { font-family: Georgia, serif; font-size: 1.05rem; }.frequency-strip small { margin-top: 2px; color: var(--ink-soft); font-size: var(--font-size-min); }
.cohort-card header > span { align-self: start; color: var(--ink-soft); font-size: var(--font-size-min); }.cohort-table { margin-top: 18px; }.cohort-table__head, .cohort-table__row { display: grid; grid-template-columns: 1.25fr .45fr .9fr .9fr; align-items: center; gap: 8px; }.cohort-table__head { padding: 0 8px 8px; color: var(--ink-soft); font-size: var(--font-size-min); font-weight: 850; text-transform: uppercase; }.cohort-table__row { min-height: 45px; padding: 8px; border-top: 1px solid var(--line); font-size: var(--font-size-min); }.cohort-table__row > strong { font-size: var(--font-size-min); }.cohort-table__row > div { display: grid; grid-template-columns: 1fr 25px; align-items: center; gap: 5px; }.cohort-table__row i { height: 5px; overflow: hidden; border-radius: 99px; background: #e9e8e3; }.cohort-table__row b { display: block; height: 100%; border-radius: inherit; background: #397a69; }.cohort-table__row em { color: var(--ink-soft); font-size: var(--font-size-min); font-style: normal; text-align: right; }
.section-kicker, .activity-card header > span { color: #2f6b5f; }
.widget-actions { display: flex; align-items: start; justify-content: flex-end; gap: 7px; }.returning-chip { padding: 7px 9px; border-radius: 10px; background: #e8f4f0; color: #2f6b5f; font-size: var(--font-size-min); text-align: center; }.returning-chip strong { display: block; font-family: Georgia, serif; font-size: 1.1rem; }.sample-note { align-self: center; color: var(--ink-soft); font-size: var(--font-size-min); }
@media (max-width: 880px) { .engagement__grid { grid-template-columns: 1fr; } }
@media (max-width: 620px) { .section-heading { align-items: start; flex-direction: column; }.section-heading > p { text-align: left; }.cohort-table__head, .cohort-table__row { grid-template-columns: 1.2fr .4fr .8fr .8fr; }.frequency-strip { grid-template-columns: 1fr 1fr; } }
</style>
