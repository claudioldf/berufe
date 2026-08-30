import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import { describe, expect, it } from "vitest";
import IdentityUploadForm from "~/components/dashboard/verification/IdentityUploadForm.vue";
import ProfileStep from "~/components/onboarding/ProfileStep.vue";
import ServicesStep from "~/components/onboarding/ServicesStep.vue";
import Success from "~/components/onboarding/Success.vue";
import VerificationStep from "~/components/onboarding/VerificationStep.vue";
import type { ProfessionalProfileDraft, Service } from "~/types";

function profileDraft(
  overrides: Partial<ProfessionalProfileDraft> = {},
): ProfessionalProfileDraft {
  return {
    name: "Marcos Alves",
    birthdate: "1990-04-12",
    headline: "Elétrica residencial com cuidado.",
    bio: "Trabalho com instalações e manutenção residencial.",
    yearsExperience: 11,
    whatsapp: "47999991111",
    instagram: "",
    youtube: "",
    selectedServices: [],
    serviceNotes: {},
    primaryService: "",
    coverageCityCode: "",
    coversWholeCity: false,
    selectedNeighborhoodCodes: [],
    ...overrides,
  };
}

const services: Service[] = [
  {
    id: "svc-eletricista",
    name: "Eletricista",
    slug: "eletricista",
    category: "Instalações",
    icon: "i-lucide-zap",
    description: "Instalações e manutenção elétrica.",
    aliases: [],
  },
  {
    id: "svc-diarista",
    name: "Diarista",
    slug: "diarista",
    category: "Serviços domésticos",
    icon: "i-lucide-spray-can",
    description: "Limpeza residencial.",
    aliases: [],
  },
];

const ButtonStub = defineComponent({
  props: {
    to: { type: String, default: "" },
    type: { type: String, default: "button" },
    form: { type: String, default: "" },
    target: { type: String, default: "" },
    rel: { type: String, default: "" },
    disabled: { type: Boolean, default: false },
  },
  template: `
    <component
      :is="to ? 'a' : 'button'"
      :href="to || undefined"
      :type="type"
      :form="form || undefined"
      :target="target || undefined"
      :rel="rel || undefined"
      :disabled="disabled"
    >
      <slot />
    </component>
  `,
});

describe("onboarding step contracts", () => {
  it("offers review, public profile, and dashboard actions after publishing", async () => {
    const wrapper = mount(Success, {
      props: { publicSlug: "ana-souza" },
      global: {
        stubs: {
          DesignSystemSurfaceCard: { template: "<section><slot /></section>" },
          DesignSystemEyebrow: { template: "<span><slot /></span>" },
          UButton: ButtonStub,
          UIcon: true,
        },
      },
    });

    const publicProfile = wrapper.get('a[href="/be/ana-souza"]');
    expect(publicProfile.text()).toContain("Ver perfil público");
    expect(publicProfile.attributes("target")).toBe("_blank");
    expect(publicProfile.attributes("rel")).toBe("noopener noreferrer");
    expect(wrapper.get('a[href="/app/professional"]').text()).toContain(
      "Ir para o painel",
    );

    await wrapper.get("button").trigger("click");
    expect(wrapper.emitted("review")).toHaveLength(1);
  });

  it("keeps both verification choices in the bottom action row", async () => {
    const wrapper = mount(VerificationStep, {
      props: { submitted: false },
      global: {
        components: {
          DashboardVerificationIdentityUploadForm: IdentityUploadForm,
        },
        stubs: {
          DesignSystemSurfaceCard: { template: "<section><slot /></section>" },
          DesignSystemEyebrow: { template: "<span><slot /></span>" },
          UButton: ButtonStub,
          UIcon: true,
        },
      },
    });

    expect(wrapper.get(".onboarding-upload-card").text()).not.toContain(
      "Enviar e concluir",
    );

    const actions = wrapper.get(".onboarding-step-actions");
    const skip = actions
      .findAll("button")
      .find(
        (button) => button.text() === "Pular verificação e publicar perfil",
      );
    const submit = actions
      .findAll("button")
      .find((button) => button.text() === "Enviar e concluir");

    expect(skip).toBeTruthy();
    expect(submit?.attributes("form")).toBe("onboarding-identity-verification");
    expect(submit?.attributes("disabled")).toBeUndefined();

    await wrapper.get("form").trigger("submit");
    expect(wrapper.get('[role="alert"]').text()).toContain("Selecione");
    expect(
      wrapper.get('input[name="identity-document"]').attributes("aria-invalid"),
    ).toBe("true");
    expect(wrapper.emitted("complete")).toBeUndefined();

    const file = new File(["identity"], "identity.png", {
      type: "image/png",
    });
    const input = wrapper.get('input[name="identity-document"]');
    Object.defineProperty(input.element, "files", { value: [file] });
    await input.trigger("change");

    await wrapper.get("form").trigger("submit");
    expect(wrapper.emitted("complete")?.[0]).toEqual([file]);

    await skip!.trigger("click");
    expect(wrapper.emitted("skip")).toHaveLength(1);
  });

  it("lists services alphabetically", () => {
    const wrapper = mount(ServicesStep, {
      props: {
        draft: profileDraft(),
        services,
      },
    });

    expect(
      wrapper.findAll(".service-picker button").map((button) => button.text()),
    ).toEqual(["Diarista", "Eletricista"]);
  });

  it("keeps a profile without a birthdate on the current step", async () => {
    const wrapper = mount(ProfileStep, {
      props: {
        draft: profileDraft({ birthdate: "" }),
        photo: {
          current: null,
          hasPublishedPhoto: true,
          publishedImageUrl: null,
          latestUpload: null,
        },
      },
    });

    await wrapper.get("form").trigger("submit");

    expect(wrapper.get('[role="alert"]').text()).toContain("nascimento");
    expect(
      wrapper.get('input[name="birthdate"]').attributes("aria-invalid"),
    ).toBe("true");
    expect(wrapper.get('label[for="profile-birthdate"]').classes()).toContain(
      "form-field--invalid",
    );
    expect(wrapper.get("#profile-birthdate-error").text()).toContain(
      "nascimento",
    );
    expect(wrapper.emitted("complete")).toBeUndefined();
  });

  it("reveals every invalid required profile field inline", async () => {
    const wrapper = mount(ProfileStep, {
      props: {
        draft: profileDraft({ name: "", birthdate: "" }),
      },
    });

    await wrapper.get("form").trigger("submit");

    expect(wrapper.get("form").attributes()).toHaveProperty("novalidate");
    expect(wrapper.get('input[name="name"]').attributes("aria-invalid")).toBe(
      "true",
    );
    expect(
      wrapper.get('input[name="birthdate"]').attributes("aria-invalid"),
    ).toBe("true");
    expect(
      wrapper.get(".profile-photo-control").attributes("aria-invalid"),
    ).toBe("true");
    expect(wrapper.get(".profile-photo-control").classes()).toContain(
      "profile-photo-control--invalid",
    );
    expect(wrapper.get("#profile-name-error").text()).toContain("nome");
    expect(wrapper.get("#profile-birthdate-error").text()).toContain(
      "nascimento",
    );
    expect(wrapper.get("#profile-photo-status").text()).toContain("foto");
    expect(wrapper.emitted("complete")).toBeUndefined();
  });

  it("emits a cloned valid profile payload", async () => {
    const draft = profileDraft();
    const wrapper = mount(ProfileStep, {
      props: {
        draft,
        photo: {
          current: null,
          hasPublishedPhoto: true,
          publishedImageUrl: null,
          latestUpload: null,
        },
      },
    });

    await wrapper.get("form").trigger("submit");

    const payload = wrapper.emitted("complete")?.[0]?.[0] as
      ProfessionalProfileDraft | undefined;
    expect(payload?.name).toBe("Marcos Alves");
    expect(payload?.selectedServices).not.toBe(draft.selectedServices);
  });

  it("keeps the required profile photo inside the identity step", async () => {
    const wrapper = mount(ProfileStep, { props: { draft: profileDraft() } });
    const file = new File(["photo"], "profile.png", { type: "image/png" });
    const input = wrapper.get('input[type="file"]');
    Object.defineProperty(input.element, "files", {
      configurable: true,
      value: [file],
    });

    await input.trigger("change");

    expect(wrapper.text()).toContain("Foto profissional");
    expect(wrapper.text()).toContain("Obrigatória");
    expect(wrapper.emitted("photoSelect")?.[0]?.[0]).toBe(file);
  });

  it("requires both a service and coverage before advancing", async () => {
    const wrapper = mount(ServicesStep, {
      props: {
        draft: profileDraft({
          coverageCityCode: "4209102",
          coversWholeCity: true,
        }),
        services,
      },
    });

    await wrapper.get("form").trigger("submit");
    expect(wrapper.get('[role="alert"]').text()).toContain("serviço");
    expect(wrapper.get(".service-picker").attributes("aria-invalid")).toBe(
      "true",
    );
    expect(wrapper.get(".service-picker").classes()).toContain(
      "service-picker--invalid",
    );
    expect(wrapper.get(".service-picker").attributes("aria-describedby")).toBe(
      "profile-service-selection-error",
    );
    expect(wrapper.get("#profile-service-selection-error").text()).toContain(
      "serviço",
    );
    expect(
      wrapper.get('select[name="primary-service"]').attributes("aria-invalid"),
    ).toBe("false");

    await wrapper.get('button[aria-pressed="false"]').trigger("click");
    expect(wrapper.get(".service-picker").attributes("aria-invalid")).toBe(
      "false",
    );
    expect(wrapper.get(".service-picker").classes()).not.toContain(
      "service-picker--invalid",
    );
    expect(wrapper.find("#profile-service-selection-error").exists()).toBe(
      false,
    );
    await wrapper.get("form").trigger("submit");

    expect(wrapper.emitted("complete")).toHaveLength(1);
  });

  it("reveals service and coverage errors on their controls", async () => {
    const wrapper = mount(ServicesStep, {
      props: {
        draft: profileDraft(),
        services,
      },
    });

    await wrapper.get("form").trigger("submit");

    expect(wrapper.get("form").attributes()).toHaveProperty("novalidate");
    expect(wrapper.get("#profile-service-selection-error").text()).toContain(
      "serviço",
    );
    expect(
      wrapper.get('select[name="coverage-state"]').attributes("aria-invalid"),
    ).toBe("true");
    expect(
      wrapper.get('select[name="coverage-city"]').attributes("aria-invalid"),
    ).toBe("true");
    expect(wrapper.get('select[name="coverage-state"]').classes()).toContain(
      "location-coverage-fields__select--invalid",
    );
    expect(wrapper.emitted("complete")).toBeUndefined();
  });
});
