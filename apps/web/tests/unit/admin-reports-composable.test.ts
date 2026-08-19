import { flushPromises } from "@vue/test-utils";
import { effectScope, shallowRef } from "vue";
import { useAdminGrowthReport } from "@app/composables/useAdminGrowthReport";
import type { ReportPeriodData, ReportPeriodKey } from "@app/types";

vi.mock("@app/services/api/client", () => ({ useApiClient: () => ({}) }));

const report = { generatedAt: "2026-08-18T15:00:00Z" } as ReportPeriodData;

describe("administrator reports composable", () => {
  it("loads immediately, reloads on period changes, and contains errors for retry", async () => {
    const load = vi
      .fn()
      .mockResolvedValueOnce(report)
      .mockRejectedValueOnce(new Error("Relatório indisponível."))
      .mockResolvedValueOnce(report);
    const period = shallowRef<ReportPeriodKey>("since_launch");
    const scope = effectScope();
    const workflow = scope.run(() => useAdminGrowthReport(period, { load }))!;

    await flushPromises();
    expect(workflow.report.value).toEqual(report);
    expect(load).toHaveBeenCalledWith("since_launch", expect.any(AbortSignal));

    period.value = "last_7_days";
    await flushPromises();
    expect(workflow.error.value).toBe("Relatório indisponível.");
    expect(workflow.report.value).toEqual(report);

    await workflow.load();
    expect(workflow.error.value).toBe("");
    scope.stop();
  });
});
