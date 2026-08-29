import type { BerufeApiClient } from "@app/services/api/client";
import {
  fetchAdminProfessionals,
  mapAdminProfessionals,
  setAdminProfessionalPublication,
} from "@app/services/api/admin-professionals";
import type { components } from "@app/services/api/schema";
import type { AdminProfessionalFilters } from "@app/types";

type ApiData = components["schemas"]["AdminProfessionalsData"];

const data: ApiData = {
  items: [
    {
      id: "5f6a2c1a-1111-4c00-9000-000000000001",
      professional_profile_id: "5f6a2c1a-2222-4c00-9000-000000000002",
      public_slug: "ana-souza",
      display_name: "Ana Souza",
      profile_status: "published",
      city: "Joinville",
      state: "SC",
      phone_verified: true,
      phone_last4: "4002",
      identity_verified: true,
      account_status: "active",
      portfolio_count: 3,
      reference_count: 1,
      customer_count: 5,
      quote_count: 2,
      registered_at: "2026-01-10T12:00:00Z",
      last_login_at: "2026-08-20T09:00:00Z",
      login_count: 7,
      published_at: "2026-01-12T12:00:00Z",
    },
  ],
  summary: {
    total: 1,
    published: 1,
    suspended: 0,
    onboarding_finished: 1,
    identity_verified: 1,
  },
  meta: { page: 1, per_page: 20, total_count: 1, total_pages: 1 },
};

const defaultFilters: AdminProfessionalFilters = {
  page: 1,
  q: "",
  phone: "",
  city: null,
  state: null,
  identityVerified: "all",
  onboardingFinished: "all",
  sort: "recent",
};

describe("administrator professional directory API", () => {
  it("maps the contract shape to camelCase domain fields", () => {
    const result = mapAdminProfessionals(data);

    expect(result.items[0]).toEqual({
      id: "5f6a2c1a-1111-4c00-9000-000000000001",
      professionalProfileId: "5f6a2c1a-2222-4c00-9000-000000000002",
      publicSlug: "ana-souza",
      displayName: "Ana Souza",
      profileStatus: "published",
      city: "Joinville",
      state: "SC",
      phoneVerified: true,
      phoneLast4: "4002",
      identityVerified: true,
      accountStatus: "active",
      portfolioCount: 3,
      referenceCount: 1,
      customerCount: 5,
      quoteCount: 2,
      registeredAt: "2026-01-10T12:00:00Z",
      lastLoginAt: "2026-08-20T09:00:00Z",
      loginCount: 7,
      publishedAt: "2026-01-12T12:00:00Z",
    });
    expect(result.summary).toEqual({
      total: 1,
      published: 1,
      suspended: 0,
      onboardingFinished: 1,
      identityVerified: 1,
    });
    expect(result.meta).toEqual({
      page: 1,
      perPage: 20,
      totalCount: 1,
      totalPages: 1,
    });
  });

  it("fetches with every filter and omits values matching the defaults", async () => {
    const client = {
      GET: vi.fn().mockResolvedValue({
        data: { data, request_id: "professionals-200" },
        error: undefined,
        response: new Response(null),
      }),
    } as unknown as BerufeApiClient;
    const signal = new AbortController().signal;

    await fetchAdminProfessionals(
      client,
      {
        page: 2,
        q: "ana",
        phone: "47999996003",
        city: "4209102",
        state: "SC",
        identityVerified: "yes",
        onboardingFinished: "no",
        sort: "name_asc",
      },
      signal,
    );

    expect(client.GET).toHaveBeenCalledWith("/api/v1/admin/professionals", {
      params: {
        query: {
          page: 2,
          per_page: 20,
          q: "ana",
          phone: "47999996003",
          city: "4209102",
          state: "SC",
          identity_verified: "yes",
          onboarding_finished: "no",
          sort: "name_asc",
        },
      },
      signal,
    });

    await fetchAdminProfessionals(client, defaultFilters, signal);

    expect(client.GET).toHaveBeenLastCalledWith("/api/v1/admin/professionals", {
      params: { query: { page: 1, per_page: 20 } },
      signal,
    });
  });

  it("throws a normalized error when the request fails", async () => {
    const client = {
      GET: vi.fn().mockResolvedValue({
        data: undefined,
        error: {
          error: {
            code: "validation_failed",
            message: "Revise os filtros.",
            request_id: "req-1",
          },
        },
        response: new Response(null, { headers: { "X-Request-Id": "req-1" } }),
      }),
    } as unknown as BerufeApiClient;

    await expect(
      fetchAdminProfessionals(client, defaultFilters),
    ).rejects.toThrow("Revise os filtros.");
  });

  it("posts a publication decision with the current filters and refreshes the list", async () => {
    const client = {
      POST: vi.fn().mockResolvedValue({
        data: { data, request_id: "professionals-publication-200" },
        error: undefined,
        response: new Response(null),
      }),
    } as unknown as BerufeApiClient;

    await setAdminProfessionalPublication(
      client,
      "5f6a2c1a-2222-4c00-9000-000000000002",
      false,
      "Motivo com detalhes suficientes.",
      { ...defaultFilters, page: 2, q: "ana" },
    );

    expect(client.POST).toHaveBeenCalledWith(
      "/api/v1/admin/professionals/{id}/publication",
      {
        params: {
          path: { id: "5f6a2c1a-2222-4c00-9000-000000000002" },
          query: { page: 2, per_page: 20, q: "ana" },
        },
        body: {
          publication: {
            published: false,
            reason: "Motivo com detalhes suficientes.",
          },
        },
      },
    );
  });
});
