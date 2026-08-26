import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import StructuredSearchFallback from "@app/components/public/StructuredSearchFallback.vue";
import type { Service, StructuredSearchCity } from "@app/types";

const InputMenuStub = defineComponent({
  name: "UInputMenu",
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
const cities: StructuredSearchCity[] = [
  { id: "joinville-sc", name: "Joinville", stateCode: "SC" },
];

describe("structured search fallback", () => {
  it("requires a service and emits controlled service and city values", async () => {
    const wrapper = await mountSuspended(StructuredSearchFallback, {
      props: { services, cities },
      global: {
        stubs: {
          UInputMenu: InputMenuStub,
          UButton: ButtonStub,
          UIcon: true,
        },
      },
    });
    const submit = wrapper.get('button[type="submit"]');

    expect(submit.attributes("disabled")).toBeDefined();
    await wrapper
      .get('input[name="fallback_service"]')
      .setValue(services[0]!.id);
    expect(submit.attributes("disabled")).toBeUndefined();

    await wrapper.get("form").trigger("submit");

    expect(wrapper.emitted("submit")?.[0]?.[0]).toEqual({
      serviceId: services[0]!.id,
      serviceName: "Eletricista",
      stateCode: "SC",
      city: "Joinville",
    });
  });
});
