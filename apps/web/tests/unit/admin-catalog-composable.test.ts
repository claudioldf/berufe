import { useAdminCatalog } from "@app/composables/useAdminCatalog";
import type { AdminCatalog } from "@app/types";

vi.mock("@app/services/api/client", () => ({ useApiClient: () => ({}) }));

const catalog = (name: string): AdminCatalog => ({
  categories: [{ id: "instalacoes", name: "Instalações" }],
  services: [
    {
      id: "service-id",
      name,
      identifier: "eletricista",
      description: "Instalações elétricas.",
      category: "instalacoes",
      active: true,
    },
  ],
});

describe("administrator service catalog composable", () => {
  it("owns loading and service mutation state", async () => {
    const load = vi.fn().mockResolvedValue(catalog("Eletricista"));
    const updateService = vi
      .fn()
      .mockResolvedValue(catalog("Eletricista residencial"));
    const invalidatePublicCatalog = vi.fn().mockResolvedValue(undefined);
    const subject = useAdminCatalog({
      load,
      updateService,
      invalidatePublicCatalog,
    });

    await subject.load();
    await subject.updateService("service-id", {
      name: "Eletricista residencial",
    });

    expect(subject.catalog.value.services[0]?.name).toBe(
      "Eletricista residencial",
    );
    expect(subject.isLoading.value).toBe(false);
    expect(subject.isMutating.value).toBe(false);
    expect(updateService).toHaveBeenCalledWith("service-id", {
      name: "Eletricista residencial",
    });
    expect(invalidatePublicCatalog).toHaveBeenCalledOnce();
  });

  it("retains a safe load error and releases state", async () => {
    const subject = useAdminCatalog({
      load: vi.fn().mockRejectedValue(new Error("Catálogo indisponível.")),
    });
    await expect(subject.load()).rejects.toThrow("Catálogo indisponível.");
    expect(subject.loadError.value).toBe("Catálogo indisponível.");
    expect(subject.isLoading.value).toBe(false);
  });
});
