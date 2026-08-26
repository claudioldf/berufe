import type { BerufeApiClient } from "@app/services/api/client";
import { fetchPublicSearchLocation } from "@app/services/api/search-location";

function apiClientReturning(result: object) {
  return {
    GET: vi.fn().mockResolvedValue(result),
  } as unknown as BerufeApiClient;
}

describe("public search location API", () => {
  it("maps the effective location and discloses its source", async () => {
    const client = apiClientReturning({
      data: {
        data: {
          state_code: "SC",
          city: "Joinville",
          state_slug: "sc",
          city_slug: "joinville",
          source: "ip",
        },
        request_id: "location-200",
      },
      error: undefined,
      response: new Response(null),
    });

    await expect(fetchPublicSearchLocation(client)).resolves.toEqual({
      location: {
        stateCode: "SC",
        city: "Joinville",
        stateSlug: "sc",
        citySlug: "joinville",
      },
      source: "ip",
    });
    expect(client.GET).toHaveBeenCalledWith("/api/v1/public/search-location");
  });

  it("normalizes provider endpoint failures", async () => {
    const client = apiClientReturning({
      data: undefined,
      error: {
        error: {
          code: "service_unavailable",
          message: "Serviço temporariamente indisponível.",
          request_id: "location-503",
        },
      },
      response: new Response(null, {
        status: 503,
        headers: { "X-Request-Id": "location-503" },
      }),
    });

    await expect(fetchPublicSearchLocation(client)).rejects.toMatchObject({
      name: "ApiRequestError",
      code: "service_unavailable",
      requestId: "location-503",
    });
  });
});
