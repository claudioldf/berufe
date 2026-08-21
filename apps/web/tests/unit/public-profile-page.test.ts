import { mountSuspended } from "@nuxt/test-utils/runtime";
import { flushPromises } from "@vue/test-utils";
import { useState } from "#app";
import type { PublicProfessionalProfileResult } from "@app/types";
import type { CurrentAccount } from "@app/services/api/application-session";
import PublicProfilePage from "@app/pages/profissionais/[slug].vue";

const mocks = vi.hoisted(() => ({
  client: {},
  fetchProfile: vi.fn(),
  recordView: vi.fn(),
}));

vi.mock("@app/services/api/client", () => ({
  useApiClient: () => mocks.client,
}));
vi.mock("@app/services/api/public-discovery", () => ({
  fetchPublicProfessionalProfile: mocks.fetchProfile,
  recordPublicProfessionalProfileView: mocks.recordView,
}));

const result: PublicProfessionalProfileResult = {
  professional: {
    id: "ad59e74a-a1aa-47d5-b725-26350f0f2376",
    slug: "ana-souza",
    name: "Ana Souza",
    profileType: "self_service",
    claimed: true,
    headline: "Elétrica residencial.",
    bio: "Instalações residenciais.",
    avatar: null,
    primaryService: "Eletricista",
    primaryServiceSlug: "eletricista",
    services: ["Eletricista"],
    serviceNotes: ["Quadros elétricos"],
    neighborhoods: ["América"],
    allJoinville: false,
    yearsExperience: 11,
    evidence: [
      {
        id: "phone",
        type: "phone",
        label: "Telefone confirmado",
        verifiedAt: null,
      },
    ],
    portfolio: [],
    relationships: [],
    updatedAt: "2026-08-17T12:00:00Z",
  },
  interactionToken: "signed-profile-interaction",
};

describe("public profile page", () => {
  beforeEach(async () => {
    vi.clearAllMocks();
    useState("application-session-status", () => "unknown").value = "unknown";
    useState<CurrentAccount | null>(
      "application-session-account",
      () => null,
    ).value = null;
    mocks.fetchProfile.mockResolvedValue(result);
    mocks.recordView.mockResolvedValue(undefined);
  });

  it("loads the Rails projection, preserves finder context, and records after rendering", async () => {
    const wrapper = await mountSuspended(PublicProfilePage, {
      shallow: true,
      route:
        "/profissionais/ana-souza?servico=eletricista&bairro=america&contexto=signed-search-context",
    });
    await flushPromises();

    expect(mocks.fetchProfile).toHaveBeenCalledWith(
      mocks.client,
      "ana-souza",
      "signed-search-context",
    );
    expect(mocks.recordView).toHaveBeenCalledWith(
      mocks.client,
      result.professional.id,
      "signed-profile-interaction",
    );
    const hero = wrapper.getComponent({ name: "ProfileHero" });
    expect(hero.props("professional")).toEqual(result.professional);
    expect(hero.props("resultsUrl")).toBe(
      "/encontrar?servico=eletricista&bairro=america",
    );
    const contactUrl = new URL(String(hero.props("contactUrl")));
    expect(contactUrl.pathname).toBe(
      `/api/v1/public/professionals/${result.professional.id}/whatsapp`,
    );
    expect(contactUrl.searchParams.get("source")).toBe("public_profile");
    expect(contactUrl.searchParams.get("interaction_token")).toBe(
      "signed-profile-interaction",
    );
    expect(contactUrl.searchParams.has("interactionToken")).toBe(false);
    expect(wrapper.html()).not.toContain("@data/professionals");
  });

  it("does not let a view-metric failure replace the rendered profile", async () => {
    mocks.recordView.mockRejectedValue(new Error("metric unavailable"));

    const wrapper = await mountSuspended(PublicProfilePage, {
      shallow: true,
      route:
        "/profissionais/ana-souza?servico=eletricista&bairro=america&contexto=signed-search-context",
    });
    await flushPromises();

    expect(wrapper.getComponent({ name: "ProfileHero" }).exists()).toBe(true);
    expect(mocks.recordView).toHaveBeenCalledOnce();
  });

  it("selects the simplified public layout for an external profile", async () => {
    const externalResult: PublicProfessionalProfileResult = {
      ...result,
      professional: {
        ...result.professional,
        slug: "carla-pinturas",
        name: "Carla Pinturas",
        profileType: "external",
        claimed: false,
        headline: null,
        bio: null,
        primaryService: null,
        primaryServiceSlug: null,
        services: [],
        serviceNotes: [],
        neighborhoods: [],
        yearsExperience: null,
        evidence: [],
      },
    };
    mocks.fetchProfile.mockResolvedValue(externalResult);

    const wrapper = await mountSuspended(PublicProfilePage, {
      shallow: true,
      route: "/profissionais/carla-pinturas",
    });
    await flushPromises();

    const external = wrapper.getComponent({ name: "ProfileExternalProfile" });
    expect(external.props("professional")).toEqual(externalResult.professional);
    expect(wrapper.findComponent({ name: "ProfileHero" }).exists()).toBe(false);
    expect(wrapper.findComponent({ name: "ProfileDetails" }).exists()).toBe(
      false,
    );
  });

  it("keeps relationship requests out of the public profile", async () => {
    useState("application-session-status", () => "unknown").value =
      "authenticated";
    useState<CurrentAccount | null>(
      "application-session-account",
      () => null,
    ).value = {
      id: "0f1f76eb-ce21-4e39-83c8-acfc255101f1",
      role: "professional",
      status: "active",
      registered: true,
      verified: true,
      registrationCompleted: true,
      registrationDisplayName: "Outra profissional",
      professionalProfileId: "fc34e59b-0915-45c1-b0ea-29015578264a",
      relationshipEligible: true,
    };

    const wrapper = await mountSuspended(PublicProfilePage, {
      shallow: true,
      route: "/profissionais/ana-souza",
      global: { renderStubDefaultSlot: true },
    });
    await flushPromises();

    expect(wrapper.getComponent({ name: "ProfileDetails" }).exists()).toBe(
      true,
    );
    expect(
      wrapper.findComponent({ name: "RelationshipCreateDialog" }).exists(),
    ).toBe(false);
    expect(wrapper.text()).not.toContain("Conectar");
  });
});
