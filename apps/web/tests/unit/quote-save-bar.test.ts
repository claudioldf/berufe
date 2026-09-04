import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import SaveBar from "~/components/dashboard/quote/SaveBar.vue";

const ButtonStub = defineComponent({
  props: {
    disabled: Boolean,
    loading: Boolean,
    icon: { type: String, default: "" },
  },
  emits: ["click"],
  template: `
    <button
      :disabled="disabled"
      :data-loading="loading ? 'true' : 'false'"
      :data-icon="icon"
      @click="$emit('click')"
    >
      <slot />
    </button>
  `,
});

const TooltipStub = defineComponent({
  props: { reason: { type: String, default: null } },
  template: `<div :data-tooltip-reason="reason ?? ''"><slot /></div>`,
});

function mountSaveBar(
  props: Partial<InstanceType<typeof SaveBar>["$props"]> = {},
) {
  return mount(SaveBar, {
    props: {
      saved: false,
      shared: false,
      readyToShare: false,
      valid: true,
      editing: false,
      savingIntent: null,
      error: "",
      shareEnabled: true,
      ...props,
    },
    global: {
      stubs: {
        UButton: ButtonStub,
        UIcon: true,
        DesignSystemDisabledTooltip: TooltipStub,
      },
    },
  });
}

describe("quote save bar", () => {
  it.each([
    [false, "Gerar"],
    [true, "Atualizar"],
  ] as const)(
    "labels the primary action for editing=%s",
    async (editing, expectedLabel) => {
      const wrapper = mountSaveBar({ editing });
      const share = wrapper
        .findAll("button")
        .find((button) => button.text() === expectedLabel);

      expect(wrapper.get('[role="status"]').text()).toContain(
        "Alterações não salvas",
      );
      expect(share?.attributes("disabled")).toBeUndefined();

      await share?.trigger("click");

      expect(wrapper.emitted("share")).toHaveLength(1);
    },
  );

  it("shows direct sharing and disables redundant saving when already saved", () => {
    const wrapper = mountSaveBar({ saved: true, readyToShare: true });
    const save = wrapper
      .findAll("button")
      .find((button) => button.text() === "Salvar rascunho");

    expect(wrapper.text()).toContain("Enviar ao cliente");
    expect(wrapper.get('[role="status"]').text()).toContain(
      "Aguardando envio ao cliente",
    );
    expect(save?.attributes("disabled")).toBeDefined();
    expect(
      save?.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe(
      "O rascunho já está salvo. Faça uma alteração para salvar novamente.",
    );
  });

  it("uses distinct icons for saving, generating, and sharing", () => {
    const save = mountSaveBar();
    const share = mountSaveBar({ saved: true, readyToShare: true });

    expect(
      save
        .findAll("button")
        .find((button) => button.text() === "Salvar rascunho")
        ?.attributes("data-icon"),
    ).toBe("i-lucide-file-text");
    expect(
      save
        .findAll("button")
        .find((button) => button.text() === "Gerar")
        ?.attributes("data-icon"),
    ).toBe("i-lucide-check");
    expect(
      share
        .findAll("button")
        .find((button) => button.text() === "Enviar ao cliente")
        ?.attributes("data-icon"),
    ).toBe("i-lucide-share");
  });

  it("announces and loads only the save-before-share action", () => {
    const wrapper = mountSaveBar({ savingIntent: "share" });
    const buttons = wrapper.findAll("button");
    const preview = buttons.find(
      (button) => button.text() === "Pré-visualizar",
    );
    const save = buttons.find((button) =>
      button.text().includes("Salvar rascunho"),
    );
    const share = buttons.find((button) => button.text() === "Salvando…");

    expect(wrapper.get('[role="status"]').text()).toContain(
      "Salvando orçamento…",
    );
    expect(save?.attributes("data-loading")).toBe("false");
    expect(save?.attributes("disabled")).toBeDefined();
    expect(
      save?.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("Aguarde o salvamento necessário para compartilhar.");
    expect(preview?.attributes("disabled")).toBeDefined();
    expect(
      preview?.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("Aguarde o salvamento necessário para compartilhar.");
    expect(share?.attributes("data-loading")).toBe("true");
    expect(share?.attributes("disabled")).toBeDefined();
    expect(
      share?.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("Aguarde o salvamento necessário para compartilhar.");
  });

  it("announces persistence errors and keeps sharing unavailable when ineligible", () => {
    const wrapper = mountSaveBar({
      error: "Não foi possível salvar. Tente novamente.",
      saved: true,
      readyToShare: true,
      shareEnabled: false,
    });
    const share = wrapper
      .findAll("button")
      .find((button) => button.text() === "Enviar ao cliente");

    expect(wrapper.get('[role="alert"]').text()).toContain(
      "Não foi possível salvar. Tente novamente.",
    );
    expect(share?.attributes("disabled")).toBeDefined();
    expect(
      share?.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe(
      "Seu perfil precisa estar disponível para compartilhar o orçamento.",
    );
  });

  it("explains why sharing is unavailable instead of a silent disabled button", () => {
    const blocked = mountSaveBar({
      saved: true,
      readyToShare: true,
      shareEnabled: false,
      shareBlockedReason: "Conta suspensa: regularize para continuar.",
    });
    const share = blocked
      .findAll("button")
      .find((button) => button.text() === "Enviar ao cliente");

    expect(share?.attributes("disabled")).toBeDefined();
    expect(
      share?.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("Conta suspensa: regularize para continuar.");

    const available = mountSaveBar({
      saved: true,
      readyToShare: true,
      shareEnabled: true,
      shareBlockedReason: null,
    });
    const availableShare = available
      .findAll("button")
      .find((button) => button.text() === "Enviar ao cliente");
    expect(
      availableShare?.element
        .closest("[data-tooltip-reason]")
        ?.getAttribute("data-tooltip-reason"),
    ).toBe("");
  });

  it("keeps submission available so the builder can reveal invalid fields", () => {
    const wrapper = mountSaveBar({ valid: false });
    const save = wrapper
      .findAll("button")
      .find((button) => button.text() === "Salvar rascunho");
    const share = wrapper
      .findAll("button")
      .find((button) => button.text() === "Gerar");

    expect(wrapper.get('[role="status"]').text()).toContain(
      "Preencha os campos obrigatórios",
    );
    expect(save?.attributes("disabled")).toBeUndefined();
    expect(share?.attributes("disabled")).toBeUndefined();
  });
});
