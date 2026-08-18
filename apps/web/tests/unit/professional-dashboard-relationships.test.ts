import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent, ref, shallowRef } from "vue";
import ProfessionalDashboardPage from "@app/pages/app/professional/index.vue";

const mocks = vi.hoisted(() => ({
  useWorkspace: vi.fn(),
  showToast: vi.fn(),
  share: vi.fn(),
}));

vi.mock("@app/composables/useProfessionalWorkspace", () => ({
  useProfessionalWorkspace: mocks.useWorkspace,
}));
vi.mock("@app/composables/useToast", () => ({
  useToast: () => ({ showToast: mocks.showToast }),
}));
vi.mock("@app/composables/useShare", () => ({
  useShare: () => ({ share: mocks.share }),
}));

const ButtonStub = defineComponent({
  props: {
    disabled: { type: Boolean, default: false },
    loading: { type: Boolean, default: false },
  },
  emits: ["click"],
  template:
    '<button type="button" :disabled="disabled" :data-loading="loading" @click="$emit(\'click\')"><slot /></button>',
});

const mountOptions = {
  shallow: true,
  global: {
    renderStubDefaultSlot: true,
    stubs: { UButton: ButtonStub },
  },
} as const;

function workspace(options: { pending?: boolean; failed?: boolean } = {}) {
  const respondToRelationship = vi
    .fn()
    .mockResolvedValue({ status: "accepted" });
  return {
    data: ref({
      dashboard: {
        localDate: "2026-08-18",
        readiness: {
          percentage: 100,
          steps: {
            identityContact: true,
            serviceCoverage: true,
            reviewablePortfolio: true,
            approvedIdentity: true,
          },
        },
        recentQuotes: [],
      },
      pendingRelationships: [
        {
          id: "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
          relationshipType: "worked_together",
          contextNote: "Atuamos juntos em uma obra.",
          status: "pending",
          createdAt: "2026-08-17T12:00:00Z",
          respondedAt: null,
          initiator: {
            id: "f39d4810-f28d-4977-b5e5-387131d12942",
            publicSlug: "ana-souza",
            displayName: "Ana Souza",
          },
          recipient: {
            id: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
            publicSlug: "beto-lima",
            displayName: "Beto Lima",
          },
        },
      ],
      profile: {
        id: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
        publicSlug: "beto-lima",
        status: "published",
        revisionStatus: "approved",
        revisionRejectionReason: null,
        hasPublishedRevision: true,
        photo: {
          current: null,
          hasPublishedPhoto: false,
          latestUpload: null,
        },
        portfolioItems: [],
        verification: {
          current: {
            id: "43a94f5e-1429-4ec7-bbc4-a6f805d5182d",
            verificationType: "identity",
            status: "approved",
            rejectionReason: null,
            submittedAt: "2026-08-16T12:00:00Z",
          },
        },
        identity: {
          name: "Beto Lima",
          headline: "Elétrica residencial.",
          bio: "Instalações em Joinville.",
          yearsExperience: 8,
          whatsapp: "47999991111",
          instagram: "",
          youtube: "",
        },
        services: [],
        coverage: { allJoinville: true, neighborhoods: [] },
      },
    }),
    status: shallowRef(options.pending ? "pending" : "success"),
    error: shallowRef(options.failed ? new Error("private failure") : null),
    relationshipRespondingId: shallowRef<string | null>(null),
    relationshipError: shallowRef(""),
    respondToRelationship,
  };
}

describe("professional dashboard relationships", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("renders real inbound workspace data and confirms through Rails before success feedback", async () => {
    const currentWorkspace = workspace();
    mocks.useWorkspace.mockResolvedValue(currentWorkspace);
    const wrapper = await mountSuspended(
      ProfessionalDashboardPage,
      mountOptions,
    );

    const relationshipRow = wrapper
      .findAll("article")
      .find((article) =>
        article.text().includes("Ana Souza trabalhou com você"),
      );
    expect(relationshipRow).toBeDefined();
    expect(relationshipRow!.text()).toContain("Aguardando sua resposta");

    const buttons = relationshipRow!.findAll("button");
    await buttons[1]!.trigger("click");

    expect(currentWorkspace.respondToRelationship).toHaveBeenCalledWith(
      "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
      "accepted",
    );
    expect(mocks.showToast).toHaveBeenCalledWith(
      expect.objectContaining({ title: "Colaboração confirmada" }),
    );

    const shareButton = wrapper
      .findAll("button")
      .find((button) => button.text().includes("Compartilhar perfil"));
    await shareButton!.trigger("click");
    expect(mocks.share).toHaveBeenCalledWith(
      expect.objectContaining({
        title: "Beto Lima na Berufe",
        url: "http://localhost:3000/profissionais/beto-lima",
      }),
    );
  });

  it("shows safe loading, empty, and failure feedback in the existing pending section", async () => {
    const pendingWorkspace = workspace({ pending: true });
    mocks.useWorkspace.mockResolvedValue(pendingWorkspace);
    const loading = await mountSuspended(
      ProfessionalDashboardPage,
      mountOptions,
    );
    expect(loading.text()).toContain("Carregando seu painel profissional");

    const failedWorkspace = workspace({ failed: true });
    failedWorkspace.data.value.pendingRelationships = [];
    mocks.useWorkspace.mockResolvedValue(failedWorkspace);
    const failed = await mountSuspended(
      ProfessionalDashboardPage,
      mountOptions,
    );
    expect(failed.text()).toContain("Não foi possível carregar seu painel.");
    expect(failed.text()).not.toContain("private failure");

    failedWorkspace.error.value = null;
    await failed.vm.$nextTick();
    expect(failed.text()).toContain(
      "Nenhuma pendência precisa da sua atenção agora.",
    );
    expect(failed.text()).toContain("Nenhum orçamento criado ainda.");
  });

  it("shows real rejected work and the server-calculated readiness", async () => {
    const currentWorkspace = workspace();
    currentWorkspace.data.value.dashboard.readiness.percentage = 25;
    currentWorkspace.data.value.pendingRelationships = [];
    currentWorkspace.data.value.profile.status = "draft";
    currentWorkspace.data.value.profile.revisionStatus = "rejected";
    currentWorkspace.data.value.profile.revisionRejectionReason =
      "A apresentação precisa de mais detalhes.";
    currentWorkspace.data.value.profile.verification.current!.status =
      "rejected";
    currentWorkspace.data.value.profile.verification.current!.rejectionReason =
      "A imagem não está legível.";
    mocks.useWorkspace.mockResolvedValue(currentWorkspace);

    const wrapper = await mountSuspended(
      ProfessionalDashboardPage,
      mountOptions,
    );

    expect(wrapper.text()).toContain("Seu perfil precisa de ajustes");
    expect(wrapper.text()).toContain(
      "A apresentação precisa de mais detalhes.",
    );
    expect(wrapper.text()).toContain("A imagem não está legível.");
    expect(
      wrapper.find("dashboard-checklist-stub").attributes("readiness"),
    ).toBe("25");
  });
});
