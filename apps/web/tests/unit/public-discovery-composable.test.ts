import { useFeaturedProfessionals } from "@app/composables/useFeaturedProfessionals";

const apiClient = vi.hoisted(() => ({ GET: vi.fn() }));

vi.mock("@app/services/api/client", () => ({
  useApiClient: () => apiClient,
}));

describe("public discovery composable", () => {
  it("shares an SSR-compatible featured-professionals request", async () => {
    apiClient.GET.mockResolvedValue({
      data: {
        data: { professionals: [] },
        request_id: "featured-empty",
      },
      error: undefined,
      response: new Response(null),
    });

    const { data, error } = await useFeaturedProfessionals();

    expect(error.value).toBeUndefined();
    expect(data.value).toEqual([]);
    expect(apiClient.GET).toHaveBeenCalledWith(
      "/api/v1/public/professionals/featured",
    );
  });
});
