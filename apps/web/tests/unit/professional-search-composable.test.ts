import { clearNuxtData } from "#app";
import { flushPromises } from "@vue/test-utils";
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
    await flushPromises();
    vi.clearAllMocks();
  });

  it("keeps a first visit idle until a service is submitted", async () => {
    await useRouter().replace("/encontrar");

    const search = await useProfessionalSearch({
      services: [service],
      neighborhoods,
    });

    expect(search.hasSearchTerm.value).toBe(false);
    expect(search.serviceInput.value).toBe("");
    expect(search.results.value).toEqual([]);
    expect(search.selectedService.value).toBeUndefined();
    expect(search.isSearching.value).toBe(false);
    expect(search.status.value).toBe("idle");
    expect(apiClient.POST).not.toHaveBeenCalled();

    await search.submitSearch({
      professionalName: "",
      service: "   ",
      neighborhood: "all",
    });

    expect(useRoute().query.servico).toBeUndefined();
    expect(apiClient.POST).not.toHaveBeenCalled();
  });

  it("loads the route search through Rails and retains its anonymous context", async () => {
    apiClient.POST.mockResolvedValue({
      data: {
        data: {
          query: {
            normalized_term: "eletricista",
            professional_name: "Ana Souza",
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
              public_slug: "ana-souza",
              display_name: "Ana Souza",
              headline: "Elétrica residencial.",
              photo_url: null,
              primary_service: {
                id: service.id,
                name: service.name,
                slug: service.slug,
              },
              matching_service: {
                id: service.id,
                name: service.name,
                slug: service.slug,
              },
              coverage: {
                all_joinville: false,
                neighborhoods: [{ code: "america", name: "América" }],
              },
              verification_labels: [],
              portfolio_count: 2,
              relationship_count: 1,
              public_snapshot_updated_at: "2026-08-17T12:00:00Z",
            },
          ],
          related_services: [],
          meta: { page: 1, per_page: 20, total_count: 1, total_pages: 1 },
          interaction: {
            search_event_id: "8d09847f-14d8-4ef7-80ea-8be6e9eb6d81",
            token: "signed-search-context",
          },
        },
        request_id: "finder-search",
      },
      error: undefined,
      response: new Response(null),
    });
    await useRouter().replace(
      "/encontrar?servico=eletricista&bairro=america&nome=Ana%20Souza",
    );
    await flushPromises();
    await clearNuxtData("public-professional-search");
    vi.clearAllMocks();

    const search = await useProfessionalSearch({
      services: [service],
      neighborhoods,
    });

    expect(search.hasSearchTerm.value).toBe(true);
    expect(search.professionalNameInput.value).toBe("Ana Souza");
    expect(search.isSearching.value).toBe(false);
    expect(search.error.value).toBeUndefined();
    expect(
      search.results.value.map((professional) => professional.name),
    ).toEqual(["Ana Souza"]);
    expect(search.interaction.value?.token).toBe("signed-search-context");
    expect(search.relatedServices.value).toEqual([]);
    expect(apiClient.POST).toHaveBeenCalledWith(
      "/api/v1/public/professional-searches",
      {
        body: {
          service: "eletricista",
          professional_name: "Ana Souza",
          neighborhood_code: "america",
        },
      },
    );
    expect(apiClient.POST).toHaveBeenCalledOnce();

    await useRouter().replace("/encontrar");

    expect(search.hasSearchTerm.value).toBe(false);
    expect(search.professionalNameInput.value).toBe("");
    expect(search.serviceInput.value).toBe("");
    expect(search.results.value).toEqual([]);
    expect(search.interaction.value).toBeNull();
    expect(apiClient.POST).toHaveBeenCalledOnce();
  });

  it("canonicalizes a controlled alias when updating the existing route controls", async () => {
    apiClient.POST.mockResolvedValue({
      data: {
        data: {
          query: {
            normalized_term: "stale-response",
            service: null,
            neighborhood: null,
          },
          professionals: [],
          related_services: [],
          meta: { page: 1, per_page: 20, total_count: 0, total_pages: 0 },
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

    await search.submitSearch({
      professionalName: "  Ana Souza  ",
      service: "  ELÉTRICA!  ",
      neighborhood: "all",
    });

    expect(useRoute().query).toMatchObject({
      servico: "eletricista",
      bairro: "all",
      nome: "Ana Souza",
    });
  });

  it("does not present a stale response for another neighborhood", async () => {
    apiClient.POST.mockResolvedValue({
      data: {
        data: {
          query: {
            normalized_term: "eletricista",
            service: null,
            neighborhood: { code: "centro", name: "Centro" },
          },
          professionals: [],
          related_services: [],
          meta: { page: 1, per_page: 20, total_count: 0, total_pages: 0 },
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
