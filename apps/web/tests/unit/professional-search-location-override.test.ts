import { clearNuxtData } from "#app";
import { flushPromises } from "@vue/test-utils";
import { shallowRef } from "vue";
import { useProfessionalSearch } from "@app/composables/useProfessionalSearch";
import { encodeSearchExpression } from "@app/utils/searchExpression";

const apiClient = vi.hoisted(() => ({ POST: vi.fn() }));

vi.mock("@app/services/api/client", () => ({
  useApiClient: () => apiClient,
}));

describe("professional search location override", () => {
  it("adopts the parsed city and replaces the route without searching twice", async () => {
    const joinville = {
      cityCode: "4209102",
      stateCode: "SC",
      city: "Joinville",
      stateSlug: "sc",
      citySlug: "joinville",
    };
    const curitiba = {
      cityCode: "4106902",
      stateCode: "PR",
      city: "Curitiba",
      stateSlug: "pr",
      citySlug: "curitiba",
    };
    apiClient.POST.mockResolvedValue({
      data: {
        data: {
          professionals: [],
          related_services: [],
          meta: {
            page: 1,
            per_page: 20,
            total_count: 0,
            total_pages: 0,
          },
          interpretation: {
            services: [],
            effective_location: {
              city_code: curitiba.cityCode,
              state_code: curitiba.stateCode,
              city: curitiba.city,
              state_slug: curitiba.stateSlug,
              city_slug: curitiba.citySlug,
            },
            locations: [
              {
                city_code: curitiba.cityCode,
                state_code: curitiba.stateCode,
                city: curitiba.city,
                neighborhood: null,
              },
            ],
            normalized_request: "Eu preciso de pintor em Curitiba, PR.",
          },
          interaction: null,
        },
        request_id: "parsed-city-search",
      },
      error: undefined,
      response: new Response(null),
    });
    await useRouter().replace(
      `/encontrar/sc/joinville?q=${encodeSearchExpression("Pintor em Curitiba")}`,
    );
    await clearNuxtData();
    const activeLocation = shallowRef(joinville);

    const search = await useProfessionalSearch({
      location: activeLocation,
      onLocationResolved(nextLocation) {
        activeLocation.value = nextLocation;
      },
    });
    await flushPromises();

    expect(activeLocation.value).toEqual(curitiba);
    await vi.waitFor(() =>
      expect(useRoute().path).toBe("/encontrar/pr/curitiba"),
    );
    expect(useRoute().query.q).toBe(
      encodeSearchExpression("Pintor em Curitiba"),
    );
    expect(search.totalCount.value).toBe(0);
    expect(apiClient.POST).toHaveBeenCalledOnce();
    expect(apiClient.POST).toHaveBeenCalledWith(
      "/api/v1/public/professional-searches",
      {
        body: {
          expression: "Pintor em Curitiba",
          default_location: { city_code: "4209102" },
        },
      },
    );
  });
});
