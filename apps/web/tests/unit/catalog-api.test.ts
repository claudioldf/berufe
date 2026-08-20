import type { BerufeApiClient } from "@app/services/api/client";
import {
  fetchPublicCatalog,
  mapPublicCatalog,
} from "@app/services/api/catalog";
import type { ApiRequestError } from "@app/services/api/errors";
import type { components } from "@app/services/api/schema";

type CatalogData = components["schemas"]["CatalogData"];

const catalogData: CatalogData = {
  categories: [
    {
      id: "82d70aa7-6ca7-44d0-99d7-c6151804d5d1",
      slug: "instalacoes",
      name: "Instalações",
      icon: "i-lucide-wrench",
    },
  ],
  services: [
    {
      id: "de83e041-286f-4b50-91fa-61a0ee8c1801",
      name: "Eletricista",
      slug: "eletricista",
      category_slug: "instalacoes",
      icon: "i-lucide-zap",
      description: "Instalações elétricas.",
      aliases: ["elétrica"],
    },
  ],
  neighborhoods: [
    {
      code: "america",
      name: "América",
      state_code: "SC",
      city: "Joinville",
    },
  ],
};

function apiClientReturning(result: object) {
  return {
    GET: vi.fn().mockResolvedValue(result),
  } as unknown as BerufeApiClient;
}

describe("public catalog API", () => {
  it("maps the contracted catalog into the existing mockup domain shape", () => {
    expect(mapPublicCatalog(catalogData)).toEqual({
      categories: [
        {
          id: "instalacoes",
          name: "Instalações",
          icon: "i-lucide-wrench",
        },
      ],
      services: [
        {
          id: "de83e041-286f-4b50-91fa-61a0ee8c1801",
          name: "Eletricista",
          slug: "eletricista",
          category: "instalacoes",
          icon: "i-lucide-zap",
          description: "Instalações elétricas.",
          aliases: ["elétrica"],
        },
      ],
      neighborhoods: [
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
      ],
    });
  });

  it("loads the catalog through the generated client operation", async () => {
    const client = apiClientReturning({
      data: { data: catalogData, request_id: "catalog-200" },
      error: undefined,
      response: new Response(null),
    });

    const catalog = await fetchPublicCatalog(client);

    expect(catalog.services[0]?.slug).toBe("eletricista");
    expect(client.GET).toHaveBeenCalledWith("/api/v1/catalog");
  });

  it("normalizes a contracted API error", async () => {
    const client = apiClientReturning({
      data: undefined,
      error: {
        error: {
          code: "service_unavailable",
          message: "Serviço temporariamente indisponível.",
          request_id: "catalog-503",
        },
      },
      response: new Response(null, {
        headers: { "X-Request-Id": "catalog-503" },
      }),
    });

    await expect(fetchPublicCatalog(client)).rejects.toMatchObject({
      name: "ApiRequestError",
      code: "service_unavailable",
      requestId: "catalog-503",
    } satisfies Partial<ApiRequestError>);
  });

  it("uses the safe fallback when a successful response has no data", async () => {
    const client = apiClientReturning({
      data: undefined,
      error: undefined,
      response: new Response(null),
    });

    await expect(fetchPublicCatalog(client)).rejects.toMatchObject({
      name: "ApiRequestError",
      code: "unexpected_error",
      requestId: "client",
    } satisfies Partial<ApiRequestError>);
  });
});
