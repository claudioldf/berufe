import type {
  PublicProfessionalCard,
  PublicProfessionalSearchResult,
} from "~/types";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { BerufeApiClient } from "~/services/api/client";
import type { components } from "~/services/api/schema";

type ContractProfessionalCard = components["schemas"]["PublicProfessionalCard"];

export function mapPublicProfessionalCard(
  card: ContractProfessionalCard,
): PublicProfessionalCard {
  return {
    id: card.id,
    slug: card.publicSlug,
    name: card.displayName,
    headline: card.headline,
    photoUrl: card.photoUrl,
    primaryService: card.primaryService,
    matchingService: card.matchingService,
    coverage: card.coverage,
    verificationLabels: card.verificationLabels,
    portfolioCount: card.portfolioCount,
    relationshipCount: card.relationshipCount,
    publicSnapshotUpdatedAt: card.publicSnapshotUpdatedAt,
  };
}

interface PublicProfessionalSearchInput {
  service: string;
  neighborhoodCode?: string | null;
}

export async function searchPublicProfessionals(
  client: BerufeApiClient,
  input: PublicProfessionalSearchInput,
): Promise<PublicProfessionalSearchResult> {
  const { data, error, response } = await client.POST(
    "/api/v1/public/professional-searches",
    {
      body: {
        service: input.service,
        neighborhoodCode: input.neighborhoodCode ?? null,
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

  return {
    normalizedTerm: data.data.query.normalizedTerm,
    resolvedService: data.data.query.service,
    neighborhood: data.data.query.neighborhood,
    professionals: data.data.professionals.map(mapPublicProfessionalCard),
    relatedServices: data.data.relatedServices,
    interaction: data.data.interaction,
  };
}

export async function fetchFeaturedProfessionals(
  client: BerufeApiClient,
): Promise<PublicProfessionalCard[]> {
  const { data, error, response } = await client.GET(
    "/api/v1/public/professionals/featured",
  );
  if (error || !data) {
    throw new ApiRequestError(
      normalizeApiError(
        error,
        response.headers.get("X-Request-Id") ?? "client",
      ),
    );
  }

  return data.data.professionals.map(mapPublicProfessionalCard);
}
