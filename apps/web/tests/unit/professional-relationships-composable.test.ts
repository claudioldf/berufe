import { ApiRequestError } from "@app/services/api/errors";
import type { ProfessionalRelationship } from "@app/services/api/professional-relationships";
import { useProfessionalRelationships } from "@app/composables/useProfessionalRelationships";

const relationship: ProfessionalRelationship = {
  id: "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
  relationshipType: "recommendation",
  contextNote: null,
  status: "pending",
  source: "existing_profile",
  createdAt: "2026-08-18T12:00:00Z",
  respondedAt: null,
  initiator: {
    id: "f39d4810-f28d-4977-b5e5-387131d12942",
    publicSlug: "ana-souza",
    displayName: "Ana Souza",
    profileType: "self_service",
    photoUrl: null,
    profileAvailable: false,
  },
  recipient: {
    id: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
    publicSlug: "beto-lima",
    displayName: "Beto Lima",
    profileType: "self_service",
    photoUrl: null,
    profileAvailable: false,
  },
};

describe("professional relationship workflow", () => {
  it("prevents duplicate submissions while one request is pending", async () => {
    let resolveCreate: ((value: ProfessionalRelationship) => void) | undefined;
    const create = vi.fn(
      () =>
        new Promise<ProfessionalRelationship>((resolve) => {
          resolveCreate = resolve;
        }),
    );
    const workflow = useProfessionalRelationships({ create });
    const input = {
      target: {
        type: "profile",
        professionalProfileId: relationship.recipient.id,
      },
      relationshipType: relationship.relationshipType,
    } as const;

    const first = workflow.requestRelationship(input);
    await workflow.requestRelationship(input);

    expect(workflow.isSubmitting.value).toBe(true);
    expect(create).toHaveBeenCalledOnce();
    resolveCreate?.(relationship);
    await expect(first).resolves.toEqual(relationship);
    expect(workflow.isSubmitting.value).toBe(false);
  });

  it("keeps a normalized API failure visible until the next attempt", async () => {
    const failure = new ApiRequestError({
      code: "relationship_conflict",
      message: "Esta solicitação de relação já existe.",
      fieldErrors: {},
      requestId: "relationship-conflict",
    });
    const workflow = useProfessionalRelationships({
      create: vi.fn().mockRejectedValue(failure),
    });

    await expect(
      workflow.requestRelationship({
        target: {
          type: "profile",
          professionalProfileId: relationship.recipient.id,
        },
        relationshipType: "recommendation",
      }),
    ).rejects.toBe(failure);
    expect(workflow.error.value).toBe("Esta solicitação de relação já existe.");

    workflow.clearError();
    expect(workflow.error.value).toBe("");
  });

  it("keeps only the latest name-search result", async () => {
    let resolveFirst:
      ((value: Array<{ id: string; displayName: string }>) => void) | undefined;
    const latest = {
      id: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
      publicSlug: "beto-lima",
      displayName: "Beto Lima",
      profileType: "external" as const,
      photoUrl: null,
    };
    const search = vi
      .fn()
      .mockImplementationOnce(
        () =>
          new Promise((resolve) => {
            resolveFirst = resolve;
          }),
      )
      .mockResolvedValueOnce([latest]);
    const workflow = useProfessionalRelationships({ search });

    const first = workflow.searchCandidates("Be");
    await workflow.searchCandidates("Beto");
    resolveFirst?.([
      {
        id: "stale",
        publicSlug: "stale",
        displayName: "Resultado antigo",
        profileType: "self_service",
        photoUrl: null,
      },
    ]);
    await first;

    expect(search).toHaveBeenNthCalledWith(1, "Be");
    expect(search).toHaveBeenNthCalledWith(2, "Beto");
    expect(workflow.candidates.value).toEqual([latest]);
    expect(workflow.isSearching.value).toBe(false);
  });
});
