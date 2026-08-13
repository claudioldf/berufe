<script setup lang="ts">
import { computed, shallowRef } from 'vue'
import reportsData from '../../../../data/reports.json'
import type { GrowthReportsData, ReportPeriodKey } from '~/types'

const reports = reportsData as GrowthReportsData
const selectedPeriod = shallowRef<ReportPeriodKey>('since_launch')

const report = computed(() => reports.data[selectedPeriod.value])
const selectedPeriodLabel = computed(() => reports.periods.find(period => period.key === selectedPeriod.value)?.label ?? '')
const published = computed(() => report.value.supply.funnel.find(stage => stage.key === 'published')?.value ?? 0)
const hasData = computed(() => published.value > 0 || report.value.discovery.searches > 0)

function selectPeriod(period: ReportPeriodKey) {
  selectedPeriod.value = period
}
</script>

<template>
  <section class="growth-reports">
    <div class="report-toolbar">
      <div>
        <strong>{{ selectedPeriodLabel }}</strong>
        <small>{{ report.windowLabel }} · atualizado em 12 ago, 09:00</small>
      </div>
      <div class="period-switcher" role="group" aria-label="Período do relatório">
        <button v-for="period in reports.periods" :key="period.key" type="button" :class="{ active: selectedPeriod === period.key }" :aria-pressed="selectedPeriod === period.key" @click="selectPeriod(period.key)">{{ period.shortLabel }}</button>
      </div>
    </div>

    <div class="privacy-notice">
      <UIcon name="i-lucide-user-round-x" />
      <div><strong>Privacidade desde o primeiro dado</strong><p>{{ reports.privacyNotice }}</p></div>
      <span><UIcon name="i-lucide-info" /> Contato não é contratação</span>
    </div>

    <div v-if="!hasData" class="launch-empty">
      <span><UIcon name="i-lucide-rocket" /></span>
      <div><DesignSystemKicker>Primeiro marco</DesignSystemKicker><h2>Publique os primeiros 5 profissionais</h2><p>O relatório ganhará funis e taxas assim que houver denominadores. Até lá, acompanhe cadastro, verificação e publicação em contagens absolutas.</p></div>
      <strong>0/{{ report.supply.targetMinimum }}</strong>
    </div>

    <template v-else>
      <AdminReportsGrowthSummary :report="report" />
      <AdminReportsSupplyHealth :supply="report.supply" />
      <AdminReportsDiscoveryHealth :discovery="report.discovery" />
      <AdminReportsEngagementHealth :engagement="report.engagement" />
      <AdminReportsTrustOperations :trust="report.trust" :quotes="report.quotes" :operations="report.operations" />
    </template>

    <footer class="report-footnote">
      <UIcon name="i-lucide-database" />
      <p><strong>Como lemos estes dados:</strong> ações profissionais vêm dos registros do produto; buscas e contatos são agregados sem identidade de visitante. Percentuais nunca escondem a base.</p>
    </footer>
  </section>
</template>

<style scoped lang="scss">
.growth-reports {
  display: grid;
  gap: 26px;
}
.report-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}
.report-toolbar strong,
.report-toolbar small {
  display: block;
}
.report-toolbar strong {
  font-size: 0.83rem;
}
.report-toolbar small {
  margin-top: 3px;
  color: var(--ink-soft);
  font-size: var(--font-size-min);
}
.period-switcher {
  display: inline-flex;
  gap: 3px;
  padding: 3px;
  border: 1px solid var(--line);
  border-radius: 11px;
  background: rgba(255, 255, 255, 0.62);
}
.period-switcher button {
  padding: 7px 10px;
  border: 0;
  border-radius: 8px;
  background: transparent;
  color: var(--ink-soft);
  cursor: pointer;
  font-size: var(--font-size-min);
  font-weight: 800;
}
.period-switcher button:hover {
  background: #f0eee8;
  color: var(--ink);
}
.period-switcher button.active {
  background: #17352f;
  color: white;
  box-shadow: 0 4px 12px rgba(23, 53, 47, 0.16);
}
.privacy-notice {
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 10px;
  margin-top: -12px;
  padding: 13px 14px;
  border: 1px solid #a7ccc0;
  border-radius: 13px;
  background: #e8f4f0;
  color: #397a69;
}
.privacy-notice > svg {
  font-size: 1.25rem;
}
.privacy-notice strong,
.privacy-notice p {
  margin: 0;
}
.privacy-notice strong {
  font-size: var(--font-size-min);
}
.privacy-notice p {
  margin-top: 2px;
  color: var(--ink-soft);
  font-size: var(--font-size-min);
}
.privacy-notice > span {
  display: flex;
  align-items: center;
  gap: 4px;
  color: #397a69;
  font-size: var(--font-size-min);
  font-weight: 850;
}
.launch-empty {
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 17px;
  padding: 22px;
  border: 1px solid var(--line);
  border-radius: 18px;
  background: white;
}
.launch-empty > span {
  display: grid;
  place-items: center;
  width: 48px;
  height: 48px;
  border-radius: 14px;
  background: #fff0ec;
  color: #b9533e;
  font-size: 1.3rem;
}
.launch-empty h2,
.launch-empty p {
  margin: 0;
}
.launch-empty h2 {
  margin-top: 3px;
  font-family: Georgia, serif;
  font-size: 1.3rem;
  font-weight: 500;
}
.launch-empty div > p:last-child {
  margin-top: 5px;
  color: var(--ink-soft);
  font-size: var(--font-size-min);
  line-height: 1.5;
}
.launch-empty > strong {
  font-family: Georgia, serif;
  font-size: 1.7rem;
}
.report-footnote {
  display: flex;
  align-items: start;
  gap: 8px;
  padding: 13px 15px;
  border-top: 1px solid var(--line);
  color: var(--ink-soft);
}
.report-footnote svg {
  flex: 0 0 auto;
  margin-top: 2px;
}
.report-footnote p {
  margin: 0;
  font-size: var(--font-size-min);
  line-height: 1.5;
}
.report-footnote strong {
  color: var(--ink);
}
@media (max-width: 640px) {
  .report-toolbar {
    align-items: stretch;
    flex-direction: column;
  }
  .period-switcher {
    align-self: stretch;
  }
  .period-switcher button {
    flex: 1;
  }
  .privacy-notice {
    grid-template-columns: auto 1fr;
  }
  .privacy-notice > span {
    display: none;
  }
  .launch-empty {
    grid-template-columns: auto 1fr;
  }
  .launch-empty > strong {
    grid-column: 2;
  }
}
</style>
