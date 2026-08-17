import { clearNuxtData } from "#app";
import { useProfessionalSearch } from "@app/composables/useProfessionalSearch";
import type { Neighborhood, Service } from "@app/types";

const apiClient = vi.hoisted(() => ({ POST: vi.fn() }));

vi.mock("@app/services/api/client", () => ({
  useApiClient: () => apiClient,
}));

const service: Service = {
  id: "c43071a5-4c47-4324-99ef-41846ee35538",
  name: "Eletricista",
  slug: "eletricista",
  category: "instalacoes",
  icon: "i-lucide-zap",
  description: "Instalações elétricas residenciais.",
  aliases: ["elétrica"],
};
const neighborhoods: Neighborhood[] = [
  {
    code: "all",
    name: "Toda Joinville",
    stateCode: "SC",
    city: "Joinville",
  },
  {
    code: "america",
    name: "América",
    stateCode: "SC",
    city: "Joinville",
  },
];

describe("professional search composable", () => {
  beforeEach(async () => {
    vi.clearAllMocks();
    await clearNuxtData("public-professional-search");
    await useRouter().replace("/encontrar?servico=eletricista&bairro=america");
  });

  it("loads the route search through Rails and retains its anonymous context", async () => {
    apiClient.POST.mockResolvedValue({
      data: {
        data: {
          query: {
            normalizedTerm: "eletricista",
            service: {
              id: service.id,
              name: service.name,
              slug: service.slug,
              icon: service.icon,
              description: service.description,
            },
            neighborhood: { code: "america", name: "América" },
          },
          professionals: [
            {
              id: "ad59e74a-a1aa-47d5-b725-26350f0f2376",
              publicSlug: "ana-souza",
              displayName: "Ana Souza",
              headline: "Elétrica residencial.",
              photoUrl: null,
              primaryService: {
                id: service.id,
                name: service.name,
                slug: service.slug,
              },
              matchingService: {
                id: service.id,
                name: service.name,
                slug: service.slug,
              },
              coverage: {
                allJoinville: false,
                neighborhoods: [{ code: "america", name: "América" }],
              },
              verificationLabels: [],
              portfolioCount: 2,
              relationshipCount: 1,
              publicSnapshotUpdatedAt: "2026-08-17T12:00:00Z",
            },
          ],
          relatedServices: [],
          interaction: {
            searchEventId: "8d09847f-14d8-4ef7-80ea-8be6e9eb6d81",
            token: "signed-search-context",
          },
        },
        request_id: "finder-search",
      },
      error: undefined,
      response: new Response(null),
    });

    const search = await useProfessionalSearch({
      services: [service],
      neighborhoods,
    });

    expect(search.error.value).toBeUndefined();
    expect(
      search.results.value.map((professional) => professional.name),
    ).toEqual(["Ana Souza"]);
    expect(search.interaction.value?.token).toBe("signed-search-context");
    expect(search.relatedServices.value).toEqual([]);
    expect(apiClient.POST).toHaveBeenCalledWith(
      "/api/v1/public/professional-searches",
      { body: { service: "eletricista", neighborhoodCode: "america" } },
    );
  });

  it("canonicalizes a controlled alias when updating the existing route controls", async () => {
    apiClient.POST.mockResolvedValue({
      data: {
        data: {
          query: {
            normalizedTerm: "stale-response",
            service: null,
            neighborhood: null,
          },
          professionals: [],
          relatedServices: [],
          interaction: null,
        },
        request_id: "finder-empty",
      },
      error: undefined,
      response: new Response(null),
    });
    const search = await useProfessionalSearch({
      services: [service],
      neighborhoods,
    });

    await search.submitSearch({ service: "ELÉTRICA!", neighborhood: "all" });

    expect(useRoute().query).toMatchObject({
      servico: "eletricista",
      bairro: "all",
    });
  });

  it("does not present a stale response for another neighborhood", async () => {
    apiClient.POST.mockResolvedValue({
      data: {
        data: {
          query: {
            normalizedTerm: "eletricista",
            service: null,
            neighborhood: { code: "centro", name: "Centro" },
          },
          professionals: [],
          relatedServices: [],
          interaction: null,
        },
        request_id: "finder-stale-neighborhood",
      },
      error: undefined,
      response: new Response(null),
    });

    const search = await useProfessionalSearch({
      services: [service],
      neighborhoods,
    });

    expect(search.results.value).toEqual([]);
    expect(search.interaction.value).toBeNull();
  });
});
