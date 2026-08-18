import type {
  PublicProfessionalCard,
  PublicProfessionalProfile,
  PublicProfessionalProfileResult,
  PublicProfessionalSearchResult,
} from "~/types";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { BerufeApiClient } from "~/services/api/client";
import type { components } from "~/services/api/schema";

type ContractProfessionalCard = components["schemas"]["PublicProfessionalCard"];
type ContractProfessionalProfile =
  components["schemas"]["PublicProfessionalProfile"];

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

export function mapPublicProfessionalProfile(
  profile: ContractProfessionalProfile,
): PublicProfessionalProfile {
  const primaryService =
    profile.services.find((service) => service.isPrimary) ??
    profile.services[0]!;

  return {
    id: profile.id,
    slug: profile.publicSlug,
    name: profile.displayName,
    headline: profile.headline,
    bio: profile.bio,
    avatar: profile.photoUrl,
    primaryService: primaryService.name,
    primaryServiceSlug: primaryService.slug,
    services: profile.services.map((service) => service.name),
    serviceNotes: profile.services.map((service) => service.note),
    neighborhoods: profile.coverage.neighborhoods.map(
      (neighborhood) => neighborhood.name,
    ),
    allJoinville: profile.coverage.allJoinville,
    yearsExperience: profile.yearsExperience,
    evidence: profile.verificationLabels.map((label) => ({
      id: label.type,
      type: label.type,
      label: label.label,
      verifiedAt: label.verifiedAt,
    })),
    portfolio: profile.portfolio.map((item) => ({
      id: item.id,
      title: item.title,
      service: item.service.name,
      description: item.description,
      image: item.imageUrl,
    })),
    relationships: profile.relationships.map((relationship) => ({
      id: relationship.id,
      professionalName: relationship.professional.displayName,
      professionalSlug: relationship.professional.publicSlug,
      avatar: relationship.professional.photoUrl,
      type: relationship.type,
      direction: relationship.direction,
      note: relationship.note,
    })),
    updatedAt: profile.publicSnapshotUpdatedAt,
    ...(profile.socialLinks.instagram
      ? { instagram: profile.socialLinks.instagram }
      : {}),
    ...(profile.socialLinks.youtube
      ? { youtube: profile.socialLinks.youtube }
      : {}),
  };
}

export async function fetchPublicProfessionalProfile(
  client: BerufeApiClient,
  slug: string,
  interactionToken?: string,
): Promise<PublicProfessionalProfileResult> {
  const { data, error, response } = await client.GET(
    "/api/v1/public/professionals/{slug}",
    {
      params: {
        path: { slug },
        query: interactionToken ? { interactionToken } : {},
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
    professional: mapPublicProfessionalProfile(data.data.professional),
    interactionToken: data.data.interaction.token,
  };
}

export async function recordPublicProfessionalProfileView(
  client: BerufeApiClient,
  professionalId: string,
  interactionToken: string,
): Promise<void> {
  const { error, response } = await client.POST(
    "/api/v1/public/professionals/{id}/views",
    {
      params: { path: { id: professionalId } },
      body: { interactionToken },
    },
  );
  if (error || !response.ok) {
    throw new ApiRequestError(
      normalizeApiError(
        error,
        response.headers.get("X-Request-Id") ?? "client",
      ),
    );
  }
}
