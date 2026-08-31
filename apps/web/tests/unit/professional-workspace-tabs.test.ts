import { mountSuspended } from "@nuxt/test-utils/runtime";
import ProfessionalWorkspaceTabs from "@app/components/dashboard/ProfessionalWorkspaceTabs.vue";

vi.mock("~/composables/useApplicationSession", async () => {
  const { ref } = await import("vue");
  return {
    useApplicationSession: () => ({
      account: ref({
        role: "professional",
        registrationCompleted: true,
      }),
      restoreSession: vi.fn().mockResolvedValue(true),
    }),
  };
});

describe("professional workspace tabs", () => {
  it("links from profile sections to the dedicated customer page", async () => {
    const wrapper = await mountSuspended(ProfessionalWorkspaceTabs, {
      props: { portfolioCount: 4, relationshipCount: 2 },
      route: "/app/professional/profile?tab=portfolio",
    });

    expect(
      wrapper.get('[href="/app/professional/customers"]').text(),
    ).toContain("Clientes");
    expect(wrapper.findAll("nav > a").map((link) => link.text())).toEqual([
      "Dados do perfil",
      "Meus trabalhos 4",
      "Clientes",
      "Recomendações",
      "Minha rede 2",
      "Verificações",
    ]);
    expect(
      wrapper
        .get('[href="/app/professional/profile?tab=portfolio"]')
        .attributes("aria-current"),
    ).toBe("page");
    expect(wrapper.text()).toContain("4");
  });

  it("marks customers active throughout the customer directory", async () => {
    const wrapper = await mountSuspended(ProfessionalWorkspaceTabs, {
      route: "/app/professional/customers/a3f42858-40bc-4bda-bb66-35f32eece27c",
    });

    expect(
      wrapper
        .get('[href="/app/professional/customers"]')
        .attributes("aria-current"),
    ).toBe("page");
  });

  it("marks recommendations active on its own dedicated route", async () => {
    const wrapper = await mountSuspended(ProfessionalWorkspaceTabs, {
      route: "/app/professional/recommendations",
    });

    expect(
      wrapper
        .get('[href="/app/professional/recommendations"]')
        .attributes("aria-current"),
    ).toBe("page");
  });
});
