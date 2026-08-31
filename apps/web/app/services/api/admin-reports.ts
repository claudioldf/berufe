import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { components } from "~/services/api/schema";
import type { ReportPeriodData, ReportPeriodKey } from "~/types";

type ApiReport = components["schemas"]["AdminGrowthReportData"];
type ApiComparison = components["schemas"]["AdminGrowthReportComparison"];

function milestoneValue(value: number, percentage: boolean) {
  return percentage ? `${Math.round(value * 100)}%` : String(value);
}

export function formatReportComparison(
  comparison: ApiComparison,
  options: { suffix?: string; percentageMilestone?: boolean } = {},
) {
  const directional = comparison.directional ? " · direcional" : "";
  if (comparison.kind === "milestone") {
    if (comparison.reached !== null) {
      return `Marco de ${milestoneValue(comparison.reached, Boolean(options.percentageMilestone))} alcançado`;
    }
    if (comparison.next !== null) {
      return `Próximo marco: ${milestoneValue(comparison.next, Boolean(options.percentageMilestone))}`;
    }
    return "Marco final alcançado";
  }

  if (comparison.delta === null) return "—";

  const delta = comparison.delta;
  const sign = delta > 0 ? "+" : "";
  const value =
    comparison.kind === "percentage_points"
      ? `${sign}${(delta * 100).toLocaleString("pt-BR", { maximumFractionDigits: 1 })} pp`
      : `${sign}${delta.toLocaleString("pt-BR")}${options.suffix ? ` ${options.suffix}` : ""}`;
  return `${value}${directional}`;
}

export function mapAdminGrowthReport(data: ApiReport): ReportPeriodData {
  return {
    generatedAt: data.generated_at,
    period: {
      key: data.period.key,
      label: data.period.label,
      shortLabel: data.period.short_label,
      windowLabel: data.period.window_label,
      truncated: data.period.truncated,
    },
    privacyNotice: data.privacy_notice,
    summary: {
      published: {
        value: data.summary.published.value,
        currentStock: data.summary.published.current_stock,
        change: formatReportComparison(data.summary.published.comparison),
      },
      activated: {
        ...data.summary.activated,
        change: formatReportComparison(data.summary.activated.comparison),
      },
      searchCoverage: {
        ...data.summary.search_coverage,
        change: formatReportComparison(
          data.summary.search_coverage.comparison,
          {
            percentageMilestone: true,
          },
        ),
      },
      handoffs: {
        ...data.summary.handoffs,
        change: formatReportComparison(data.summary.handoffs.comparison, {
          suffix: "contatos",
        }),
      },
      returning: {
        ...data.summary.returning,
        change: formatReportComparison(data.summary.returning.comparison, {
          suffix: "profissionais",
        }),
      },
    },
    supply: {
      targetMinimum: data.supply.target_minimum,
      targetMaximum: data.supply.target_maximum,
      funnel: data.supply.funnel.map((stage) => ({
        key: stage.key,
        label: stage.label,
        value: stage.value,
        description: stage.description ?? undefined,
        rate: stage.ratio.rate,
      })),
      activation: data.supply.activation.map((metric) => ({
        key: metric.key,
        label: metric.label,
        value: metric.numerator,
        total: metric.denominator,
        rate: metric.rate,
        description: metric.description,
        icon: metric.icon,
      })),
    },
    discovery: {
      stages: data.discovery.stages,
      profileViews: data.discovery.profile_views,
      whatsappHandoffs: data.discovery.whatsapp_handoffs,
      demand: data.discovery.demand,
      gaps: data.discovery.gaps.map((gap) => ({
        service: gap.service,
        location: gap.location,
        searches: gap.searches,
        professionals: gap.professionals,
        catalogStatus: gap.catalog_status,
      })),
    },
    engagement: {
      eligibleProfessionals: data.engagement.eligible_professionals,
      meaningfulActives: data.engagement.meaningful_actives,
      returningProfessionals: data.engagement.returning_professionals,
      activeWeeks: data.engagement.active_weeks,
      actions: data.engagement.actions,
      cohorts: data.engagement.cohorts,
    },
    trust: {
      funnels: data.trust.funnels.map((funnel) => ({
        key: funnel.key,
        label: funnel.label,
        started: funnel.started,
        responded: funnel.responded,
        approved: funnel.approved,
        responseRate: funnel.response_rate,
        approvalRate: funnel.approval_rate,
      })),
    },
    quotes: {
      created: data.quotes.created,
      shared: data.quotes.shared,
      shareRate: data.quotes.share_rate,
      uniqueCreators: data.quotes.unique_creators,
      repeatCreators: data.quotes.repeat_creators,
    },
    operations: {
      pending: data.moderation.pending,
      oldestPendingHours: data.moderation.oldest_pending_hours,
      oldestPendingTargetHours: data.moderation.oldest_pending_target_hours,
      medianReviewHours: data.moderation.median_review_hours,
      p90ReviewHours: data.moderation.p90_review_hours,
      rejected: data.moderation.rejected,
      reviewed: data.moderation.reviewed,
      approvalRate: data.moderation.approval_rate,
      hidden: data.moderation.hidden,
      restored: data.moderation.restored,
    },
  };
}

export async function fetchAdminGrowthReport(
  client: BerufeApiClient,
  period: ReportPeriodKey,
  signal?: AbortSignal,
): Promise<ReportPeriodData> {
  const result = await client.GET("/api/v1/admin/reports/growth", {
    params: { query: { period } },
    signal,
  });
  if (result.error || !result.data) {
    throw new ApiRequestError(
      normalizeApiError(
        result.error,
        result.response.headers.get("X-Request-Id") ?? "client",
      ),
    );
  }
  return mapAdminGrowthReport(result.data.data);
}
