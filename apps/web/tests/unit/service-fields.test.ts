import { mount } from "@vue/test-utils";
import { defineComponent, reactive } from "vue";
import ServiceFields from "~/components/dashboard/quote/ServiceFields.vue";
import type { Quote } from "~/types";

const SurfaceCardStub = defineComponent({
  template: "<section><slot /></section>",
});
const FieldStub = defineComponent({
  props: {
    label: { type: String, default: "" },
    error: { type: String, default: "" },
    required: Boolean,
  },
  template:
    '<label :data-error="error">{{ label }}<slot :control-id="\'service-field\'" :described-by="error ? \'service-field-error\' : null" :invalid="Boolean(error)" /></label>',
});

describe("quote service fields", () => {
  it("keeps the service details in their own second card", () => {
    const quote = reactive({
      validUntil: "",
      scheduledOn: "",
      serviceDescription: "Instalação elétrica",
      serviceAddress: "",
    }) as Quote;
    const wrapper = mount(ServiceFields, {
      props: { modelValue: quote },
      global: {
        stubs: {
          DesignSystemSurfaceCard: SurfaceCardStub,
          DesignSystemFormField: FieldStub,
        },
      },
    });

    expect(wrapper.get("header").text()).toContain("02");
    expect(wrapper.get("h2").text()).toBe("Serviço");
    expect(wrapper.find('input[name="customerName"]').exists()).toBe(false);
    expect(wrapper.get('input[name="validUntil"]')).toBeDefined();
    expect(wrapper.get('input[name="scheduledOn"]')).toBeDefined();
    expect(wrapper.get('input[name="serviceDescription"]')).toBeDefined();
    expect(wrapper.get('input[name="serviceAddress"]')).toBeDefined();
  });

  it("connects inline errors and invalid state to service controls", () => {
    const quote = reactive({
      validUntil: "",
      scheduledOn: "invalid",
      serviceDescription: "",
      serviceAddress: "",
    }) as Quote;
    const wrapper = mount(ServiceFields, {
      props: {
        modelValue: quote,
        errors: {
          validUntil: "Informe até quando o orçamento é válido.",
          scheduledOn: "Informe uma data válida.",
          serviceDescription: "Descreva o serviço.",
          items: {},
        },
      },
      global: {
        stubs: {
          DesignSystemSurfaceCard: SurfaceCardStub,
          DesignSystemFormField: FieldStub,
        },
      },
    });

    expect(
      wrapper.get('input[name="validUntil"]').attributes("aria-invalid"),
    ).toBe("true");
    expect(
      wrapper.get('input[name="scheduledOn"]').attributes("aria-invalid"),
    ).toBe("true");
    expect(
      wrapper
        .get('input[name="serviceDescription"]')
        .attributes("aria-invalid"),
    ).toBe("true");
    expect(wrapper.text()).toContain("Válido até");
  });
});
