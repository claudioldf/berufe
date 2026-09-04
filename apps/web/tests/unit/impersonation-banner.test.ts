import { mount } from "@vue/test-utils";
import ImpersonationBanner from "@app/components/auth/ImpersonationBanner.vue";

describe("impersonation banner", () => {
  it("keeps the delegated identity visible and emits the return action", async () => {
    const wrapper = mount(ImpersonationBanner, {
      props: { displayName: "Ana Souza", stopping: false, error: "" },
      global: {
        stubs: {
          DesignSystemContainer: { template: "<div><slot /></div>" },
          UIcon: true,
          UButton: {
            props: ["label", "disabled"],
            emits: ["click"],
            template:
              '<button :disabled="disabled" @click="$emit(\'click\')">{{ label }}</button>',
          },
        },
      },
    });

    expect(wrapper.text()).toContain(
      "Você está gerenciando a conta de Ana Souza",
    );
    await wrapper.get("button").trigger("click");
    expect(wrapper.emitted("stop")).toHaveLength(1);
  });

  it("shows pending and error feedback accessibly", () => {
    const wrapper = mount(ImpersonationBanner, {
      props: {
        displayName: "Ana Souza",
        stopping: true,
        error: "Não foi possível voltar.",
      },
      global: {
        stubs: {
          DesignSystemContainer: { template: "<div><slot /></div>" },
          UIcon: true,
          UButton: {
            props: ["label", "disabled"],
            template: '<button :disabled="disabled">{{ label }}</button>',
          },
        },
      },
    });

    expect(wrapper.get("button").attributes("disabled")).toBeDefined();
    expect(wrapper.get('[role="alert"]').text()).toBe(
      "Não foi possível voltar.",
    );
  });
});
