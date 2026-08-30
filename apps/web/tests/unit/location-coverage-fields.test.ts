import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent, readonly, shallowRef } from "vue";
import LocationCoverageFields from "@app/components/location/LocationCoverageFields.vue";

const mocks = vi.hoisted(() => ({
  initialize: vi.fn(),
  loadCities: vi.fn(),
  loadNeighborhoods: vi.fn(),
}));

vi.mock("@app/composables/useLocations", () => {
  const states = shallowRef([
    { code: "42", abbreviation: "SC", name: "Santa Catarina" },
  ]);
  const cities = shallowRef([
    {
      code: "4209102",
      name: "Joinville",
      slug: "joinville",
      stateCode: "42",
      stateAbbreviation: "SC",
      stateName: "Santa Catarina",
    },
  ]);
  const neighborhoods = shallowRef([
    { code: "4209102007", cityCode: "4209102", name: "América" },
  ]);

  return {
    useLocations: () => ({
      states: readonly(states),
      cities: readonly(cities),
      neighborhoods: readonly(neighborhoods),
      loading: readonly(shallowRef(false)),
      error: readonly(shallowRef("")),
      initialize: mocks.initialize,
      loadCities: mocks.loadCities,
      loadNeighborhoods: mocks.loadNeighborhoods,
    }),
  };
});

const FormFieldStub = defineComponent({
  props: {
    id: { type: String, default: "field" },
    error: { type: String, default: "" },
  },
  template: `
    <label>
      <slot
        :control-id="id"
        :described-by="error ? id + '-error' : undefined"
        :invalid="Boolean(error)"
      />
      <span v-if="error" :id="id + '-error'" role="alert">{{ error }}</span>
    </label>
  `,
});

describe("location coverage fields", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.initialize.mockResolvedValue(null);
    mocks.loadCities.mockResolvedValue([]);
    mocks.loadNeighborhoods.mockResolvedValue([
      { code: "4209102007", cityCode: "4209102", name: "América" },
    ]);
  });

  it("selects a state, city, and official IBGE neighborhood by code", async () => {
    const wrapper = await mountSuspended(LocationCoverageFields, {
      props: {
        modelValue: {
          cityCode: "",
          wholeCity: false,
          neighborhoodCodes: [],
        },
      },
      global: {
        stubs: {
          DesignSystemFormField: FormFieldStub,
          UIcon: true,
        },
      },
    });

    await wrapper.get('select[name="coverage-state"]').setValue("42");
    await wrapper.setProps({
      modelValue: wrapper.emitted("update:modelValue")!.at(-1)![0],
    });
    await wrapper.get('select[name="coverage-city"]').setValue("4209102");
    await wrapper.setProps({
      modelValue: wrapper.emitted("update:modelValue")!.at(-1)![0],
    });
    await wrapper
      .get(".location-coverage-fields__neighborhoods button")
      .trigger("click");

    expect(mocks.loadCities).toHaveBeenCalledWith("SC");
    expect(mocks.loadNeighborhoods).toHaveBeenCalledWith("4209102");
    expect(wrapper.emitted("update:modelValue")!.at(-1)).toEqual([
      {
        cityCode: "4209102",
        wholeCity: false,
        neighborhoodCodes: ["4209102007"],
      },
    ]);
  });

  it("places an incomplete coverage error on the first available selector", async () => {
    const wrapper = await mountSuspended(LocationCoverageFields, {
      props: {
        modelValue: {
          cityCode: "",
          wholeCity: false,
          neighborhoodCodes: [],
        },
        validationError: "Selecione uma cidade e a área atendida.",
      },
      global: {
        stubs: {
          DesignSystemFormField: FormFieldStub,
          UIcon: true,
        },
      },
    });

    expect(
      wrapper.get('select[name="coverage-state"]').attributes("aria-invalid"),
    ).toBe("true");
    expect(wrapper.get('[role="alert"]').text()).toContain(
      "Selecione uma cidade",
    );
  });
});
