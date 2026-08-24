import { mount } from "@vue/test-utils";
import CodeStep from "~/components/auth/CodeStep.vue";
import PhoneStep from "~/components/auth/PhoneStep.vue";
import RegistrationStep from "~/components/auth/RegistrationStep.vue";
import {
  professionalPhoneStepContent,
  resolveProfessionalAuthIntent,
} from "~/utils/professional-auth";

describe("phone authentication components", () => {
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

    await wrapper.setProps({ cooldown: 3600 });
    expect(resend.text()).toBe("Reenviar código amanhã");

    await wrapper.setProps({ error: "Código inválido ou expirado." });
    expect(wrapper.get('[role="alert"]').text()).toContain("Código inválido");
    expect(wrapper.get("#auth-code").attributes("aria-invalid")).toBe("true");
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
    expect(wrapper.get('[role="alert"]').text()).toContain("Revise os campos.");
  });
});
