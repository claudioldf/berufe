import type { BerufeApiClient } from "@app/services/api/client";
import {
  createProfessionalRelationship,
  respondProfessionalRelationship,
  searchProfessionalRelationshipCandidates,
} from "@app/services/api/professional-relationships";

function apiClientReturning(result: object) {
  return {
    POST: vi.fn().mockResolvedValue(result),
    GET: vi.fn().mockResolvedValue(result),
  } as unknown as BerufeApiClient;
}

describe("professional relationships API", () => {
  it("creates and maps a pending relationship without client-owned state", async () => {
    const client = apiClientReturning({
      data: {
        data: {
          relationship: {
            id: "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
            relationship_type: "recommendation",
            context_note: "Trabalhamos em uma reforma.",
            status: "pending",
            source: "existing_profile",
            created_at: "2026-08-18T12:00:00Z",
            responded_at: null,
            initiator: {
              id: "f39d4810-f28d-4977-b5e5-387131d12942",
              public_slug: "ana-souza",
              display_name: "Ana Souza",
              profile_type: "self_service",
              photo_url: null,
              profile_available: false,
            },
            recipient: {
              id: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
              public_slug: "beto-lima",
              display_name: "Beto Lima",
              profile_type: "self_service",
              photo_url: "https://api.example.test/beto.jpg",
              profile_available: true,
            },
          },
        },
        request_id: "relationship-create",
      },
      error: undefined,
      response: new Response(null, { status: 201 }),
    });

    await expect(
      createProfessionalRelationship(client, {
        target: {
          type: "profile",
          professionalProfileId: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
        },
        relationshipType: "recommendation",
        contextNote: "  Trabalhamos em uma reforma.  ",
      }),
    ).resolves.toMatchObject({
      relationshipType: "recommendation",
      contextNote: "Trabalhamos em uma reforma.",
      status: "pending",
      recipient: { displayName: "Beto Lima" },
    });
    expect(client.POST).toHaveBeenCalledWith(
      "/api/v1/professional/relationships",
      {
        body: {
          relationship: {
            target: {
              type: "profile",
              professional_profile_id: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
            },
            relationship_type: "recommendation",
            context_note: "Trabalhamos em uma reforma.",
          },
        },
      },
    );
  });

  it("normalizes a duplicate conflict for the dialog", async () => {
    const client = apiClientReturning({
      data: undefined,
      error: {
        error: {
          code: "relationship_conflict",
          message: "Esta solicitação de relação já existe.",
          request_id: "relationship-conflict",
        },
      },
      response: new Response(null, { status: 409 }),
    });

    await expect(
      createProfessionalRelationship(client, {
        target: {
          type: "profile",
          professionalProfileId: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
        },
        relationshipType: "worked_together",
      }),
    ).rejects.toMatchObject({
      code: "relationship_conflict",
      requestId: "relationship-conflict",
    });
  });

  it("records an accepted or declined response against the stable relationship id", async () => {
    const client = apiClientReturning({
      data: {
        data: {
          relationship: {
            id: "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
            relationship_type: "worked_together",
            context_note: null,
            status: "accepted",
            source: "existing_profile",
            created_at: "2026-08-17T12:00:00Z",
            responded_at: "2026-08-18T12:00:00Z",
            initiator: {
              id: "f39d4810-f28d-4977-b5e5-387131d12942",
              public_slug: "ana-souza",
              display_name: "Ana Souza",
              profile_type: "self_service",
              photo_url: null,
              profile_available: false,
            },
            recipient: {
              id: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
              public_slug: "beto-lima",
              display_name: "Beto Lima",
              profile_type: "self_service",
              photo_url: "https://api.example.test/beto.jpg",
              profile_available: true,
            },
          },
        },
        request_id: "relationship-accept",
      },
      error: undefined,
      response: new Response(null, { status: 200 }),
    });

    await expect(
      respondProfessionalRelationship(
        client,
        "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
        "accepted",
      ),
    ).resolves.toMatchObject({
      status: "accepted",
      respondedAt: "2026-08-18T12:00:00Z",
    });
    expect(client.POST).toHaveBeenCalledWith(
      "/api/v1/professional/relationships/{id}/response",
      {
        params: {
          path: { id: "d25c64fa-3e6a-4e56-adc9-85bdac0045cb" },
        },
        body: { response: "accepted" },
      },
    );
  });

  it("sends the external profile fields inside the discriminated phone target", async () => {
    const client = apiClientReturning({
      data: {
        data: {
          relationship: {
            id: "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
            relationship_type: "recommendation",
            context_note: null,
            status: "pending",
            source: "external_phone",
            created_at: "2026-08-20T12:00:00Z",
            responded_at: null,
            initiator: {
              id: "f39d4810-f28d-4977-b5e5-387131d12942",
              public_slug: "ana-souza",
              display_name: "Ana Souza",
              profile_type: "self_service",
              photo_url: null,
              profile_available: true,
            },
            recipient: {
              id: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
              public_slug: "beto-lima",
              display_name: "Beto Lima",
              profile_type: "external",
              photo_url: null,
              profile_available: true,
            },
          },
        },
        request_id: "relationship-external",
      },
      error: undefined,
      response: new Response(null, { status: 201 }),
    });

    await createProfessionalRelationship(client, {
      target: {
        type: "phone",
        name: "  Beto Lima  ",
        phone: "+5547999991234",
        serviceIds: ["cc1e5dfa-36a2-4f13-b37c-d1a3f9d25460"],
        coverage: {
          allJoinville: false,
          neighborhoodCodes: ["america"],
        },
        contactPublicationAttested: true,
      },
      relationshipType: "recommendation",
    });

    expect(client.POST).toHaveBeenCalledWith(
      "/api/v1/professional/relationships",
      {
        body: {
          relationship: {
            target: {
              type: "phone",
              name: "Beto Lima",
              phone: "+5547999991234",
              service_ids: ["cc1e5dfa-36a2-4f13-b37c-d1a3f9d25460"],
              coverage: {
                all_joinville: false,
                neighborhood_codes: ["america"],
              },
              contact_publication_attested: true,
            },
            relationship_type: "recommendation",
            context_note: null,
          },
        },
      },
    );
  });

  it("maps safe name-search candidates", async () => {
    const client = apiClientReturning({
      data: {
        data: {
          candidates: [
            {
              id: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
              public_slug: "beto-lima",
              display_name: "Beto Lima",
              profile_type: "external",
              photo_url: null,
            },
          ],
        },
        request_id: "relationship-candidates",
      },
      error: undefined,
      response: new Response(null, { status: 200 }),
    });

    await expect(
      searchProfessionalRelationshipCandidates(client, "Beto"),
    ).resolves.toEqual([
      {
        id: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
        publicSlug: "beto-lima",
        displayName: "Beto Lima",
        profileType: "external",
        photoUrl: null,
      },
    ]);
    expect(client.GET).toHaveBeenCalledWith(
      "/api/v1/professional/relationship-candidates",
      { params: { query: { query: "Beto" } } },
    );
  });
});
