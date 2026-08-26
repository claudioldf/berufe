import { mountSuspended } from "@nuxt/test-utils/runtime";
import SearchLocationHint from "@app/components/public/SearchLocationHint.vue";
import { fallbackSearchLocation } from "@app/utils/searchLocation";

describe("search location hint", () => {
  it("discloses an approximate location and lets the visitor confirm a supported city", async () => {
    const wrapper = await mountSuspended(SearchLocationHint, {
      props: {
        location: fallbackSearchLocation,
        cities: [fallbackSearchLocation],
        source: "ip",
      },
      global: { stubs: { UIcon: true } },
    });

    expect(wrapper.text()).toContain("Localização aproximada");
    expect(wrapper.text()).toContain("Joinville, SC");
    expect(wrapper.find("select").exists()).toBe(false);

    await wrapper.get("button").trigger("click");
    const picker = wrapper.get("select");
    expect(picker.attributes("value")).toBe("sc/joinville");
    await picker.trigger("change");

    expect(wrapper.emitted("change")?.[0]?.[0]).toEqual(fallbackSearchLocation);
    expect(wrapper.find("select").exists()).toBe(false);
  });

  it("makes the launch-city fallback visible", async () => {
    const wrapper = await mountSuspended(SearchLocationHint, {
      props: {
        location: fallbackSearchLocation,
        cities: [fallbackSearchLocation],
        source: "fallback",
      },
      global: { stubs: { UIcon: true } },
    });

    expect(wrapper.text()).toContain("Buscando em Joinville, SC");
    expect(wrapper.text()).toContain("alterar cidade");
  });
});
