import type { BerufeApiClient } from "@app/services/api/client";
import {
  createAdminCatalogNeighborhood,
  createAdminCatalogService,
  fetchAdminCatalog,
  mapAdminCatalog,
  reorderAdminCatalogNeighborhoods,
  reorderAdminCatalogServices,
  updateAdminCatalogNeighborhood,
  updateAdminCatalogService,
} from "@app/services/api/admin-catalog";
import type { ApiRequestError } from "@app/services/api/errors";
import type { components } from "@app/services/api/schema";

type AdminCatalogData = components["schemas"]["AdminCatalogData"];

const catalogData: AdminCatalogData = {
  categories: [
    {
      id: "82d70aa7-6ca7-44d0-99d7-c6151804d5d1",
      slug: "instalacoes",
      name: "Instalações",
    },
  ],
  services: [
    {
      id: "de83e041-286f-4b50-91fa-61a0ee8c1801",
      name: "Eletricista",
      slug: "eletricista",
      category_slug: "instalacoes",
      description: "Instalações elétricas.",
      is_active: false,
      sort_order: 0,
    },
  ],
  neighborhoods: [
    {
      code: "america",
      name: "América",
      state_code: "SC",
      city: "Joinville",
      is_active: true,
      sort_order: 0,
    },
  ],
};

function apiClientReturning(result: object) {
  return {
    GET: vi.fn().mockResolvedValue(result),
    POST: vi.fn().mockResolvedValue(result),
    PATCH: vi.fn().mockResolvedValue(result),
    PUT: vi.fn().mockResolvedValue(result),
  } as unknown as BerufeApiClient;
}

const successfulResult = () => ({
  data: { data: catalogData, request_id: "admin-catalog-200" },
  error: undefined,
  response: new Response(null),
});

describe("administrator catalog API", () => {
  it("maps the private contract without deriving the all-city selector", () => {
    expect(mapAdminCatalog(catalogData)).toEqual({
      categories: [{ id: "instalacoes", name: "Instalações" }],
      services: [
        {
          id: "de83e041-286f-4b50-91fa-61a0ee8c1801",
          name: "Eletricista",
          identifier: "eletricista",
          description: "Instalações elétricas.",
          category: "instalacoes",
          active: false,
        },
      ],
      neighborhoods: [
        {
          id: "america",
          name: "América",
          identifier: "america",
          description: "",
          stateCode: "SC",
          city: "Joinville",
          active: true,
        },
      ],
    });
  });

  it("uses every generated management operation with its typed payload", async () => {
    const client = apiClientReturning(successfulResult());
    const serviceId = "de83e041-286f-4b50-91fa-61a0ee8c1801";

    await fetchAdminCatalog(client);
    await createAdminCatalogService(client, {
      name: "Encanador",
      slug: "encanador",
      category_slug: "instalacoes",
      description: "Reparos hidráulicos.",
    });
    await updateAdminCatalogService(client, serviceId, { is_active: false });
    await reorderAdminCatalogServices(client, [serviceId]);
    await createAdminCatalogNeighborhood(client, {
      name: "América",
      code: "america",
      state_code: "SC",
      city: "Joinville",
    });
    await updateAdminCatalogNeighborhood(client, "america", {
      name: "América",
    });
    await reorderAdminCatalogNeighborhoods(client, ["america"]);

    expect(client.GET).toHaveBeenCalledWith("/api/v1/admin/catalog");
    expect(client.POST).toHaveBeenNthCalledWith(
      1,
      "/api/v1/admin/catalog/services",
      {
        body: {
          name: "Encanador",
          slug: "encanador",
          category_slug: "instalacoes",
          description: "Reparos hidráulicos.",
        },
      },
    );
    expect(client.PATCH).toHaveBeenNthCalledWith(
      1,
      "/api/v1/admin/catalog/services/{id}",
      { params: { path: { id: serviceId } }, body: { is_active: false } },
    );
    expect(client.PUT).toHaveBeenNthCalledWith(
      1,
      "/api/v1/admin/catalog/services/order",
      { body: { ids: [serviceId] } },
    );
    expect(client.POST).toHaveBeenNthCalledWith(
      2,
      "/api/v1/admin/catalog/neighborhoods",
      {
        body: {
          name: "América",
          code: "america",
          state_code: "SC",
          city: "Joinville",
        },
      },
    );
    expect(client.PATCH).toHaveBeenNthCalledWith(
      2,
      "/api/v1/admin/catalog/neighborhoods/{code}",
      { params: { path: { code: "america" } }, body: { name: "América" } },
    );
    expect(client.PUT).toHaveBeenNthCalledWith(
      2,
      "/api/v1/admin/catalog/neighborhoods/order",
      { body: { codes: ["america"] } },
    );
  });

  it("normalizes private catalog errors", async () => {
    const client = apiClientReturning({
      data: undefined,
      error: {
        error: {
          code: "catalog_conflict",
          message: "O catálogo foi alterado.",
          request_id: "catalog-409",
        },
      },
      response: new Response(null, {
        headers: { "X-Request-Id": "catalog-409" },
      }),
    });

    await expect(fetchAdminCatalog(client)).rejects.toMatchObject({
      name: "ApiRequestError",
      code: "catalog_conflict",
      requestId: "catalog-409",
    } satisfies Partial<ApiRequestError>);
  });

  it("fails safely when a successful response omits its catalog payload", async () => {
    const client = apiClientReturning({
      data: undefined,
      error: undefined,
      response: new Response(null, {
        headers: { "X-Request-Id": "catalog-missing-data" },
      }),
    });

    await expect(fetchAdminCatalog(client)).rejects.toMatchObject({
      name: "ApiRequestError",
      code: "unexpected_error",
      requestId: "catalog-missing-data",
    } satisfies Partial<ApiRequestError>);
  });
});
