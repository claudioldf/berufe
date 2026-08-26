import { mountSuspended } from "@nuxt/test-utils/runtime";
import SearchLoadingCard from "@app/components/public/SearchLoadingCard.vue";

const stubs = {
  DesignSystemSurfaceCard: {
    template: '<article class="surface-card"><slot /></article>',
  },
  UIcon: true,
};

describe("search loading card", () => {
  it("describes the expression search while results are loading", async () => {
    const wrapper = await mountSuspended(SearchLoadingCard, {
      global: { stubs },
    });

    const status = wrapper.get('[role="status"]');
    expect(status.attributes()).toMatchObject({
      "aria-live": "polite",
      "aria-atomic": "true",
      "aria-busy": "true",
    });
    expect(status.text()).toContain(
      "Entendendo seu pedido e buscando profissionais...",
    );
    expect(status.text()).toContain(
      "Estamos identificando o serviço, a região e os sinais de confiança",
    );
    expect(wrapper.find('[name="i-lucide-user-search"]').exists()).toBe(true);
    expect(wrapper.find('[name="i-lucide-sparkles"]').exists()).toBe(false);
  });

  it("uses focused copy for a structured search", async () => {
    const wrapper = await mountSuspended(SearchLoadingCard, {
      props: { structured: true },
      global: { stubs },
    });

    expect(wrapper.get('[role="status"]').text()).toContain(
      "Buscando profissionais com os filtros selecionados...",
    );
    expect(wrapper.text()).toContain(
      "Estamos combinando o serviço e a cidade escolhidos",
    );
  });
});
