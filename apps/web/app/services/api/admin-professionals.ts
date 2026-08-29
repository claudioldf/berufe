import type { AdminProfessionalFilters, AdminProfessionalPage } from "~/types";
import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { components } from "~/services/api/schema";

type AdminProfessionalsData = components["schemas"]["AdminProfessionalsData"];

interface ApiResult<T> {
  data?: T;
  error?: unknown;
  response: Response;
}

export function mapAdminProfessionals(
  data: AdminProfessionalsData,
): AdminProfessionalPage {
  return {
    items: data.items.map((item) => ({
      id: item.id,
      professionalProfileId: item.professional_profile_id,
      publicSlug: item.public_slug,
      displayName: item.display_name,
      profileStatus: item.profile_status,
      city: item.city,
      state: item.state,
      phoneVerified: item.phone_verified,
      phoneLast4: item.phone_last4,
      identityVerified: item.identity_verified,
      accountStatus: item.account_status,
      portfolioCount: item.portfolio_count,
      referenceCount: item.reference_count,
      customerCount: item.customer_count,
      quoteCount: item.quote_count,
      registeredAt: item.registered_at,
      lastLoginAt: item.last_login_at,
      loginCount: item.login_count,
      publishedAt: item.published_at,
    })),
    summary: {
      total: data.summary.total,
      published: data.summary.published,
      suspended: data.summary.suspended,
      onboardingFinished: data.summary.onboarding_finished,
      identityVerified: data.summary.identity_verified,
    },
    meta: {
      page: data.meta.page,
      perPage: data.meta.per_page,
      totalCount: data.meta.total_count,
      totalPages: data.meta.total_pages,
    },
  };
}

function requireProfessionals(
  result: ApiResult<{ data: AdminProfessionalsData }>,
): AdminProfessionalPage {
  if (result.error || !result.data) {
    throw new ApiRequestError(
      normalizeApiError(
        result.error,
        result.response.headers.get("X-Request-Id") ?? "client",
      ),
    );
  }

  return mapAdminProfessionals(result.data.data);
}

function query(filters: AdminProfessionalFilters) {
  return {
    page: filters.page,
    per_page: 20,
    q: filters.q || undefined,
    phone: filters.phone || undefined,
    city: filters.city || undefined,
    state: filters.state || undefined,
    identity_verified:
      filters.identityVerified !== "all" ? filters.identityVerified : undefined,
    onboarding_finished:
      filters.onboardingFinished !== "all"
        ? filters.onboardingFinished
        : undefined,
    sort: filters.sort !== "recent" ? filters.sort : undefined,
  };
}

export async function fetchAdminProfessionals(
  client: BerufeApiClient,
  filters: AdminProfessionalFilters,
  signal?: AbortSignal,
): Promise<AdminProfessionalPage> {
  return requireProfessionals(
    await client.GET("/api/v1/admin/professionals", {
      params: { query: query(filters) },
      signal,
    }),
  );
}

export async function setAdminProfessionalPublication(
  client: BerufeApiClient,
  professionalProfileId: string,
  published: boolean,
  reason: string | null,
  filters: AdminProfessionalFilters,
): Promise<AdminProfessionalPage> {
  return requireProfessionals(
    await client.POST("/api/v1/admin/professionals/{id}/publication", {
      params: {
        path: { id: professionalProfileId },
        query: query(filters),
      },
      body: { publication: { published, reason } },
    }),
  );
}
