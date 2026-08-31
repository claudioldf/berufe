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
  coverageCityCode: "",
  coversWholeCity: false,
  selectedNeighborhoodCodes: [],
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
  props: {
    id: { type: String, required: true },
    error: { type: String, default: "" },
  },
  template: `
    <label>
      <slot name="label" />
      <slot
        :control-id="id"
        :described-by="error ? id + '-error' : undefined"
        :invalid="Boolean(error)"
      />
      <span v-if="error" :id="id + '-error'" role="alert">{{ error }}</span>
    </label>
  `,
});
const TooltipStub = defineComponent({
  props: { reason: { type: String, default: null } },
  template: `<div :data-tooltip-reason="reason ?? ''"><slot /></div>`,
});

const global = {
  stubs: {
    UModal: ModalStub,
    UButton: ButtonStub,
    UIcon: true,
    DesignSystemFormField: FormFieldStub,
    DesignSystemDisabledTooltip: TooltipStub,
  },
};

describe("professional profile identity photo control", () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("shows the selected profile photo before it finishes uploading", async () => {
    vi.spyOn(URL, "createObjectURL").mockReturnValue("blob:profile-preview");
    const wrapper = await mountSuspended(IdentitySection, {
      props: { modelValue: { ...draft } },
      global,
    });
    const file = new File(["profile photo"], "profile.png", {
      type: "image/png",
    });
    const input = wrapper.get('input[name="profile-photo"]');
    Object.defineProperty(input.element, "files", { value: [file] });

    await input.trigger("change");

    expect(
      wrapper.get('img[alt="Prévia da foto profissional"]').attributes("src"),
    ).toBe("blob:profile-preview");
    expect(wrapper.emitted("photoSelect")?.[0]).toEqual([file]);
  });

  it("confirms removal before emitting the destructive action", async () => {
    const wrapper = await mountSuspended(IdentitySection, {
      props: {
        modelValue: { ...draft },
        allowPhotoRemoval: true,
        photo: {
          current: {
            id: "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
            submittedAt: "2026-08-23T12:00:00Z",
          },
          hasPhoto: true,
          imageUrl: "https://api.example.test/profile-photo.jpg",
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

  it("explains why photo actions are unavailable while a mutation runs", async () => {
    const wrapper = await mountSuspended(IdentitySection, {
      props: {
        modelValue: { ...draft },
        photoUploading: true,
      },
      global,
    });
    const action = wrapper
      .findAll("button")
      .find((button) => button.text() === "Adicionar foto")!;

    expect(action.attributes("disabled")).toBeDefined();
    expect(
      action.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("Aguarde o envio da foto terminar.");

    await wrapper.setProps({ photoUploading: false, photoRemoving: true });
    expect(
      action.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("Aguarde a remoção da foto terminar.");
  });

  it("allows a professional biography of up to 2,500 characters", async () => {
    const wrapper = await mountSuspended(IdentitySection, {
      props: { modelValue: { ...draft, bio: "B".repeat(2500) } },
      global,
    });
    const biography = wrapper.get('textarea[name="bio"]');

    expect(biography.attributes("maxlength")).toBe("2500");
    expect(wrapper.text()).toContain("2500/2500");
  });

  it("connects identity errors to their fields", async () => {
    const wrapper = await mountSuspended(IdentitySection, {
      props: {
        modelValue: { ...draft },
        errors: {
          name: "Revise o nome.",
          birthdate: "",
          whatsapp: "",
          headline: "",
          bio: "",
          yearsExperience: "",
        },
      },
      global,
    });

    const name = wrapper.get('input[name="name"]');
    expect(name.attributes("aria-invalid")).toBe("true");
    expect(name.attributes("aria-describedby")).toBe("profile-name-error");
    expect(wrapper.get('[role="alert"]').text()).toBe("Revise o nome.");
  });

  it("masks WhatsApp and applies the invalid style to the complete control", async () => {
    const wrapper = await mountSuspended(IdentitySection, {
      props: {
        modelValue: { ...draft },
        errors: {
          name: "",
          birthdate: "",
          whatsapp: "Revise o WhatsApp.",
          headline: "",
          bio: "",
          yearsExperience: "",
        },
      },
      global,
    });
    const input = wrapper.get<HTMLInputElement>('input[name="whatsapp"]');

    expect(input.element.value).toBe("(47) 9 9999-1111");
    expect(input.attributes("aria-invalid")).toBe("true");
    expect(wrapper.get(".phone-field").classes()).toContain(
      "phone-field--invalid",
    );
    await input.setValue("47988882222");
    expect(wrapper.props("modelValue").whatsapp).toBe("(47) 9 8888-2222");
  });
});
