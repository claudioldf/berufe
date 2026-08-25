import { flushPromises } from "@vue/test-utils";
import { effectScope } from "vue";
import { useAdminSearchAudits } from "@app/composables/useAdminSearchAudits";
import type { SearchAuditPage } from "@app/types";

vi.mock("@app/services/api/client", () => ({ useApiClient: () => ({}) }));

const page = (value: number): SearchAuditPage => ({
  items: [],
  meta: { page: value, perPage: 20, totalCount: 21, totalPages: 2 },
});

describe("administrator search-audit composable", () => {
  it("loads immediately, pages through server results, and exposes retry errors", async () => {
    const load = vi
      .fn()
      .mockResolvedValueOnce(page(1))
      .mockResolvedValueOnce(page(2))
      .mockRejectedValueOnce(new Error("Auditoria indisponível."));
    const scope = effectScope();
    const workflow = scope.run(() => useAdminSearchAudits({ load }))!;

    await flushPromises();
    expect(workflow.audits.value.meta.page).toBe(1);
    expect(load).toHaveBeenCalledWith(1, expect.any(AbortSignal));

    workflow.setPage(2);
    await flushPromises();
    expect(workflow.audits.value.meta.page).toBe(2);
    expect(load).toHaveBeenLastCalledWith(2, expect.any(AbortSignal));

    await workflow.load();
    expect(workflow.error.value).toBe("Auditoria indisponível.");
    expect(workflow.isLoading.value).toBe(false);
    scope.stop();
  });
});
