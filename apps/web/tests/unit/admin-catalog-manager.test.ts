import { mountSuspended } from "@nuxt/test-utils/runtime";
import { flushPromises } from "@vue/test-utils";
import { nextTick, ref, type Ref } from "vue";
import { ApiRequestError } from "@app/services/api/errors";
import type { AdminCatalog } from "@app/types";
import CatalogManager from "~/components/admin/CatalogManager.vue";

interface AdminCatalogMock {
  catalog: Ref<AdminCatalog>;
  isLoading: Ref<boolean>;
  isMutating: Ref<boolean>;
  loadError: Ref<string>;
  load: ReturnType<typeof vi.fn>;
  createService: ReturnType<typeof vi.fn>;
  updateService: ReturnType<typeof vi.fn>;
  reorderServices: ReturnType<typeof vi.fn>;
  createNeighborhood: ReturnType<typeof vi.fn>;
  updateNeighborhood: ReturnType<typeof vi.fn>;
  reorderNeighborhoods: ReturnType<typeof vi.fn>;
}

const mocks = vi.hoisted(() => ({
  state: undefined as AdminCatalogMock | undefined,
  showToast: vi.fn(),
}));

vi.mock("@app/composables/useAdminCatalog", () => ({
  useAdminCatalog: () => mocks.state!,
}));
vi.mock("@app/composables/useToast", () => ({
  useToast: () => ({ showToast: mocks.showToast }),
}));

const initialCatalog = (): AdminCatalog => ({
  categories: [
    { id: "instalacoes", name: "Instalações" },
    { id: "acabamentos", name: "Acabamentos" },
  ],
  services: [
    {
      id: "de83e041-286f-4b50-91fa-61a0ee8c1801",
      name: "Eletricista",
      identifier: "eletricista",
      description: "Instalações elétricas.",
      category: "instalacoes",
      active: true,
    },
    {
      id: "de83e041-286f-4b50-91fa-61a0ee8c1802",
      name: "Pintor",
      identifier: "pintor",
      description: "Pintura residencial.",
      category: "acabamentos",
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
    {
      id: "centro",
      name: "Centro",
      identifier: "centro",
      description: "",
      stateCode: "SC",
      city: "Joinville",
      active: true,
    },
  ],
});

const ModalStub = {
  props: ["open", "title", "description"],
  emits: ["update:open"],
  template:
    '<section v-if="open" role="dialog"><h2>{{ title }}</h2><slot name="body" /></section>',
};
const ButtonStub = {
  props: ["label", "disabled"],
  emits: ["click"],
  template:
    '<button type="button" :disabled="disabled" @click="$emit(\'click\')">{{ label }}<slot /></button>',
};

beforeEach(() => {
  vi.clearAllMocks();
  mocks.state = {
    catalog: ref(initialCatalog()),
    isLoading: ref(false),
    isMutating: ref(false),
    loadError: ref(""),
    load: vi.fn().mockResolvedValue(undefined),
    createService: vi.fn().mockResolvedValue(undefined),
    updateService: vi.fn().mockResolvedValue(undefined),
    reorderServices: vi.fn().mockResolvedValue(undefined),
    createNeighborhood: vi.fn().mockResolvedValue(undefined),
    updateNeighborhood: vi.fn().mockResolvedValue(undefined),
    reorderNeighborhoods: vi.fn().mockResolvedValue(undefined),
  };
});

async function mountManager() {
  const wrapper = await mountSuspended(CatalogManager, {
    global: {
      stubs: {
        UIcon: true,
        UModal: ModalStub,
        UButton: ButtonStub,
      },
    },
  });
  await flushPromises();
  return wrapper;
}

function buttonWithText(
  wrapper: Awaited<ReturnType<typeof mountManager>>,
  text: string,
) {
  const button = wrapper
    .findAll("button")
    .find((candidate) => candidate.text().includes(text));
  if (!button) throw new Error(`Button not found: ${text}`);
  return button;
}

describe("administrator catalog manager", () => {
  it("loads populated forms and filters neighborhoods independently without exposing all-city", async () => {
    const wrapper = await mountManager();

    expect(mocks.state!.load).toHaveBeenCalledOnce();
    expect(wrapper.text()).toContain("Eletricista");
    expect(wrapper.text()).not.toContain("Toda Joinville");

    await buttonWithText(wrapper, "Editar").trigger("click");
    expect(wrapper.get('[role="dialog"]').text()).toContain("Editar serviço");
    expect(wrapper.get('input[name="catalog-name"]').element).toHaveProperty(
      "value",
      "Eletricista",
    );
    await buttonWithText(wrapper, "Cancelar").trigger("click");
    expect(wrapper.find('[role="dialog"]').exists()).toBe(false);

    await buttonWithText(wrapper, "Bairros").trigger("click");
    await wrapper.get('input[name="filter-state-code"]').setValue("sc");
    await wrapper.get('input[name="filter-city"]').setValue("join");
    await wrapper.get('input[name="filter-neighborhood"]').setValue("America");

    expect(wrapper.text()).toContain("América");
    expect(wrapper.text()).not.toContain("Centro");
  });

  it("adds, renames, changes status, and reorders services through the API workflow", async () => {
    const wrapper = await mountManager();

    await buttonWithText(wrapper, "Adicionar entrada").trigger("click");
    await wrapper.get('input[name="catalog-name"]').setValue("Encanador");
    await wrapper.get('input[name="catalog-identifier"]').setValue("encanador");
    await wrapper
      .get('textarea[name="catalog-description"]')
      .setValue("Reparos hidráulicos.");
    await wrapper.get("form").trigger("submit");
    await flushPromises();

    expect(mocks.state!.createService).toHaveBeenCalledWith({
      name: "Encanador",
      slug: "encanador",
      category_slug: "instalacoes",
      description: "Reparos hidráulicos.",
    });
    expect(wrapper.find('[role="dialog"]').exists()).toBe(false);

    await buttonWithText(wrapper, "Editar").trigger("click");
    await wrapper
      .get('input[name="catalog-name"]')
      .setValue("Eletricista residencial");
    await wrapper
      .get('select[name="catalog-category"]')
      .setValue("acabamentos");
    await wrapper.get("form").trigger("submit");
    await flushPromises();
    expect(mocks.state!.updateService).toHaveBeenCalledWith(
      "de83e041-286f-4b50-91fa-61a0ee8c1801",
      {
        name: "Eletricista residencial",
        category_slug: "acabamentos",
        description: "Instalações elétricas.",
      },
    );

    await buttonWithText(wrapper, "Ativo").trigger("click");
    await flushPromises();
    expect(mocks.state!.updateService).toHaveBeenCalledWith(
      "de83e041-286f-4b50-91fa-61a0ee8c1801",
      { is_active: false },
    );

    await wrapper
      .get('button[aria-label="Mover Eletricista para baixo"]')
      .trigger("click");
    await flushPromises();
    expect(mocks.state!.reorderServices).toHaveBeenCalledWith([
      "de83e041-286f-4b50-91fa-61a0ee8c1802",
      "de83e041-286f-4b50-91fa-61a0ee8c1801",
    ]);
  });

  it("suggests a stable neighborhood code and keeps launch location validation in the existing form", async () => {
    const wrapper = await mountManager();
    await buttonWithText(wrapper, "Bairros").trigger("click");
    await buttonWithText(wrapper, "Adicionar entrada").trigger("click");
    await wrapper.get('input[name="catalog-name"]').setValue("Santo Antônio");

    expect(
      wrapper.get('input[name="catalog-identifier"]').element,
    ).toHaveProperty("value", "santo-antonio");
    await wrapper.get('input[name="state-code"]').setValue("RJ");
    await wrapper.get("form").trigger("submit");

    expect(mocks.state!.createNeighborhood).not.toHaveBeenCalled();
    expect(mocks.showToast).toHaveBeenCalledWith(
      expect.objectContaining({ title: "Localidade inválida" }),
    );

    await wrapper.get('input[name="state-code"]').setValue("SC");
    await wrapper.get("form").trigger("submit");
    await flushPromises();
    expect(mocks.state!.createNeighborhood).toHaveBeenCalledWith({
      name: "Santo Antônio",
      code: "santo-antonio",
      state_code: "SC",
      city: "Joinville",
    });
  });

  it("renames, changes status, and reorders neighborhoods", async () => {
    const wrapper = await mountManager();
    await buttonWithText(wrapper, "Bairros").trigger("click");

    await buttonWithText(wrapper, "Editar").trigger("click");
    await wrapper.get('input[name="catalog-name"]').setValue("América Norte");
    await wrapper.get("form").trigger("submit");
    await flushPromises();
    expect(mocks.state!.updateNeighborhood).toHaveBeenCalledWith("america", {
      name: "América Norte",
      state_code: "SC",
      city: "Joinville",
    });

    await buttonWithText(wrapper, "Ativo").trigger("click");
    await flushPromises();
    expect(mocks.state!.updateNeighborhood).toHaveBeenCalledWith("america", {
      is_active: false,
    });

    await wrapper
      .get('button[aria-label="Mover América para baixo"]')
      .trigger("click");
    await flushPromises();
    expect(mocks.state!.reorderNeighborhoods).toHaveBeenCalledWith([
      "centro",
      "america",
    ]);
  });

  it("rejects duplicate identifiers and incomplete service data locally", async () => {
    const wrapper = await mountManager();
    await buttonWithText(wrapper, "Adicionar entrada").trigger("click");
    await wrapper.get('input[name="catalog-name"]').setValue("Outra entrada");
    await wrapper
      .get('input[name="catalog-identifier"]')
      .setValue("eletricista");
    await wrapper.get("form").trigger("submit");

    expect(mocks.state!.createService).not.toHaveBeenCalled();
    expect(mocks.showToast).toHaveBeenCalledWith(
      expect.objectContaining({ title: "Identificador já utilizado" }),
    );

    await wrapper
      .get('input[name="catalog-identifier"]')
      .setValue("outra-entrada");
    await wrapper.get('select[name="catalog-category"]').setValue("");
    await wrapper.get("form").trigger("submit");

    expect(mocks.state!.createService).not.toHaveBeenCalled();
    expect(mocks.showToast).toHaveBeenCalledWith(
      expect.objectContaining({ title: "Revise os campos informados" }),
    );
  });

  it("renders retry and safe mutation errors without closing the populated catalog", async () => {
    const wrapper = await mountManager();
    mocks.state!.loadError.value = "Catálogo temporariamente indisponível.";
    await nextTick();

    expect(wrapper.get('[role="alert"]').text()).toContain(
      "Catálogo temporariamente indisponível.",
    );
    await buttonWithText(wrapper, "Tentar novamente").trigger("click");
    expect(mocks.state!.load).toHaveBeenCalledTimes(2);

    mocks.state!.loadError.value = "";
    mocks.state!.updateService.mockRejectedValueOnce(
      new ApiRequestError({
        code: "validation_failed",
        message: "Revise os campos informados.",
        fieldErrors: { name: ["não pode ficar em branco"] },
        requestId: "catalog-422",
      }),
    );
    await nextTick();
    await buttonWithText(wrapper, "Ativo").trigger("click");
    await flushPromises();

    expect(mocks.showToast).toHaveBeenCalledWith({
      title: "Não foi possível atualizar",
      description: "não pode ficar em branco",
    });
    expect(wrapper.text()).toContain("Eletricista");
  });

  it("refreshes stale catalog state after a conflict", async () => {
    const wrapper = await mountManager();
    mocks.state!.reorderServices.mockRejectedValueOnce(
      new ApiRequestError({
        code: "catalog_conflict",
        message: "O catálogo foi alterado.",
        fieldErrors: {},
        requestId: "catalog-409",
      }),
    );

    await wrapper
      .get('button[aria-label="Mover Eletricista para baixo"]')
      .trigger("click");
    await flushPromises();

    expect(mocks.showToast).toHaveBeenCalledWith({
      title: "Catálogo desatualizado",
      description: "O catálogo foi alterado.",
    });
    expect(mocks.state!.load).toHaveBeenCalledTimes(2);
  });
});
