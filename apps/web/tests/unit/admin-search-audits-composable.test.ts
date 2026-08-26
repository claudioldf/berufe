import { flushPromises } from "@vue/test-utils";
import { effectScope, reactive } from "vue";
import type { RouteLocationNormalizedLoaded, Router } from "vue-router";
import { useAdminSearchAudits } from "@app/composables/useAdminSearchAudits";
import type { SearchAuditPage } from "@app/types";

vi.mock("@app/services/api/client", () => ({ useApiClient: () => ({}) }));

const page = (value: number): SearchAuditPage => ({
  items: [],
  summary: {
    total: 21,
    zeroResults: 3,
    notUnderstood: 2,
    thinResults: 4,
    operationalIssue: 1,
    healthy: 11,
  },
  meta: { page: value, perPage: 20, totalCount: 21, totalPages: 2 },
});

describe("administrator search-audit composable", () => {
  function routeDependencies() {
    const routeState = reactive<{ query: Record<string, unknown> }>({
      query: {},
    });
    const route = routeState as unknown as Pick<
      RouteLocationNormalizedLoaded,
      "query"
    >;
    const router = {
      replace: vi.fn(async (location: { query?: Record<string, unknown> }) => {
        routeState.query = { ...location.query };
      }),
    } as unknown as Pick<Router, "replace">;
    return { route, router, routeState };
  }

  it("loads URL-backed filters, pages through results, and exposes retry errors", async () => {
    const load = vi
      .fn()
      .mockResolvedValueOnce(page(1))
      .mockResolvedValueOnce(page(2))
      .mockRejectedValueOnce(new Error("Auditoria indisponível."));
    const { route, router, routeState } = routeDependencies();
    const scope = effectScope();
    const workflow = scope.run(() =>
      useAdminSearchAudits({ load, route, router }),
    )!;

    await flushPromises();
    expect(workflow.audits.value.meta.page).toBe(1);
    expect(load).toHaveBeenCalledWith(
      { page: 1, q: "", outcome: null, sort: "results_asc" },
      expect.any(AbortSignal),
    );

    await workflow.setPage(2);
    await flushPromises();
    expect(workflow.audits.value.meta.page).toBe(2);
    expect(routeState.query).toEqual({ page: "2" });
    expect(load).toHaveBeenLastCalledWith(
      { page: 2, q: "", outcome: null, sort: "results_asc" },
      expect.any(AbortSignal),
    );

    await workflow.load();
    expect(workflow.error.value).toBe("Auditoria indisponível.");
    expect(workflow.isLoading.value).toBe(false);
    scope.stop();
  });

  it("resets pagination and shares analytical filter state through the URL", async () => {
    const load = vi.fn().mockResolvedValue(page(1));
    const { route, router, routeState } = routeDependencies();
    const scope = effectScope();
    const workflow = scope.run(() =>
      useAdminSearchAudits({ load, route, router }),
    )!;
    await flushPromises();

    await workflow.submitQuery("  eletricista  ");
    await workflow.setOutcome("zero_results");
    await workflow.setSort("newest");
    await flushPromises();

    expect(routeState.query).toEqual({
      q: "eletricista",
      outcome: "zero_results",
      sort: "newest",
    });
    expect(load).toHaveBeenLastCalledWith(
      {
        page: 1,
        q: "eletricista",
        outcome: "zero_results",
        sort: "newest",
      },
      expect.any(AbortSignal),
    );

    await workflow.clearFilters();
    await flushPromises();
    expect(routeState.query).toEqual({ sort: "newest" });
    scope.stop();
  });
});
