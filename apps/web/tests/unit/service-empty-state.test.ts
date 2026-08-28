import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import ServiceEmptyState from "~/components/dashboard/ServiceEmptyState.vue";
import FeatureEmptyState from "~/components/design-system/FeatureEmptyState.vue";

const SurfaceCardStub = defineComponent({
  template: '<section class="surface-card"><slot /></section>',
});
const ButtonLinkStub = defineComponent({
  props: { to: { type: String, default: "" } },
  template: '<a :href="to"><slot /></a>',
});

describe("professional services empty state", () => {
  it("explains how services appear and links to the first quote", () => {
    const wrapper = mount(ServiceEmptyState, {
      global: {
        components: {
          DesignSystemFeatureEmptyState: FeatureEmptyState,
        },
        stubs: {
          DesignSystemSurfaceCard: SurfaceCardStub,
          UButton: ButtonLinkStub,
          UIcon: true,
        },
      },
    });

    expect(wrapper.text()).toContain(
      "Seu próximo serviço começa com uma proposta aprovada.",
    );
    expect(wrapper.text()).toContain(
      "Acompanhamento da execução até a conclusão",
    );
    expect(wrapper.text()).toContain("Cliente aprovou");
    expect(
      wrapper.get('a[href="/app/professional/quotes/new"]').text(),
    ).toContain("Criar meu primeiro orçamento");
  });
});
