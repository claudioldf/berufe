import type { BerufeApiClient } from "./client";
import { ApiRequestError, normalizeApiError } from "./errors";

export type ProfessionalRelationshipType = "recommendation" | "worked_together";

export interface ProfessionalRelationshipRequestInput {
  recipientProfessionalId: string;
  relationshipType: ProfessionalRelationshipType;
  contextNote?: string | null;
}

export interface ProfessionalRelationshipParty {
  id: string;
  publicSlug: string;
  displayName: string;
}

export interface ProfessionalRelationship {
  id: string;
  relationshipType: ProfessionalRelationshipType;
  contextNote: string | null;
  status: "pending" | "accepted" | "declined";
  createdAt: string;
  respondedAt: string | null;
  initiator: ProfessionalRelationshipParty;
  recipient: ProfessionalRelationshipParty;
}

export async function createProfessionalRelationship(
  client: BerufeApiClient,
  input: ProfessionalRelationshipRequestInput,
): Promise<ProfessionalRelationship> {
  const { data, error, response } = await client.POST(
    "/api/v1/professional/relationships",
    {
      body: {
        relationship: {
          recipient_professional_id: input.recipientProfessionalId,
          relationship_type: input.relationshipType,
          context_note: input.contextNote?.trim() || null,
        },
      },
    },
  );
  if (error || !data) {
    throw new ApiRequestError(
      normalizeApiError(
        error,
        response.headers.get("X-Request-Id") ?? "client",
      ),
    );
  }

  const relationship = data.data.relationship;
  return {
    id: relationship.id,
    relationshipType: relationship.relationship_type,
    contextNote: relationship.context_note,
    status: relationship.status,
    createdAt: relationship.created_at,
    respondedAt: relationship.responded_at,
    initiator: {
      id: relationship.initiator.id,
      publicSlug: relationship.initiator.public_slug,
      displayName: relationship.initiator.display_name,
    },
    recipient: {
      id: relationship.recipient.id,
      publicSlug: relationship.recipient.public_slug,
      displayName: relationship.recipient.display_name,
    },
  };
}
