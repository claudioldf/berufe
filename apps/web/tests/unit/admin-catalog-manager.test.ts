import { mountSuspended } from "@nuxt/test-utils/runtime";
import { flushPromises } from "@vue/test-utils";
import { ref } from "vue";
import CatalogManager from "~/components/admin/CatalogManager.vue";

const mocks = vi.hoisted(() => ({
  createService: vi.fn(),
  load: vi.fn(),
}));
vi.mock("@app/composables/useAdminCatalog", () => ({
  useAdminCatalog: () => ({
    catalog: ref({
      categories: [{ id: "instalacoes", name: "Instalações" }],
      services: [
        {
          id: "service-id",
          name: "Eletricista",
          identifier: "eletricista",
          description: "Instalações elétricas.",
          category: "instalacoes",
          active: true,
        },
      ],
    }),
    isLoading: ref(false),
    isMutating: ref(false),
    loadError: ref(""),
    load: mocks.load,
    createService: mocks.createService,
    updateService: vi.fn(),
    reorderServices: vi.fn(),
  }),
}));
vi.mock("@app/composables/useToast", () => ({
  useToast: () => ({ showToast: vi.fn() }),
}));

describe("administrator service catalog manager", () => {
  it("loads services and explains that IBGE manages locations", async () => {
    const wrapper = await mountSuspended(CatalogManager, {
      global: { stubs: { UIcon: true, UButton: true, UModal: true } },
    });
    await flushPromises();

    expect(mocks.load).toHaveBeenCalledOnce();
    expect(wrapper.text()).toContain("Eletricista");
    expect(wrapper.text()).toContain("importação do IBGE");
    expect(wrapper.text()).not.toContain("Toda Joinville");
  });
});
