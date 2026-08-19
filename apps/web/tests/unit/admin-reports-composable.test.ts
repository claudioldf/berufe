import { flushPromises } from "@vue/test-utils";
import { effectScope, nextTick, shallowRef } from "vue";
import { useAdminGrowthReport } from "@app/composables/useAdminGrowthReport";
import type { ReportPeriodData, ReportPeriodKey } from "@app/types";

vi.mock("@app/services/api/client", () => ({ useApiClient: () => ({}) }));

function reportFor(period: ReportPeriodKey) {
  return {
    generatedAt: "2026-08-18T15:00:00Z",
    period: {
      key: period,
      label: period,
      shortLabel: period,
      windowLabel: period,
      truncated: false,
    },
  } as ReportPeriodData;
}

describe("administrator reports composable", () => {
  it("loads immediately, reloads on period changes, and contains errors for retry", async () => {
    const sinceLaunchReport = reportFor("since_launch");
    const lastSevenDaysReport = reportFor("last_7_days");
    let rejectPeriodChange!: (cause: Error) => void;
    const pendingPeriodChange = new Promise<ReportPeriodData>(
      (_resolve, reject) => {
        rejectPeriodChange = reject;
      },
    );
    const load = vi
      .fn()
      .mockResolvedValueOnce(sinceLaunchReport)
      .mockReturnValueOnce(pendingPeriodChange)
      .mockResolvedValueOnce(lastSevenDaysReport);
    const period = shallowRef<ReportPeriodKey>("since_launch");
    const scope = effectScope();
    const workflow = scope.run(() => useAdminGrowthReport(period, { load }))!;

    await flushPromises();
    expect(workflow.report.value).toEqual(sinceLaunchReport);
    expect(load).toHaveBeenCalledWith("since_launch", expect.any(AbortSignal));

    period.value = "last_7_days";
    await nextTick();
    expect(workflow.report.value).toBeNull();
    expect(workflow.isLoading.value).toBe(true);

    rejectPeriodChange(new Error("Relatório indisponível."));
    await flushPromises();
    expect(workflow.error.value).toBe("Relatório indisponível.");
    expect(workflow.report.value).toBeNull();

    await workflow.load();
    expect(workflow.error.value).toBe("");
    expect(workflow.report.value).toEqual(lastSevenDaysReport);
    scope.stop();
  });
});
