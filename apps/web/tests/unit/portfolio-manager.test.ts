import { mount } from "@vue/test-utils";
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
    expect(wrapper.text()).toContain("Aprovado");
    expect(wrapper.get("h2").text()).toBe("Meus trabalhos");
  });

  it("shows private owner status and uses the existing card action for soft deletion", async () => {
    const wrapper = mount(PortfolioManager, {
      props: { items: [rejectedItem], serviceOptions: ["Eletricista"] },
    });

    expect(wrapper.text()).toContain("Recusado");
    expect(wrapper.text()).toContain("A imagem está desfocada.");
    expect(wrapper.find("article img").exists()).toBe(false);

    await wrapper
      .get('button[aria-label="Excluir Cozinha iluminada"]')
      .trigger("click");
    expect(wrapper.emitted("removed")?.[0]).toEqual(["portfolio-1"]);
  });
});
