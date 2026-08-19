<script setup lang="ts">
import { computed, shallowRef, watch } from "vue";
import type { ReportPeriodKey, ReportPeriodOption } from "~/types";
import { formatDateTime } from "~/utils/formatters";

const periods: ReportPeriodOption[] = [
  {
    key: "since_launch",
    label: "Desde o lançamento",
    shortLabel: "Desde o início",
  },
  { key: "last_30_days", label: "Últimos 30 dias", shortLabel: "30 dias" },
  { key: "last_7_days", label: "Últimos 7 dias", shortLabel: "7 dias" },
];
const route = useRoute();
const router = useRouter();

function isReportPeriod(value: unknown): value is ReportPeriodKey {
  return periods.some((period) => period.key === value);
}

const selectedPeriod = shallowRef<ReportPeriodKey>(
  isReportPeriod(route.query.period) ? route.query.period : "since_launch",
);
const { report, isLoading, error, load } = useAdminGrowthReport(selectedPeriod);
const displayedPeriods = computed(() =>
  periods.map((option) =>
    report.value?.period.key === option.key ? report.value.period : option,
  ),
);
const selectedPeriodLabel = computed(
  () =>
    displayedPeriods.value.find((period) => period.key === selectedPeriod.value)
      ?.label ?? "",
);
const generatedLabel = computed(() =>
  report.value ? formatDateTime(report.value.generatedAt) : "",
);

async function selectPeriod(period: ReportPeriodKey) {
  selectedPeriod.value = period;
  const query = { ...route.query };
  if (period === "since_launch") delete query.period;
  else query.period = period;
  await router.replace({ query });
}

watch(
  () => route.query.period,
  (period) => {
    selectedPeriod.value = isReportPeriod(period) ? period : "since_launch";
  },
);
</script>

<template>
  <section class="growth-reports" :aria-busy="isLoading">
    <div v-if="isLoading && !report" class="report-state" role="status">
      <UIcon name="i-lucide-loader-circle" />
      <span>Carregando relatório…</span>
    </div>

    <div
      v-else-if="error && !report"
      class="report-state report-state--error"
      role="alert"
    >
      <UIcon name="i-lucide-circle-alert" />
      <span>{{ error }}</span>
      <button type="button" @click="load">Tentar novamente</button>
    </div>

    <template v-else-if="report">
      <div class="report-toolbar">
        <div>
          <strong>{{ selectedPeriodLabel }}</strong>
          <small
            >{{ report.period.windowLabel }} · atualizado em
            {{ generatedLabel }}</small
          >
        </div>
        <div
          class="period-switcher"
          role="group"
          aria-label="Período do relatório"
        >
          <button
            v-for="period in displayedPeriods"
            :key="period.key"
            type="button"
            :class="{ active: selectedPeriod === period.key }"
            :aria-pressed="selectedPeriod === period.key"
            @click="selectPeriod(period.key)"
          >
            {{ period.shortLabel }}
          </button>
        </div>
      </div>

      <p v-if="error" class="report-refresh-error" role="alert">
        {{ error }}
        <button type="button" @click="load">Tentar novamente</button>
      </p>

      <div class="privacy-notice">
        <UIcon name="i-lucide-user-round-x" />
        <div>
          <strong>Privacidade desde o primeiro dado</strong>
          <p>{{ report.privacyNotice }}</p>
        </div>
        <span><UIcon name="i-lucide-info" /> Contato não é contratação</span>
      </div>

      <AdminReportsGrowthSummary :report="report" />
      <AdminReportsSupplyHealth :supply="report.supply" />
      <AdminReportsDiscoveryHealth :discovery="report.discovery" />
      <AdminReportsEngagementHealth :engagement="report.engagement" />
      <AdminReportsTrustOperations
        :trust="report.trust"
        :quotes="report.quotes"
        :operations="report.operations"
      />

      <footer class="report-footnote">
        <UIcon name="i-lucide-database" />
        <p>
          <strong>Como lemos estes dados:</strong> ações profissionais vêm dos
          registros do produto; buscas e contatos são agregados sem identidade
          de visitante. Percentuais nunca escondem a base.
        </p>
      </footer>
    </template>
  </section>
</template>

<style scoped lang="scss">
.growth-reports {
  display: grid;
  gap: 26px;
}
.report-state {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 9px;
  min-height: 240px;
  padding: 24px;
  border: 1px solid var(--line);
  border-radius: 18px;
  background: white;
  color: var(--ink-soft);
}
.report-state--error {
  color: var(--color-danger);
}
.report-state button,
.report-refresh-error button {
  border: 0;
  background: transparent;
  color: var(--color-brand);
  cursor: pointer;
  font-weight: 800;
}
.report-refresh-error {
  margin: -12px 0;
  color: var(--color-danger);
  font-size: var(--font-size-min);
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
  background: rgb(255 255 255 / 62%);
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
  background: var(--color-surface-muted);
  color: var(--ink);
}
.period-switcher button.active {
  background: var(--color-brand-strong);
  color: white;
  box-shadow: 0 4px 12px rgb(23 53 47 / 16%);
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
  background: var(--color-brand-tint);
  color: var(--color-brand);
}
.privacy-notice > svg {
  font-size: 1.25rem;
}
.privacy-notice strong,
.privacy-notice p {
  margin: 0;
}
.privacy-notice strong,
.privacy-notice p,
.privacy-notice > span {
  font-size: var(--font-size-min);
}
.privacy-notice p {
  margin-top: 2px;
  color: var(--ink-soft);
}
.privacy-notice > span {
  display: flex;
  align-items: center;
  gap: 4px;
  font-weight: 850;
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
@media (width <= 640px) {
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
}
</style>
