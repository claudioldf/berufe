import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import Avatar from "@app/components/design-system/Avatar.vue";

const IconStub = defineComponent({
  props: { name: { type: String, required: true } },
  template: '<span data-icon :data-name="name" />',
});

describe("design system avatar", () => {
  it("shows a supplied contextual icon instead of initials without a photo", () => {
    const wrapper = mount(Avatar, {
      props: {
        name: "Ana Souza",
        fallbackIcon: "i-lucide-zap",
      },
      global: { stubs: { UIcon: IconStub } },
    });

    expect(wrapper.get("[data-icon]").attributes("data-name")).toBe(
      "i-lucide-zap",
    );
    expect(wrapper.get(".avatar__fallback").text()).toBe("");
  });

  it("preserves initials when no contextual icon is supplied", () => {
    const wrapper = mount(Avatar, {
      props: { name: "Ana Souza" },
      global: { stubs: { UIcon: IconStub } },
    });

    expect(wrapper.find("[data-icon]").exists()).toBe(false);
    expect(wrapper.get(".avatar__fallback").text()).toBe("AS");
  });
});
