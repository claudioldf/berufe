import { mockNuxtImport, mountSuspended } from "@nuxt/test-utils/runtime";
import { mount } from "@vue/test-utils";
import { defineComponent, ref, shallowRef } from "vue";
import DashboardChecklist from "@app/components/dashboard/DashboardChecklist.vue";
import DashboardQuickActions from "@app/components/dashboard/DashboardQuickActions.vue";
import ProfessionalDashboardPage from "@app/pages/app/professional/index.vue";
import type { ProfessionalRelationship } from "~/types";

const mocks = vi.hoisted(() => ({
  useWorkspace: vi.fn(),
  useCatalogs: vi.fn(),
  showToast: vi.fn(),
  share: vi.fn(),
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
vi.mock("@app/composables/useShare", () => ({
  useShare: () => ({ share: mocks.share }),
}));
// withSiteUrl resolves relatively (no request host) outside a real SSR
// request context; pin it to an absolute origin to match production.
mockNuxtImport("withSiteUrl", () => {
  return (path: string) => ({ value: `http://localhost:3000${path}` });
});

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
    stubs: {
      UButton: ButtonStub,
      DashboardActivitySections: false,
      DashboardChecklist: false,
      DashboardQuickActions: false,
      DashboardQuoteEmptyState: false,
      DashboardRecentWork: false,
      DesignSystemFeatureEmptyState: false,
    },
  },
} as const;

const owner = {
  id: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
  publicSlug: "beto-lima",
  displayName: "Beto Lima",
  profileType: "self_service" as const,
  photoUrl: null,
  profileAvailable: false,
};
const otherProfessional = {
  id: "f39d4810-f28d-4977-b5e5-387131d12942",
  publicSlug: "ana-souza",
  displayName: "Ana Souza",
  profileType: "self_service" as const,
  photoUrl: null,
  profileAvailable: false,
};

function pendingRelationship(
  direction: "incoming" | "outgoing" = "incoming",
): ProfessionalRelationship {
  return {
    id: "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
    relationshipType: "worked_together",
    contextNote: "Atuamos juntos em uma obra.",
    status: "pending",
    source: "existing_profile",
    createdAt: "2026-08-17T12:00:00Z",
    respondedAt: null,
    initiator: direction === "outgoing" ? owner : otherProfessional,
    recipient: direction === "outgoing" ? otherProfessional : owner,
  };
}

function workspace(options: { pending?: boolean; failed?: boolean } = {}) {
  const respondToRelationship = vi
    .fn()
    .mockResolvedValue({ status: "accepted" });
  const inboundRelationship = pendingRelationship();
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
        changeRequestedQuotes: [],
        recentQuotes: [],
        recentServiceJobs: [],
      },
      pendingRelationships: [inboundRelationship],
      relationships: [inboundRelationship],
      profile: {
        id: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
        publicSlug: "beto-lima",
        status: "published",
        presentationType: "self_service" as const,
        isPublic: true,
        isSearchEligible: true,
        isIndexable: true,
        publicationBlockers: [],
        revisionStatus: "approved",
        revisionRejectionReason: null,
        hasPublishedRevision: true,
        photo: {
          current: null,
          hasPublishedPhoto: false,
          publishedImageUrl: null,
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
          birthdate: "1990-04-12",
          headline: "Elétrica residencial.",
          bio: "Instalações em Joinville.",
          yearsExperience: 8,
          whatsapp: "47999991111",
          instagram: "",
          youtube: "",
        },
        services: [],
        coverage: {
          city: {
            code: "4209102",
            name: "Joinville",
            slug: "joinville",
            stateCode: "42",
            stateAbbreviation: "SC",
            stateName: "Santa Catarina",
          },
          wholeCity: true,
          neighborhoods: [],
        },
      },
    }),
    status: shallowRef(options.pending ? "pending" : "success"),
    error: shallowRef(options.failed ? new Error("private failure") : null),
    relationshipRespondingId: shallowRef<string | null>(null),
    relationshipError: shallowRef(""),
    submissionSaving: shallowRef(false),
    submissionError: shallowRef(""),
    submitProfile: vi.fn().mockResolvedValue(undefined),
    respondToRelationship,
  };
}

describe("professional dashboard", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.useCatalogs.mockResolvedValue({
      data: ref({
        categories: [],
        services: [],
        cities: [
          {
            cityCode: "4209102",
            stateCode: "SC",
            city: "Joinville",
            stateSlug: "sc",
            citySlug: "joinville",
          },
        ],
      }),
      error: shallowRef(null),
    });
  });

  it("opens the shared relationship dialog from the quick action", async () => {
    mocks.useWorkspace.mockResolvedValue(workspace());
    const wrapper = await mountSuspended(
      ProfessionalDashboardPage,
      mountOptions,
    );

    const add = wrapper.get(
      '.actions-card button[aria-label="Recomendar um profissional"]',
    );
    await add.trigger("click");

    expect(
      wrapper.getComponent({ name: "RelationshipCreateDialog" }).props("open"),
    ).toBe(true);
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
    expect(relationshipRow!.text()).not.toContain("Aguardando sua resposta");

    const buttons = relationshipRow!.findAll("button");
    await buttons[1]!.trigger("click");

    expect(currentWorkspace.respondToRelationship).toHaveBeenCalledWith(
      "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
      "accepted",
    );
    expect(mocks.showToast).toHaveBeenCalledWith(
      expect.objectContaining({
        title: "Vocês estão conectados",
        description: "A conexão já pode aparecer nos perfis públicos.",
      }),
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

  it("shows outbound pending connections without recipient response actions", async () => {
    const currentWorkspace = workspace();
    currentWorkspace.data.value.pendingRelationships = [];
    currentWorkspace.data.value.relationships = [
      pendingRelationship("outgoing"),
    ];
    mocks.useWorkspace.mockResolvedValue(currentWorkspace);

    const wrapper = await mountSuspended(
      ProfessionalDashboardPage,
      mountOptions,
    );

    const relationshipRow = wrapper
      .findAll("article")
      .find((article) =>
        article.text().includes("Você trabalhou com Ana Souza"),
      );
    expect(relationshipRow).toBeDefined();
    expect(relationshipRow!.text()).toContain("Aguardando confirmação");
    expect(relationshipRow!.text()).toContain("Enviado em");
    expect(relationshipRow!.findAll("button")).toHaveLength(0);
  });

  it("continues the hero with quick actions before dashboard content", async () => {
    mocks.useWorkspace.mockResolvedValue(workspace());
    const wrapper = await mountSuspended(
      ProfessionalDashboardPage,
      mountOptions,
    );

    const visibleText = wrapper.text();
    const statusIndex = visibleText.indexOf("Seu perfil está publicado");
    const quickActionsIndex = visibleText.indexOf("Editar perfil");
    const activityIndex = visibleText.indexOf("Para resolver.");
    const quoteEmptyIndex = visibleText.indexOf(
      "Transforme pedidos em trabalhos fechados.",
    );
    const progressIndex = visibleText.indexOf("100% completo");

    expect(quickActionsIndex).toBeGreaterThanOrEqual(0);
    expect(statusIndex).toBeGreaterThan(quickActionsIndex);
    expect(statusIndex).toBeGreaterThanOrEqual(0);
    expect(activityIndex).toBeGreaterThan(statusIndex);
    expect(quoteEmptyIndex).toBeGreaterThan(activityIndex);
    expect(visibleText).not.toContain("Ferramentas");
    expect(visibleText).not.toContain("Orçamentos recentes.");
    expect(visibleText).not.toContain("Ações rápidas");
    expect(progressIndex).toBeGreaterThan(quoteEmptyIndex);
    expect(wrapper.findAll(".actions-card")).toHaveLength(1);
    expect(wrapper.find(".dashboard-welcome .actions-card").exists()).toBe(
      true,
    );
    expect(wrapper.find(".dashboard-content .actions-card").exists()).toBe(
      false,
    );
    expect(wrapper.find('a[aria-label="Ver verificações"]').exists()).toBe(
      false,
    );
    expect(wrapper.find(".dashboard-sidebar .actions-card").exists()).toBe(
      false,
    );
  });

  it("shows safe loading and failure feedback and hides empty activity sections", async () => {
    const pendingWorkspace = workspace({ pending: true });
    mocks.useWorkspace.mockResolvedValue(pendingWorkspace);
    const loading = await mountSuspended(
      ProfessionalDashboardPage,
      mountOptions,
    );
    expect(loading.text()).toContain("Carregando seu painel profissional");

    const failedWorkspace = workspace({ failed: true });
    failedWorkspace.data.value.pendingRelationships = [];
    failedWorkspace.data.value.relationships = [];
    mocks.useWorkspace.mockResolvedValue(failedWorkspace);
    const failed = await mountSuspended(
      ProfessionalDashboardPage,
      mountOptions,
    );
    expect(failed.text()).toContain("Não foi possível carregar seu painel.");
    expect(failed.text()).not.toContain("private failure");

    failedWorkspace.error.value = null;
    await failed.vm.$nextTick();
    expect(failed.find(".dashboard-activity").exists()).toBe(false);
    expect(failed.text()).toContain(
      "Transforme pedidos em trabalhos fechados.",
    );
  });

  it("shows real rejected work and the server-calculated readiness", async () => {
    const currentWorkspace = workspace();
    currentWorkspace.data.value.dashboard.readiness.percentage = 25;
    currentWorkspace.data.value.pendingRelationships = [];
    currentWorkspace.data.value.profile.status = "draft";
    currentWorkspace.data.value.profile.isPublic = false;
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
    expect(wrapper.findComponent(DashboardChecklist).props("readiness")).toBe(
      25,
    );
  });

  it("nudges toward search visibility for a published profile that is not yet indexable", async () => {
    const currentWorkspace = workspace();
    currentWorkspace.data.value.profile.isPublic = true;
    currentWorkspace.data.value.profile.isIndexable = false;
    mocks.useWorkspace.mockResolvedValue(currentWorkspace);

    const wrapper = await mountSuspended(
      ProfessionalDashboardPage,
      mountOptions,
    );

    expect(wrapper.text()).toContain("Seu perfil ainda não aparece no Google.");
  });

  it("does not show the search-visibility nudge once the profile is indexable", async () => {
    const currentWorkspace = workspace();
    currentWorkspace.data.value.profile.isPublic = true;
    currentWorkspace.data.value.profile.isIndexable = true;
    mocks.useWorkspace.mockResolvedValue(currentWorkspace);

    const wrapper = await mountSuspended(
      ProfessionalDashboardPage,
      mountOptions,
    );

    expect(wrapper.text()).not.toContain(
      "Seu perfil ainda não aparece no Google.",
    );
  });

  it("publishes a complete draft directly from the status banner", async () => {
    const currentWorkspace = workspace();
    currentWorkspace.data.value.dashboard.readiness.percentage = 75;
    currentWorkspace.data.value.profile.status = "draft";
    currentWorkspace.data.value.profile.isPublic = false;
    currentWorkspace.data.value.profile.isSearchEligible = false;
    currentWorkspace.data.value.profile.revisionStatus = "draft";
    currentWorkspace.data.value.profile.hasPublishedRevision = false;
    mocks.useWorkspace.mockResolvedValue(currentWorkspace);

    const wrapper = await mountSuspended(
      ProfessionalDashboardPage,
      mountOptions,
    );

    expect(wrapper.text()).toContain("Seu perfil está pronto para publicar");
    expect(wrapper.text()).toContain("Os dados obrigatórios estão completos.");

    const publishButton = wrapper
      .findAll("button")
      .find((button) => button.text().includes("Publicar perfil"));
    expect(publishButton).toBeDefined();
    await publishButton!.trigger("click");

    expect(currentWorkspace.submitProfile).toHaveBeenCalledOnce();
    expect(mocks.showToast).toHaveBeenCalledWith({
      title: "Perfil publicado",
      description: "Clientes já podem encontrar e entrar em contato com você.",
    });
    expect(wrapper.findComponent(DashboardChecklist).props("canPublish")).toBe(
      true,
    );
  });

  it("hides completed checklist items and emits the publish action", async () => {
    const wrapper = mount(DashboardChecklist, {
      props: {
        readiness: 75,
        canPublish: true,
        publishing: false,
        items: [
          {
            id: "profile",
            label: "Base do perfil",
            description: "Nome, foto, nascimento e contato",
            icon: "i-lucide-user-round",
            done: true,
            to: "/app/professional/profile",
          },
          {
            id: "portfolio",
            label: "Primeiro trabalho",
            description: "Um trabalho em análise ou aprovado",
            icon: "i-lucide-image-plus",
            done: false,
            to: "/app/professional/profile?tab=portfolio",
          },
        ],
      },
      global: {
        stubs: {
          DesignSystemSurfaceCard: { template: "<section><slot /></section>" },
          NuxtLink: { template: "<a><slot /></a>" },
          UButton: ButtonStub,
          UIcon: true,
        },
      },
    });

    expect(wrapper.text()).not.toContain("Base do perfil");
    expect(wrapper.text()).toContain("Primeiro trabalho");

    const publishButton = wrapper.get("button");
    expect(publishButton.text()).toContain("Publicar perfil");
    await publishButton.trigger("click");
    expect(wrapper.emitted("publish")).toEqual([[]]);
  });

  it("renders compact quick actions and emits the recommendation action", async () => {
    const wrapper = mount(DashboardQuickActions, {
      global: {
        stubs: {
          DesignSystemSurfaceCard: { template: "<section><slot /></section>" },
          NuxtLink: {
            props: ["to"],
            template: '<a :href="to"><slot /></a>',
          },
          UIcon: true,
        },
      },
    });

    expect(wrapper.findAll("a").map((link) => link.attributes("href"))).toEqual(
      [
        "/app/professional/profile?tab=portfolio",
        "/app/professional/profile?tab=verificacoes",
        "/app/professional/services",
        "/app/professional/profile",
      ],
    );
    expect(wrapper.get(".actions-card").attributes("aria-label")).toBe(
      "Ações rápidas",
    );
    expect(wrapper.text()).not.toContain("Ações rápidas");
    expect(
      wrapper.findAll("a").map((link) => link.attributes("aria-label")),
    ).toEqual([
      "Adicionar novo trabalho",
      "Ver verificações",
      "Acompanhar serviços",
      "Editar perfil",
    ]);
    expect(
      wrapper
        .findAll(".actions-card__list > *")
        .map((action) => action.attributes("aria-label")),
    ).toEqual([
      "Adicionar novo trabalho",
      "Ver verificações",
      "Acompanhar serviços",
      "Recomendar um profissional",
      "Editar perfil",
    ]);
    expect(wrapper.get("button").attributes("aria-label")).toBe(
      "Recomendar um profissional",
    );
    expect(wrapper.text()).not.toContain("Fortaleça seu perfil");

    await wrapper.setProps({ identityVerified: true });
    expect(wrapper.find('a[aria-label="Ver verificações"]').exists()).toBe(
      false,
    );
    expect(wrapper.findAll(".actions-card__list > *")).toHaveLength(4);
    expect(
      wrapper
        .findAll(".actions-card__list > *")
        .map((action) => action.attributes("aria-label")),
    ).toEqual([
      "Adicionar novo trabalho",
      "Acompanhar serviços",
      "Recomendar um profissional",
      "Editar perfil",
    ]);

    await wrapper.get("button").trigger("click");
    expect(wrapper.emitted("recommend")).toEqual([[]]);
  });
});
