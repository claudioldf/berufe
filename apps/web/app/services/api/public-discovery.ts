import type { PublicProfessionalCard } from "~/types";
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
    coverage: card.coverage,
    verificationLabels: card.verificationLabels,
    portfolioCount: card.portfolioCount,
    relationshipCount: card.relationshipCount,
    publicSnapshotUpdatedAt: card.publicSnapshotUpdatedAt,
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
