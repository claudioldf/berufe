import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import ExpressionSearch from "@app/components/public/ExpressionSearch.vue";

const InputStub = defineComponent({
  name: "UInput",
  inheritAttrs: false,
  props: {
    modelValue: { type: String, default: "" },
    name: { type: String, default: undefined },
    placeholder: { type: String, default: undefined },
    required: { type: Boolean, default: false },
    maxlength: { type: [String, Number], default: undefined },
    ui: { type: Object, default: () => ({}) },
  },
  emits: ["update:modelValue"],
  template: `
    <input
      :name="name"
      :required="required"
      :maxlength="maxlength"
      :placeholder="placeholder"
      :value="modelValue"
      :class="ui.base"
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

const stubs = { UInput: InputStub, UButton: ButtonStub, UIcon: true };

describe("expression search", () => {
  it("requires a nonblank expression capped at 200 characters", async () => {
    const wrapper = await mountSuspended(ExpressionSearch, {
      global: { stubs },
    });

    expect(wrapper.get('input[name="expression"]').attributes()).toMatchObject({
      required: "",
      maxlength: "200",
      placeholder: "Ex.: Preciso pintar um quarto infantil",
    });
    expect(wrapper.find('button[type="submit"]').exists()).toBe(false);
    expect(wrapper.get('input[name="expression"]').classes()).toContain(
      "rounded-none",
    );
    expect(wrapper.find('u-icon-stub[name="i-lucide-search"]').exists()).toBe(
      true,
    );

    await wrapper.get("form").trigger("submit");
    expect(wrapper.emitted("submit")).toBeUndefined();
  });

  it("emits the trimmed free-form request after a user submits it", async () => {
    const wrapper = await mountSuspended(ExpressionSearch, {
      global: { stubs },
    });

    await wrapper
      .get('input[name="expression"]')
      .setValue("  preciso de um pintor no América  ");
    expect(wrapper.find('button[type="submit"]').exists()).toBe(true);
    expect(wrapper.get('button[type="submit"]').text()).toContain(
      "Buscar profissionais",
    );
    await wrapper.get("form").trigger("submit");

    expect(wrapper.emitted("submit")?.[0]?.[0]).toEqual({
      expression: "preciso de um pintor no América",
    });
  });

  it("does not submit an expression longer than 200 characters", async () => {
    const wrapper = await mountSuspended(ExpressionSearch, {
      global: { stubs },
    });

    await wrapper.get('input[name="expression"]').setValue("x".repeat(201));
    expect(wrapper.find('button[type="submit"]').exists()).toBe(false);
    await wrapper.get("form").trigger("submit");

    expect(wrapper.emitted("submit")).toBeUndefined();
  });
});
