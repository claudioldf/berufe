import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import SaveBar from "~/components/dashboard/quote/SaveBar.vue";

const ButtonStub = defineComponent({
  props: {
    disabled: Boolean,
    loading: Boolean,
  },
  emits: ["click"],
  template: `
    <button
      :disabled="disabled"
      :data-loading="loading ? 'true' : 'false'"
      @click="$emit('click')"
    >
      <slot />
    </button>
  `,
});

function mountSaveBar(
  props: Partial<InstanceType<typeof SaveBar>["$props"]> = {},
) {
  return mount(SaveBar, {
    props: {
      saved: false,
      shared: false,
      valid: true,
      savingIntent: null,
      error: "",
      shareEnabled: true,
      ...props,
    },
    global: {
      stubs: {
        UButton: ButtonStub,
        UIcon: true,
      },
    },
  });
}

describe("quote save bar", () => {
  it("offers one explicit save-and-share action for an unsaved quote", async () => {
    const wrapper = mountSaveBar();
    const share = wrapper
      .findAll("button")
      .find((button) => button.text() === "Salvar e compartilhar");

    expect(wrapper.get('[role="status"]').text()).toContain(
      "Alterações não salvas",
    );
    expect(share?.attributes("disabled")).toBeUndefined();

    await share?.trigger("click");

    expect(wrapper.emitted("share")).toHaveLength(1);
  });

  it("shows direct sharing and disables redundant saving when already saved", () => {
    const wrapper = mountSaveBar({ saved: true });
    const save = wrapper
      .findAll("button")
      .find((button) => button.text() === "Salvar rascunho");

    expect(wrapper.text()).toContain("Compartilhar");
    expect(wrapper.get('[role="status"]').text()).toContain("Rascunho salvo");
    expect(save?.attributes("disabled")).toBeDefined();
  });

  it("announces and loads only the save-before-share action", () => {
    const wrapper = mountSaveBar({ savingIntent: "share" });
    const buttons = wrapper.findAll("button");
    const save = buttons.find((button) =>
      button.text().includes("Salvar rascunho"),
    );
    const share = buttons.find((button) => button.text() === "Salvando…");

    expect(wrapper.get('[role="status"]').text()).toContain(
      "Salvando antes de compartilhar…",
    );
    expect(save?.attributes("data-loading")).toBe("false");
    expect(share?.attributes("data-loading")).toBe("true");
    expect(share?.attributes("disabled")).toBeDefined();
  });

  it("announces persistence errors and keeps sharing unavailable when ineligible", () => {
    const wrapper = mountSaveBar({
      error: "Não foi possível salvar. Tente novamente.",
      shareEnabled: false,
    });
    const share = wrapper
      .findAll("button")
      .find((button) => button.text() === "Salvar e compartilhar");

    expect(wrapper.get('[role="alert"]').text()).toContain(
      "Não foi possível salvar. Tente novamente.",
    );
    expect(share?.attributes("disabled")).toBeDefined();
  });
});
