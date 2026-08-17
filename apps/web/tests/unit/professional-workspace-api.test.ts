import type { BerufeApiClient } from "@app/services/api/client";
import {
  fetchProfessionalWorkspace,
  attachProfessionalProfilePhoto,
  attachProfessionalPortfolioItem,
  deleteProfessionalPortfolioItem,
  mapProfessionalWorkspace,
  updateProfessionalIdentity,
  updateProfessionalSupply,
} from "@app/services/api/professional-workspace";
import type { components } from "@app/services/api/schema";
import type { ProfessionalProfileDraft } from "~/types";

type WorkspaceData = components["schemas"]["ProfessionalWorkspaceData"];

const workspaceData: WorkspaceData = {
  profile: {
    id: "23a94f5e-1429-4ec7-bbc4-a6f805d5182d",
    public_slug: "ana-souza",
    profile_status: "draft",
    revision_status: "draft",
    has_published_revision: false,
    photo: {
      current: null,
      has_published_photo: false,
      latest_upload: null,
    },
    portfolio_items: [],
    identity: {
      display_name: "Ana Souza",
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
      profile: {
        id: workspaceData.profile.id,
        publicSlug: "ana-souza",
        status: "draft",
        revisionStatus: "draft",
        hasPublishedRevision: false,
        photo: {
          current: null,
          hasPublishedPhoto: false,
          latestUpload: null,
        },
        portfolioItems: [],
        identity: {
          name: "Ana Souza",
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
