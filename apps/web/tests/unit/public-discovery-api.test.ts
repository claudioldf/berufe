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
  public_slug: "ana-souza",
  profile_type: "self_service",
  claimed: true,
  display_name: "Ana Souza",
  headline: "Elétrica residencial.",
  photo_url:
    "https://api.berufe.test/api/v1/public/profile-photos/4efae63b-b17c-4d4d-a3de-49bebdcba821/image",
  primary_service: {
    id: "c43071a5-4c47-4324-99ef-41846ee35538",
    name: "Eletricista",
    slug: "eletricista",
  },
  matching_service: {
    id: "c43071a5-4c47-4324-99ef-41846ee35538",
    name: "Eletricista",
    slug: "eletricista",
  },
  coverage: {
    all_joinville: false,
    neighborhoods: [{ code: "america", name: "América" }],
  },
  verification_labels: [
    {
      type: "identity",
      label: "Identidade verificada",
      verified_at: "2026-08-16T12:00:00Z",
    },
  ],
  portfolio_count: 3,
  relationship_count: 2,
  public_snapshot_updated_at: "2026-08-17T12:00:00Z",
};

const contractProfile: ContractProfessionalProfile = {
  id: contractCard.id,
  public_slug: "ana-souza",
  profile_type: "self_service",
  claimed: true,
  display_name: "Ana Souza",
  headline: "Elétrica residencial.",
  bio: "Instalações e reparos em Joinville.",
  years_experience: 11,
  photo_url: contractCard.photo_url,
  services: [
    {
      id: contractCard.primary_service!.id,
      name: "Eletricista",
      slug: "eletricista",
      is_primary: true,
      note: "Quadros elétricos",
    },
    {
      id: "894a140b-219f-4fab-a01e-6f0dc02f6764",
      name: "Marido de aluguel",
      slug: "marido-de-aluguel",
      is_primary: false,
      note: null,
    },
  ],
  coverage: contractCard.coverage,
  verification_labels: contractCard.verification_labels,
  evidence_summary: {
    completed_services: 3,
    recommendations: 1,
    worked_together_professionals: 2,
  },
  customer_recommendations: [
    {
      id: "8f4c75ae-8450-4b07-873f-29ca65d540e7",
      display_name: "Marina Costa",
      recommendation_text: "Serviço cuidadoso e entregue no prazo.",
      submitted_at: "2026-08-18T12:00:00Z",
      verification_label: "Link enviado por e-mail",
    },
  ],
  portfolio: [
    {
      id: "b9029f26-f2c1-4001-9696-cf34d7259999",
      title: "Quadro organizado",
      description: null,
      service: contractCard.primary_service!,
      image_url: "https://api.berufe.test/portfolio.png",
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
        public_slug: "beto-lima",
        display_name: "Beto Lima",
        photo_url: null,
      },
    },
  ],
  social_links: {
    instagram: "https://www.instagram.com/berufe.ana/",
    youtube: null,
  },
  public_snapshot_updated_at: "2026-08-17T12:00:00Z",
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
      profileType: "self_service",
      claimed: true,
      name: "Ana Souza",
      headline: "Elétrica residencial.",
      photoUrl: contractCard.photo_url,
      primaryService: contractCard.primary_service,
      matchingService: contractCard.matching_service,
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
    });
    expect(card).not.toHaveProperty("whatsapp");
  });

  it("submits a service and optional neighborhood through the typed search operation", async () => {
    const client = apiClientReturning({
      data: {
        data: {
          query: {
            normalized_term: "eletrica",
            service: {
              id: contractCard.matching_service!.id,
              name: "Eletricista",
              slug: "eletricista",
              icon: "i-lucide-zap",
              description: "Instalações elétricas residenciais.",
            },
            neighborhood: { code: "america", name: "América" },
          },
          professionals: [contractCard],
          related_services: [],
          meta: { page: 1, per_page: 20, total_count: 1, total_pages: 1 },
          interaction: {
            search_event_id: "8d09847f-14d8-4ef7-80ea-8be6e9eb6d81",
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
    expect(result.totalCount).toBe(1);
    expect(client.POST).toHaveBeenCalledWith(
      "/api/v1/public/professional-searches",
      { body: { service: "Elétrica", neighborhood_code: "america" } },
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
      { body: { service: "Elétrica", neighborhood_code: null } },
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
      profileType: "self_service",
      claimed: true,
      name: "Ana Souza",
      headline: "Elétrica residencial.",
      bio: "Instalações e reparos em Joinville.",
      avatar: contractProfile.photo_url,
      primaryService: "Eletricista",
      primaryServiceSlug: "eletricista",
      services: ["Eletricista", "Marido de aluguel"],
      serviceNotes: ["Quadros elétricos", null],
      neighborhoods: ["América"],
      allJoinville: false,
      yearsExperience: 11,
      evidence: contractProfile.verification_labels.map((label) => ({
        id: label.type,
        type: label.type,
        label: label.label,
        verifiedAt: label.verified_at,
      })),
      evidenceSummary: {
        completedServices: 3,
        recommendations: 1,
        workedTogetherProfessionals: 2,
      },
      customerRecommendations: [
        {
          id: "8f4c75ae-8450-4b07-873f-29ca65d540e7",
          displayName: "Marina Costa",
          text: "Serviço cuidadoso e entregue no prazo.",
          submittedAt: "2026-08-18T12:00:00Z",
          verificationLabel: "Link enviado por e-mail",
        },
      ],
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
          query: { interaction_token: "signed-search-context" },
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
        body: { interaction_token: "signed-profile-interaction" },
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
