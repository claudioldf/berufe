import { mount } from "@vue/test-utils";
import { defineComponent, nextTick } from "vue";
import PortfolioManager from "~/components/dashboard/PortfolioManager.vue";
import PortfolioUploadForm from "~/components/dashboard/portfolio/UploadForm.vue";
import type { ProfessionalPortfolioItem } from "~/types";

const portfolioItem: ProfessionalPortfolioItem = {
  id: "portfolio-1",
  title: "Cozinha iluminada",
  service: "Eletricista",
  description: "Instalação completa.",
  image: null,
  submittedAt: "2026-08-17T12:00:00Z",
};
const TooltipStub = defineComponent({
  props: { reason: { type: String, default: null } },
  template: `<div :data-tooltip-reason="reason ?? ''"><slot /></div>`,
});

describe("professional portfolio manager", () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("previews a selected image in the add-work form", async () => {
    vi.spyOn(URL, "createObjectURL").mockReturnValue("blob:portfolio-preview");
    const wrapper = mount(PortfolioUploadForm, {
      props: { serviceOptions: ["Eletricista"] },
    });
    const file = new File(["portfolio photo"], "cozinha.png", {
      type: "image/png",
    });
    const input = wrapper.get('input[name="portfolio-image"]');
    Object.defineProperty(input.element, "files", { value: [file] });

    await input.trigger("change");

    const preview = wrapper.get('img[alt="Prévia de cozinha.png"]');
    expect(preview.attributes("src")).toBe("blob:portfolio-preview");
    expect(wrapper.text()).toContain("cozinha.png");
  });

  it("reveals required errors and focuses the first field after submit", async () => {
    const wrapper = mount(PortfolioUploadForm, {
      attachTo: document.body,
      props: { serviceOptions: [] },
    });
    const submit = wrapper
      .findAll("button")
      .find((button) => button.text().includes("Adicionar ao perfil"));

    expect(submit?.attributes("disabled")).toBeUndefined();
    await wrapper.get("form").trigger("submit");
    await nextTick();

    const file = wrapper.get<HTMLInputElement>('input[name="portfolio-image"]');
    expect(wrapper.text()).toContain("Selecione uma imagem JPG ou PNG.");
    expect(wrapper.text()).toContain("Informe o título do trabalho.");
    expect(file.attributes("aria-invalid")).toBe("true");
    expect(document.activeElement).toBe(file.element);
    expect(wrapper.emitted("submitted")).toBeUndefined();
    wrapper.unmount();
  });

  it("prefills edit fields and submits without requiring a replacement image", async () => {
    const wrapper = mount(PortfolioUploadForm, {
      props: {
        serviceOptions: ["Eletricista", "Pintor"],
        imageRequired: false,
        initialValues: portfolioItem,
        submitLabel: "Salvar alterações",
      },
    });

    expect(
      wrapper.get<HTMLInputElement>('input[name="portfolio-title"]').element
        .value,
    ).toBe("Cozinha iluminada");
    expect(
      wrapper.get<HTMLSelectElement>('select[name="portfolio-service"]').element
        .value,
    ).toBe("Eletricista");
    expect(
      wrapper.get<HTMLTextAreaElement>('textarea[name="portfolio-description"]')
        .element.value,
    ).toBe("Instalação completa.");
    expect(wrapper.text()).toContain("mantenha a foto atual");

    await wrapper.get("form").trigger("submit");

    expect(wrapper.emitted("submitted")?.[0]).toEqual([
      {
        file: null,
        title: "Cozinha iluminada",
        service: "Eletricista",
        description: "Instalação completa.",
      },
    ]);
  });

  it("explains disabled portfolio actions while a work item is saved", () => {
    const wrapper = mount(PortfolioUploadForm, {
      props: {
        serviceOptions: ["Eletricista"],
        showCancel: true,
        submitting: true,
      },
      global: {
        stubs: { DesignSystemDisabledTooltip: TooltipStub },
      },
    });

    for (const button of wrapper.findAll("button")) {
      expect(button.attributes("disabled")).toBeDefined();
      expect(
        button.element
          .closest("[data-tooltip-reason]")
          ?.getAttribute("data-tooltip-reason"),
      ).toBe("Aguarde o salvamento do trabalho terminar.");
    }
  });

  it("explains the value of a portfolio and opens the first upload", async () => {
    const wrapper = mount(PortfolioManager, {
      props: { items: [], serviceOptions: ["Eletricista"] },
    });

    expect(wrapper.text()).toContain(
      "Mostre resultados antes mesmo da conversa.",
    );
    expect(wrapper.text()).toContain(
      "Imagens em destaque no seu perfil público",
    );
    expect(wrapper.text()).toContain("Meus trabalhos");
    expect(wrapper.text()).not.toContain("Seu trabalho na prática");
    expect(wrapper.find(".portfolio-manager__grid").exists()).toBe(false);

    const firstUpload = wrapper
      .findAll("button")
      .find((button) =>
        button.text().includes("Adicionar meu primeiro trabalho"),
      );
    expect(firstUpload).toBeDefined();
    await firstUpload!.trigger("click");
    expect(wrapper.getComponent({ name: "UModal" }).props("open")).toBe(true);
  });

  it("renders the Rails public-image URL in the existing card", () => {
    const publishedItem: ProfessionalPortfolioItem = {
      ...portfolioItem,
      id: "portfolio-published",
      image:
        "http://localhost:3001/api/v1/public/portfolio-items/portfolio-published/image",
    };
    const wrapper = mount(PortfolioManager, {
      props: { items: [publishedItem], serviceOptions: ["Eletricista"] },
    });

    expect(wrapper.get("article img").attributes("src")).toBe(
      publishedItem.image,
    );
    expect(wrapper.text()).not.toContain("Aprovado");
    expect(wrapper.get("h2").text()).toBe("Meus trabalhos");
  });

  it("renders portfolio items without moderation states", () => {
    const items: ProfessionalPortfolioItem[] = [
      {
        ...portfolioItem,
        id: "portfolio-one",
        title: "Primeiro trabalho",
      },
      {
        ...portfolioItem,
        id: "portfolio-two",
        title: "Segundo trabalho",
      },
    ];
    const wrapper = mount(PortfolioManager, {
      props: { items, serviceOptions: ["Eletricista"] },
    });

    expect(wrapper.text()).toContain("Primeiro trabalho");
    expect(wrapper.text()).toContain("Segundo trabalho");
    expect(wrapper.text()).not.toMatch(/Em análise|Aprovado|Recusado|Oculto/);
    expect(wrapper.find(".portfolio-manager__status").exists()).toBe(false);
  });

  it("uses the existing card action for soft deletion", async () => {
    const wrapper = mount(PortfolioManager, {
      props: { items: [portfolioItem], serviceOptions: ["Eletricista"] },
    });

    expect(wrapper.find("article img").exists()).toBe(false);

    await wrapper
      .get('button[aria-label="Excluir Cozinha iluminada"]')
      .trigger("click");
    expect(wrapper.emitted("removed")?.[0]).toEqual(["portfolio-1"]);
  });

  it("edits the existing item in place", async () => {
    const wrapper = mount(PortfolioManager, {
      props: {
        items: [portfolioItem],
        serviceOptions: ["Eletricista"],
      },
    });
    const editButton = wrapper
      .findAll("button")
      .find((button) => button.text().includes("Editar"));

    expect(editButton).toBeDefined();
    await editButton!.trigger("click");

    const editModal = wrapper
      .findAllComponents({ name: "UModal" })
      .find((modal) => modal.props("title") === "Editar trabalho");
    const editForm = wrapper
      .findAllComponents(PortfolioUploadForm)
      .find((form) => form.props("submitLabel") === "Salvar alterações");
    expect(editModal?.props("open")).toBe(true);
    expect(editForm?.props("initialValues")).toMatchObject({
      title: "Cozinha iluminada",
      service: "Eletricista",
      description: "Instalação completa.",
    });

    const description = editForm!.get<HTMLTextAreaElement>(
      'textarea[name="portfolio-description"]',
    );
    await description.setValue("Descrição corrigida.");
    await editForm!.get("form").trigger("submit");

    expect(wrapper.emitted("updated")?.[0]).toEqual([
      "portfolio-1",
      {
        file: null,
        title: "Cozinha iluminada",
        service: "Eletricista",
        description: "Descrição corrigida.",
      },
    ]);
    expect(editModal?.props("open")).toBe(true);
    expect(description.element.value).toBe("Descrição corrigida.");

    editModal?.vm.$emit("update:open", false);
    await nextTick();
    expect(wrapper.emitted("editClosed")).toHaveLength(1);
  });

  it("opens an item from the dashboard deep link", () => {
    const wrapper = mount(PortfolioManager, {
      props: {
        items: [portfolioItem],
        serviceOptions: ["Eletricista"],
        initialEditItemId: portfolioItem.id,
      },
    });
    const editModal = wrapper
      .findAllComponents({ name: "UModal" })
      .find((modal) => modal.props("title") === "Editar trabalho");

    expect(editModal?.props("open")).toBe(true);
  });

  it("explains that new items and edits are immediate", () => {
    const wrapper = mount(PortfolioManager, {
      props: {
        items: [portfolioItem],
        serviceOptions: ["Eletricista"],
      },
    });

    expect(wrapper.text()).toContain("alterações aparecem imediatamente");
  });
});
