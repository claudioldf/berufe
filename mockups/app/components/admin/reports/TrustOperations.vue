<script setup lang="ts">
import { computed } from 'vue'
import type { ReportPeriodData } from '~/types'

const props = defineProps<{
  trust: ReportPeriodData['trust']
  quotes: ReportPeriodData['quotes']
  operations: ReportPeriodData['operations']
}>()

const quoteShareRate = computed(() => props.quotes.created ? Math.round((props.quotes.shared / props.quotes.created) * 100) : 0)
const approvalRate = computed(() => props.operations.reviewed ? Math.round(((props.operations.reviewed - props.operations.rejected) / props.operations.reviewed) * 100) : 0)

function percent(value: number, total: number) {
  if (!total) return '—'
  return `${Math.round((value / total) * 100)}%`
}
</script>

<template>
  <section class="trust-ops" aria-label="Rede, orçamentos e operação">
    <DesignSystemSurfaceCard as="article" class="network-card">
      <header>
        <div><DesignSystemKicker>Efeito de rede</DesignSystemKicker><h2>Confiança e convites</h2><span>Conclusão dos pedidos que fortalecem cada perfil.</span></div>
        <AdminReportsMetricHelp
          title="Confiança e convites"
          meaning="Acompanha pedidos de recomendação, relações profissionais e convites desde a criação até a conclusão e aprovação."
          goal="Aumentar a conclusão de pedidos legítimos e transformar conexões reais em evidências de confiança para mais perfis."
          reading="Baixa conclusão pede lembretes ou um fluxo mais simples. Aprovação não deve ser maximizada a qualquer custo: moderação continua protegendo a autenticidade."
        />
      </header>
      <div class="network-list">
        <div v-for="funnel in trust.funnels" :key="funnel.key">
          <strong>{{ funnel.label }}</strong>
          <div class="network-values"><span><b>{{ funnel.started }}</b><small>iniciados</small></span><UIcon name="i-lucide-arrow-right" /><span><b>{{ funnel.completed }}</b><small>concluídos</small></span><UIcon name="i-lucide-arrow-right" /><span><b>{{ funnel.approved }}</b><small>aprovados</small></span></div>
          <p>{{ percent(funnel.completed, funnel.started) }} de conclusão · {{ percent(funnel.approved, funnel.completed) }} aprovados</p>
        </div>
      </div>
    </DesignSystemSurfaceCard>

    <DesignSystemSurfaceCard as="article" class="quote-card">
      <header>
        <div><DesignSystemKicker>Utilidade recorrente</DesignSystemKicker><h2>Orçamentos</h2><span>Uso que pode trazer o profissional de volta.</span></div>
        <div class="widget-actions">
          <span class="rate-chip">{{ quoteShareRate }}% compartilhados</span>
          <AdminReportsMetricHelp
            title="Uso de orçamentos"
            meaning="Mostra orçamentos criados e compartilhados, quantos profissionais distintos usaram a ferramenta e quantos voltaram a usá-la."
            goal="Aumentar criadores únicos, compartilhamentos e uso recorrente, validando uma utilidade semanal além da descoberta pública."
            reading="Taxa de compartilhamento baixa pode indicar rascunhos abandonados ou dificuldade no fluxo. A Berufe não interpreta compartilhamento como aceite ou pagamento."
          />
        </div>
      </header>
      <div class="quote-numbers">
        <div><strong>{{ quotes.created }}</strong><small>criados</small></div>
        <UIcon name="i-lucide-arrow-right" />
        <div><strong>{{ quotes.shared }}</strong><small>compartilhados</small></div>
      </div>
      <div class="quote-people"><div><UIcon name="i-lucide-user-round-check" /><span><strong>{{ quotes.uniqueCreators }}</strong><small>criadores únicos</small></span></div><div><UIcon name="i-lucide-repeat-2" /><span><strong>{{ quotes.repeatCreators }}</strong><small>criadores recorrentes</small></span></div></div>
    </DesignSystemSurfaceCard>

    <DesignSystemSurfaceCard as="article" class="ops-card">
      <header>
        <div><DesignSystemKicker>Velocidade operacional</DesignSystemKicker><h2>Saúde da moderação</h2></div>
        <div class="widget-actions">
          <span :class="['pending-chip', { 'pending-chip--alert': operations.oldestPendingHours > 24 }]"><DesignSystemStatusDot :tone="operations.oldestPendingHours > 24 ? 'warning' : 'success'" />{{ operations.pending }} pendentes</span>
          <AdminReportsMetricHelp
            title="Saúde da moderação"
            meaning="Monitora tamanho e idade da fila, tempo mediano, P90 de análise, aprovação e ocorrências de conteúdo oculto ou reportado."
            goal="Evitar itens acima de 24 horas, reduzir mediana e P90 sem enfraquecer a revisão de identidade e evidências."
            reading="P90 revela os casos lentos que a mediana esconde. Rejeição não é uma falha a zerar; mudanças bruscas podem indicar baixa qualidade de envio ou critérios confusos."
          />
        </div>
      </header>
      <div class="ops-grid">
        <div><span>Mais antigo</span><strong>{{ operations.oldestPendingHours }}h</strong><small>atenção acima de 24h</small></div>
        <div><span>Tempo mediano</span><strong>{{ operations.medianReviewHours }}h</strong><small>até a decisão</small></div>
        <div><span>P90 de análise</span><strong>{{ operations.p90ReviewHours }}h</strong><small>90% abaixo disso</small></div>
        <div><span>Aprovação</span><strong>{{ approvalRate }}%</strong><small>{{ operations.rejected }}/{{ operations.reviewed }} recusados</small></div>
      </div>
      <footer><UIcon name="i-lucide-shield-alert" /><span>{{ operations.hiddenOrReported }} conteúdo(s) oculto(s) ou reportado(s) no período.</span></footer>
    </DesignSystemSurfaceCard>
  </section>
</template>

<style scoped>
.trust-ops { display: grid; grid-template-columns: 1.2fr .8fr; gap: 12px; }.network-card, .quote-card, .ops-card { padding: 20px; }.network-card header h2, .network-card header p, .network-card header span, .quote-card header h2, .quote-card header p, .quote-card header span, .ops-card header h2, .ops-card header p { margin: 0; }.network-card h2, .quote-card h2, .ops-card h2 { margin-top: 2px !important; font-family: Georgia, serif; font-size: 1.25rem; font-weight: 500; }.network-card header span, .quote-card header div > span { display: block; margin-top: 4px; color: var(--ink-soft); font-size: var(--font-size-min); }
.network-list { display: grid; gap: 8px; margin-top: 17px; }.network-list > div { padding: 12px; border-radius: 12px; background: #f7f5f0; }.network-list > div > strong { font-size: var(--font-size-min); }.network-values { display: grid; grid-template-columns: 1fr auto 1fr auto 1fr; align-items: center; gap: 8px; margin-top: 9px; }.network-values > span { display: flex; align-items: baseline; gap: 4px; }.network-values b { font-family: Georgia, serif; font-size: 1rem; }.network-values small { color: var(--ink-soft); font-size: var(--font-size-min); }.network-values > svg { color: #a1aaa6; font-size: var(--font-size-min); }.network-list p { margin: 7px 0 0; color: #397a69; font-size: var(--font-size-min); font-weight: 800; }
.quote-card header, .ops-card header { display: flex; justify-content: space-between; gap: 10px; }.rate-chip { align-self: start; padding: 6px 8px; border-radius: 8px; background: #e8f4f0; color: #397a69; font-size: var(--font-size-min); font-weight: 850; white-space: nowrap; }.quote-numbers { display: grid; grid-template-columns: 1fr auto 1fr; align-items: center; gap: 10px; margin-top: 26px; }.quote-numbers > div { padding: 13px; border-radius: 12px; background: #f7f5f0; text-align: center; }.quote-numbers strong, .quote-numbers small { display: block; }.quote-numbers strong { font-family: Georgia, serif; font-size: 1.6rem; }.quote-numbers small { color: var(--ink-soft); font-size: var(--font-size-min); }.quote-numbers > svg { color: #397a69; }.quote-people { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-top: 10px; }.quote-people > div { display: flex; align-items: center; gap: 8px; padding: 10px; border: 1px solid var(--line); border-radius: 11px; }.quote-people svg { color: #705e93; }.quote-people strong, .quote-people small { display: block; }.quote-people strong { font-size: var(--font-size-min); }.quote-people small { color: var(--ink-soft); font-size: var(--font-size-min); }
.ops-card { grid-column: 1 / -1; }.ops-card header > span { display: flex; align-items: center; gap: 6px; align-self: start; padding: 6px 9px; border-radius: 9px; background: #e8f4f0; color: #397a69; font-size: var(--font-size-min); font-weight: 850; }.ops-card header > .ops-card__alert { background: #fff2cf; color: #8d6813; }.ops-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 9px; margin-top: 17px; }.ops-grid > div { padding: 13px; border-radius: 11px; background: #f7f5f0; }.ops-grid span, .ops-grid strong, .ops-grid small { display: block; }.ops-grid span { color: var(--ink-soft); font-size: var(--font-size-min); }.ops-grid strong { margin-top: 6px; font-family: Georgia, serif; font-size: 1.35rem; }.ops-grid small { margin-top: 2px; color: var(--ink-soft); font-size: var(--font-size-min); }.ops-card footer { display: flex; align-items: center; gap: 7px; margin-top: 12px; color: var(--ink-soft); font-size: var(--font-size-min); }.ops-card footer svg { color: #b9533e; }
.rate-chip { color: #2f6b5f; }
.network-card header, .widget-actions { display: flex; align-items: start; justify-content: space-between; gap: 8px; }.widget-actions { align-items: center; justify-content: flex-end; }.pending-chip { display: flex; align-items: center; gap: 6px; padding: 6px 9px; border-radius: 9px; background: #e8f4f0; color: #2f6b5f; font-size: var(--font-size-min); font-weight: 850; white-space: nowrap; }.pending-chip--alert { background: #fff2cf; color: #806014; }
@media (max-width: 850px) { .trust-ops { grid-template-columns: 1fr; }.ops-card { grid-column: auto; } }
@media (max-width: 540px) { .ops-grid { grid-template-columns: 1fr 1fr; }.network-values small { display: none; } }
</style>
