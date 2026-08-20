import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import RelationshipRequestDialog from "@app/components/profile/RelationshipRequestDialog.vue";

const ModalStub = defineComponent({
  props: { open: { type: Boolean, default: false } },
  emits: ["update:open"],
  template:
    '<section v-if="open"><slot name="body" /><footer><slot name="footer" /></footer></section>',
});
const FieldStub = defineComponent({
  template: "<label><slot /></label>",
});
const ButtonStub = defineComponent({
  props: { disabled: { type: Boolean, default: false } },
  emits: ["click"],
  template:
    '<button type="button" :disabled="disabled" @click="$emit(\'click\')"><slot /></button>',
});

describe("relationship request dialog", () => {
  it("submits only the supported relationship fields from user interaction", async () => {
    const wrapper = await mountSuspended(RelationshipRequestDialog, {
      props: {
        open: true,
        recipientProfessionalId: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
        recipientName: "Beto Lima",
        submitting: false,
      },
      global: {
        stubs: {
          UModal: ModalStub,
          UButton: ButtonStub,
          DesignSystemFormField: FieldStub,
        },
      },
    });

    await wrapper.get("select").setValue("worked_together");
    await wrapper
      .get("textarea")
      .setValue("Executamos uma reforma residencial juntos.");
    await wrapper.get("footer button:last-child").trigger("click");

    expect(wrapper.emitted("submit")?.at(-1)).toEqual([
      {
        recipientProfessionalId: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
        relationshipType: "worked_together",
        contextNote: "Executamos uma reforma residencial juntos.",
      },
    ]);
    expect(wrapper.get("textarea").attributes("maxlength")).toBe("300");
  });

  it("shows API feedback and disables both actions while submitting", async () => {
    const wrapper = await mountSuspended(RelationshipRequestDialog, {
      props: {
        open: true,
        recipientProfessionalId: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
        recipientName: "Beto Lima",
        submitting: true,
        error: "Esta solicitação de relação já existe.",
      },
      global: {
        stubs: {
          UModal: ModalStub,
          UButton: ButtonStub,
          DesignSystemFormField: FieldStub,
        },
      },
    });

    expect(wrapper.get('[role="alert"]').text()).toContain(
      "Esta solicitação de relação já existe.",
    );
    expect(
      wrapper
        .findAll("footer button")
        .every((button) => button.attributes("disabled") !== undefined),
    ).toBe(true);
  });
});
