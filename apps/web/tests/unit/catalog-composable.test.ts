import { useCatalogs } from "@app/composables/useCatalogs";

const apiClient = vi.hoisted(() => ({ GET: vi.fn() }));

vi.mock("@app/services/api/client", () => ({
  useApiClient: () => apiClient,
}));

describe("catalog composable", () => {
  it("shares the SSR-compatible public catalog request", async () => {
    apiClient.GET.mockResolvedValue({
      data: {
        data: {
          categories: [],
          services: [],
          cities: [
            {
              city_code: "4209102",
              state_code: "SC",
              city: "Joinville",
              state_slug: "sc",
              city_slug: "joinville",
            },
          ],
        },
        request_id: "catalog-empty",
      },
      error: undefined,
      response: new Response(null),
    });

    const { data, error } = await useCatalogs();

    expect(error.value).toBeUndefined();
    expect(data.value).toEqual({
      categories: [],
      services: [],
      cities: [
        {
          cityCode: "4209102",
          stateCode: "SC",
          city: "Joinville",
          stateSlug: "sc",
          citySlug: "joinville",
        },
      ],
    });
  });
});
