import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import Progress from "~/components/onboarding/Progress.vue";
import type { OnboardingStepDefinition } from "~/types";

const steps: OnboardingStepDefinition[] = [
  { id: "profile", label: "Perfil", description: "", icon: "i-lucide-user" },
  {
    id: "services",
    label: "Serviços",
    description: "",
    icon: "i-lucide-wrench",
  },
  {
    id: "verification",
    label: "Verificação",
    description: "",
    icon: "i-lucide-badge-check",
  },
];

const TooltipStub = defineComponent({
  props: { reason: { type: String, default: null } },
  template: `<div :data-tooltip-reason="reason ?? ''"><slot /></div>`,
});

function mountProgress(availableSteps: OnboardingStepDefinition["id"][]) {
  return mount(Progress, {
    props: {
      progress: 33,
      steps,
      completion: { profile: true, services: false, verification: false },
      activeStep: "profile",
      availableSteps,
    },
    global: {
      stubs: { DesignSystemDisabledTooltip: TooltipStub, UIcon: true },
    },
  });
}

function stepButton(wrapper: ReturnType<typeof mountProgress>, label: string) {
  const button = wrapper
    .findAll("nav button")
    .find((candidate) => candidate.text().includes(label));
  if (!button) throw new Error(`step button "${label}" not found`);
  return button;
}

describe("onboarding progress", () => {
  it("explains a locked step instead of a silent disabled button", () => {
    const wrapper = mountProgress(["profile"]);
    const locked = stepButton(wrapper, "Serviços");

    expect(locked.attributes("disabled")).toBeDefined();
    expect(
      locked.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("Conclua as etapas anteriores para liberar");
  });

  it("leaves an available step enabled with no reason to show", () => {
    const wrapper = mountProgress(["profile", "services"]);
    const available = stepButton(wrapper, "Serviços");

    expect(available.attributes("disabled")).toBeUndefined();
    expect(
      available.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("");
  });

  it("emits select when an available step is clicked", async () => {
    const wrapper = mountProgress(["profile", "services"]);
    await stepButton(wrapper, "Serviços").trigger("click");
    expect(wrapper.emitted("select")?.at(-1)).toEqual(["services"]);
  });
});
