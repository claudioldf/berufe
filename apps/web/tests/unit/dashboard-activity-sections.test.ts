import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import DashboardActivitySections from "@app/components/dashboard/DashboardActivitySections.vue";
import type {
  ProfessionalRelationship,
  ProfessionalRelationshipParty,
  ProfessionalWorkspace,
} from "~/types";

const owner: ProfessionalRelationshipParty = {
  id: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
  publicSlug: "beto-lima",
  displayName: "Beto Lima",
  profileType: "self_service",
  photoUrl: null,
  profileAvailable: true,
};

function otherProfessional(
  id: string,
  displayName: string,
): ProfessionalRelationshipParty {
  return {
    id,
    publicSlug: displayName.toLocaleLowerCase("pt-BR").replaceAll(" ", "-"),
    displayName,
    profileType: "self_service",
    photoUrl: null,
    profileAvailable: true,
  };
}

function relationship(
  direction: "incoming" | "outgoing",
  id: string,
  other: ProfessionalRelationshipParty,
): ProfessionalRelationship {
  return {
    id,
    relationshipType: "recommendation",
    contextNote: null,
    status: "pending",
    source: "existing_profile",
    createdAt: "2026-08-17T12:00:00Z",
    respondedAt: null,
    initiator: direction === "outgoing" ? owner : other,
    recipient: direction === "outgoing" ? other : owner,
  };
}

function workspace(): ProfessionalWorkspace {
  return {
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
    pendingRelationships: [],
    relationships: [],
    profile: {
      id: owner.id,
      publicSlug: owner.publicSlug,
      status: "published",
      presentationType: "self_service",
      isPublic: true,
      isSearchEligible: true,
      publicationBlockers: [],
      revisionStatus: "approved",
      revisionRejectionReason: null,
      hasPublishedRevision: true,
      photo: {
        current: null,
        hasPublishedPhoto: true,
        publishedImageUrl: null,
        latestUpload: null,
      },
      portfolioItems: [],
      verification: { current: null },
      identity: {
        name: owner.displayName,
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
  };
}

const ButtonStub = defineComponent({
  props: {
    disabled: { type: Boolean, default: false },
    loading: { type: Boolean, default: false },
    to: { type: String, default: "" },
  },
  emits: ["click"],
  template:
    '<a v-if="to" :href="to"><slot /></a><button v-else type="button" :disabled="disabled" :data-loading="loading" @click="$emit(\'click\')"><slot /></button>',
});

const mountOptions = {
  global: {
    stubs: {
      UButton: ButtonStub,
      UIcon: true,
      DesignSystemEyebrow: defineComponent({
        template: '<span class="eyebrow"><slot /></span>',
      }),
    },
  },
} as const;

describe("dashboard activity sections", () => {
  it("separates actionable inbound requests from outbound notices", async () => {
    const currentWorkspace = workspace();
    const ana = otherProfessional("ana-id", "Ana Souza");
    const caio = otherProfessional("caio-id", "Caio Costa");
    currentWorkspace.relationships = [
      relationship("incoming", "incoming-id", ana),
      relationship("outgoing", "outgoing-id", caio),
    ];

    const wrapper = await mountSuspended(DashboardActivitySections, {
      ...mountOptions,
      props: {
        workspace: currentWorkspace,
        relationshipError: "Não foi possível responder agora.",
      },
    });

    const attention = wrapper.get(".activity-section--attention");
    const ongoing = wrapper.get(".activity-section--ongoing");
    expect(wrapper.get(".dashboard-activity").classes()).not.toContain(
      "dashboard-activity--split",
    );
    expect(attention.text()).toContain("Ação necessária");
    expect(attention.text()).toContain("Para resolver.");
    expect(attention.text()).toContain("Ana Souza recomendou você");
    expect(attention.text()).not.toContain("Aguardando sua resposta");
    expect(attention.text()).toContain("Não foi possível responder agora.");
    expect(attention.text()).not.toContain("Caio Costa");
    expect(ongoing.text()).toContain("Avisos");
    expect(ongoing.text()).toContain("Para acompanhar.");
    expect(ongoing.text()).toContain("Você recomendou Caio Costa");
    expect(ongoing.text()).toContain("Aguardando confirmação");
    expect(ongoing.findAll("button")).toHaveLength(0);

    const connect = attention
      .findAll("button")
      .find((button) => button.text().includes("Conectar"));
    await connect!.trigger("click");
    expect(wrapper.emitted("respond")?.[0]).toEqual([
      "incoming-id",
      "accepted",
    ]);
  });

  it("groups review states as notices and rejected states as actionable", async () => {
    const currentWorkspace = workspace();
    currentWorkspace.profile.revisionStatus = "rejected";
    currentWorkspace.profile.revisionRejectionReason =
      "A apresentação precisa de mais detalhes.";
    currentWorkspace.profile.photo.current = {
      id: "photo-id",
      status: "pending_review",
      rejectionReason: null,
      submittedAt: "2026-08-18T10:00:00Z",
    };
    currentWorkspace.profile.portfolioItems = [
      {
        id: "pending-work",
        title: "Instalação em análise",
        service: "Eletricista",
        description: "",
        image: null,
        status: "pending_review",
        rejectionReason: null,
        submittedAt: "2026-08-18T11:00:00Z",
      },
      {
        id: "rejected-work",
        title: "Instalação rejeitada",
        service: "Eletricista",
        description: "",
        image: null,
        status: "rejected",
        rejectionReason: "Envie uma foto mais nítida.",
        submittedAt: "2026-08-18T09:00:00Z",
      },
    ];
    currentWorkspace.profile.verification.current = {
      id: "verification-id",
      verificationType: "identity",
      status: "expired",
      rejectionReason: null,
      submittedAt: "2026-08-17T10:00:00Z",
    };

    const wrapper = await mountSuspended(DashboardActivitySections, {
      ...mountOptions,
      props: { workspace: currentWorkspace },
    });

    const attention = wrapper.get(".activity-section--attention");
    const ongoing = wrapper.get(".activity-section--ongoing");
    expect(attention.text()).toContain(
      "A apresentação precisa de mais detalhes.",
    );
    expect(attention.text()).toContain("Instalação rejeitada");
    expect(attention.text()).toContain("Verificação de identidade");
    expect(attention.text()).not.toContain("Expirada");
    expect(attention.text()).not.toContain("Instalação em análise");
    expect(ongoing.text()).toContain("Foto do perfil");
    expect(ongoing.text()).toContain("Instalação em análise");
    expect(ongoing.text()).not.toContain("Instalação rejeitada");
  });

  it("shows every requested quote change with its latest message and review link", async () => {
    const currentWorkspace = workspace();
    currentWorkspace.dashboard.changeRequestedQuotes = [
      {
        id: "newer-quote-id",
        number: 23,
        customerName: "Marina Cliente",
        serviceDescription: "Instalação de luminárias",
        latestChangeRequest: {
          id: "newer-request-id",
          revision: 4,
          message:
            "Trocar duas luminárias e revisar a posição dos interruptores.",
          requestedAt: "2026-08-19T14:00:00Z",
        },
      },
      {
        id: "older-quote-id",
        number: 19,
        customerName: "Paulo Cliente",
        serviceDescription: "Pintura interna",
        latestChangeRequest: {
          id: "older-request-id",
          revision: 2,
          message: "Usar tinta lavável.",
          requestedAt: "2026-08-18T14:00:00Z",
        },
      },
    ];
    currentWorkspace.relationships = [
      relationship(
        "incoming",
        "incoming-id",
        otherProfessional("ana-id", "Ana Souza"),
      ),
    ];

    const wrapper = await mountSuspended(DashboardActivitySections, {
      ...mountOptions,
      props: { workspace: currentWorkspace },
    });

    const attention = wrapper.get(".activity-section--attention");
    const items = attention.findAll("article");
    expect(items).toHaveLength(3);
    expect(items.map((item) => item.get("strong").text())).toEqual([
      "Orçamento #23 · Marina Cliente",
      "Orçamento #19 · Paulo Cliente",
      "Ana Souza recomendou você",
    ]);
    expect(items[0]!.text()).not.toContain("Alteração solicitada");
    expect(items[0]!.text()).toContain(
      "Trocar duas luminárias e revisar a posição dos interruptores.",
    );
    expect(items[1]!.text()).toContain("Usar tinta lavável.");
    expect(
      attention.findAll("a").map((link) => link.attributes("href")),
    ).toEqual([
      "/app/professional/quotes/new?quote=newer-quote-id",
      "/app/professional/quotes/new?quote=older-quote-id",
    ]);
    expect(
      attention
        .findAll("a")
        .every((link) => link.text() === "Revisar orçamento"),
    ).toBe(true);
  });

  it("uses one stacked container for a single group and hides it when empty", async () => {
    const ongoingWorkspace = workspace();
    ongoingWorkspace.relationships = [
      relationship(
        "outgoing",
        "outgoing-id",
        otherProfessional("ana-id", "Ana Souza"),
      ),
    ];
    const ongoingOnly = await mountSuspended(DashboardActivitySections, {
      ...mountOptions,
      props: { workspace: ongoingWorkspace },
    });

    expect(ongoingOnly.find(".activity-section--attention").exists()).toBe(
      false,
    );
    expect(ongoingOnly.get(".activity-section--ongoing").exists()).toBe(true);
    expect(ongoingOnly.get(".dashboard-activity").classes()).toEqual([
      "dashboard-activity",
    ]);

    const empty = await mountSuspended(DashboardActivitySections, {
      ...mountOptions,
      props: { workspace: workspace() },
    });
    expect(empty.find(".dashboard-activity").exists()).toBe(false);
  });
});
