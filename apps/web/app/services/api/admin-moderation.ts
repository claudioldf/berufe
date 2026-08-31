import type {
  ModerationDecision,
  ModerationFilters,
  ModerationQueue,
  ModerationTargetType,
} from "~/types";
import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { components } from "~/services/api/schema";
import { formatDateTime } from "~/utils/formatters";

type AdminModerationData = components["schemas"]["AdminModerationData"];
const typeLabels: Record<ModerationTargetType, string> = {
  verification_request: "Verificação",
};

interface ApiResult<T> {
  data?: T;
  error?: unknown;
  response: Response;
}

export function formatModerationAge(
  value: string | null,
  now = new Date(),
): string {
  if (!value) return "—";
  const elapsedMinutes = Math.max(
    0,
    Math.floor((now.getTime() - new Date(value).getTime()) / 60_000),
  );
  if (elapsedMinutes < 60) return `há ${elapsedMinutes}min`;
  const elapsedHours = Math.floor(elapsedMinutes / 60);
  if (elapsedHours < 24) return `há ${elapsedHours}h`;
  return `há ${Math.floor(elapsedHours / 24)}d`;
}

export function mapAdminModeration(
  data: AdminModerationData,
  now = new Date(),
): ModerationQueue {
  return {
    items: data.items.map((item) => ({
      id: item.target_id,
      targetType: item.target_type,
      status: item.status,
      type: typeLabels[item.target_type],
      title: item.title,
      subtitle: item.subtitle,
      submittedAt: formatDateTime(item.submitted_at),
      age: formatModerationAge(item.submitted_at, now),
      details: item.details,
      preview: item.preview,
      claimedBirthdate: item.claimed_birthdate,
      verificationFileId: item.verification_file_id,
    })),
    meta: {
      page: data.meta.page,
      perPage: data.meta.per_page,
      totalCount: data.meta.total_count,
      totalPages: data.meta.total_pages,
    },
    summary: {
      pendingCount: data.summary.pending_count,
      reviewedTodayCount: data.summary.reviewed_today_count,
      oldestPendingAt: data.summary.oldest_pending_submitted_at,
      oldestPendingAge: formatModerationAge(
        data.summary.oldest_pending_submitted_at,
        now,
      ),
    },
  };
}

function requireModerationQueue(
  result: ApiResult<{ data: AdminModerationData }>,
): ModerationQueue {
  if (result.error || !result.data) {
    throw new ApiRequestError(
      normalizeApiError(
        result.error,
        result.response.headers.get("X-Request-Id") ?? "client",
      ),
    );
  }

  return mapAdminModeration(result.data.data);
}

function query(filters: ModerationFilters) {
  return {
    status: filters.status,
    search: filters.search || undefined,
    page: filters.page,
    per_page: filters.perPage,
  };
}

export async function fetchAdminModeration(
  client: BerufeApiClient,
  filters: ModerationFilters,
): Promise<ModerationQueue> {
  return requireModerationQueue(
    await client.GET("/api/v1/admin/moderation", {
      params: { query: query(filters) },
    }),
  );
}

export async function createAdminModerationDecision(
  client: BerufeApiClient,
  targetType: ModerationTargetType,
  targetId: string,
  action: ModerationDecision,
  filters: ModerationFilters,
  attributes: {
    reason?: string;
    note?: string;
    identityMatchConfirmed?: boolean;
  } = {},
): Promise<ModerationQueue> {
  return requireModerationQueue(
    await client.POST(
      "/api/v1/admin/moderation/{target_type}/{target_id}/decisions",
      {
        params: {
          path: { target_type: targetType, target_id: targetId },
          query: query(filters),
        },
        body: {
          decision: {
            action,
            reason: attributes.reason || null,
            note: attributes.note || null,
            identity_match_confirmed:
              attributes.identityMatchConfirmed ?? false,
          },
        },
      },
    ),
  );
}

export async function fetchAdminVerificationFile(
  client: BerufeApiClient,
  id: string,
): Promise<Blob> {
  const result = await client.GET(
    "/api/v1/admin/verification-files/{id}/content",
    {
      params: { path: { id } },
      parseAs: "blob",
    },
  );
  if (result.error || !result.data) {
    throw new ApiRequestError(
      normalizeApiError(
        result.error,
        result.response.headers.get("X-Request-Id") ?? "client",
      ),
    );
  }

  return result.data;
}
