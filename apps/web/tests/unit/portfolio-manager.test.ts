import { mount } from "@vue/test-utils";
import PortfolioManager from "~/components/dashboard/PortfolioManager.vue";
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
