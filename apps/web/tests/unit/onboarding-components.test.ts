import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import ProfileStep from "~/components/onboarding/ProfileStep.vue";
import ServicesStep from "~/components/onboarding/ServicesStep.vue";
import type { Neighborhood, ProfessionalProfileDraft, Service } from "~/types";

function profileDraft(
  overrides: Partial<ProfessionalProfileDraft> = {},
): ProfessionalProfileDraft {
  return {
    name: "Marcos Alves",
    headline: "Elétrica residencial com cuidado.",
    bio: "Trabalho com instalações e manutenção residencial.",
    yearsExperience: 11,
    whatsapp: "47999991111",
    instagram: "",
    youtube: "",
    selectedServices: [],
    primaryService: "",
    allJoinville: false,
    selectedNeighborhoods: [],
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
];
const neighborhoods: Neighborhood[] = [
  {
    code: "america",
    name: "América",
    stateCode: "SC",
    city: "Joinville",
  },
];

describe("onboarding step contracts", () => {
  it("keeps an invalid profile on the current step", async () => {
    const wrapper = mount(ProfileStep, {
      props: { draft: profileDraft({ headline: "" }) },
    });

    await wrapper.get("form").trigger("submit");

    expect(wrapper.get('[role="alert"]').text()).toContain("apresentação");
    expect(wrapper.emitted("complete")).toBeUndefined();
  });

  it("emits a cloned valid profile payload", async () => {
    const draft = profileDraft();
    const wrapper = mount(ProfileStep, { props: { draft } });

    await wrapper.get("form").trigger("submit");

    const payload = wrapper.emitted("complete")?.[0]?.[0] as
      ProfessionalProfileDraft | undefined;
    expect(payload?.name).toBe("Marcos Alves");
    expect(payload?.selectedServices).not.toBe(draft.selectedServices);
  });

  it("requires both a service and coverage before advancing", async () => {
    const wrapper = mount(ServicesStep, {
      props: {
        draft: profileDraft(),
        services,
        neighborhoods,
      },
    });

    await wrapper.get("form").trigger("submit");
    expect(wrapper.get('[role="alert"]').text()).toContain("serviço");

    await wrapper.get('button[aria-pressed="false"]').trigger("click");
    await wrapper.get('input[name="all-joinville"]').setValue(true);
    await wrapper.get("form").trigger("submit");

    expect(wrapper.emitted("complete")).toHaveLength(1);
  });
});
