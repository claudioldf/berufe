import type { BerufeApiClient } from "@app/services/api/client";
import {
  fetchProfessionalWorkspace,
  attachProfessionalProfilePhoto,
  attachProfessionalPortfolioItem,
  deleteProfessionalPortfolioItem,
  deleteProfessionalRelationship,
  attachProfessionalVerificationRequest,
  mapProfessionalWorkspace,
  submitProfessionalProfile,
  updateProfessionalIdentity,
  updateProfessionalSupply,
} from "@app/services/api/professional-workspace";
import type { components } from "@app/services/api/schema";
import type { ProfessionalProfileDraft } from "~/types";

type WorkspaceData = components["schemas"]["ProfessionalWorkspaceData"];

const workspaceData: WorkspaceData = {
  dashboard: {
    local_date: "2026-08-18",
    readiness: {
      percentage: 50,
      steps: {
        identity_contact: true,
        service_coverage: true,
        reviewable_portfolio: false,
        approved_identity: false,
      },
    },
    change_requested_quotes: [
      {
        id: "23d124e2-9fd7-4278-90b9-9ba6bb6ab809",
        quote_number: 2,
        customer_name: "Fadinha 2",
        service_description: "Instalação de luminárias",
        latest_change_request: {
          id: "fc12cf67-8a82-4c83-bcfa-1360461c5c62",
          revision: 3,
          message: "Trocar uma luminária de lugar.",
          requested_at: "2026-08-23T02:29:10Z",
        },
      },
    ],
    recent_quotes: [],
    recent_service_jobs: [],
  },
  pending_relationships: [],
  relationships: [],
  profile: {
    id: "23a94f5e-1429-4ec7-bbc4-a6f805d5182d",
    public_slug: "ana-souza",
    profile_status: "draft",
    presentation_type: "self_service",
    is_public: false,
    is_search_eligible: false,
    publication_blockers: ["photo"],
    revision_status: "draft",
    revision_rejection_reason: null,
    has_published_revision: false,
    photo: {
      current: null,
      has_published_photo: false,
      published_image_url: null,
      latest_upload: null,
    },
    portfolio_items: [],
    verification: { current: null },
    identity: {
      display_name: "Ana Souza",
      birthdate: "1990-04-12",
      headline: "Elétrica residencial.",
      bio: "Instalações em Joinville.",
      years_experience: 12,
      whatsapp: "+5547999991111",
      instagram: "https://www.instagram.com/ana.obras/",
      youtube: null,
    },
    services: [
      {
        id: "de83e041-286f-4b50-91fa-61a0ee8c1801",
        name: "Eletricista",
        is_primary: true,
        note: "Quadros e circuitos",
      },
    ],
    coverage: {
      all_joinville: true,
      neighborhoods: [],
    },
  },
};

function apiClientReturning(
  method: "GET" | "PATCH" | "PUT" | "POST" | "DELETE",
  result: object,
) {
  return {
    [method]: vi.fn().mockResolvedValue(result),
  } as unknown as BerufeApiClient;
}

describe("professional workspace API", () => {
  it("maps the server-owned identity into the existing editor shape", () => {
    expect(mapProfessionalWorkspace(workspaceData)).toEqual({
      dashboard: {
        localDate: "2026-08-18",
        readiness: {
          percentage: 50,
          steps: {
            identityContact: true,
            serviceCoverage: true,
            reviewablePortfolio: false,
            approvedIdentity: false,
          },
        },
        changeRequestedQuotes: [
          {
            id: "23d124e2-9fd7-4278-90b9-9ba6bb6ab809",
            number: 2,
            customerName: "Fadinha 2",
            serviceDescription: "Instalação de luminárias",
            latestChangeRequest: {
              id: "fc12cf67-8a82-4c83-bcfa-1360461c5c62",
              revision: 3,
              message: "Trocar uma luminária de lugar.",
              requestedAt: "2026-08-23T02:29:10Z",
            },
          },
        ],
        recentQuotes: [],
        recentServiceJobs: [],
      },
      pendingRelationships: [],
      relationships: [],
      profile: {
        id: workspaceData.profile.id,
        publicSlug: "ana-souza",
        status: "draft",
        presentationType: "self_service",
        isPublic: false,
        isSearchEligible: false,
        publicationBlockers: ["photo"],
        revisionStatus: "draft",
        revisionRejectionReason: null,
        hasPublishedRevision: false,
        photo: {
          current: null,
          hasPublishedPhoto: false,
          publishedImageUrl: null,
          latestUpload: null,
        },
        portfolioItems: [],
        verification: { current: null },
        identity: {
          name: "Ana Souza",
          birthdate: "1990-04-12",
          headline: "Elétrica residencial.",
          bio: "Instalações em Joinville.",
          yearsExperience: 12,
          whatsapp: "47999991111",
          instagram: "https://www.instagram.com/ana.obras/",
          youtube: "",
        },
        services: [
          {
            id: "de83e041-286f-4b50-91fa-61a0ee8c1801",
            name: "Eletricista",
            isPrimary: true,
            note: "Quadros e circuitos",
          },
        ],
        coverage: {
          allJoinville: true,
          neighborhoods: [],
        },
      },
    });
  });

  it("loads the authenticated workspace", async () => {
    const client = apiClientReturning("GET", {
      data: { data: workspaceData, request_id: "workspace-get" },
      error: undefined,
      response: new Response(null),
    });

    await expect(fetchProfessionalWorkspace(client)).resolves.toEqual(
      mapProfessionalWorkspace(workspaceData),
    );
    expect(client.GET).toHaveBeenCalledWith("/api/v1/professional/workspace");
  });

  it("maps inbound pending relationships without exposing account contact data", () => {
    const pending = {
      id: "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
      relationship_type: "worked_together" as const,
      context_note: "Atuamos juntos em uma obra.",
      status: "pending" as const,
      source: "external_phone" as const,
      created_at: "2026-08-17T12:00:00Z",
      responded_at: null,
      initiator: {
        id: "f39d4810-f28d-4977-b5e5-387131d12942",
        public_slug: "ana-souza",
        display_name: "Ana Souza",
        profile_type: "external" as const,
        photo_url: null,
        profile_available: false,
      },
      recipient: {
        id: workspaceData.profile.id,
        public_slug: "beto-lima",
        display_name: "Beto Lima",
        profile_type: "self_service" as const,
        photo_url: null,
        profile_available: false,
      },
    };

    expect(
      mapProfessionalWorkspace({
        ...workspaceData,
        pending_relationships: [pending],
      }).pendingRelationships,
    ).toEqual([
      {
        id: pending.id,
        relationshipType: "worked_together",
        contextNote: "Atuamos juntos em uma obra.",
        status: "pending",
        source: "external_phone",
        createdAt: "2026-08-17T12:00:00Z",
        respondedAt: null,
        initiator: {
          id: pending.initiator.id,
          publicSlug: "ana-souza",
          displayName: "Ana Souza",
          profileType: "external",
          photoUrl: null,
          profileAvailable: false,
        },
        recipient: {
          id: pending.recipient.id,
          publicSlug: "beto-lima",
          displayName: "Beto Lima",
          profileType: "self_service",
          photoUrl: null,
          profileAvailable: false,
        },
      },
    ]);
  });

  it("attaches a processed photo to the existing professional workspace", async () => {
    const client = apiClientReturning("PUT", {
      data: { data: workspaceData, request_id: "workspace-photo" },
      error: undefined,
      response: new Response(null),
    });

    await attachProfessionalProfilePhoto(
      client,
      "12d12a91-582e-4f1b-aa6b-49b5fd7ce1eb",
    );

    expect(client.PUT).toHaveBeenCalledWith(
      "/api/v1/professional/profile/photo",
      {
        body: {
          media_upload_id: "12d12a91-582e-4f1b-aa6b-49b5fd7ce1eb",
        },
      },
    );
  });

  it("creates and soft-deletes portfolio items through stable identifiers", async () => {
    const createClient = apiClientReturning("POST", {
      data: { data: workspaceData, request_id: "portfolio-create" },
      error: undefined,
      response: new Response(null),
    });
    const deleteClient = apiClientReturning("DELETE", {
      data: { data: workspaceData, request_id: "portfolio-delete" },
      error: undefined,
      response: new Response(null),
    });

    await attachProfessionalPortfolioItem(createClient, {
      mediaUploadId: "12d12a91-582e-4f1b-aa6b-49b5fd7ce1eb",
      serviceId: "de83e041-286f-4b50-91fa-61a0ee8c1801",
      title: "Cozinha iluminada",
      description: "Instalação completa.",
    });
    await deleteProfessionalPortfolioItem(
      deleteClient,
      "22d12a91-582e-4f1b-aa6b-49b5fd7ce1eb",
    );

    expect(createClient.POST).toHaveBeenCalledWith(
      "/api/v1/professional/portfolio-items",
      {
        body: {
          portfolio_item: {
            media_upload_id: "12d12a91-582e-4f1b-aa6b-49b5fd7ce1eb",
            service_id: "de83e041-286f-4b50-91fa-61a0ee8c1801",
            title: "Cozinha iluminada",
            description: "Instalação completa.",
          },
        },
      },
    );
    expect(deleteClient.DELETE).toHaveBeenCalledWith(
      "/api/v1/professional/portfolio-items/{id}",
      {
        params: {
          path: { id: "22d12a91-582e-4f1b-aa6b-49b5fd7ce1eb" },
        },
      },
    );
  });

  it("removes a professional relationship and maps the refreshed workspace", async () => {
    const client = apiClientReturning("DELETE", {
      data: { data: workspaceData, request_id: "relationship-delete" },
      error: undefined,
      response: new Response(null),
    });

    await expect(
      deleteProfessionalRelationship(
        client,
        "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
      ),
    ).resolves.toEqual(mapProfessionalWorkspace(workspaceData));
    expect(client.DELETE).toHaveBeenCalledWith(
      "/api/v1/professional/relationships/{id}",
      {
        params: {
          path: { id: "d25c64fa-3e6a-4e56-adc9-85bdac0045cb" },
        },
      },
    );
  });

  it("attaches one processed identity image without requesting document fields", async () => {
    const client = apiClientReturning("POST", {
      data: { data: workspaceData, request_id: "verification-create" },
      error: undefined,
      response: new Response(null),
    });

    await attachProfessionalVerificationRequest(
      client,
      "32d12a91-582e-4f1b-aa6b-49b5fd7ce1eb",
    );

    expect(client.POST).toHaveBeenCalledWith(
      "/api/v1/professional/verification-requests",
      {
        body: {
          verification_request: {
            media_upload_id: "32d12a91-582e-4f1b-aa6b-49b5fd7ce1eb",
            verification_type: "identity",
          },
        },
      },
    );
  });

  it("submits persisted onboarding state without a browser profile payload", async () => {
    const client = apiClientReturning("POST", {
      data: { data: workspaceData, request_id: "profile-submission" },
      error: undefined,
      response: new Response(null),
    });

    await submitProfessionalProfile(client);

    expect(client.POST).toHaveBeenCalledWith(
      "/api/v1/professional/profile/submission",
    );
  });

  it("persists only the current identity/contact surface", async () => {
    const client = apiClientReturning("PATCH", {
      data: { data: workspaceData, request_id: "workspace-patch" },
      error: undefined,
      response: new Response(null),
    });
    const draft: ProfessionalProfileDraft = {
      ...mapProfessionalWorkspace(workspaceData).profile.identity,
      selectedServices: ["Eletricista"],
      serviceNotes: { Eletricista: "Quadros e circuitos" },
      primaryService: "Eletricista",
      allJoinville: true,
      selectedNeighborhoods: [],
    };

    await updateProfessionalIdentity(client, draft);

    expect(client.PATCH).toHaveBeenCalledWith("/api/v1/professional/profile", {
      body: {
        identity: {
          display_name: "Ana Souza",
          birthdate: "1990-04-12",
          headline: "Elétrica residencial.",
          bio: "Instalações em Joinville.",
          years_experience: 12,
          whatsapp: "47999991111",
          instagram: "https://www.instagram.com/ana.obras/",
          youtube: null,
        },
      },
    });
  });

  it("maps displayed catalog names to stable IDs for services and coverage", async () => {
    const client = apiClientReturning("PATCH", {
      data: { data: workspaceData, request_id: "workspace-supply" },
      error: undefined,
      response: new Response(null),
    });
    const draft: ProfessionalProfileDraft = {
      ...mapProfessionalWorkspace(workspaceData).profile.identity,
      selectedServices: ["Eletricista"],
      serviceNotes: { Eletricista: "Quadros e circuitos" },
      primaryService: "Eletricista",
      allJoinville: false,
      selectedNeighborhoods: ["América"],
    };

    await updateProfessionalSupply(
      client,
      draft,
      [
        {
          id: "de83e041-286f-4b50-91fa-61a0ee8c1801",
          name: "Eletricista",
          slug: "eletricista",
          category: "instalacoes",
          icon: "i-lucide-zap",
          description: "Instalações elétricas.",
          aliases: [],
        },
      ],
      [
        {
          code: "america",
          name: "América",
          stateCode: "SC",
          city: "Joinville",
        },
      ],
    );

    expect(client.PATCH).toHaveBeenCalledWith("/api/v1/professional/profile", {
      body: {
        services: [
          {
            service_id: "de83e041-286f-4b50-91fa-61a0ee8c1801",
            is_primary: true,
            note: "Quadros e circuitos",
          },
        ],
        coverage: {
          all_joinville: false,
          neighborhood_codes: ["america"],
        },
      },
    });
  });

  it("preserves safe contract failures", async () => {
    const client = apiClientReturning("GET", {
      data: undefined,
      error: {
        error: {
          code: "authentication_required",
          message: "Entre novamente para continuar.",
          request_id: "workspace-401",
        },
      },
      response: new Response(null, {
        status: 401,
        headers: { "X-Request-Id": "workspace-401" },
      }),
    });

    await expect(fetchProfessionalWorkspace(client)).rejects.toMatchObject({
      name: "ApiRequestError",
      code: "authentication_required",
      requestId: "workspace-401",
    });
  });
});
