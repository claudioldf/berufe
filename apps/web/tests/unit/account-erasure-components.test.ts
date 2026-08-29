import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import AccountErasureForm from "~/components/account/AccountErasureForm.vue";
import ErasureRequestStatus from "~/components/account/ErasureRequestStatus.vue";

const SurfaceCardStub = defineComponent({
  template: "<section><slot /></section>",
});
const ButtonStub = defineComponent({
  props: {
    disabled: { type: Boolean, default: false },
    loading: { type: Boolean, default: false },
    to: { type: String, default: "" },
  },
  emits: ["click"],
  template:
    '<button :disabled="disabled" :data-to="to" :data-loading="loading" @click="$emit(\'click\')"><slot /></button>',
});
const global = {
  stubs: {
    DesignSystemSurfaceCard: SurfaceCardStub,
    DesignSystemEyebrow: { template: "<span><slot /></span>" },
    UButton: ButtonStub,
    UIcon: true,
  },
};

describe("account erasure components", () => {
  it("explains irreversible consequences", () => {
    const wrapper = mount(AccountErasureForm, {
      props: { submitting: false, error: "" },
      global,
    });

    expect(wrapper.text()).toContain("Esta ação é irreversível");
    expect(wrapper.text()).toContain("Conta");
    expect(wrapper.text()).not.toContain("Zona de risco");
    expect(wrapper.text()).toContain(
      "apagado dos nossos sistemas em até 30 dias",
    );
    expect(wrapper.text()).toContain("permanecem por cinco anos");
    expect(
      wrapper
        .findAll("button")
        .find((button) => button.text() === "Cancelar")
        ?.attributes("data-to"),
    ).toBe("/app/professional/profile");
  });

  it("requires acknowledgement before emitting one submission", async () => {
    const wrapper = mount(AccountErasureForm, {
      props: { submitting: false, error: "" },
      global,
    });
    const submit = wrapper
      .findAll("button")
      .find((button) => button.text().includes("Excluir conta"))!;

    expect(submit.attributes("disabled")).toBeDefined();
    await wrapper.get('input[type="checkbox"]').setValue(true);
    expect(submit.attributes("disabled")).toBeUndefined();

    await wrapper.get("form").trigger("submit");
    expect(wrapper.emitted("submit")).toHaveLength(1);
  });

  it("renders retry state and only privacy-safe request details", async () => {
    const wrapper = mount(ErasureRequestStatus, {
      props: {
        refreshing: false,
        request: {
          reference: "23a94f5e-1429-4ec7-bbc4-a6f805d5182d",
          status: "retrying",
          requestedAt: "2026-08-29T15:00:00.000Z",
          unpublishedAt: "2026-08-29T15:00:00.000Z",
          completionDeadlineAt: "2026-09-28T15:00:00.000Z",
          completedAt: null,
        },
      },
      global,
    });

    expect(wrapper.text()).toContain("Exclusão em nova tentativa");
    expect(wrapper.text()).toContain("conta continua despublicada");
    expect(wrapper.text()).toContain("23a94f5e-1429-4ec7-bbc4-a6f805d5182d");
    expect(wrapper.text()).not.toContain("telefone");

    await wrapper
      .findAll("button")
      .find((button) => button.text().includes("Atualizar estado"))!
      .trigger("click");
    expect(wrapper.emitted("refresh")).toHaveLength(1);
  });
});
