import { clearNuxtData } from "#app";
import { mountSuspended } from "@nuxt/test-utils/runtime";
import { flushPromises } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { useProfessionalSearch } from "@app/composables/useProfessionalSearch";
import { encodeSearchExpression } from "@app/utils/searchExpression";

const apiClient = vi.hoisted(() => ({ POST: vi.fn() }));

vi.mock("@app/services/api/client", () => ({
  useApiClient: () => apiClient,
}));

const expression = "Preciso de eletricista no bairro América";
const location = {
  cityCode: "4209102",
  stateCode: "SC" as const,
  city: "Joinville" as const,
  stateSlug: "sc" as const,
  citySlug: "joinville" as const,
};
const finderPath = "/encontrar/sc/joinville";
const professional = {
  id: "ad59e74a-a1aa-47d5-b725-26350f0f2376",
  public_slug: "ana-souza",
  profile_type: "self_service" as const,
  claimed: true,
  display_name: "Ana Souza",
  headline: "Elétrica residencial.",
  photo_url: null,
  primary_service: {
    id: "c43071a5-4c47-4324-99ef-41846ee35538",
    name: "Eletricista",
    slug: "eletricista",
  },
  matching_service: {
    id: "c43071a5-4c47-4324-99ef-41846ee35538",
    name: "Eletricista",
    slug: "eletricista",
  },
  coverage: {
    city: {
      code: "4209102",
      name: "Joinville",
      slug: "joinville",
      state_code: "42",
      state_abbreviation: "SC",
      state_name: "Santa Catarina",
    },
    whole_city: false,
    neighborhoods: [{ code: "4209102007", name: "América" }],
  },
  verification_labels: [],
  portfolio_count: 2,
  relationship_count: 1,
  public_snapshot_updated_at: "2026-08-17T12:00:00Z",
};

function successfulResponse(
  professionals = [professional],
  totalCount = 1,
  normalizedRequest: string | null = "Eu preciso de eletricista no América.",
  effectiveLocation = {
    city_code: "4209102",
    state_code: "SC",
    city: "Joinville",
    state_slug: "sc",
    city_slug: "joinville",
  },
) {
  return {
    data: {
      data: {
        professionals,
        related_services: [],
        meta: {
          page: 1,
          per_page: 20,
          total_count: totalCount,
          total_pages: totalCount > 20 ? 2 : 1,
        },
        interpretation: {
          services: [
            {
              ...professional.matching_service,
              icon: "i-lucide-zap",
              description: "Instalações elétricas residenciais.",
            },
          ],
          effective_location: effectiveLocation,
          locations: [
            {
              city_code: effectiveLocation.city_code,
              state_code: effectiveLocation.state_code,
              city: effectiveLocation.city,
              neighborhood:
                effectiveLocation.city_code === "4209102"
                  ? { code: "4209102007", name: "América" }
                  : null,
            },
          ],
          normalized_request: normalizedRequest,
        },
        interaction: {
          search_event_id: "8d09847f-14d8-4ef7-80ea-8be6e9eb6d81",
          token: "signed-search-context",
        },
      },
      request_id: "finder-search",
    },
    error: undefined,
    response: new Response(null),
  };
}

function rateLimitedResponse() {
  return {
    data: undefined,
    error: {
      error: {
        code: "public_search_rate_limited",
        message: "Muitas buscas em um período curto.",
        request_id: "rate-limited-search",
      },
    },
    response: new Response(null, { status: 429 }),
  };
}

describe("professional search composable", () => {
  beforeEach(async () => {
    vi.clearAllMocks();
    await clearNuxtData();
    await useRouter().replace("/encontrar");
    await flushPromises();
  });

  it("mounts the search view while its initial request is still pending", async () => {
    let resolveSearch:
      ((response: ReturnType<typeof successfulResponse>) => void) | undefined;
    apiClient.POST.mockImplementation(
      () =>
        new Promise<ReturnType<typeof successfulResponse>>((resolve) => {
          resolveSearch = resolve;
        }),
    );
    await clearNuxtData();

    const SearchViewHarness = defineComponent({
      async setup() {
        const search = await useProfessionalSearch({ location });

        return () =>
          h(
            "p",
            search.isSearching.value ? "Busca em andamento" : "Busca concluída",
          );
      },
    });
    let mounted = false;
    const mounting = mountSuspended(SearchViewHarness, {
      route: `${finderPath}?expressao=${encodeSearchExpression(expression)}`,
    }).then((wrapper) => {
      mounted = true;
      return wrapper;
    });

    try {
      await vi.waitFor(() => expect(apiClient.POST).toHaveBeenCalledOnce(), {
        timeout: 5_000,
      });
      await flushPromises();

      expect(mounted).toBe(true);
      expect((await mounting).text()).toContain("Busca em andamento");
    } finally {
      resolveSearch?.(successfulResponse());
      await mounting;
    }
  });

  it("keeps a first visit idle until an expression is submitted", async () => {
    const search = await useProfessionalSearch({ location });

    expect(search.hasSearchTerm.value).toBe(false);
    expect(search.expressionInput.value).toBe("");
    expect(search.results.value).toEqual([]);
    expect(search.isSearching.value).toBe(false);
    expect(search.status.value).toBe("idle");
    expect(apiClient.POST).not.toHaveBeenCalled();

    await search.submitSearch({ expression: "   " });
    expect(useRoute().query.expressao).toBeUndefined();
  });

  it("decodes the route expression and sends its visible default location to Rails", async () => {
    apiClient.POST.mockResolvedValue(successfulResponse());
    await useRouter().replace(
      `${finderPath}?expressao=${encodeSearchExpression(expression)}`,
    );
    await clearNuxtData();

    const search = await useProfessionalSearch({ location });

    expect(search.expressionInput.value).toBe(expression);
    expect(search.results.value.map((item) => item.name)).toEqual([
      "Ana Souza",
    ]);
    expect(search.interaction.value?.token).toBe("signed-search-context");
    expect(search.interpretation.value).toEqual({
      services: [
        {
          ...professional.matching_service,
          icon: "i-lucide-zap",
          description: "Instalações elétricas residenciais.",
        },
      ],
      effectiveLocation: location,
      locations: [
        {
          cityCode: "4209102",
          stateCode: "SC",
          city: "Joinville",
          neighborhood: { code: "4209102007", name: "América" },
        },
      ],
      normalizedRequest: "Eu preciso de eletricista no América.",
    });
    expect(apiClient.POST).toHaveBeenCalledWith(
      "/api/v1/public/professional-searches",
      {
        body: {
          expression,
          default_location: { city_code: "4209102" },
        },
      },
    );
  });

  it("stores a submitted UTF-8 expression as unpadded Base64URL route state", async () => {
    const search = await useProfessionalSearch({ location });

    await search.submitSearch({ expression: `  ${expression}  ` });

    expect(useRoute().query).toEqual({
      expressao: encodeSearchExpression(expression),
    });
    expect(useRoute().path).toBe(finderPath);
  });

  it("enters the searching state before route navigation completes", async () => {
    const search = await useProfessionalSearch({ location });
    let resolveNavigation: (() => void) | undefined;
    const push = vi.spyOn(useRouter(), "push").mockImplementation(
      () =>
        new Promise<void>((resolve) => {
          resolveNavigation = resolve;
        }),
    );

    try {
      const submission = search.submitSearch({ expression });

      expect(search.isSearching.value).toBe(true);
      expect(push).toHaveBeenCalledOnce();

      resolveNavigation?.();
      await submission;

      expect(search.isSearching.value).toBe(false);
    } finally {
      push.mockRestore();
    }
  });

  it("preserves a rate-limit error code across the Nuxt async-data boundary", async () => {
    apiClient.POST.mockResolvedValue(rateLimitedResponse());
    await useRouter().replace(
      `${finderPath}?expressao=${encodeSearchExpression(expression)}`,
    );
    await clearNuxtData();

    const search = await useProfessionalSearch({ location });

    expect(search.error.value).toEqual({
      code: "public_search_rate_limited",
      message: "Muitas buscas em um período curto.",
      fieldErrors: {},
      requestId: "rate-limited-search",
    });
    expect(search.isSearching.value).toBe(false);
    expect(search.results.value).toEqual([]);
  });

  it("replaces a rate-limited expression with a structured search result", async () => {
    apiClient.POST.mockImplementation(
      (_path: string, request: { body: Record<string, unknown> }) =>
        Promise.resolve(
          "expression" in request.body
            ? rateLimitedResponse()
            : successfulResponse([professional], 1, null),
        ),
    );
    await useRouter().replace(
      `${finderPath}?expressao=${encodeSearchExpression(expression)}`,
    );
    await clearNuxtData();
    const search = await useProfessionalSearch({ location });

    await search.submitStructuredSearch({
      serviceId: professional.matching_service.id,
      serviceName: "Eletricista",
      cityCode: "4106902",
      city: "Curitiba",
      stateCode: "PR",
      stateSlug: "pr",
      citySlug: "curitiba",
    });

    expect(search.expressionInput.value).toBe("Eletricista em Curitiba");
    expect(useRoute().path).toBe("/encontrar/pr/curitiba");
    expect(useRoute().query).toEqual({
      expressao: encodeSearchExpression("Eletricista em Curitiba"),
    });
    expect(search.error.value).toBeNull();
    expect(search.results.value.map((item) => item.name)).toEqual([
      "Ana Souza",
    ]);
    expect(search.interpretation.value?.normalizedRequest).toBeNull();
    expect(apiClient.POST).toHaveBeenCalledWith(
      "/api/v1/public/professional-searches",
      {
        body: {
          service_id: professional.matching_service.id,
          city_code: "4106902",
        },
      },
    );
  });
});
