import type { BerufeApiClient } from "@app/services/api/client";
import {
  fetchFeaturedProfessionals,
  fetchPublicProfessionalProfile,
  mapPublicProfessionalCard,
  mapPublicProfessionalProfile,
  recordPublicProfessionalProfileView,
  searchPublicProfessionals,
} from "@app/services/api/public-discovery";
import type { ApiRequestError } from "@app/services/api/errors";
import type { components } from "@app/services/api/schema";

type ContractProfessionalCard = components["schemas"]["PublicProfessionalCard"];
type ContractProfessionalProfile =
  components["schemas"]["PublicProfessionalProfile"];

const contractCard: ContractProfessionalCard = {
  id: "ad59e74a-a1aa-47d5-b725-26350f0f2376",
  publicSlug: "ana-souza",
  displayName: "Ana Souza",
  headline: "Elétrica residencial.",
  photoUrl:
    "https://api.berufe.test/api/v1/public/profile-photos/4efae63b-b17c-4d4d-a3de-49bebdcba821/image",
  primaryService: {
    id: "c43071a5-4c47-4324-99ef-41846ee35538",
    name: "Eletricista",
    slug: "eletricista",
  },
  matchingService: {
    id: "c43071a5-4c47-4324-99ef-41846ee35538",
    name: "Eletricista",
    slug: "eletricista",
  },
  coverage: {
    allJoinville: false,
    neighborhoods: [{ code: "america", name: "América" }],
  },
  verificationLabels: [
    {
      type: "identity",
      label: "Identidade verificada",
      verifiedAt: "2026-08-16T12:00:00Z",
    },
  ],
  portfolioCount: 3,
  relationshipCount: 2,
  publicSnapshotUpdatedAt: "2026-08-17T12:00:00Z",
};

const contractProfile: ContractProfessionalProfile = {
  id: contractCard.id,
  publicSlug: "ana-souza",
  displayName: "Ana Souza",
  headline: "Elétrica residencial.",
  bio: "Instalações e reparos em Joinville.",
  yearsExperience: 11,
  photoUrl: contractCard.photoUrl,
  services: [
    {
      id: contractCard.primaryService!.id,
      name: "Eletricista",
      slug: "eletricista",
      isPrimary: true,
      note: "Quadros elétricos",
    },
    {
      id: "894a140b-219f-4fab-a01e-6f0dc02f6764",
      name: "Marido de aluguel",
      slug: "marido-de-aluguel",
      isPrimary: false,
      note: null,
    },
  ],
  coverage: contractCard.coverage,
  verificationLabels: contractCard.verificationLabels,
  portfolio: [
    {
      id: "b9029f26-f2c1-4001-9696-cf34d7259999",
      title: "Quadro organizado",
      description: null,
      service: contractCard.primaryService!,
      imageUrl: "https://api.berufe.test/portfolio.png",
    },
  ],
  relationships: [
    {
      id: "de381ccd-d0e5-4d50-8322-a4daff09a486",
      type: "recommendation",
      direction: "incoming",
      note: "Indicação profissional.",
      professional: {
        id: "9c315329-e728-4d48-96bc-7be4bc70d147",
        publicSlug: "beto-lima",
        displayName: "Beto Lima",
        photoUrl: null,
      },
    },
  ],
  socialLinks: {
    instagram: "https://www.instagram.com/berufe.ana/",
    youtube: null,
  },
  publicSnapshotUpdatedAt: "2026-08-17T12:00:00Z",
};

function apiClientReturning(result: object) {
  return {
    GET: vi.fn().mockResolvedValue(result),
    POST: vi.fn().mockResolvedValue(result),
  } as unknown as BerufeApiClient;
}

describe("public discovery API", () => {
  it("maps the safe public card contract without a contact field", () => {
    const card = mapPublicProfessionalCard(contractCard);

    expect(card).toEqual({
      id: contractCard.id,
      slug: "ana-souza",
      name: "Ana Souza",
      headline: "Elétrica residencial.",
      photoUrl: contractCard.photoUrl,
      primaryService: contractCard.primaryService,
      matchingService: contractCard.matchingService,
      coverage: contractCard.coverage,
      verificationLabels: contractCard.verificationLabels,
      portfolioCount: 3,
      relationshipCount: 2,
      publicSnapshotUpdatedAt: "2026-08-17T12:00:00Z",
    });
    expect(card).not.toHaveProperty("whatsapp");
  });

  it("submits a service and optional neighborhood through the typed search operation", async () => {
    const client = apiClientReturning({
      data: {
        data: {
          query: {
            normalizedTerm: "eletrica",
            service: {
              id: contractCard.matchingService!.id,
              name: "Eletricista",
              slug: "eletricista",
              icon: "i-lucide-zap",
              description: "Instalações elétricas residenciais.",
            },
            neighborhood: { code: "america", name: "América" },
          },
          professionals: [contractCard],
          relatedServices: [],
          interaction: {
            searchEventId: "8d09847f-14d8-4ef7-80ea-8be6e9eb6d81",
            token: "signed-search-interaction",
          },
        },
        request_id: "search-200",
      },
      error: undefined,
      response: new Response(null),
    });

    const result = await searchPublicProfessionals(client, {
      service: "Elétrica",
      neighborhoodCode: "america",
    });

    expect(result.normalizedTerm).toBe("eletrica");
    expect(result.professionals[0]?.matchingService?.name).toBe("Eletricista");
    expect(result.interaction).toEqual({
      searchEventId: "8d09847f-14d8-4ef7-80ea-8be6e9eb6d81",
      token: "signed-search-interaction",
    });
    expect(client.POST).toHaveBeenCalledWith(
      "/api/v1/public/professional-searches",
      { body: { service: "Elétrica", neighborhoodCode: "america" } },
    );
  });

  it("normalizes a search transport failure", async () => {
    const client = apiClientReturning({
      data: undefined,
      error: undefined,
      response: new Response(null),
    });

    await expect(
      searchPublicProfessionals(client, { service: "Elétrica" }),
    ).rejects.toMatchObject({
      name: "ApiRequestError",
      code: "unexpected_error",
      requestId: "client",
    } satisfies Partial<ApiRequestError>);
    expect(client.POST).toHaveBeenCalledWith(
      "/api/v1/public/professional-searches",
      { body: { service: "Elétrica", neighborhoodCode: null } },
    );
  });

  it("loads featured professionals through the generated operation", async () => {
    const client = apiClientReturning({
      data: {
        data: { professionals: [contractCard] },
        request_id: "featured-200",
      },
      error: undefined,
      response: new Response(null),
    });

    const professionals = await fetchFeaturedProfessionals(client);

    expect(professionals).toHaveLength(1);
    expect(professionals[0]?.slug).toBe("ana-souza");
    expect(client.GET).toHaveBeenCalledWith(
      "/api/v1/public/professionals/featured",
    );
  });

  it("normalizes an API failure and a missing success body", async () => {
    const apiErrorClient = apiClientReturning({
      data: undefined,
      error: {
        error: {
          code: "service_unavailable",
          message: "Profissionais temporariamente indisponíveis.",
          request_id: "featured-503",
        },
      },
      response: new Response(null, {
        headers: { "X-Request-Id": "featured-503" },
      }),
    });
    await expect(
      fetchFeaturedProfessionals(apiErrorClient),
    ).rejects.toMatchObject({
      name: "ApiRequestError",
      code: "service_unavailable",
      requestId: "featured-503",
    } satisfies Partial<ApiRequestError>);

    const emptyClient = apiClientReturning({
      data: undefined,
      error: undefined,
      response: new Response(null),
    });
    await expect(fetchFeaturedProfessionals(emptyClient)).rejects.toMatchObject(
      {
        name: "ApiRequestError",
        code: "unexpected_error",
        requestId: "client",
      } satisfies Partial<ApiRequestError>,
    );
  });

  it("maps and loads the complete safe public profile with its signed interaction", async () => {
    expect(mapPublicProfessionalProfile(contractProfile)).toEqual({
      id: contractProfile.id,
      slug: "ana-souza",
      name: "Ana Souza",
      headline: "Elétrica residencial.",
      bio: "Instalações e reparos em Joinville.",
      avatar: contractProfile.photoUrl,
      primaryService: "Eletricista",
      primaryServiceSlug: "eletricista",
      services: ["Eletricista", "Marido de aluguel"],
      serviceNotes: ["Quadros elétricos", null],
      neighborhoods: ["América"],
      allJoinville: false,
      yearsExperience: 11,
      evidence: contractProfile.verificationLabels.map((label) => ({
        id: label.type,
        type: label.type,
        label: label.label,
        verifiedAt: label.verifiedAt,
      })),
      portfolio: [
        {
          id: "b9029f26-f2c1-4001-9696-cf34d7259999",
          title: "Quadro organizado",
          description: null,
          service: "Eletricista",
          image: "https://api.berufe.test/portfolio.png",
        },
      ],
      relationships: [
        {
          id: "de381ccd-d0e5-4d50-8322-a4daff09a486",
          professionalName: "Beto Lima",
          professionalSlug: "beto-lima",
          avatar: null,
          type: "recommendation",
          direction: "incoming",
          note: "Indicação profissional.",
        },
      ],
      updatedAt: "2026-08-17T12:00:00Z",
      instagram: "https://www.instagram.com/berufe.ana/",
    });

    const client = apiClientReturning({
      data: {
        data: {
          professional: contractProfile,
          interaction: { token: "signed-profile-interaction" },
        },
        request_id: "profile-200",
      },
      error: undefined,
      response: new Response(null),
    });
    const result = await fetchPublicProfessionalProfile(
      client,
      "ana-souza",
      "signed-search-context",
    );

    expect(result.professional.name).toBe("Ana Souza");
    expect(result.interactionToken).toBe("signed-profile-interaction");
    expect(client.GET).toHaveBeenCalledWith(
      "/api/v1/public/professionals/{slug}",
      {
        params: {
          path: { slug: "ana-souza" },
          query: { interactionToken: "signed-search-context" },
        },
      },
    );
  });

  it("records a profile view through the typed mutation and normalizes failures", async () => {
    const success = apiClientReturning({
      data: undefined,
      error: undefined,
      response: new Response(null, { status: 204 }),
    });
    await expect(
      recordPublicProfessionalProfileView(
        success,
        contractProfile.id,
        "signed-profile-interaction",
      ),
    ).resolves.toBeUndefined();
    expect(success.POST).toHaveBeenCalledWith(
      "/api/v1/public/professionals/{id}/views",
      {
        params: { path: { id: contractProfile.id } },
        body: { interactionToken: "signed-profile-interaction" },
      },
    );

    const failure = apiClientReturning({
      data: undefined,
      error: {
        error: {
          code: "validation_failed",
          message: "Interação inválida ou expirada.",
          request_id: "profile-view-422",
        },
      },
      response: new Response(null, {
        status: 422,
        headers: { "X-Request-Id": "profile-view-422" },
      }),
    });
    await expect(
      recordPublicProfessionalProfileView(
        failure,
        contractProfile.id,
        "expired",
      ),
    ).rejects.toMatchObject({
      code: "validation_failed",
      requestId: "profile-view-422",
    });
  });
});
