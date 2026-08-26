import type { BerufeApiClient } from "@app/services/api/client";
import {
  fetchAdminSearchAudits,
  mapAdminSearchAudits,
} from "@app/services/api/admin-search-audits";
import type { components } from "@app/services/api/schema";

type ApiData = components["schemas"]["AdminSearchAuditData"];

const data: ApiData = {
  items: [
    {
      id: "1d724daa-10f8-48c0-9c51-1a82cb9fd475",
      input_prompt: "Preciso de pintor no América",
      raw_llm_response: '{"service_ids":[]}',
      parsed_response: {
        service_ids: ["db13859d-b24e-48a2-9f27-cf1f4cf59915"],
        services: [
          {
            id: "db13859d-b24e-48a2-9f27-cf1f4cf59915",
            name: "Pintor",
          },
        ],
        locations: [
          {
            state_code: "SC",
            city: "Joinville",
            neighborhood: { code: "america", name: "América" },
          },
        ],
        keywords: [],
        normalized_request: "Eu preciso de pintor no América, Joinville.",
      },
      status: "completed",
      response_source: "provider",
      adapter: "openai",
      model: "gpt-5-mini",
      provider_request_id: "req_123",
      prompt_digest: "a".repeat(64),
      result_count: 7,
      created_at: "2026-08-25T12:00:00Z",
    },
  ],
  summary: {
    total: 1,
    zero_results: 0,
    not_understood: 0,
    thin_results: 0,
    operational_issue: 0,
    healthy: 1,
  },
  meta: { page: 1, per_page: 20, total_count: 1, total_pages: 1 },
};

describe("administrator search-audit API", () => {
  it("maps raw, parsed, and match-count fields to frontend types", () => {
    const result = mapAdminSearchAudits(data);

    expect(result.items[0]).toMatchObject({
      inputPrompt: "Preciso de pintor no América",
      rawLlmResponse: '{"service_ids":[]}',
      resultCount: 7,
      responseSource: "provider",
    });
    expect(result.items[0]?.parsedResponse).toMatchObject({
      services: [{ name: "Pintor" }],
      locations: [
        {
          stateCode: "SC",
          city: "Joinville",
          neighborhood: { name: "América" },
        },
      ],
      normalizedRequest: "Eu preciso de pintor no América, Joinville.",
    });
    expect(result.meta).toEqual({
      page: 1,
      perPage: 20,
      totalCount: 1,
      totalPages: 1,
    });
    expect(result.summary).toEqual({
      total: 1,
      zeroResults: 0,
      notUnderstood: 0,
      thinResults: 0,
      operationalIssue: 0,
      healthy: 1,
    });
  });

  it("fetches server-side filters and omits the default ascending sort", async () => {
    const client = {
      GET: vi.fn().mockResolvedValue({
        data: { data, request_id: "search-audits-200" },
        error: undefined,
        response: new Response(null),
      }),
    } as unknown as BerufeApiClient;
    const signal = new AbortController().signal;

    await fetchAdminSearchAudits(
      client,
      {
        page: 2,
        q: "eletricista",
        outcome: "thin_results",
        sort: "newest",
      },
      signal,
    );

    expect(client.GET).toHaveBeenCalledWith("/api/v1/admin/search-audits", {
      params: {
        query: {
          page: 2,
          per_page: 20,
          q: "eletricista",
          outcome: "thin_results",
          sort: "newest",
        },
      },
      signal,
    });

    await fetchAdminSearchAudits(
      client,
      { page: 1, q: "", outcome: null, sort: "results_asc" },
      signal,
    );

    expect(client.GET).toHaveBeenLastCalledWith("/api/v1/admin/search-audits", {
      params: { query: { page: 1, per_page: 20 } },
      signal,
    });
  });
});
