import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import SearchLocationHint from "@app/components/public/SearchLocationHint.vue";
import { fallbackSearchLocation } from "@app/utils/searchLocation";

const ButtonStub = defineComponent({
  name: "UButton",
  inheritAttrs: false,
  props: {
    type: { type: String, default: "button" },
    color: { type: String, default: undefined },
    variant: { type: String, default: undefined },
  },
  emits: ["click"],
  template:
    '<button v-bind="$attrs" :type="type" @click="$emit(\'click\', $event)"><slot /></button>',
});

const ModalStub = defineComponent({
  name: "UModal",
  props: {
    open: { type: Boolean, default: false },
    title: { type: String, default: "" },
    description: { type: String, default: "" },
  },
  emits: ["update:open"],
  template: `
    <section v-if="open" role="dialog" aria-modal="true" :aria-label="title">
      <h2>{{ title }}</h2>
      <p>{{ description }}</p>
      <slot name="body" />
    </section>
  `,
});

const stubs = { UButton: ButtonStub, UModal: ModalStub, UIcon: true };

describe("search location hint", () => {
  it("opens a compact city list and selects a supported city with one click", async () => {
    const wrapper = await mountSuspended(SearchLocationHint, {
      props: {
        location: fallbackSearchLocation,
        cities: [fallbackSearchLocation],
        source: "ip",
      },
      global: { stubs },
    });

    expect(wrapper.text()).toContain("Localização aproximada");
    expect(wrapper.text()).toContain("Joinville, SC");
    expect(wrapper.find("select").exists()).toBe(false);
    expect(wrapper.find('[role="dialog"]').exists()).toBe(false);

    const trigger = wrapper.get(".search-location__change");
    expect(trigger.attributes("aria-expanded")).toBe("false");
    await trigger.trigger("click");

    const dialog = wrapper.get('[role="dialog"]');
    expect(trigger.attributes("aria-expanded")).toBe("true");
    expect(dialog.attributes("aria-label")).toBe("Escolha sua cidade");
    expect(dialog.text()).toContain(
      "Mostramos apenas cidades com profissionais disponíveis.",
    );
    expect(dialog.text()).toContain("Joinville");
    expect(dialog.text()).toContain("SC");

    const city = dialog.get(".search-location__option");
    expect(city.attributes("aria-current")).toBe("location");
    await city.trigger("click");

    expect(wrapper.emitted("change")?.[0]?.[0]).toEqual(fallbackSearchLocation);
    expect(wrapper.find('[role="dialog"]').exists()).toBe(false);
  });

  it("makes the launch-city fallback visible", async () => {
    const wrapper = await mountSuspended(SearchLocationHint, {
      props: {
        location: fallbackSearchLocation,
        cities: [fallbackSearchLocation],
        source: "fallback",
      },
      global: { stubs },
    });

    expect(wrapper.text()).toContain("Buscando em Joinville, SC");
    expect(wrapper.text()).toContain("alterar cidade");
  });

  it("opens a friendly empty state when no city has available professionals", async () => {
    const wrapper = await mountSuspended(SearchLocationHint, {
      props: {
        location: fallbackSearchLocation,
        cities: [],
        source: "fallback",
      },
      global: { stubs },
    });

    await wrapper.get(".search-location__change").trigger("click");

    const dialog = wrapper.get('[role="dialog"]');
    expect(dialog.text()).toContain("Nenhuma cidade disponível");
    expect(dialog.text()).toContain(
      "Nenhuma cidade com profissionais disponíveis no momento.",
    );
    expect(dialog.find(".search-location__option").exists()).toBe(false);
    expect(dialog.find("select").exists()).toBe(false);
  });
});
