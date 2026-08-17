import { useCatalogs } from "@app/composables/useCatalogs";

const apiClient = vi.hoisted(() => ({ GET: vi.fn() }));

vi.mock("@app/services/api/client", () => ({
  useApiClient: () => apiClient,
}));

describe("catalog composable", () => {
  it("shares the SSR-compatible public catalog request", async () => {
    apiClient.GET.mockResolvedValue({
      data: {
        data: { categories: [], services: [], neighborhoods: [] },
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
      neighborhoods: [
        {
          code: "all",
          name: "Toda Joinville",
          stateCode: "SC",
          city: "Joinville",
        },
      ],
    });
  });
});
