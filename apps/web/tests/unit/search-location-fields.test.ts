import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent, h } from "vue";
import SearchLocationFields from "@app/components/public/SearchLocationFields.vue";
import { fallbackSearchLocation } from "@app/utils/searchLocation";
import type { SearchLocation } from "~/types";

const curitiba: SearchLocation = {
  cityCode: "4106902",
  stateCode: "PR",
  city: "Curitiba",
  stateSlug: "pr",
  citySlug: "curitiba",
};

const cities = [fallbackSearchLocation, curitiba];

// Plain selects stand in for the Nuxt UI dropdowns so the test can drive them.
const SelectStub = defineComponent({
  name: "USelect",
  props: {
    modelValue: { type: String, default: undefined },
    items: { type: Array, default: () => [] },
  },
  emits: ["update:modelValue"],
  setup(props, { emit }) {
    return () =>
      h(
        "select",
        {
          "aria-label": "Estado",
          value: props.modelValue,
          onChange: (event: Event) =>
            emit(
              "update:modelValue",
              (event.target as HTMLSelectElement).value,
            ),
        },
        (props.items as string[]).map((item) =>
          h("option", { value: item }, item),
        ),
      );
  },
});

const SelectMenuStub = defineComponent({
  name: "USelectMenu",
  props: {
    modelValue: { type: String, default: undefined },
    items: { type: Array, default: () => [] },
    valueKey: { type: String, default: "value" },
    labelKey: { type: String, default: "label" },
  },
  emits: ["update:modelValue"],
  setup(props, { emit }) {
    return () =>
      h(
        "select",
        {
          "aria-label": "Cidade",
          value: props.modelValue ?? "",
          onChange: (event: Event) =>
            emit(
              "update:modelValue",
              (event.target as HTMLSelectElement).value,
            ),
        },
        (props.items as Record<string, string>[]).map((item) =>
          h("option", { value: item[props.valueKey] }, item[props.labelKey]),
        ),
      );
  },
});

const stubs = { USelect: SelectStub, USelectMenu: SelectMenuStub, UIcon: true };

describe("search location fields", () => {
  it("pre-fills the state and city from the detected location", async () => {
    const wrapper = await mountSuspended(SearchLocationFields, {
      props: { location: fallbackSearchLocation, cities, source: "ip" },
      global: { stubs },
    });

    expect(wrapper.text()).toContain("Sua localização aproximada:");
    expect(wrapper.text()).toContain("Joinville, SC");
    expect(wrapper.get('select[aria-label="Estado"]').element).toHaveProperty(
      "value",
      "SC",
    );
    expect(wrapper.get('select[aria-label="Cidade"]').element).toHaveProperty(
      "value",
      "joinville",
    );
  });

  it("lists only the cities of the chosen state and applies a city only when one is picked", async () => {
    const wrapper = await mountSuspended(SearchLocationFields, {
      props: { location: fallbackSearchLocation, cities, source: "manual" },
      global: { stubs },
    });

    await wrapper.get('select[aria-label="Estado"]').setValue("PR");

    const options = wrapper
      .findAll('select[aria-label="Cidade"] option')
      .map((option) => option.text());
    expect(options).toEqual(["Curitiba"]);
    expect(wrapper.emitted("change")).toBeUndefined();

    await wrapper.get('select[aria-label="Cidade"]').setValue("curitiba");

    expect(wrapper.emitted("change")?.[0]).toEqual([curitiba]);
  });
});
