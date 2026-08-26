import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FeatureEmptyState from "~/components/design-system/FeatureEmptyState.vue";
import FormField from "~/components/design-system/FormField.vue";
import Heading from "~/components/design-system/Heading.vue";

describe("design-system contracts", () => {
  it("connects field labels, hints, and errors with stable IDs", () => {
    const wrapper = mount(FormField, {
      props: {
        id: "customer-name",
        label: "Nome do cliente",
        hint: "Como aparecerá no orçamento.",
      },
      slots: {
        default:
          '<input id="customer-name" aria-describedby="customer-name-hint">',
      },
    });

    expect(wrapper.get("label").attributes("for")).toBe("customer-name");
    expect(wrapper.get("small").attributes("id")).toBe("customer-name-hint");
  });

  it("renders semantic heading levels independently from visual variants", () => {
    const wrapper = mount(Heading, {
      props: { as: "h1", variant: "workspace" },
      slots: { default: "Meu perfil" },
    });
    expect(wrapper.element.tagName).toBe("H1");
    expect(wrapper.classes()).toContain("heading--workspace");
  });

  it("uses action and status icons in feature cards", () => {
    const wrapper = mount(FeatureEmptyState, {
      props: {
        eyebrow: "Comece por aqui",
        title: "Cadastre seu primeiro trabalho",
        description: "Mostre sua experiência profissional.",
        visual: {
          icon: "i-lucide-images",
          title: "Portfólio",
          caption: "Seus trabalhos",
          metaLabel: "Status",
          metaValue: "Pronto para começar",
          badge: "Perfil em construção",
        },
      },
      global: {
        stubs: {
          DesignSystemSurfaceCard: {
            template: '<section class="surface-card"><slot /></section>',
          },
          UIcon: true,
        },
      },
    });

    expect(wrapper.find('[name="i-lucide-circle-plus"]').exists()).toBe(true);
    expect(wrapper.find('[name="i-lucide-badge-check"]').exists()).toBe(true);
    expect(wrapper.find('[name="i-lucide-sparkles"]').exists()).toBe(false);
  });
});
