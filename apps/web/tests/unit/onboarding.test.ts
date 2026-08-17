import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, shallowRef } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import type { ProfessionalProfileDraft } from "~/types";
import {
  calculateOnboardingProgress,
  createInitialProfessionalOnboardingState,
  getOnboardingStepCompletion,
  normalizeBrazilianPhone,
  onboardingImageMaxBytes,
  parseProfessionalOnboardingState,
  professionalOnboardingStorageKey,
  useProfessionalOnboarding,
  validateOnboardingImage,
  validateOnboardingProfile,
  validateOnboardingServices,
} from "~/composables/useProfessionalOnboarding";

function validDraft(): ProfessionalProfileDraft {
  return {
    name: "Marcos Alves",
    headline: "Elétrica residencial com cuidado e clareza.",
    bio: "Trabalho com instalações, reformas e manutenção residencial.",
    yearsExperience: 11,
    whatsapp: "+55 (47) 99999-1111",
    instagram: "",
    youtube: "",
    selectedServices: ["Eletricista"],
    serviceNotes: { Eletricista: "Quadros e circuitos" },
    primaryService: "Eletricista",
    allJoinville: true,
    selectedNeighborhoods: [],
  };
}

afterEach(() => {
  window.localStorage.clear();
});

describe("professional onboarding rules", () => {
  it("validates the four frontend completion areas", () => {
    const draft = validDraft();
    expect(Object.values(validateOnboardingProfile(draft))).toEqual([
      "",
      "",
      "",
      "",
    ]);
    expect(Object.values(validateOnboardingServices(draft))).toEqual(["", ""]);
    expect(normalizeBrazilianPhone(draft.whatsapp)).toBe("47999991111");

    const state = createInitialProfessionalOnboardingState();
    state.profile = draft;
    state.portfolio = {
      title: "Iluminação da cozinha",
      service: "Eletricista",
      description: "Novo circuito e iluminação da bancada.",
      submittedAt: "2026-08-15T12:00:00.000Z",
    };
    state.verificationStatus = "submitted";
    state.completion = {
      profile: "2026-08-15T12:00:00.000Z",
      services: "2026-08-15T12:01:00.000Z",
      portfolio: "2026-08-15T12:02:00.000Z",
      verification: "2026-08-15T12:03:00.000Z",
    };

    const completion = getOnboardingStepCompletion(state);
    expect(completion).toEqual({
      profile: true,
      services: true,
      portfolio: true,
      verification: true,
    });
    expect(calculateOnboardingProgress(completion)).toBe(100);
  });

  it("rejects invalid images and stale or malformed browser state", () => {
    const validFile = new File(["image"], "work.jpg", {
      type: "image/jpeg",
    });
    const invalidType = new File(["image"], "work.gif", {
      type: "image/gif",
    });
    const oversized = new File(["image"], "work.png", {
      type: "image/png",
    });
    Object.defineProperty(oversized, "size", {
      value: onboardingImageMaxBytes + 1,
    });

    expect(validateOnboardingImage(validFile).valid).toBe(true);
    expect(validateOnboardingImage(invalidType).valid).toBe(false);
    expect(validateOnboardingImage(oversized).valid).toBe(false);
    expect(parseProfessionalOnboardingState("not-json")).toBeNull();
    expect(
      parseProfessionalOnboardingState(JSON.stringify({ version: 2 })),
    ).toBeNull();
  });

  it("persists submitted progress without persisting uploaded files", async () => {
    const onboarding = shallowRef<
      ReturnType<typeof useProfessionalOnboarding> | undefined
    >();
    const Host = defineComponent({
      setup() {
        onboarding.value = useProfessionalOnboarding({
          saveIdentity: async (draft) => draft,
          saveSupply: async (draft) => draft,
          savePortfolio: async (draft) => ({
            title: draft.title,
            service: draft.service,
            description: draft.description,
            submittedAt: "2026-08-15T12:02:00.000Z",
          }),
        });
        return () => h("div");
      },
    });
    const wrapper = mount(Host);
    await nextTick();
    const workflow = onboarding.value!;
    workflow.reset();
    workflow.initializeFromAuth({
      name: "Marcos Alves",
      phone: "(47) 99999-1111",
    });

    const draft = validDraft();
    await expect(workflow.completeProfile(draft)).resolves.toBe(true);
    await expect(workflow.completeServices(draft)).resolves.toBe(true);
    const file = new File(["private-image-bytes"], "private.jpg", {
      type: "image/jpeg",
    });
    await expect(
      workflow.completePortfolio({
        file,
        title: "Iluminação da cozinha",
        service: "Eletricista",
        description: "",
      }),
    ).resolves.toBe(true);
    expect(workflow.completeVerification(file)).toBe(true);

    const stored = window.localStorage.getItem(
      professionalOnboardingStorageKey,
    )!;
    expect(stored).not.toContain("private-image-bytes");
    expect(stored).not.toContain("private.jpg");
    expect(parseProfessionalOnboardingState(stored)).not.toBeNull();
    expect(workflow.progress.value).toBe(100);

    wrapper.unmount();
  });
});
