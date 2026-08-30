import { mount } from "@vue/test-utils";
import { nextTick } from "vue";
import PortfolioManager from "~/components/dashboard/PortfolioManager.vue";
import PortfolioUploadForm from "~/components/dashboard/portfolio/UploadForm.vue";
import type { ProfessionalPortfolioItem } from "~/types";

const rejectedItem: ProfessionalPortfolioItem = {
  id: "portfolio-1",
  title: "Cozinha iluminada",
  service: "Eletricista",
  description: "Instalação completa.",
  image: null,
  status: "rejected",
  rejectionReason: "A imagem está desfocada.",
  submittedAt: "2026-08-17T12:00:00Z",
};

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

  it("renders the approved Rails public-image URL in the existing card", () => {
    const approvedItem: ProfessionalPortfolioItem = {
      ...rejectedItem,
      id: "portfolio-approved",
      image:
        "http://localhost:3001/api/v1/public/portfolio-items/portfolio-approved/image",
      status: "approved",
      rejectionReason: null,
    };
    const wrapper = mount(PortfolioManager, {
      props: { items: [approvedItem], serviceOptions: ["Eletricista"] },
    });

    expect(wrapper.get("article img").attributes("src")).toBe(
      approvedItem.image,
    );
    expect(wrapper.text()).not.toContain("Aprovado");
    expect(wrapper.get("h2").text()).toBe("Meus trabalhos");
  });

  it("hides status labels unless the portfolio item was rejected", () => {
    const items: ProfessionalPortfolioItem[] = [
      {
        ...rejectedItem,
        id: "portfolio-pending",
        title: "Trabalho pendente",
        status: "pending_review",
        rejectionReason: null,
      },
      {
        ...rejectedItem,
        id: "portfolio-approved",
        title: "Trabalho aprovado",
        status: "approved",
        rejectionReason: null,
      },
      {
        ...rejectedItem,
        id: "portfolio-hidden",
        title: "Trabalho oculto",
        status: "hidden",
        rejectionReason: null,
      },
      rejectedItem,
    ];
    const wrapper = mount(PortfolioManager, {
      props: { items, serviceOptions: ["Eletricista"] },
    });

    expect(wrapper.text()).not.toContain("Em análise");
    expect(wrapper.text()).not.toContain("Aprovado");
    expect(wrapper.text()).not.toContain("Oculto");
    expect(wrapper.findAll(".portfolio-manager__status")).toHaveLength(1);
    expect(wrapper.get(".portfolio-manager__status").text()).toBe("Recusado");
  });

  it("shows private owner status and uses the existing card action for soft deletion", async () => {
    const wrapper = mount(PortfolioManager, {
      props: { items: [rejectedItem], serviceOptions: ["Eletricista"] },
    });

    expect(wrapper.text()).toContain("Recusado");
    expect(wrapper.get(".portfolio-manager__reason strong").text()).toBe(
      "Motivo:",
    );
    expect(wrapper.get(".portfolio-manager__reason").text()).toContain(
      "A imagem está desfocada.",
    );
    expect(wrapper.find(".portfolio-manager__reason-toggle").exists()).toBe(
      false,
    );
    expect(wrapper.find("article img").exists()).toBe(false);

    await wrapper
      .get('button[aria-label="Excluir Cozinha iluminada"]')
      .trigger("click");
    expect(wrapper.emitted("removed")?.[0]).toEqual(["portfolio-1"]);
  });

  it("expands and collapses a long rejection reason", async () => {
    const longReason =
      "A imagem está desfocada e não permite avaliar com clareza a qualidade do acabamento, os detalhes da instalação e o resultado final apresentado. Envie uma nova foto com boa iluminação.";
    const wrapper = mount(PortfolioManager, {
      props: {
        items: [{ ...rejectedItem, rejectionReason: longReason }],
        serviceOptions: ["Eletricista"],
      },
    });
    const reason = wrapper.get(".portfolio-manager__reason");
    const toggle = wrapper.get(".portfolio-manager__reason-toggle");

    expect(reason.get("strong").text()).toBe("Motivo:");
    expect(reason.text()).not.toContain("Envie uma nova foto");
    expect(toggle.text()).toBe("ver mais");
    expect(toggle.attributes("aria-expanded")).toBe("false");

    await toggle.trigger("click");

    expect(reason.text()).toContain(longReason);
    expect(toggle.text()).toBe("ver menos");
    expect(toggle.attributes("aria-expanded")).toBe("true");

    await toggle.trigger("click");

    expect(reason.text()).not.toContain("Envie uma nova foto");
    expect(toggle.text()).toBe("ver mais");
  });
});
