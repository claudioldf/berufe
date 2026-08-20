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

export interface ProfessionalRelationshipCandidate {
  id: string;
  publicSlug: string;
  displayName: string;
  profileType: "self_service" | "external";
  photoUrl: string | null;
}

export type ProfessionalRelationshipTarget =
  | {
      type: "profile";
      professionalProfileId: string;
    }
  | {
      type: "phone";
      name: string;
      phone: string;
      serviceIds: string[];
      coverage: {
        allJoinville: boolean;
        neighborhoodCodes: string[];
      };
      contactPublicationAttested: true;
    };

export interface ProfessionalRelationshipRequestInput {
  target: ProfessionalRelationshipTarget;
  relationshipType: ProfessionalRelationshipType;
  contextNote?: string | null;
}

export type ProfessionalRelationshipResponse = "accepted" | "declined";

interface ContractRelationship {
  id: string;
  relationship_type: ProfessionalRelationshipType;
  context_note: string | null;
  status: "pending" | "accepted" | "declined";
  source: "existing_profile" | "external_phone";
  created_at: string;
  responded_at: string | null;
  initiator: ContractRelationshipParty;
  recipient: ContractRelationshipParty;
}

interface ContractRelationshipParty {
  id: string;
  public_slug: string;
  display_name: string;
  profile_type: "self_service" | "external";
  photo_url: string | null;
  profile_available: boolean;
}

export function mapProfessionalRelationship(
  relationship: ContractRelationship,
): ProfessionalRelationship {
  return {
    id: relationship.id,
    relationshipType: relationship.relationship_type,
    contextNote: relationship.context_note,
    status: relationship.status,
    source: relationship.source,
    createdAt: relationship.created_at,
    respondedAt: relationship.responded_at,
    initiator: mapParty(relationship.initiator),
    recipient: mapParty(relationship.recipient),
  };
}

function mapParty(party: ContractRelationshipParty) {
  return {
    id: party.id,
    publicSlug: party.public_slug,
    displayName: party.display_name,
    profileType: party.profile_type,
    photoUrl: party.photo_url,
    profileAvailable: party.profile_available,
  };
}

function requestError(error: unknown, response: Response) {
  return new ApiRequestError(
    normalizeApiError(error, response.headers.get("X-Request-Id") ?? "client"),
  );
}

export async function searchProfessionalRelationshipCandidates(
  client: BerufeApiClient,
  query: string,
): Promise<ProfessionalRelationshipCandidate[]> {
  const { data, error, response } = await client.GET(
    "/api/v1/professional/relationship-candidates",
    { params: { query: { query } } },
  );
  if (error || !data) throw requestError(error, response);

  return data.data.candidates.map((candidate) => ({
    id: candidate.id,
    publicSlug: candidate.public_slug,
    displayName: candidate.display_name,
    profileType: candidate.profile_type,
    photoUrl: candidate.photo_url,
  }));
}

export async function createProfessionalRelationship(
  client: BerufeApiClient,
  input: ProfessionalRelationshipRequestInput,
): Promise<ProfessionalRelationship> {
  const target =
    input.target.type === "profile"
      ? {
          type: "profile" as const,
          professional_profile_id: input.target.professionalProfileId,
        }
      : {
          type: "phone" as const,
          name: input.target.name.trim(),
          phone: input.target.phone,
          service_ids: input.target.serviceIds,
          coverage: {
            all_joinville: input.target.coverage.allJoinville,
            neighborhood_codes: input.target.coverage.neighborhoodCodes,
          },
          contact_publication_attested: input.target.contactPublicationAttested,
        };
  const { data, error, response } = await client.POST(
    "/api/v1/professional/relationships",
    {
      body: {
        relationship: {
          target,
          relationship_type: input.relationshipType,
          context_note: input.contextNote?.trim() || null,
        },
      },
    },
  );
  if (error || !data) throw requestError(error, response);

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
  if (error || !data) throw requestError(error, response);

  return mapProfessionalRelationship(data.data.relationship);
}
