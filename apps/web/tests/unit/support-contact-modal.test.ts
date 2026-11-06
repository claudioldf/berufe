import { flushPromises, mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import SupportContactModal from "~/components/help/SupportContactModal.vue";
import { ApiRequestError } from "~/services/api/errors";

const UModalStub = defineComponent({
  props: { open: { type: Boolean, default: false } },
  template:
    '<section v-if="open"><slot name="body" /><footer><slot name="footer" /></footer></section>',
});

const UButtonStub = defineComponent({
  props: {
    disabled: { type: Boolean, default: false },
    type: { type: String, default: "button" },
  },
  emits: ["click"],
  template:
    '<button :type="type" :disabled="disabled" @click="$emit(\'click\')"><slot /></button>',
});

const FormFieldStub = defineComponent({
  props: {
    label: { type: String, default: "" },
    error: { type: String, default: "" },
  },
  template:
    '<label>{{ label }}<slot control-id="field" /><small v-if="error">{{ error }}</small></label>',
});

function mountModal(submit: (input: unknown) => Promise<void>) {
  return mount(SupportContactModal, {
    props: { open: true, topic: "excluir-conta", submit },
    global: {
      stubs: {
        UModal: UModalStub,
        UButton: UButtonStub,
        UIcon: true,
        DesignSystemFormField: FormFieldStub,
      },
    },
  });
}

async function fill(wrapper: ReturnType<typeof mountModal>) {
  await wrapper.get('input[name="name"]').setValue("Ana Souza");
  await wrapper.get('input[name="email"]').setValue("ana@example.com");
  await wrapper.get('textarea[name="message"]').setValue("Preciso de ajuda.");
}

describe("SupportContactModal", () => {
  it("keeps submit disabled until name, e-mail and a long enough message exist", async () => {
    const wrapper = mountModal(vi.fn());
    const submit = () => wrapper.get('button[type="submit"]');

    expect(submit().attributes("disabled")).toBeDefined();
    await fill(wrapper);
    expect(submit().attributes("disabled")).toBeUndefined();
  });

  it("sends the topic with the draft and shows the confirmation", async () => {
    const send = vi.fn().mockResolvedValue(undefined);
    const wrapper = mountModal(send);

    await fill(wrapper);
    await wrapper.get("form").trigger("submit");
    await flushPromises();

    expect(send).toHaveBeenCalledWith(
      expect.objectContaining({
        name: "Ana Souza",
        email: "ana@example.com",
        topic: "excluir-conta",
      }),
    );
    expect(wrapper.text()).toContain("Mensagem enviada");
  });

  it("shows the field errors returned by the API", async () => {
    const send = vi.fn().mockRejectedValue(
      new ApiRequestError({
        code: "validation_failed",
        message: "Revise os campos da mensagem.",
        requestId: "r1",
        fieldErrors: { email: ["informe um e-mail válido"] },
      }),
    );
    const wrapper = mountModal(send);

    await fill(wrapper);
    await wrapper.get("form").trigger("submit");
    await flushPromises();

    expect(wrapper.text()).toContain("informe um e-mail válido");
    expect(wrapper.get('[role="alert"]').text()).toContain(
      "Revise os campos destacados.",
    );
  });

  it("falls back to the support address on unexpected failures", async () => {
    const wrapper = mountModal(vi.fn().mockRejectedValue(new Error("boom")));

    await fill(wrapper);
    await wrapper.get("form").trigger("submit");
    await flushPromises();

    expect(wrapper.get('[role="alert"]').text()).toContain(
      "suporte@berufe.com.br",
    );
  });
});
