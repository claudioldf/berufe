import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import IdentitySection from "@app/components/dashboard/profile/IdentitySection.vue";
import type { ProfessionalProfileDraft } from "~/types";

const draft: ProfessionalProfileDraft = {
  name: "Ana Souza",
  birthdate: "1990-04-12",
  headline: "Elétrica residencial.",
  bio: "Instalações em Joinville.",
  yearsExperience: 8,
  whatsapp: "47999991111",
  instagram: "",
  youtube: "",
  selectedServices: [],
  serviceNotes: {},
  primaryService: "",
  allJoinville: false,
  selectedNeighborhoods: [],
};

const ModalStub = defineComponent({
  props: {
    open: { type: Boolean, default: false },
    title: { type: String, default: "" },
    description: { type: String, default: "" },
  },
  emits: ["update:open"],
  template:
    '<section v-if="open" role="dialog"><h2>{{ title }}</h2><p>{{ description }}</p><footer><slot name="footer" /></footer></section>',
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
const FormFieldStub = defineComponent({
  props: { id: { type: String, required: true } },
  template:
    '<label><slot name="label" /><slot :control-id="id" :described-by="undefined" /></label>',
});

const global = {
  stubs: {
    UModal: ModalStub,
    UButton: ButtonStub,
    UIcon: true,
    DesignSystemFormField: FormFieldStub,
  },
};

describe("professional profile identity photo control", () => {
  it("confirms removal before emitting the destructive action", async () => {
    const wrapper = await mountSuspended(IdentitySection, {
      props: {
        modelValue: { ...draft },
        allowPhotoRemoval: true,
        photo: {
          current: {
            id: "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
            status: "approved",
            rejectionReason: null,
            submittedAt: "2026-08-23T12:00:00Z",
          },
          hasPublishedPhoto: true,
          publishedImageUrl: "https://api.example.test/profile-photo.jpg",
          latestUpload: null,
        },
      },
      global,
    });

    const removeButton = wrapper
      .findAll("button")
      .find((button) => button.text() === "Remover foto");
    expect(removeButton).toBeTruthy();

    await removeButton!.trigger("click");
    expect(wrapper.get('[role="dialog"]').text()).toContain(
      "ficará indisponível",
    );
    expect(wrapper.emitted("photoRemove")).toBeUndefined();

    const confirmButton = wrapper
      .get('[role="dialog"]')
      .findAll("button")
      .find((button) => button.text() === "Remover foto");
    await confirmButton!.trigger("click");

    expect(wrapper.emitted("photoRemove")).toHaveLength(1);
  });

  it("does not offer removal without a current or published photo", async () => {
    const wrapper = await mountSuspended(IdentitySection, {
      props: {
        modelValue: { ...draft },
        allowPhotoRemoval: true,
      },
      global,
    });

    expect(wrapper.text()).not.toContain("Remover foto");
  });
});
