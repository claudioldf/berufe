<script setup lang="ts">
import { computed, type DeepReadonly } from "vue";
import type { ReportPeriodData } from "~/types";
import { formatRate } from "~/utils/formatters";

const props = defineProps<{
  trust: DeepReadonly<ReportPeriodData["trust"]>;
  quotes: DeepReadonly<ReportPeriodData["quotes"]>;
  operations: DeepReadonly<ReportPeriodData["operations"]>;
}>();

const oldestPendingExceedsTarget = computed(
  () =>
    props.operations.oldestPendingHours >
    props.operations.oldestPendingTargetHours,
);
</script>

<template>
  <section class="trust-ops" aria-label="Rede, orçamentos e operação">
    <DesignSystemSurfaceCard as="article" class="network-card">
      <header>
        <div>
          <DesignSystemKicker>Efeito de rede</DesignSystemKicker>
          <h2>Relações profissionais</h2>
          <span>Confirmações entre membros que fortalecem cada perfil.</span>
        </div>
        <AdminReportsMetricHelp
          title="Relações profissionais"
          meaning="Acompanha relações iniciadas no período até a resposta e a confirmação do destinatário."
          goal="Transformar conexões reais entre membros existentes em evidências públicas de confiança."
          reading="Baixa resposta pode indicar atrito. A taxa de aprovação mostra quantos destinatários confirmaram a relação solicitada."
        />
      </header>
      <div class="network-list">
        <div v-for="funnel in trust.funnels" :key="funnel.key">
          <strong>{{ funnel.label }}</strong>
          <div class="network-values">
            <span
              ><b>{{ funnel.started }}</b
              ><small>iniciadas</small></span
            >
            <UIcon name="i-lucide-arrow-right" />
            <span
              ><b>{{ funnel.responded }}</b
              ><small>respondidas</small></span
            >
            <UIcon name="i-lucide-arrow-right" />
            <span
              ><b>{{ funnel.approved }}</b
              ><small>aprovadas</small></span
            >
          </div>
          <p>
            {{ formatRate(funnel.responseRate.rate, 0) }} de resposta ·
            {{ formatRate(funnel.approvalRate.rate, 0) }} aprovadas
          </p>
        </div>
      </div>
    </DesignSystemSurfaceCard>

    <DesignSystemSurfaceCard as="article" class="quote-card">
      <header>
        <div>
          <DesignSystemKicker>Utilidade recorrente</DesignSystemKicker>
          <h2>Orçamentos</h2>
          <span>Uso que pode trazer o profissional de volta.</span>
        </div>
        <div class="widget-actions">
          <span class="rate-chip"
            >{{ formatRate(quotes.shareRate.rate, 0) }} compartilhados</span
          >
          <AdminReportsMetricHelp
            title="Uso de orçamentos"
            meaning="Mostra orçamentos criados e compartilhados, criadores distintos e quem usou a ferramenta mais de uma vez."
            goal="Aumentar criadores únicos, compartilhamentos e uso recorrente."
            reading="Compartilhamento baixo pode indicar rascunhos abandonados. Compartilhar não significa aceite ou pagamento."
          />
        </div>
      </header>
      <div class="quote-numbers">
        <div>
          <strong>{{ quotes.created }}</strong
          ><small>criados</small>
        </div>
        <UIcon name="i-lucide-arrow-right" />
        <div>
          <strong>{{ quotes.shared }}</strong
          ><small>compartilhados</small>
        </div>
      </div>
      <div class="quote-people">
        <div>
          <UIcon name="i-lucide-user-round-check" />
          <span
            ><strong>{{ quotes.uniqueCreators }}</strong
            ><small>criadores únicos</small></span
          >
        </div>
        <div>
          <UIcon name="i-lucide-repeat-2" />
          <span
            ><strong>{{ quotes.repeatCreators }}</strong
            ><small>2+ no período</small></span
          >
        </div>
      </div>
    </DesignSystemSurfaceCard>

    <DesignSystemSurfaceCard as="article" class="ops-card">
      <header>
        <div>
          <DesignSystemKicker>Velocidade operacional</DesignSystemKicker>
          <h2>Saúde da moderação</h2>
        </div>
        <div class="widget-actions">
          <span
            :class="[
              'pending-chip',
              { 'pending-chip--alert': oldestPendingExceedsTarget },
            ]"
          >
            <DesignSystemStatusDot
              :tone="oldestPendingExceedsTarget ? 'warning' : 'success'"
            />{{ operations.pending }} pendentes
          </span>
          <AdminReportsMetricHelp
            title="Saúde da moderação"
            meaning="Monitora tamanho e idade da fila, mediana, P90 de análise, aprovação e conteúdo ocultado."
            :goal="`Evitar itens acima de ${operations.oldestPendingTargetHours} horas e reduzir tempos sem enfraquecer a revisão.`"
            reading="P90 revela casos lentos. Rejeição não é uma falha a zerar; pode ser uma proteção necessária."
          />
        </div>
      </header>
      <div class="ops-grid">
        <div>
          <span>Mais antigo</span
          ><strong>{{ operations.oldestPendingHours }}h</strong
          ><small
            >atenção acima de {{ operations.oldestPendingTargetHours }}h</small
          >
        </div>
        <div>
          <span>Tempo mediano</span
          ><strong>{{ operations.medianReviewHours }}h</strong
          ><small>até a decisão</small>
        </div>
        <div>
          <span>P90 de análise</span
          ><strong>{{ operations.p90ReviewHours }}h</strong
          ><small>90% abaixo disso</small>
        </div>
        <div>
          <span>Aprovação</span
          ><strong>{{ formatRate(operations.approvalRate.rate, 0) }}</strong
          ><small
            >{{ operations.rejected }}/{{
              operations.reviewed
            }}
            recusados</small
          >
        </div>
      </div>
      <footer>
        <UIcon name="i-lucide-shield-alert" />
        <span>{{ operations.hidden }} conteúdo(s) ocultado(s) no período.</span>
      </footer>
    </DesignSystemSurfaceCard>
  </section>
</template>

<style scoped lang="scss">
.trust-ops {
  display: grid;
  grid-template-columns: 1.2fr 0.8fr;
  gap: 12px;
}
.network-card,
.quote-card,
.ops-card {
  padding: 20px;
}
.network-card header,
.quote-card header,
.ops-card header,
.widget-actions {
  display: flex;
  align-items: start;
  justify-content: space-between;
  gap: 8px;
}
.network-card h2,
.quote-card h2,
.ops-card h2 {
  margin: 2px 0 0;
  font-family: var(--font-display);
  font-size: 1.25rem;
  font-weight: 500;
}
.network-card header span,
.quote-card header div > span {
  display: block;
  margin-top: 4px;
  color: var(--ink-soft);
  font-size: var(--font-size-min);
}
.network-list {
  display: grid;
  gap: 8px;
  margin-top: 17px;
}
.network-list > div {
  padding: 12px;
  border-radius: 12px;
  background: var(--color-surface-neutral);
}
.network-list > div > strong,
.network-list p,
.network-values small {
  font-size: var(--font-size-min);
}
.network-values {
  display: grid;
  grid-template-columns: 1fr auto 1fr auto 1fr;
  align-items: center;
  gap: 8px;
  margin-top: 9px;
}
.network-values > span {
  display: flex;
  align-items: baseline;
  gap: 4px;
}
.network-values b {
  font-family: var(--font-display);
  font-size: 1rem;
}
.network-values small {
  color: var(--ink-soft);
}
.network-values > svg {
  color: #a1aaa6;
  font-size: var(--font-size-min);
}
.network-list p {
  margin: 7px 0 0;
  color: var(--color-brand);
  font-weight: 800;
}
.widget-actions {
  align-items: center;
  justify-content: flex-end;
}
.rate-chip,
.pending-chip {
  padding: 6px 8px;
  border-radius: 8px;
  background: var(--color-brand-tint);
  color: var(--color-success);
  font-size: var(--font-size-min);
  font-weight: 850;
  white-space: nowrap;
}
.quote-numbers {
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  align-items: center;
  gap: 10px;
  margin-top: 26px;
}
.quote-numbers > div {
  padding: 13px;
  border-radius: 12px;
  background: var(--color-surface-neutral);
  text-align: center;
}
.quote-numbers strong,
.quote-numbers small,
.quote-people strong,
.quote-people small {
  display: block;
}
.quote-numbers strong {
  font-family: var(--font-display);
  font-size: 1.6rem;
}
.quote-numbers small,
.quote-people small {
  color: var(--ink-soft);
  font-size: var(--font-size-min);
}
.quote-numbers > svg {
  color: var(--color-brand);
}
.quote-people {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
  margin-top: 10px;
}
.quote-people > div {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px;
  border: 1px solid var(--line);
  border-radius: 11px;
}
.quote-people svg {
  color: #705e93;
}
.quote-people strong {
  font-size: var(--font-size-min);
}
.ops-card {
  grid-column: 1 / -1;
}
.pending-chip {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 9px;
  &--alert {
    background: #fff2cf;
    color: #806014;
  }
}
.ops-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 9px;
  margin-top: 17px;
}
.ops-grid > div {
  padding: 13px;
  border-radius: 11px;
  background: var(--color-surface-neutral);
}
.ops-grid span,
.ops-grid strong,
.ops-grid small {
  display: block;
}
.ops-grid span,
.ops-grid small,
.ops-card footer {
  color: var(--ink-soft);
  font-size: var(--font-size-min);
}
.ops-grid strong {
  margin-top: 6px;
  font-family: var(--font-display);
  font-size: 1.35rem;
}
.ops-grid small {
  margin-top: 2px;
}
.ops-card footer {
  display: flex;
  align-items: center;
  gap: 7px;
  margin-top: 12px;
}
.ops-card footer svg {
  color: #b9533e;
}
@media (width <= 850px) {
  .trust-ops {
    grid-template-columns: 1fr;
  }
  .ops-card {
    grid-column: auto;
  }
}
@media (width <= 540px) {
  .ops-grid {
    grid-template-columns: 1fr 1fr;
  }
  .network-values small {
    display: none;
  }
}
</style>
