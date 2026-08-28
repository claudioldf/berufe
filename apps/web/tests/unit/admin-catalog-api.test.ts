import type { BerufeApiClient } from "@app/services/api/client";
import {
  createAdminCatalogService,
  fetchAdminCatalog,
  mapAdminCatalog,
  reorderAdminCatalogServices,
  updateAdminCatalogService,
} from "@app/services/api/admin-catalog";
import type { components } from "@app/services/api/schema";

type AdminCatalogData = components["schemas"]["AdminCatalogData"];
const serviceId = "de83e041-286f-4b50-91fa-61a0ee8c1801";
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
      id: serviceId,
      name: "Eletricista",
      slug: "eletricista",
      category_slug: "instalacoes",
      description: "Instalações elétricas.",
      is_active: true,
      sort_order: 0,
    },
  ],
};

function client() {
  const result = {
    data: { data: catalogData, request_id: "catalog-200" },
    response: new Response(null),
  };
  return {
    GET: vi.fn().mockResolvedValue(result),
    POST: vi.fn().mockResolvedValue(result),
    PATCH: vi.fn().mockResolvedValue(result),
    PUT: vi.fn().mockResolvedValue(result),
  } as unknown as BerufeApiClient;
}

describe("administrator service catalog API", () => {
  it("maps only import-independent service data", () => {
    expect(mapAdminCatalog(catalogData)).toEqual({
      categories: [{ id: "instalacoes", name: "Instalações" }],
      services: [
        {
          id: serviceId,
          name: "Eletricista",
          identifier: "eletricista",
          description: "Instalações elétricas.",
          category: "instalacoes",
          active: true,
        },
      ],
    });
  });

  it("uses the generated service-management operations", async () => {
    const api = client();
    await fetchAdminCatalog(api);
    await createAdminCatalogService(api, {
      name: "Encanador",
      slug: "encanador",
      category_slug: "instalacoes",
      description: "Reparos hidráulicos.",
    });
    await updateAdminCatalogService(api, serviceId, { is_active: false });
    await reorderAdminCatalogServices(api, [serviceId]);

    expect(api.GET).toHaveBeenCalledWith("/api/v1/admin/catalog");
    expect(api.POST).toHaveBeenCalledWith("/api/v1/admin/catalog/services", {
      body: expect.objectContaining({ slug: "encanador" }),
    });
    expect(api.PATCH).toHaveBeenCalledWith(
      "/api/v1/admin/catalog/services/{id}",
      { params: { path: { id: serviceId } }, body: { is_active: false } },
    );
    expect(api.PUT).toHaveBeenCalledWith(
      "/api/v1/admin/catalog/services/order",
      { body: { ids: [serviceId] } },
    );
  });
});
