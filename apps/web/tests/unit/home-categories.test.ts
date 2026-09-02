import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import Categories from "~/components/home/Categories.vue";
import type { Service } from "~/types";
import { encodeSearchExpression } from "~/utils/searchExpression";

const NuxtLinkStub = defineComponent({
  props: { to: { type: [String, Object], required: true } },
  template: "<a><slot /></a>",
});

const services: Service[] = Array.from({ length: 10 }, (_, index) => ({
  id: `service-${index + 1}`,
  name: `Serviço ${index + 1}`,
  slug: `servico-${index + 1}`,
  category: "categoria",
  icon: "i-lucide-wrench",
  description: `Descrição do serviço ${index + 1}.`,
  aliases: [],
}));

describe("home categories", () => {
  it("shows eight services initially and lets the visitor expand and collapse the list", async () => {
    const wrapper = mount(Categories, {
      props: { services },
      global: {
        stubs: {
          DesignSystemPageSection: { template: "<section><slot /></section>" },
          DesignSystemContainer: { template: "<div><slot /></div>" },
          DesignSystemEyebrow: { template: "<span><slot /></span>" },
          DesignSystemHeading: { template: "<h2><slot /></h2>" },
          DesignSystemSectionCopy: { template: "<p><slot /></p>" },
          NuxtLink: NuxtLinkStub,
          UIcon: true,
        },
      },
    });

    const toggle = wrapper.get(
      'button[aria-controls="home-service-categories"]',
    );
    expect(wrapper.findAll(".category-card")).toHaveLength(8);
    expect(wrapper.text()).not.toContain("Serviço 9");
    expect(toggle.attributes("aria-expanded")).toBe("false");
    expect(toggle.text()).toContain("Ver todos os serviços");
    expect(wrapper.findAllComponents(NuxtLinkStub)[0]?.props("to")).toEqual({
      path: "/encontrar/sc/joinville",
      query: { q: encodeSearchExpression("Serviço 1") },
    });

    await toggle.trigger("click");

    expect(wrapper.findAll(".category-card")).toHaveLength(10);
    expect(wrapper.text()).toContain("Serviço 10");
    expect(toggle.attributes("aria-expanded")).toBe("true");
    expect(toggle.text()).toContain("Mostrar menos");

    await toggle.trigger("click");

    expect(wrapper.findAll(".category-card")).toHaveLength(8);
    expect(wrapper.text()).not.toContain("Serviço 9");
  });
});
