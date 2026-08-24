import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import ServiceSearch from "@app/components/public/ServiceSearch.vue";
import type { Neighborhood, Service } from "@app/types";

const InputMenuStub = defineComponent({
  name: "UInputMenu",
  inheritAttrs: false,
  props: {
    modelValue: { type: String, default: "" },
    name: { type: String, default: undefined },
    required: { type: Boolean, default: false },
  },
  emits: ["update:modelValue"],
  template: `
    <input
      :name="name"
      :required="required"
      :value="modelValue"
      @input="$emit('update:modelValue', $event.target.value)"
    >
  `,
});

const InputStub = defineComponent({
  name: "UInput",
  inheritAttrs: false,
  props: {
    modelValue: { type: String, default: "" },
    name: { type: String, default: undefined },
  },
  emits: ["update:modelValue"],
  template: `
    <input
      :name="name"
      :value="modelValue"
      @input="$emit('update:modelValue', $event.target.value)"
    >
  `,
});

const ButtonStub = defineComponent({
  name: "UButton",
  props: {
    type: { type: String, default: "button" },
    disabled: { type: Boolean, default: false },
  },
  template: '<button :type="type" :disabled="disabled"><slot /></button>',
});

const stubs = {
  UInput: InputStub,
  UInputMenu: InputMenuStub,
  UButton: ButtonStub,
  UIcon: true,
};

const services: Service[] = [
  {
    id: "c43071a5-4c47-4324-99ef-41846ee35538",
    name: "Eletricista",
    slug: "eletricista",
    category: "instalacoes",
    icon: "i-lucide-zap",
    description: "Instalações elétricas residenciais.",
    aliases: ["elétrica"],
  },
];

const neighborhoods: Neighborhood[] = [
  {
    code: "all",
    name: "Toda Joinville",
    stateCode: "SC",
    city: "Joinville",
  },
];

describe("service search", () => {
  it("requires a nonblank service before submitting", async () => {
    const wrapper = await mountSuspended(ServiceSearch, {
      props: { services, neighborhoods },
      global: { stubs },
    });
    const submitButton = wrapper.get('button[type="submit"]');

    expect(submitButton.attributes("disabled")).toBeDefined();
    expect(wrapper.get('input[name="service"]').attributes("required")).toBe(
      "",
    );
    expect(wrapper.find('input[name="professional_name"]').exists()).toBe(
      false,
    );

    await wrapper.get("form").trigger("submit");

    expect(wrapper.emitted("submit")).toBeUndefined();
  });

  it("enables submission and emits a trimmed service term", async () => {
    const wrapper = await mountSuspended(ServiceSearch, {
      props: { services, neighborhoods },
      global: { stubs },
    });

    await wrapper
      .get('input[name="service"]')
      .setValue("  troca de chuveiro  ");

    expect(
      wrapper.get('button[type="submit"]').attributes("disabled"),
    ).toBeUndefined();

    await wrapper.get("form").trigger("submit");

    expect(wrapper.emitted("submit")?.[0]?.[0]).toEqual({
      professionalName: "",
      service: "troca de chuveiro",
      neighborhood: "all",
    });
  });

  it("shows the full-width professional-name filter when requested and emits its trimmed value", async () => {
    const wrapper = await mountSuspended(ServiceSearch, {
      props: { services, neighborhoods, showProfessionalName: true },
      global: { stubs },
    });

    const nameField = wrapper.get(".service-search__field--professional");
    expect(nameField.text()).toContain("O que você precisa?");
    expect(wrapper.get('[role="separator"]').text()).toBe("OU");

    await nameField
      .get('input[name="professional_name"]')
      .setValue("  Ana Souza  ");
    await wrapper.get('input[name="service"]').setValue("Eletricista");
    await wrapper.get("form").trigger("submit");

    expect(wrapper.emitted("submit")?.[0]?.[0]).toEqual({
      professionalName: "Ana Souza",
      service: "Eletricista",
      neighborhood: "all",
    });
  });
});
