import { mount } from "@vue/test-utils";
import { defineComponent, nextTick } from "vue";
import ProfileEditor from "~/components/dashboard/ProfileEditor.vue";
import type { Professional, Service } from "~/types";

const invalidProfessional: Professional = {
  id: "professional-1",
  slug: "ana-souza",
  name: "",
  birthdate: "",
  headline: "",
  bio: "",
  avatar: "",
  primaryService: "",
  primaryServiceSlug: "",
  services: [],
  serviceNotes: [],
  coverage: { city: null, wholeCity: false, neighborhoods: [] },
  yearsExperience: 8,
  evidence: [],
  portfolio: [],
  relationships: [],
  updatedAt: "2026-08-30",
  whatsapp: "",
  instagram: "",
  youtube: "",
};

const services: Service[] = [
  {
    id: "service-1",
    name: "Eletricista",
    slug: "eletricista",
    category: "Instalações",
    icon: "i-lucide-zap",
    description: "Instalações elétricas.",
    aliases: [],
  },
];

const IdentityStub = defineComponent({
  props: {
    modelValue: { type: Object, required: true },
    errors: { type: Object, default: undefined },
  },
  emits: ["update:modelValue"],
  template: `
    <section>
      <input
        name="name"
        :value="modelValue.name"
        :aria-invalid="Boolean(errors?.name)"
        :aria-describedby="errors?.name ? 'profile-name-error' : undefined"
      />
      <span v-if="errors?.name" id="profile-name-error" role="alert">
        {{ errors.name }}
      </span>
    </section>
  `,
});
const SocialStub = defineComponent({
  props: { modelValue: Object, errors: Object },
  template: "<section />",
});
const ServicesStub = defineComponent({
  props: { modelValue: Object, services: Array, error: String },
  template: '<select :aria-invalid="Boolean(error)" />',
});
const CoverageStub = defineComponent({
  props: { modelValue: Object, error: String },
  template: '<div :aria-invalid="Boolean(error)" tabindex="-1" />',
});
const SaveBarStub = defineComponent({
  props: {
    saved: Boolean,
    saving: Boolean,
    valid: Boolean,
    validationAttempted: Boolean,
  },
  template: `
    <div>
      <span v-if="validationAttempted && !valid">Revise os campos destacados</span>
      <button type="submit" :disabled="saving || (saved && valid)">Salvar alterações</button>
    </div>
  `,
});

describe("professional profile editor validation", () => {
  it("keeps Save clickable, reveals errors, and focuses the first invalid field", async () => {
    const wrapper = mount(ProfileEditor, {
      attachTo: document.body,
      props: {
        professional: invalidProfessional,
        services,
      },
      global: {
        stubs: {
          DashboardProfileFormLayout: {
            template: "<div><slot /></div>",
          },
          DashboardProfileIdentitySection: IdentityStub,
          DashboardProfileSocialSection: SocialStub,
          DashboardProfileServicesSection: ServicesStub,
          DashboardProfileCoverageSection: CoverageStub,
          DashboardProfileSaveBar: SaveBarStub,
        },
      },
    });
    const save = wrapper.get("button");

    expect(save.attributes("disabled")).toBeUndefined();
    await wrapper.get("form").trigger("submit");
    await nextTick();

    const name = wrapper.get<HTMLInputElement>('input[name="name"]');
    expect(wrapper.get('[role="alert"]').text()).toContain("3 caracteres");
    expect(name.attributes("aria-invalid")).toBe("true");
    expect(document.activeElement).toBe(name.element);
    expect(wrapper.emitted("save")).toBeUndefined();
    wrapper.unmount();
  });
});
