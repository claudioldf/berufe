import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import SearchFailureCard from "@app/components/public/SearchFailureCard.vue";

const ButtonStub = defineComponent({
  name: "UButton",
  props: {
    type: { type: String, default: "button" },
  },
  emits: ["click"],
  template: '<button :type="type" @click="$emit(\'click\')"><slot /></button>',
});

const stubs = {
  DesignSystemSurfaceCard: {
    template: '<article class="surface-card"><slot /></article>',
  },
  UButton: ButtonStub,
  UIcon: true,
};

describe("search failure card", () => {
  it("presents a friendly retryable search error", async () => {
    const wrapper = await mountSuspended(SearchFailureCard, {
      props: {
        message: "Não conseguimos interpretar sua busca agora.",
      },
      global: { stubs },
    });

    expect(wrapper.get('[role="alert"]').text()).toContain(
      "Não foi possível concluir a busca.",
    );
    expect(wrapper.text()).toContain(
      "Não conseguimos interpretar sua busca agora.",
    );

    await wrapper.get('button[type="button"]').trigger("click");
    expect(wrapper.emitted("retry")).toHaveLength(1);
  });

  it("omits retry when the current failure should not be repeated", async () => {
    const wrapper = await mountSuspended(SearchFailureCard, {
      props: {
        message: "Aguarde um pouco e tente novamente.",
        canRetry: false,
      },
      global: { stubs },
    });

    expect(wrapper.find("button").exists()).toBe(false);
    expect(wrapper.text()).not.toContain("Sua descrição continua preenchida");
  });
});
