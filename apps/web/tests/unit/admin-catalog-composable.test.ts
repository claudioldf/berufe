import { useAdminCatalog } from "@app/composables/useAdminCatalog";
import type { AdminCatalog } from "@app/types";

const apiMocks = vi.hoisted(() => ({
  fetchAdminCatalog: vi.fn(),
  createAdminCatalogService: vi.fn(),
  updateAdminCatalogService: vi.fn(),
  reorderAdminCatalogServices: vi.fn(),
  createAdminCatalogNeighborhood: vi.fn(),
  updateAdminCatalogNeighborhood: vi.fn(),
  reorderAdminCatalogNeighborhoods: vi.fn(),
}));

vi.mock("@app/services/api/client", () => ({
  useApiClient: () => ({}),
}));

vi.mock("@app/services/api/admin-catalog", () => apiMocks);

const catalog = (serviceName: string): AdminCatalog => ({
  categories: [{ id: "instalacoes", name: "Instalações" }],
  services: [
    {
      id: "de83e041-286f-4b50-91fa-61a0ee8c1801",
      name: serviceName,
      identifier: "eletricista",
      description: "Instalações elétricas.",
      category: "instalacoes",
      active: true,
    },
  ],
  neighborhoods: [],
});

describe("administrator catalog composable", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("owns loading and mutation state and invalidates the shared public catalog", async () => {
    const load = vi.fn().mockResolvedValue(catalog("Eletricista"));
    const createService = vi
      .fn()
      .mockResolvedValue(catalog("Eletricista residencial"));
    const invalidatePublicCatalog = vi.fn().mockResolvedValue(undefined);
    const adminCatalog = useAdminCatalog({
      load,
      createService,
      invalidatePublicCatalog,
    });

    await adminCatalog.load();
    expect(adminCatalog.catalog.value.services[0]?.name).toBe("Eletricista");
    expect(adminCatalog.isLoading.value).toBe(false);

    await adminCatalog.createService({
      name: "Eletricista residencial",
      slug: "eletricista-residencial",
      categorySlug: "instalacoes",
      description: "Instalações elétricas residenciais.",
    });

    expect(adminCatalog.catalog.value.services[0]?.name).toBe(
      "Eletricista residencial",
    );
    expect(adminCatalog.isMutating.value).toBe(false);
    expect(invalidatePublicCatalog).toHaveBeenCalledOnce();
  });

  it("retains a safe load error and releases loading state", async () => {
    const adminCatalog = useAdminCatalog({
      load: vi.fn().mockRejectedValue(new Error("Catálogo indisponível.")),
    });

    await expect(adminCatalog.load()).rejects.toThrow("Catálogo indisponível.");
    expect(adminCatalog.loadError.value).toBe("Catálogo indisponível.");
    expect(adminCatalog.isLoading.value).toBe(false);
  });

  it("uses the safe fallback for an untyped load failure", async () => {
    const adminCatalog = useAdminCatalog({
      load: vi.fn().mockRejectedValue("offline"),
    });

    await expect(adminCatalog.load()).rejects.toBe("offline");
    expect(adminCatalog.loadError.value).toBe(
      "Não foi possível carregar o catálogo.",
    );
  });

  it("delegates every mutation and releases state after a failure", async () => {
    const updated = catalog("Atualizado");
    const dependencies = {
      updateService: vi.fn().mockResolvedValue(updated),
      reorderServices: vi.fn().mockResolvedValue(updated),
      createNeighborhood: vi.fn().mockResolvedValue(updated),
      updateNeighborhood: vi.fn().mockResolvedValue(updated),
      reorderNeighborhoods: vi.fn().mockResolvedValue(updated),
      invalidatePublicCatalog: vi.fn().mockResolvedValue(undefined),
    };
    const adminCatalog = useAdminCatalog(dependencies);

    await adminCatalog.updateService("service-id", { isActive: false });
    await adminCatalog.reorderServices(["service-id"]);
    await adminCatalog.createNeighborhood({
      name: "América",
      code: "america",
      stateCode: "SC",
      city: "Joinville",
    });
    await adminCatalog.updateNeighborhood("america", { isActive: false });
    await adminCatalog.reorderNeighborhoods(["america"]);

    expect(dependencies.updateService).toHaveBeenCalledWith("service-id", {
      isActive: false,
    });
    expect(dependencies.reorderServices).toHaveBeenCalledWith(["service-id"]);
    expect(dependencies.createNeighborhood).toHaveBeenCalledWith({
      name: "América",
      code: "america",
      stateCode: "SC",
      city: "Joinville",
    });
    expect(dependencies.updateNeighborhood).toHaveBeenCalledWith("america", {
      isActive: false,
    });
    expect(dependencies.reorderNeighborhoods).toHaveBeenCalledWith(["america"]);

    dependencies.updateService.mockRejectedValueOnce(new Error("conflict"));
    await expect(
      adminCatalog.updateService("service-id", { name: "Conflito" }),
    ).rejects.toThrow("conflict");
    expect(adminCatalog.isMutating.value).toBe(false);
  });

  it("suppresses concurrent loads and mutations", async () => {
    let resolveLoad!: (value: AdminCatalog) => void;
    let resolveMutation!: (value: AdminCatalog) => void;
    const load = vi.fn(
      () =>
        new Promise<AdminCatalog>((resolve) => {
          resolveLoad = resolve;
        }),
    );
    const createService = vi.fn(
      () =>
        new Promise<AdminCatalog>((resolve) => {
          resolveMutation = resolve;
        }),
    );
    const adminCatalog = useAdminCatalog({
      load,
      createService,
      invalidatePublicCatalog: vi.fn().mockResolvedValue(undefined),
    });

    const firstLoad = adminCatalog.load();
    await adminCatalog.load();
    expect(load).toHaveBeenCalledOnce();
    resolveLoad(catalog("Eletricista"));
    await firstLoad;

    const input = {
      name: "Eletricista",
      slug: "eletricista",
      categorySlug: "instalacoes",
      description: "Instalações elétricas.",
    };
    const firstMutation = adminCatalog.createService(input);
    await adminCatalog.createService(input);
    expect(createService).toHaveBeenCalledOnce();
    resolveMutation(catalog("Eletricista"));
    await firstMutation;
  });

  it("binds the default typed API operations and clears the public cache", async () => {
    for (const operation of Object.values(apiMocks)) {
      operation.mockResolvedValue(catalog("Eletricista"));
    }
    const adminCatalog = useAdminCatalog();
    const serviceInput = {
      name: "Eletricista",
      slug: "eletricista",
      categorySlug: "instalacoes",
      description: "Instalações elétricas.",
    };

    await adminCatalog.load();
    await adminCatalog.createService(serviceInput);
    await adminCatalog.updateService("service-id", { name: "Eletricista" });
    await adminCatalog.reorderServices(["service-id"]);
    await adminCatalog.createNeighborhood({
      name: "América",
      code: "america",
      stateCode: "SC",
      city: "Joinville",
    });
    await adminCatalog.updateNeighborhood("america", { name: "América" });
    await adminCatalog.reorderNeighborhoods(["america"]);

    expect(apiMocks.fetchAdminCatalog).toHaveBeenCalledOnce();
    expect(apiMocks.createAdminCatalogService).toHaveBeenCalledWith(
      expect.anything(),
      serviceInput,
    );
    expect(apiMocks.updateAdminCatalogService).toHaveBeenCalledWith(
      expect.anything(),
      "service-id",
      { name: "Eletricista" },
    );
    expect(apiMocks.reorderAdminCatalogServices).toHaveBeenCalledWith(
      expect.anything(),
      ["service-id"],
    );
    expect(apiMocks.createAdminCatalogNeighborhood).toHaveBeenCalledOnce();
    expect(apiMocks.updateAdminCatalogNeighborhood).toHaveBeenCalledOnce();
    expect(apiMocks.reorderAdminCatalogNeighborhoods).toHaveBeenCalledOnce();
  });
});
