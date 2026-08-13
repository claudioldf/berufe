<script setup lang="ts">
import { computed } from 'vue'
import type { ReportPeriodData } from '~/types'

const props = defineProps<{
  discovery: ReportPeriodData['discovery']
}>()

const discoveryStages = computed(() => [
  { key: 'searches', label: 'Buscas realizadas', value: props.discovery.searches, total: props.discovery.searches },
  { key: 'results', label: 'Com algum resultado', value: props.discovery.searchesWithResults, total: props.discovery.searches },
  { key: 'choice', label: 'Com 3+ opções', value: props.discovery.searchesWithThreeResults, total: props.discovery.searches },
  { key: 'open', label: 'Com perfil aberto', value: props.discovery.searchesWithProfileOpen, total: props.discovery.searches },
  { key: 'handoff', label: 'Contato iniciado', value: props.discovery.whatsappHandoffs, total: props.discovery.searches }
])

const maxDemand = computed(() => Math.max(...props.discovery.demand.map(item => item.value), 1))

function percent(value: number, total: number) {
  if (!total) return '—'
  return `${new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 1 }).format((value / total) * 100)}%`
}
</script>

<template>
  <section class="discovery" aria-labelledby="discovery-title">
    <header class="section-heading">
      <div><p class="section-kicker">Demanda e liquidez</p><h2 id="discovery-title">Da busca ao contato</h2></div>
      <p>Um contato é um clique deduplicado no WhatsApp — não significa contratação.</p>
    </header>

    <div class="discovery__grid">
      <article class="surface-card discovery-funnel">
        <header class="widget-heading">
          <div><h3>Cobertura da jornada</h3><p>Progressão desde a busca</p></div>
          <AdminReportsMetricHelp
            title="Cobertura da jornada"
            meaning="Mostra quantas buscas tiveram resultado, variedade, abertura de perfil e tentativa de contato. Cada etapa é comparada ao total de buscas."
            goal="Aumentar a progressão em todas as etapas: cobrir a demanda, oferecer escolha, despertar interesse e facilitar o contato."
            reading="A maior queda indica o problema principal. Falha no início sugere falta de oferta; queda após resultados sugere relevância ou qualidade dos perfis."
          />
        </header>
        <div v-for="(stage, index) in discoveryStages" :key="stage.key" class="discovery-stage">
          <div class="discovery-stage__top"><span>{{ stage.label }}</span><strong>{{ stage.value }}</strong></div>
          <div class="discovery-stage__bar"><i :style="{ width: percent(stage.value, stage.total) }" /></div>
          <small v-if="index > 0">{{ percent(stage.value, stage.total) }} das buscas</small>
          <small v-else>base do período</small>
        </div>
      </article>

      <article class="surface-card demand-card">
        <header>
          <div><h3>Demanda por serviço</h3><p>Buscas agregadas</p></div>
          <div class="widget-actions">
            <UIcon name="i-lucide-chart-no-axes-column-increasing" />
            <AdminReportsMetricHelp
              title="Demanda por serviço"
              meaning="Ordena os serviços pelo número de buscas realizadas no período, sem identificar quem pesquisou."
              goal="Usar a demanda real para priorizar recrutamento, cobertura territorial e conteúdo dos perfis."
              reading="Volume de busca não é conversão. Compare cada serviço com cobertura, opções disponíveis e contatos iniciados antes de investir na oferta."
            />
          </div>
        </header>
        <div class="demand-bars">
          <div v-for="item in discovery.demand" :key="item.label">
            <span>{{ item.label }}</span>
            <i><b :style="{ width: `${(item.value / maxDemand) * 100}%` }" /></i>
            <strong>{{ item.value }}</strong>
          </div>
        </div>
      </article>

      <article class="surface-card gaps-card">
        <header>
          <div><h3>Gaps que bloqueiam crescimento</h3><p>Buscas com pouca ou nenhuma oferta</p></div>
          <div class="widget-actions">
            <span>Priorizar rede</span>
            <AdminReportsMetricHelp
              title="Gaps de oferta"
              meaning="Destaca combinações de serviço e região que receberam buscas, mas têm zero ou poucos profissionais disponíveis."
              goal="Eliminar primeiro os gaps repetidos de serviços ativos; demandas fora do MVP devem ser avaliadas antes de ampliar o catálogo."
              reading="“Recrutar” indica falta de profissionais no catálogo atual. “Avaliar catálogo” indica uma demanda ainda não assumida pelo MVP."
            />
          </div>
        </header>
        <div class="gaps-list">
          <div v-for="gap in discovery.gaps" :key="`${gap.service}-${gap.location}`">
            <span :class="{ 'gaps-list__icon--catalog': gap.catalogStatus === 'outside_mvp' }"><UIcon :name="gap.catalogStatus === 'outside_mvp' ? 'i-lucide-list-plus' : 'i-lucide-map-pin'" /></span>
            <div><strong>{{ gap.service }} · {{ gap.location }}</strong><small>{{ gap.searches }} buscas · {{ gap.professionals }} {{ gap.professionals === 1 ? 'profissional' : 'profissionais' }}</small></div>
            <em>{{ gap.catalogStatus === 'outside_mvp' ? 'Avaliar catálogo' : 'Recrutar' }}</em>
          </div>
        </div>
      </article>
    </div>
  </section>
</template>

<style scoped>
.discovery { display: grid; gap: 13px; }
.section-heading { display: flex; align-items: end; justify-content: space-between; gap: 20px; }
.section-heading h2, .section-heading p { margin: 0; }.section-heading h2 { margin-top: 2px; font-family: Georgia, serif; font-size: 1.55rem; font-weight: 500; }.section-heading > p { max-width: 390px; color: var(--ink-soft); font-size: var(--font-size-min); line-height: 1.5; text-align: right; }
.section-kicker { color: #397a69; font-size: var(--font-size-min); font-weight: 900; letter-spacing: .12em; text-transform: uppercase; }
.discovery__grid { display: grid; grid-template-columns: .9fr 1.1fr; gap: 12px; }
.discovery-funnel { display: grid; gap: 14px; padding: 20px; }
.discovery-stage__top { display: flex; justify-content: space-between; gap: 10px; }.discovery-stage__top span, .discovery-stage__top strong { font-size: var(--font-size-min); }.discovery-stage__bar { height: 8px; margin-top: 6px; overflow: hidden; border-radius: 99px; background: #e9e8e3; }.discovery-stage__bar i { display: block; height: 100%; border-radius: inherit; background: linear-gradient(90deg, #f8755d, #f4a18f); }.discovery-stage small { display: block; margin-top: 3px; color: var(--ink-soft); font-size: var(--font-size-min); }
.demand-card, .gaps-card { padding: 20px; }.demand-card header, .gaps-card header { display: flex; justify-content: space-between; gap: 12px; }.demand-card h3, .demand-card p, .gaps-card h3, .gaps-card p { margin: 0; }.demand-card h3, .gaps-card h3 { font-family: Georgia, serif; font-size: 1.15rem; font-weight: 500; }.demand-card p, .gaps-card p { margin-top: 3px; color: var(--ink-soft); font-size: var(--font-size-min); }.demand-card header > svg { color: #397a69; font-size: 1.2rem; }
.demand-bars { display: grid; gap: 13px; margin-top: 23px; }.demand-bars > div { display: grid; grid-template-columns: 110px 1fr 28px; align-items: center; gap: 8px; }.demand-bars span, .demand-bars strong { font-size: var(--font-size-min); }.demand-bars i { height: 7px; overflow: hidden; border-radius: 99px; background: #e9e8e3; }.demand-bars b { display: block; height: 100%; border-radius: inherit; background: #397a69; }.demand-bars strong { text-align: right; }
.gaps-card { grid-column: 1 / -1; }.gaps-card header > span { align-self: start; padding: 6px 8px; border-radius: 8px; background: #fff0ec; color: #b9533e; font-size: var(--font-size-min); font-weight: 850; }.gaps-list { display: grid; grid-template-columns: repeat(3, 1fr); gap: 9px; margin-top: 17px; }.gaps-list > div { display: grid; grid-template-columns: auto 1fr; gap: 9px; padding: 12px; border-radius: 12px; background: #f7f5f0; }.gaps-list > div > span { display: grid; place-items: center; width: 32px; height: 32px; border-radius: 9px; background: #fff0ec; color: #b9533e; }.gaps-list > div > .gaps-list__icon--catalog { background: #fff7de; color: #8a6918; }.gaps-list strong, .gaps-list small { display: block; }.gaps-list strong { font-size: var(--font-size-min); line-height: 1.35; }.gaps-list small { margin-top: 3px; color: var(--ink-soft); font-size: var(--font-size-min); }.gaps-list em { grid-column: 2; color: #397a69; font-size: var(--font-size-min); font-style: normal; font-weight: 850; }
.section-kicker { color: #2f6b5f; }.gaps-card header > span, .gaps-list > div > span { color: #a94734; }
.widget-heading, .widget-actions { display: flex; align-items: start; justify-content: space-between; gap: 8px; }.widget-heading h3, .widget-heading p { margin: 0; }.widget-heading h3 { font-family: Georgia, serif; font-size: 1.15rem; font-weight: 500; }.widget-heading p { margin-top: 3px; color: var(--ink-soft); font-size: var(--font-size-min); }.widget-actions { align-items: center; justify-content: flex-end; }.demand-card .widget-actions > svg { color: #397a69; font-size: 1.2rem; }.gaps-card .widget-actions > span { align-self: start; padding: 6px 8px; border-radius: 8px; background: #fff0ec; color: #a94734; font-size: var(--font-size-min); font-weight: 850; }
@media (max-width: 800px) { .discovery__grid { grid-template-columns: 1fr; }.gaps-card { grid-column: auto; }.gaps-list { grid-template-columns: 1fr; } }
@media (max-width: 620px) { .section-heading { align-items: start; flex-direction: column; }.section-heading > p { text-align: left; } }
</style>
