import type { BerufeApiClient } from "@app/services/api/client";
import {
  fetchAdminGrowthReport,
  formatReportComparison,
  mapAdminGrowthReport,
} from "@app/services/api/admin-reports";
import type { components } from "@app/services/api/schema";

type ApiReport = components["schemas"]["AdminGrowthReportData"];

const rate = (numerator = 0, denominator = 0) => ({
  numerator,
  denominator,
  rate: denominator ? numerator / denominator : null,
});
const comparison = {
  kind: "milestone" as const,
  reached: null,
  next: 5,
  delta: null,
  directional: false,
};

const data: ApiReport = {
  generated_at: "2026-08-18T15:00:00Z",
  period: {
    key: "since_launch",
    label: "Desde o lançamento",
    short_label: "Desde o início",
    window_label: "01 ago – 18 ago",
    start_at: "2026-08-01T00:00:00-03:00",
    end_at: "2026-08-19T00:00:00-03:00",
    truncated: false,
    data_available_from: "2026-08-01",
  },
  privacy_notice: "Somente agregados.",
  summary: {
    published: {
      value: 4,
      current_stock: 7,
      metric_type: "flow",
      comparison,
    },
    activated: {
      ...rate(2, 4),
      metric_type: "cohort_outcome",
      comparison,
    },
    search_coverage: {
      ...rate(3, 4),
      metric_type: "flow",
      comparison: { ...comparison, next: 0.75 },
    },
    handoffs: { ...rate(2, 5), metric_type: "flow", comparison },
    returning: {
      ...rate(1, 7),
      metric_type: "cohort_outcome",
      comparison,
    },
  },
  supply: {
    target_minimum: 30,
    target_maximum: 50,
    funnel: [
      {
        key: "registered",
        label: "Cadastrados",
        value: 4,
        description: null,
        ratio: rate(4, 4),
      },
    ],
    activation: [
      {
        ...rate(2, 4),
        key: "all",
        label: "Perfil ativado",
        description: "cumpre os 3 critérios",
        icon: "i-lucide-sparkles",
      },
    ],
  },
  discovery: {
    stages: [
      { ...rate(4, 4), key: "searches", label: "Buscas" },
      { ...rate(2, 4), key: "contact", label: "Contato iniciado" },
    ],
    profile_views: 5,
    whatsapp_handoffs: 2,
    demand: [{ label: "Eletricista", value: 4 }],
    other_count: 1,
    gaps: [
      {
        service: "Drywall",
        location: "Joinville",
        searches: 3,
        zero_result_searches: 2,
        thin_result_searches: 1,
        professionals: 0,
        catalog_status: "inactive",
      },
    ],
  },
  engagement: {
    eligible_professionals: 7,
    meaningful_actives: 3,
    meaningful_active_rate: rate(3, 7),
    returning_professionals: 1,
    returning_rate: rate(1, 7),
    active_weeks: [{ key: "none", label: "0 semanas", value: 4 }],
    actions: [{ key: "profile", label: "Atualizou perfil", value: 2 }],
    cohorts: [{ cohort: "01–07 ago", size: 2, week1: 1, week4: null }],
  },
  trust: {
    funnels: [
      {
        key: "relationships",
        label: "Conexões profissionais",
        started: 3,
        responded: 2,
        approved: 1,
        response_rate: rate(2, 3),
        approval_rate: rate(1, 2),
      },
    ],
  },
  quotes: {
    created: 3,
    shared: 2,
    share_rate: rate(2, 3),
    unique_creators: 2,
    repeat_creators: 1,
  },
  moderation: {
    pending: 1,
    oldest_pending_hours: 4,
    oldest_pending_target_hours: 24,
    median_review_hours: 2,
    p90_review_hours: 5,
    rejected: 1,
    reviewed: 3,
    approval_rate: rate(2, 3),
    hidden: 0,
    by_target_type: { profile_revision: 3 },
  },
};

describe("administrator reports API", () => {
  it("maps generated aggregate types without exposing support-only fields to the UI", () => {
    const report = mapAdminGrowthReport(data);

    expect(report.summary.published).toMatchObject({
      value: 4,
      currentStock: 7,
    });
    expect(report.summary.searchCoverage.change).toBe("Próximo marco: 75%");
    expect(report.supply.activation[0]).toMatchObject({
      value: 2,
      total: 4,
      rate: 0.5,
    });
    expect(report.discovery.stages.at(-1)).toMatchObject({
      key: "contact",
      numerator: 2,
    });
    expect(report.discovery.gaps[0]?.catalogStatus).toBe("inactive");
    expect(report.operations.oldestPendingTargetHours).toBe(24);
    expect(report).not.toHaveProperty("discovery.otherCount");
    expect(report).not.toHaveProperty("operations.byTargetType");
  });

  it("formats small samples as directional and fetches the explicit selected period", async () => {
    expect(
      formatReportComparison({
        kind: "percentage_points",
        reached: null,
        next: null,
        delta: 0.086,
        directional: true,
      }),
    ).toBe("+8,6 pp · direcional");
    expect(
      formatReportComparison({
        kind: "count",
        reached: null,
        next: null,
        delta: null,
        directional: false,
      }),
    ).toBe("—");

    const client = {
      GET: vi.fn().mockResolvedValue({
        data: { data, request_id: "reports-200" },
        error: undefined,
        response: new Response(null),
      }),
    } as unknown as BerufeApiClient;
    const signal = new AbortController().signal;

    await fetchAdminGrowthReport(client, "last_7_days", signal);
    expect(client.GET).toHaveBeenCalledWith("/api/v1/admin/reports/growth", {
      params: { query: { period: "last_7_days" } },
      signal,
    });
  });
});
