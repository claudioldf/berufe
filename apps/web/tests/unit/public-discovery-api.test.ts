import type { BerufeApiClient } from "@app/services/api/client";
import {
  fetchFeaturedProfessionals,
  mapPublicProfessionalCard,
} from "@app/services/api/public-discovery";
import type { ApiRequestError } from "@app/services/api/errors";
import type { components } from "@app/services/api/schema";

type ContractProfessionalCard = components["schemas"]["PublicProfessionalCard"];

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

function apiClientReturning(result: object) {
  return {
    GET: vi.fn().mockResolvedValue(result),
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
      coverage: contractCard.coverage,
      verificationLabels: contractCard.verificationLabels,
      portfolioCount: 3,
      relationshipCount: 2,
      publicSnapshotUpdatedAt: "2026-08-17T12:00:00Z",
    });
    expect(card).not.toHaveProperty("whatsapp");
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
});
