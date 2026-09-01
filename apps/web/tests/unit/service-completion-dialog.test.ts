import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import ServiceCompletionDialog from "@app/components/dashboard/service/CompletionDialog.vue";

const ModalStub = defineComponent({
  props: {
    open: { type: Boolean, default: false },
    dismissible: { type: Boolean, default: true },
    close: { type: Boolean, default: true },
  },
  emits: ["update:open"],
  template: `
    <section v-if="open" class="modal" :data-dismissible="dismissible" :data-close="close">
      <slot name="body" />
      <slot name="footer" />
      <button data-dismiss type="button" @click="$emit('update:open', false)">Dismiss</button>
    </section>
  `,
});
const ButtonStub = defineComponent({
  props: {
    disabled: { type: Boolean, default: false },
    loading: { type: Boolean, default: false },
  },
  emits: ["click"],
  template:
    '<button type="button" :disabled="disabled" :data-loading="loading" @click="$emit(\'click\')"><slot /></button>',
});
const TooltipStub = defineComponent({
  props: { reason: { type: String, default: null } },
  template: `<div :data-tooltip-reason="reason ?? ''"><slot /></div>`,
});

function mountDialog(
  props: Partial<InstanceType<typeof ServiceCompletionDialog>["$props"]> = {},
) {
  return mount(ServiceCompletionDialog, {
    props: {
      open: true,
      customerName: "Ana Paula",
      deliveryChannel: "email",
      busy: false,
      pendingChoice: null,
      ...props,
    },
    global: {
      stubs: {
        UModal: ModalStub,
        UButton: ButtonStub,
        DesignSystemDisabledTooltip: TooltipStub,
      },
    },
  });
}

describe("service completion dialog", () => {
  it("closes without confirming when cancelled or dismissed", async () => {
    const cancelled = mountDialog();

    await cancelled.get("button").trigger("click");
    expect(cancelled.emitted("update:open")).toEqual([[false]]);
    expect(cancelled.emitted("confirm")).toBeUndefined();

    const dismissed = mountDialog();
    await dismissed.get("[data-dismiss]").trigger("click");
    expect(dismissed.emitted("update:open")).toEqual([[false]]);
    expect(dismissed.emitted("confirm")).toBeUndefined();
  });

  it("emits the explicit evaluation choice", async () => {
    const wrapper = mountDialog();
    const buttons = wrapper.findAll("button");

    await buttons
      .find((button) =>
        button.text().includes("Concluir sem solicitar avaliação"),
      )!
      .trigger("click");
    await buttons
      .find((button) =>
        button.text().includes("Concluir e solicitar avaliação"),
      )!
      .trigger("click");

    expect(wrapper.emitted("confirm")).toEqual([[false], [true]]);
  });

  it("explains the delivery channel and locks every action while submitting", () => {
    const wrapper = mountDialog({
      deliveryChannel: "whatsapp",
      busy: true,
      pendingChoice: true,
      error: "Não foi possível concluir o serviço.",
    });

    expect(wrapper.text()).toContain(
      "abriremos o WhatsApp com uma mensagem pronta para Ana Paula",
    );
    expect(wrapper.text()).toContain("Não foi possível concluir o serviço.");
    expect(wrapper.get(".modal").attributes()).toMatchObject({
      "data-dismissible": "false",
      "data-close": "false",
    });

    const actionButtons = wrapper
      .findAll("button")
      .filter((button) => button.attributes("data-dismiss") === undefined);
    expect(actionButtons).toHaveLength(3);
    expect(
      actionButtons.every(
        (button) => button.attributes("disabled") !== undefined,
      ),
    ).toBe(true);
    expect(
      actionButtons.every(
        (button) =>
          button.element
            .closest("[data-tooltip-reason]")
            ?.getAttribute("data-tooltip-reason") ===
          "Aguarde a conclusão do serviço terminar.",
      ),
    ).toBe(true);
  });
});
