import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { components } from "~/services/api/schema";
import type { SearchAuditPage, SearchAuditRequest } from "~/types";

type ApiSearchAuditData = components["schemas"]["AdminSearchAuditData"];

export function mapAdminSearchAudits(
  data: ApiSearchAuditData,
): SearchAuditPage {
  return {
    items: data.items.map((item) => ({
      id: item.id,
      inputPrompt: item.input_prompt,
      rawLlmResponse: item.raw_llm_response,
      parsedResponse: item.parsed_response && {
        serviceIds: item.parsed_response.service_ids,
        services: item.parsed_response.services,
        locations: item.parsed_response.locations.map((location) => ({
          stateCode: location.state_code,
          city: location.city,
          neighborhood: location.neighborhood,
        })),
        keywords: item.parsed_response.keywords,
        normalizedRequest: item.parsed_response.normalized_request,
      },
      status: item.status,
      responseSource: item.response_source,
      adapter: item.adapter,
      model: item.model,
      providerRequestId: item.provider_request_id,
      promptDigest: item.prompt_digest,
      resultCount: item.result_count,
      createdAt: item.created_at,
    })),
    summary: {
      total: data.summary.total,
      zeroResults: data.summary.zero_results,
      notUnderstood: data.summary.not_understood,
      thinResults: data.summary.thin_results,
      operationalIssue: data.summary.operational_issue,
      healthy: data.summary.healthy,
    },
    meta: {
      page: data.meta.page,
      perPage: data.meta.per_page,
      totalCount: data.meta.total_count,
      totalPages: data.meta.total_pages,
    },
  };
}

export async function fetchAdminSearchAudits(
  client: BerufeApiClient,
  request: SearchAuditRequest,
  signal?: AbortSignal,
): Promise<SearchAuditPage> {
  const query = {
    page: request.page,
    per_page: 20,
    ...(request.q ? { q: request.q } : {}),
    ...(request.outcome ? { outcome: request.outcome } : {}),
    ...(request.sort !== "results_asc" ? { sort: request.sort } : {}),
  };
  const result = await client.GET("/api/v1/admin/search-audits", {
    params: { query },
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

  return mapAdminSearchAudits(result.data.data);
}
