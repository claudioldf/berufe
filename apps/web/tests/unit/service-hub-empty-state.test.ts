import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import ServiceHubEmptyState from "~/components/public/ServiceHubEmptyState.vue";

const SurfaceCardStub = defineComponent({
  props: { as: { type: String, default: "div" } },
  template: '<component :is="as"><slot /></component>',
});

const ButtonLinkStub = defineComponent({
  props: { to: { type: String, required: true } },
  template: '<a :href="to"><slot /></a>',
});

const IconStub = defineComponent({
  props: { name: { type: String, required: true } },
  template: '<span :data-icon="name" />',
});

function mountEmptyState() {
  return mount(ServiceHubEmptyState, {
    props: {
      serviceName: "Pedreiro",
      serviceSlug: "pedreiro",
      serviceIcon: "i-lucide-brick-wall",
    },
    global: {
      stubs: {
        DesignSystemSurfaceCard: SurfaceCardStub,
        UButton: ButtonLinkStub,
        UIcon: IconStub,
      },
    },
  });
}

describe("public service hub empty state", () => {
  it("guides visitors to search while preserving professional signup", () => {
    const wrapper = mountEmptyState();

    expect(
      wrapper
        .get('section[aria-labelledby="service-hub-empty-title"]')
        .exists(),
    ).toBe(true);
    expect(wrapper.get("h2").text()).toContain(
      "Ainda estamos ampliando a oferta de pedreiro por cidade.",
    );
    expect(wrapper.text()).toContain(
      "Já pode haver profissionais atendendo a sua região.",
    );

    const links = wrapper.findAll("a");
    expect(links[0]?.attributes("href")).toBe("/encontrar");
    expect(links[0]?.text()).toContain("Buscar profissionais");
    expect(links[1]?.attributes("href")).toBe("/para-profissionais/pedreiro");
    expect(links[1]?.text()).toContain("Criar perfil grátis");
  });

  it("keeps the service illustration decorative", () => {
    const wrapper = mountEmptyState();

    expect(
      wrapper.get(".service-hub-empty__visual").attributes("aria-hidden"),
    ).toBe("true");
    expect(wrapper.get('[data-icon="i-lucide-brick-wall"]').exists()).toBe(
      true,
    );
  });
});
