import { mount } from "@vue/test-utils";
import { defineComponent, nextTick } from "vue";
import CodeStep from "~/components/auth/CodeStep.vue";
import PhoneStep from "~/components/auth/PhoneStep.vue";
import RegistrationStep from "~/components/auth/RegistrationStep.vue";
import {
  professionalPhoneStepContent,
  resolveProfessionalEntryPath,
  resolveProfessionalAuthIntent,
} from "~/utils/professional-auth";

const TooltipStub = defineComponent({
  props: { reason: { type: String, default: null } },
  template: `<div :data-tooltip-reason="reason ?? ''"><slot /></div>`,
});

describe("phone authentication components", () => {
  it.each([
    [false, false, "/app/professional/login"],
    [true, false, "/app/professional/onboarding"],
    [true, true, "/app/professional"],
  ] as const)(
    "resolves registration %s and onboarding %s to %s",
    (registrationCompleted, onboardingCompleted, expectedPath) => {
      expect(
        resolveProfessionalEntryPath({
          role: "professional",
          registrationCompleted,
          onboardingCompleted,
        }),
      ).toBe(expectedPath);
    },
  );

  it("presents distinct login and signup intent without changing the form", async () => {
    const wrapper = mount(PhoneStep, {
      props: {
        modelValue: "",
        loading: false,
        error: "",
        content: professionalPhoneStepContent.login,
      },
      global: {
        stubs: {
          DesignSystemEyebrow: { template: "<span><slot /></span>" },
          NuxtLink: {
            props: ["to"],
            template: '<a :href="to"><slot /></a>',
          },
          UButton: { template: "<button><slot /></button>" },
          UIcon: true,
        },
      },
    });

    expect(wrapper.get("h1").text()).toBe("Acesse seu perfil.");
    expect(wrapper.get("button").text()).toBe("Receber código para entrar");
    expect(wrapper.get(".phone-step__alternate a").attributes("href")).toBe(
      "/app/professional/login?intent=signup",
    );

    await wrapper.setProps({ content: professionalPhoneStepContent.signup });

    expect(wrapper.get("h1").text()).toBe("Crie seu perfil profissional.");
    expect(wrapper.get("button").text()).toBe("Receber código e começar");
    expect(wrapper.get(".phone-step__alternate a").attributes("href")).toBe(
      "/app/professional/login",
    );
    expect(resolveProfessionalAuthIntent("signup")).toBe("signup");
    expect(resolveProfessionalAuthIntent("unexpected")).toBe("login");
  });

  it("reveals, focuses, and scrolls to an invalid login field", async () => {
    const wrapper = mount(PhoneStep, {
      attachTo: document.body,
      props: {
        modelValue: "",
        loading: false,
        error: "",
        content: professionalPhoneStepContent.login,
      },
      global: {
        stubs: {
          DesignSystemEyebrow: { template: "<span><slot /></span>" },
          NuxtLink: { template: "<a><slot /></a>" },
          UButton: { template: "<button><slot /></button>" },
          UIcon: true,
        },
      },
    });
    const phone = wrapper.get<HTMLInputElement>("#auth-phone");
    const scrollIntoView = vi.fn();
    phone.element.scrollIntoView = scrollIntoView;

    await wrapper.get("form").trigger("submit");
    await nextTick();

    expect(wrapper.get('[role="alert"]').text()).toContain("número");
    expect(phone.attributes("aria-invalid")).toBe("true");
    expect(document.activeElement).toBe(phone.element);
    expect(scrollIntoView).toHaveBeenCalledWith({
      block: "center",
      inline: "nearest",
    });
    expect(wrapper.emitted("submit")).toBeUndefined();
    wrapper.unmount();
  });

  it("masks the mobile number while it is entered", async () => {
    const wrapper = mount(PhoneStep, {
      props: {
        modelValue: "",
        loading: false,
        error: "",
        content: professionalPhoneStepContent.login,
      },
      global: {
        stubs: {
          DesignSystemEyebrow: { template: "<span><slot /></span>" },
          NuxtLink: { template: "<a><slot /></a>" },
          UButton: { template: "<button><slot /></button>" },
          UIcon: true,
        },
      },
    });
    const input = wrapper.get<HTMLInputElement>("#auth-phone");

    await input.setValue("47999991111");
    const masked = wrapper.emitted("update:modelValue")?.at(-1)?.[0];
    expect(masked).toBe("(47) 9 9999-1111");
    await wrapper.setProps({ modelValue: String(masked) });
    expect(input.element.value).toBe("(47) 9 9999-1111");
    expect(input.attributes("maxlength")).toBe("16");
  });

  it("keeps short and daily resend timing in the existing control", async () => {
    const wrapper = mount(CodeStep, {
      props: {
        modelValue: "",
        phone: "(47) 99999-1111",
        loading: false,
        error: "",
        cooldown: 0,
      },
      global: {
        stubs: {
          DesignSystemEyebrow: { template: "<span><slot /></span>" },
          DesignSystemDisabledTooltip: TooltipStub,
          UButton: { template: "<button><slot /></button>" },
          UIcon: true,
        },
      },
    });
    const resend = wrapper.get("button.resend");

    expect(resend.text()).toBe("Reenviar código");
    await resend.trigger("click");
    expect(wrapper.emitted("resend")).toHaveLength(1);

    await wrapper.get(".auth-card__step-back").trigger("click");
    expect(wrapper.emitted("changePhone")).toHaveLength(1);

    await wrapper.get("#auth-code").setValue("123456");
    expect(wrapper.emitted("update:modelValue")?.[0]).toEqual(["123456"]);
    await wrapper.get("form").trigger("submit");
    expect(wrapper.emitted("submit")).toHaveLength(1);

    await wrapper.setProps({ cooldown: 30 });
    expect(resend.text()).toBe("Reenviar código em 30s");
    expect(resend.attributes()).toHaveProperty("disabled");
    expect(
      resend.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("Aguarde 30s para solicitar outro código.");

    await wrapper.setProps({ cooldown: 3600 });
    expect(resend.text()).toBe("Reenviar código amanhã");
    expect(
      resend.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("O limite de reenvios foi atingido. Tente novamente amanhã.");

    await wrapper.setProps({ error: "Código inválido ou expirado." });
    expect(wrapper.get('[role="alert"]').text()).toContain("Código inválido");
    expect(wrapper.get("#auth-code").attributes("aria-invalid")).toBe("true");
  });

  it("validates the confirmation code inline before emitting submit", async () => {
    const wrapper = mount(CodeStep, {
      props: {
        modelValue: "12",
        phone: "(47) 99999-1111",
        loading: false,
        error: "",
        cooldown: 0,
      },
      global: {
        stubs: {
          DesignSystemEyebrow: { template: "<span><slot /></span>" },
          DesignSystemDisabledTooltip: TooltipStub,
          UButton: { template: "<button><slot /></button>" },
          UIcon: true,
        },
      },
    });

    await wrapper.get("form").trigger("submit");

    expect(wrapper.get('[role="alert"]').text()).toContain("6 dígitos");
    expect(wrapper.get("#auth-code").attributes("aria-invalid")).toBe("true");
    expect(wrapper.emitted("submit")).toBeUndefined();
  });

  it("validates registration fields independently before submitting", async () => {
    const wrapper = mount(RegistrationStep, {
      props: {
        name: "",
        accepted: false,
        error: "",
        loading: false,
      },
      global: {
        stubs: {
          DesignSystemEyebrow: { template: "<span><slot /></span>" },
          DesignSystemDisabledTooltip: TooltipStub,
          NuxtLink: { template: "<a><slot /></a>" },
          UButton: { template: "<button><slot /></button>" },
          UIcon: true,
        },
      },
    });

    await wrapper.get("form").trigger("submit");

    expect(wrapper.findAll('[role="alert"]')).toHaveLength(2);
    expect(wrapper.get("#professional-name").attributes("aria-invalid")).toBe(
      "true",
    );
    expect(
      wrapper.get('input[name="accepted-terms"]').attributes("aria-invalid"),
    ).toBe("true");
    expect(wrapper.emitted("submit")).toBeUndefined();
  });

  it("submits the existing registration fields and reflects pending state", async () => {
    const wrapper = mount(RegistrationStep, {
      props: {
        name: "",
        accepted: false,
        error: "",
        loading: false,
      },
      global: {
        stubs: {
          DesignSystemEyebrow: { template: "<span><slot /></span>" },
          DesignSystemDisabledTooltip: TooltipStub,
          NuxtLink: { template: "<a><slot /></a>" },
          UButton: {
            props: ["disabled", "loading"],
            template:
              '<button :disabled="disabled" :data-loading="loading"><slot /></button>',
          },
          UIcon: true,
        },
      },
    });

    await wrapper.get("#professional-name").setValue("Ana Reparos");
    await wrapper.get('input[name="accepted-terms"]').setValue(true);
    await wrapper.get("form").trigger("submit");

    expect(wrapper.emitted("update:name")?.at(-1)).toEqual(["Ana Reparos"]);
    expect(wrapper.emitted("update:accepted")?.at(-1)).toEqual([true]);
    expect(wrapper.emitted("submit")).toHaveLength(1);

    await wrapper.setProps({ loading: true, error: "Revise os campos." });
    expect(wrapper.get("button").attributes("disabled")).toBeDefined();
    expect(wrapper.get("button").attributes("data-loading")).toBe("true");
    expect(
      wrapper
        .get("button")
        .element.closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("Aguarde a criação do perfil terminar.");
    expect(wrapper.get('[role="alert"]').text()).toContain("Revise os campos.");
  });
});
