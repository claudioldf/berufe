import { onScopeDispose, readonly, shallowRef, watch, type Ref } from "vue";
import { fetchAdminGrowthReport } from "~/services/api/admin-reports";
import { useApiClient } from "~/services/api/client";
import type { ReportPeriodData, ReportPeriodKey } from "~/types";

interface AdminGrowthReportDependencies {
  load?: (
    period: ReportPeriodKey,
    signal: AbortSignal,
  ) => Promise<ReportPeriodData>;
}

export function useAdminGrowthReport(
  period: Ref<ReportPeriodKey>,
  dependencies: AdminGrowthReportDependencies = {},
) {
  const client = useApiClient();
  const report = shallowRef<ReportPeriodData | null>(null);
  const isLoading = shallowRef(false);
  const error = shallowRef("");
  let sequence = 0;
  let controller: AbortController | undefined;
  const loadReport =
    dependencies.load ??
    ((key, signal) => fetchAdminGrowthReport(client, key, signal));

  async function load() {
    const current = ++sequence;
    controller?.abort();
    controller = new AbortController();
    isLoading.value = true;
    error.value = "";
    try {
      const next = await loadReport(period.value, controller.signal);
      if (current === sequence) report.value = next;
    } catch (cause) {
      if (controller.signal.aborted) return;
      if (current === sequence) {
        error.value =
          cause instanceof Error
            ? cause.message
            : "Não foi possível carregar o relatório.";
      }
    } finally {
      if (current === sequence) isLoading.value = false;
    }
  }

  watch(period, load, { immediate: true });
  onScopeDispose(() => controller?.abort());

  return {
    report: readonly(report),
    isLoading: readonly(isLoading),
    error: readonly(error),
    load,
  };
}
