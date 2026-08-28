import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import ProfileStep from "~/components/onboarding/ProfileStep.vue";
import ServicesStep from "~/components/onboarding/ServicesStep.vue";
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
describe("onboarding step contracts", () => {
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

    await wrapper.get('button[aria-pressed="false"]').trigger("click");
    await wrapper.get("form").trigger("submit");

    expect(wrapper.emitted("complete")).toHaveLength(1);
  });
});
