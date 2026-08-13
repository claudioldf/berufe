<script setup lang="ts">
import { computed } from 'vue'
import type { ReportPeriodData } from '~/types'

const props = defineProps<{
  supply: ReportPeriodData['supply']
}>()

const maxStage = computed(() => Math.max(...props.supply.funnel.map(stage => stage.value), 1))

const funnel = computed(() => props.supply.funnel.map((stage, index) => {
  const previous = props.supply.funnel[index - 1]?.value ?? stage.value
  return {
    ...stage,
    width: Math.max((stage.value / maxStage.value) * 100, stage.value ? 8 : 0),
    conversion: previous ? Math.round((stage.value / previous) * 100) : 0
  }
}))

function percent(value: number, total: number) {
  if (!total) return '—'
  return `${Math.round((value / total) * 100)}%`
}
</script>

<template>
  <section class="supply-grid" aria-label="Oferta e ativação profissional">
    <article class="surface-card report-card">
      <header class="report-card__header">
        <div><p class="section-kicker">Oferta</p><h2>Funil de profissionais</h2><span>Onde a rede fundadora está perdendo força.</span></div>
        <div class="goal-chip"><UIcon name="i-lucide-goal" /> Meta {{ supply.targetMinimum }}–{{ supply.targetMaximum }}</div>
      </header>
      <div class="funnel">
        <div v-for="(stage, index) in funnel" :key="stage.key" class="funnel__row">
          <div class="funnel__label"><span>{{ stage.label }}</span><small v-if="stage.description">{{ stage.description }}</small></div>
          <div class="funnel__track"><i :style="{ width: `${stage.width}%` }" /></div>
          <strong>{{ stage.value }}</strong>
          <em v-if="index > 0">{{ stage.conversion }}%</em>
          <em v-else>base</em>
        </div>
      </div>
    </article>

    <article class="surface-card report-card">
      <header class="report-card__header">
        <div><p class="section-kicker">Credibilidade</p><h2>Qualidade da oferta</h2><span>Critérios transparentes, sem nota de confiança opaca.</span></div>
      </header>
      <div class="activation-list">
        <div v-for="metric in supply.activation" :key="metric.key" class="activation-item">
          <span class="activation-item__icon"><UIcon :name="metric.icon" /></span>
          <div>
            <div class="activation-item__title"><strong>{{ metric.label }}</strong><b>{{ metric.value }}/{{ metric.total }}</b></div>
            <div class="activation-item__track"><i :style="{ width: percent(metric.value, metric.total) }" /></div>
            <small>{{ metric.description }} · {{ percent(metric.value, metric.total) }}</small>
          </div>
        </div>
      </div>
      <aside class="activation-note">
        <UIcon name="i-lucide-lightbulb" />
        <p><strong>Ativação significa evidência real.</strong> Identidade aprovada, três trabalhos e duas relações confirmadas.</p>
      </aside>
    </article>
  </section>
</template>

<style scoped>
.supply-grid { display: grid; grid-template-columns: 1.08fr .92fr; gap: 12px; }
.report-card { padding: 20px; }
.report-card__header { display: flex; align-items: start; justify-content: space-between; gap: 14px; }
.report-card__header h2, .report-card__header p, .report-card__header span { margin: 0; }
.report-card__header h2 { margin-top: 2px; font-family: Georgia, serif; font-size: 1.35rem; font-weight: 500; }
.report-card__header span { display: block; margin-top: 4px; color: var(--ink-soft); font-size: var(--font-size-min); }
.section-kicker { color: #397a69; font-size: var(--font-size-min); font-weight: 900; letter-spacing: .12em; text-transform: uppercase; }
.goal-chip { display: flex; align-items: center; gap: 5px; padding: 7px 9px; border-radius: 9px; background: #e8f4f0; color: #397a69; font-size: var(--font-size-min); font-weight: 850; white-space: nowrap; }
.funnel { display: grid; gap: 12px; margin-top: 23px; }
.funnel__row { display: grid; grid-template-columns: 128px minmax(80px, 1fr) 28px 38px; align-items: center; gap: 8px; }
.funnel__label span, .funnel__label small { display: block; }
.funnel__label span { font-size: var(--font-size-min); font-weight: 750; }
.funnel__label small { overflow: hidden; margin-top: 2px; color: var(--ink-soft); font-size: var(--font-size-min); text-overflow: ellipsis; white-space: nowrap; }
.funnel__track { height: 9px; overflow: hidden; border-radius: 99px; background: #e9e8e3; }
.funnel__track i { display: block; height: 100%; border-radius: inherit; background: linear-gradient(90deg, #397a69, #74aa9c); }
.funnel__row strong { font-size: var(--font-size-min); text-align: right; }
.funnel__row em { color: var(--ink-soft); font-size: var(--font-size-min); font-style: normal; text-align: right; }
.activation-list { display: grid; gap: 15px; margin-top: 22px; }
.activation-item { display: grid; grid-template-columns: auto 1fr; gap: 10px; align-items: start; }
.activation-item__icon { display: grid; place-items: center; width: 34px; height: 34px; border-radius: 10px; background: #f0eee8; color: #397a69; }
.activation-item__title { display: flex; justify-content: space-between; gap: 10px; }
.activation-item__title strong, .activation-item__title b { font-size: var(--font-size-min); }
.activation-item__track { height: 6px; margin-top: 7px; overflow: hidden; border-radius: 99px; background: #e9e8e3; }
.activation-item__track i { display: block; height: 100%; border-radius: inherit; background: #397a69; }
.activation-item small { display: block; margin-top: 4px; color: var(--ink-soft); font-size: var(--font-size-min); }
.activation-note { display: grid; grid-template-columns: auto 1fr; gap: 8px; margin-top: 18px; padding: 11px; border-radius: 11px; background: #fff7de; color: #85661a; }
.activation-note p { margin: 0; color: var(--ink-soft); font-size: var(--font-size-min); line-height: 1.45; }.activation-note strong { color: #85661a; }
@media (max-width: 850px) { .supply-grid { grid-template-columns: 1fr; } }
@media (max-width: 520px) { .funnel__row { grid-template-columns: 105px minmax(55px, 1fr) 24px; }.funnel__row em { display: none; }.goal-chip { display: none; } }
</style>
