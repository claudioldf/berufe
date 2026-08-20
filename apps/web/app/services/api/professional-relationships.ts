import type { BerufeApiClient } from "./client";
import { ApiRequestError, normalizeApiError } from "./errors";
import type {
  ProfessionalRelationship,
  ProfessionalRelationshipType,
} from "~/types";

export type {
  ProfessionalRelationship,
  ProfessionalRelationshipType,
} from "~/types";

export interface ProfessionalRelationshipRequestInput {
  recipientProfessionalId: string;
  relationshipType: ProfessionalRelationshipType;
  contextNote?: string | null;
}

export type ProfessionalRelationshipResponse = "accepted" | "declined";

interface ContractRelationship {
  id: string;
  relationship_type: ProfessionalRelationshipType;
  context_note: string | null;
  status: "pending" | "accepted" | "declined";
  created_at: string;
  responded_at: string | null;
  initiator: {
    id: string;
    public_slug: string;
    display_name: string;
    photo_url: string | null;
    profile_available: boolean;
  };
  recipient: {
    id: string;
    public_slug: string;
    display_name: string;
    photo_url: string | null;
    profile_available: boolean;
  };
}

export function mapProfessionalRelationship(
  relationship: ContractRelationship,
): ProfessionalRelationship {
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
      photoUrl: relationship.initiator.photo_url,
      profileAvailable: relationship.initiator.profile_available,
    },
    recipient: {
      id: relationship.recipient.id,
      publicSlug: relationship.recipient.public_slug,
      displayName: relationship.recipient.display_name,
      photoUrl: relationship.recipient.photo_url,
      profileAvailable: relationship.recipient.profile_available,
    },
  };
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

  return mapProfessionalRelationship(data.data.relationship);
}

export async function respondProfessionalRelationship(
  client: BerufeApiClient,
  id: string,
  responseValue: ProfessionalRelationshipResponse,
): Promise<ProfessionalRelationship> {
  const { data, error, response } = await client.POST(
    "/api/v1/professional/relationships/{id}/response",
    {
      params: { path: { id } },
      body: { response: responseValue },
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

  return mapProfessionalRelationship(data.data.relationship);
}
