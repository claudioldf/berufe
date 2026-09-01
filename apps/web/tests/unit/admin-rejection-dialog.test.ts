import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import RejectionDialog from "~/components/admin/moderation/RejectionDialog.vue";

const UModalStub = defineComponent({
  props: { open: { type: Boolean, default: false } },
  template:
    '<section v-if="open"><slot name="body" /><footer><slot name="footer" /></footer></section>',
});

const UButtonStub = defineComponent({
  props: { disabled: { type: Boolean, default: false } },
  emits: ["click"],
  template:
    '<button :disabled="disabled" @click="$emit(\'click\')"><slot /></button>',
});

const FormFieldStub = defineComponent({
  props: { label: { type: String, default: "" } },
  template: "<label>{{ label }}<slot :control-id=\"'field'\" /></label>",
});

const TooltipStub = defineComponent({
  props: { reason: { type: String, default: null } },
  template: `<div :data-tooltip-reason="reason ?? ''"><slot /></div>`,
});

function mountDialog(reason: string) {
  return mount(RejectionDialog, {
    props: { open: true, reason },
    global: {
      stubs: {
        UModal: UModalStub,
        UButton: UButtonStub,
        DesignSystemFormField: FormFieldStub,
        DesignSystemDisabledTooltip: TooltipStub,
      },
    },
  });
}

function confirmButton(wrapper: ReturnType<typeof mountDialog>) {
  const button = wrapper
    .findAll("button")
    .find((candidate) => candidate.text().includes("Confirmar rejeição"));
  if (!button) throw new Error("confirm button not found");
  return button;
}

describe("rejection dialog", () => {
  it("explains the ten-character minimum instead of a silent disabled button", () => {
    const wrapper = mountDialog("curta");
    const button = confirmButton(wrapper);

    expect(button.attributes("disabled")).toBeDefined();
    expect(
      button.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("Escreva ao menos 10 caracteres explicando o motivo");
  });

  it("clears the reason and enables confirmation past the minimum", () => {
    const wrapper = mountDialog("Documento não confere com o solicitado.");
    const button = confirmButton(wrapper);

    expect(button.attributes("disabled")).toBeUndefined();
    expect(
      button.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("");
  });

  it("emits confirm only once enabled", async () => {
    const wrapper = mountDialog("Documento não confere com o solicitado.");
    await confirmButton(wrapper).trigger("click");
    expect(wrapper.emitted("confirm")).toHaveLength(1);
  });
});
