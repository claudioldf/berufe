import { mountSuspended } from "@nuxt/test-utils/runtime";
import VisibilitySection from "@app/components/dashboard/profile/VisibilitySection.vue";

describe("profile visibility section", () => {
  it("explains all visibility levels and saves an explicit user selection", async () => {
    const wrapper = await mountSuspended(VisibilitySection, {
      props: {
        visibility: "discoverable",
        publicProfilePath: "/profissionais/ana-souza",
      },
    });

    expect(wrapper.text()).toContain("Público e encontrável");
    expect(wrapper.text()).toContain("Somente com o link");
    expect(wrapper.text()).toContain("Perfil despublicado");
    expect(wrapper.get('a[href="/profissionais/ana-souza"]').exists()).toBe(
      true,
    );
    expect(wrapper.get('button[type="submit"]').attributes("disabled")).toBe(
      "",
    );

    await wrapper.get('input[value="direct_link"]').setValue(true);
    expect(
      wrapper.get('button[type="submit"]').attributes("disabled"),
    ).toBeUndefined();
    await wrapper.get("form").trigger("submit");

    expect(wrapper.emitted("save")).toEqual([["direct_link"]]);
  });

  it("disables changes with a visible reason when the profile is unavailable", async () => {
    const wrapper = await mountSuspended(VisibilitySection, {
      props: {
        visibility: "unpublished",
        publicProfilePath: "/profissionais/ana-souza",
        disabledReason: "Publique o perfil para escolher sua visibilidade.",
      },
    });

    expect(wrapper.text()).toContain(
      "Publique o perfil para escolher sua visibilidade.",
    );
    expect(wrapper.find('a[href="/profissionais/ana-souza"]').exists()).toBe(
      false,
    );
    expect(wrapper.get("fieldset").attributes("disabled")).toBe("");

    await wrapper.get('input[value="discoverable"]').setValue(true);
    await wrapper.get("form").trigger("submit");
    expect(wrapper.emitted("save")).toBeUndefined();
  });
});
