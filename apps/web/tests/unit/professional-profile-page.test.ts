import { mountSuspended } from "@nuxt/test-utils/runtime";
import { flushPromises } from "@vue/test-utils";
import { ref, shallowRef } from "vue";
import professionalsData from "@data/professionals.json";
import ProfessionalProfilePage from "@app/pages/app/professional/profile.vue";

const mocks = vi.hoisted(() => ({
  useWorkspace: vi.fn(),
  useCatalogs: vi.fn(),
  showToast: vi.fn(),
}));

vi.mock("@app/composables/useProfessionalWorkspace", () => ({
  useProfessionalWorkspace: mocks.useWorkspace,
}));
vi.mock("@app/composables/useCatalogs", () => ({
  useCatalogs: mocks.useCatalogs,
}));
vi.mock("@app/composables/useToast", () => ({
  useToast: () => ({ showToast: mocks.showToast }),
}));

const fixture = (professionalsData as Array<Record<string, unknown>>)[0]!;

function catalog() {
  return {
    data: ref({
      categories: [],
      services: [
        {
          id: "c43071a5-4c47-4324-99ef-41846ee35538",
          name: "Eletricista do painel",
          slug: "eletricista-painel",
          category: "instalacoes",
          icon: "i-lucide-zap",
          description: "Instalações elétricas.",
          aliases: [],
        },
      ],
      neighborhoods: [
        {
          code: "all",
          name: "Toda Joinville",
          stateCode: "SC",
          city: "Joinville",
        },
        {
          code: "america",
          name: "América",
          stateCode: "SC",
          city: "Joinville",
        },
      ],
    }),
    error: shallowRef(null),
  };
}

function workspace() {
  return {
    data: ref({
      dashboard: {
        localDate: "2026-08-19",
        readiness: {
          percentage: 100,
          steps: {
            identityContact: true,
            serviceCoverage: true,
            reviewablePortfolio: true,
            approvedIdentity: true,
          },
        },
        changeRequestedQuotes: [],
        recentQuotes: [],
        recentServiceJobs: [],
      },
      pendingRelationships: [],
      relationships: [],
      profile: {
        id: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
        publicSlug: "beto-lima",
        status: "published" as const,
        presentationType: "self_service" as const,
        isPublic: true,
        isSearchEligible: true,
        publicationBlockers: [],
        revisionStatus: "approved" as const,
        revisionRejectionReason: null,
        hasPublishedRevision: true,
        photo: {
          current: null,
          hasPublishedPhoto: false,
          publishedImageUrl: null,
          latestUpload: null,
        },
        portfolioItems: [],
        verification: { current: null },
        identity: {
          name: "Beto Lima",
          birthdate: "1990-04-12",
          headline: "Elétrica residencial.",
          bio: "Instalações em Joinville.",
          yearsExperience: 8,
          whatsapp: "47999991111",
          instagram: "",
          youtube: "",
        },
        services: [
          {
            id: "c43071a5-4c47-4324-99ef-41846ee35538",
            name: "Eletricista do painel",
            isPrimary: true,
            note: "",
          },
        ],
        coverage: {
          allJoinville: false,
          neighborhoods: [{ code: "america", name: "América" }],
        },
      },
    }),
    error: shallowRef(null),
    saveProfile: vi.fn(),
    photoUploading: shallowRef(false),
    photoRemoving: shallowRef(false),
    photoError: shallowRef(""),
    uploadPhoto: vi.fn(),
    retryPhoto: vi.fn(),
    removePhoto: vi.fn(),
    portfolioSaving: shallowRef(false),
    createPortfolioItem: vi.fn(),
    deletePortfolioItem: vi.fn(),
    verificationSaving: shallowRef(false),
    verificationError: shallowRef(""),
    createVerificationRequest: vi.fn(),
    relationshipRespondingId: shallowRef<string | null>(null),
    relationshipRemovingId: shallowRef<string | null>(null),
    relationshipError: shallowRef(""),
    respondToRelationship: vi.fn(),
    removeRelationship: vi.fn(),
  };
}

describe("professional profile editor page", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.useCatalogs.mockResolvedValue(catalog());
    mocks.useWorkspace.mockResolvedValue(workspace());
  });

  it("builds the editor only from the authenticated workspace, never from a fixture", async () => {
    const wrapper = await mountSuspended(ProfessionalProfilePage, {
      shallow: true,
      global: { renderStubDefaultSlot: true },
    });

    const editor = wrapper.getComponent({ name: "DashboardProfileEditor" });
    const professional = editor.props("professional") as Record<
      string,
      unknown
    >;

    expect(professional).toMatchObject({
      id: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
      slug: "beto-lima",
      name: "Beto Lima",
      headline: "Elétrica residencial.",
      bio: "Instalações em Joinville.",
      primaryService: "Eletricista do painel",
      primaryServiceSlug: "eletricista-painel",
      yearsExperience: 8,
      allJoinville: false,
      neighborhoods: ["América"],
    });

    // Nothing may survive from data/professionals.json, whichever fields the
    // Professional type grows next.
    for (const [key, value] of Object.entries(fixture)) {
      if (typeof value !== "string" || !value) continue;
      expect(professional[key]).not.toBe(value);
    }
    expect(JSON.stringify(professional)).not.toContain(fixture.name as string);
    expect(wrapper.html()).not.toContain(fixture.name as string);
  });

  it("opens the URL-backed relationships tab and delegates relationship mutations", async () => {
    const currentWorkspace = workspace();
    currentWorkspace.data.value.relationships = [
      {
        id: "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
        relationshipType: "recommendation",
        contextNote: "Executamos uma reforma juntos.",
        status: "accepted",
        source: "existing_profile",
        createdAt: "2026-08-17T12:00:00Z",
        respondedAt: "2026-08-18T12:00:00Z",
        initiator: {
          id: currentWorkspace.data.value.profile.id,
          publicSlug: "beto-lima",
          displayName: "Beto Lima",
          profileType: "self_service",
          photoUrl: null,
          profileAvailable: true,
        },
        recipient: {
          id: "f39d4810-f28d-4977-b5e5-387131d12942",
          publicSlug: "ana-souza",
          displayName: "Ana Souza",
          profileType: "self_service",
          photoUrl: null,
          profileAvailable: true,
        },
      },
    ];
    mocks.useWorkspace.mockResolvedValue(currentWorkspace);

    const wrapper = await mountSuspended(ProfessionalProfilePage, {
      shallow: true,
      global: { renderStubDefaultSlot: true },
    });

    await useRouter().replace("/?tab=relacoes");
    await flushPromises();

    const manager = wrapper.getComponent({
      name: "DashboardRelationshipManager",
    });
    expect(manager.props("relationships")).toHaveLength(1);
    expect(manager.props("ownerId")).toBe(
      currentWorkspace.data.value.profile.id,
    );
    manager.vm.$emit("add");
    await wrapper.vm.$nextTick();
    expect(
      wrapper.getComponent({ name: "RelationshipCreateDialog" }).props("open"),
    ).toBe(true);

    manager.vm.$emit(
      "respond",
      "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
      "accepted",
    );
    await flushPromises();
    expect(currentWorkspace.respondToRelationship).toHaveBeenCalledWith(
      "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
      "accepted",
    );

    manager.vm.$emit("remove", "d25c64fa-3e6a-4e56-adc9-85bdac0045cb");
    await flushPromises();
    expect(currentWorkspace.removeRelationship).toHaveBeenCalledWith(
      "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
    );
    expect(mocks.showToast).toHaveBeenCalledWith(
      expect.objectContaining({ title: "Conexão removida" }),
    );
  });

  it("delegates confirmed profile-photo removal and reports success", async () => {
    const currentWorkspace = workspace();
    currentWorkspace.data.value.profile.photo = {
      current: {
        id: "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
        status: "approved",
        rejectionReason: null,
        submittedAt: "2026-08-23T12:00:00Z",
      },
      hasPublishedPhoto: true,
      publishedImageUrl: "https://api.example.test/profile-photo.jpg",
      latestUpload: null,
    };
    currentWorkspace.removePhoto.mockResolvedValue(currentWorkspace.data.value);
    mocks.useWorkspace.mockResolvedValue(currentWorkspace);

    const wrapper = await mountSuspended(ProfessionalProfilePage, {
      shallow: true,
      global: { renderStubDefaultSlot: true },
    });
    const editor = wrapper.getComponent({ name: "DashboardProfileEditor" });

    editor.vm.$emit("photoRemove");
    await flushPromises();

    expect(currentWorkspace.removePhoto).toHaveBeenCalledOnce();
    expect(mocks.showToast).toHaveBeenCalledWith({
      title: "Foto removida",
      description:
        "Ela não aparece mais no perfil. Adicione outra foto para publicá-lo novamente.",
    });
  });
});
