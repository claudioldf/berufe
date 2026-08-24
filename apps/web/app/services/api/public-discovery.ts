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
type ContractVerificationLabel =
  components["schemas"]["PublicVerificationLabel"];

function mapVerificationLabel(label: ContractVerificationLabel) {
  return {
    type: label.type,
    label: label.label,
    verifiedAt: label.verified_at,
  };
}

export function mapPublicProfessionalCard(
  card: ContractProfessionalCard,
): PublicProfessionalCard {
  return {
    id: card.id,
    slug: card.public_slug,
    profileType: card.profile_type,
    claimed: card.claimed,
    name: card.display_name,
    headline: card.headline,
    photoUrl: card.photo_url,
    primaryService: card.primary_service,
    matchingService: card.matching_service,
    coverage: {
      allJoinville: card.coverage.all_joinville,
      neighborhoods: card.coverage.neighborhoods,
    },
    verificationLabels: card.verification_labels.map(mapVerificationLabel),
    portfolioCount: card.portfolio_count,
    relationshipCount: card.relationship_count,
    publicSnapshotUpdatedAt: card.public_snapshot_updated_at,
  };
}

interface PublicProfessionalSearchInput {
  service: string;
  professionalName?: string | null;
  neighborhoodCode?: string | null;
  page?: number;
  perPage?: number;
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
        ...(input.professionalName
          ? { professional_name: input.professionalName }
          : {}),
        neighborhood_code: input.neighborhoodCode ?? null,
        ...(input.page ? { page: input.page } : {}),
        ...(input.perPage ? { per_page: input.perPage } : {}),
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
    normalizedTerm: data.data.query.normalized_term,
    professionalName: data.data.query.professional_name,
    resolvedService: data.data.query.service,
    neighborhood: data.data.query.neighborhood,
    professionals: data.data.professionals.map(mapPublicProfessionalCard),
    relatedServices: data.data.related_services,
    page: data.data.meta.page,
    perPage: data.data.meta.per_page,
    totalCount: data.data.meta.total_count,
    totalPages: data.data.meta.total_pages,
    interaction: data.data.interaction && {
      searchEventId: data.data.interaction.search_event_id,
      token: data.data.interaction.token,
    },
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
    profile.services.find((service) => service.is_primary) ??
    profile.services[0] ??
    null;

  return {
    id: profile.id,
    slug: profile.public_slug,
    profileType: profile.profile_type,
    claimed: profile.claimed,
    name: profile.display_name,
    headline: profile.headline,
    bio: profile.bio,
    avatar: profile.photo_url,
    primaryService: primaryService?.name ?? null,
    primaryServiceSlug: primaryService?.slug ?? null,
    primaryServiceIcon: primaryService?.icon ?? null,
    services: profile.services.map((service) => service.name),
    serviceNotes: profile.services.map((service) => service.note),
    neighborhoods: profile.coverage.neighborhoods.map(
      (neighborhood) => neighborhood.name,
    ),
    allJoinville: profile.coverage.all_joinville,
    yearsExperience: profile.years_experience,
    evidence: profile.verification_labels.map((label) => ({
      id: label.type,
      ...mapVerificationLabel(label),
    })),
    evidenceSummary: {
      completedServices: profile.evidence_summary.completed_services,
      recommendations: profile.evidence_summary.recommendations,
      workedTogetherProfessionals:
        profile.evidence_summary.worked_together_professionals,
    },
    customerRecommendations: profile.customer_recommendations.map(
      (recommendation) => ({
        id: recommendation.id,
        displayName: recommendation.display_name,
        text: recommendation.recommendation_text,
        submittedAt: recommendation.submitted_at,
        verificationLabel: recommendation.verification_label,
      }),
    ),
    portfolio: profile.portfolio.map((item) => ({
      id: item.id,
      title: item.title,
      service: item.service.name,
      description: item.description,
      image: item.image_url,
    })),
    relationships: profile.relationships.map((relationship) => ({
      id: relationship.id,
      professionalName: relationship.professional.display_name,
      professionalSlug: relationship.professional.public_slug,
      avatar: relationship.professional.photo_url,
      type: relationship.type,
      direction: relationship.direction,
      note: relationship.note,
    })),
    updatedAt: profile.public_snapshot_updated_at,
    ...(profile.social_links.instagram
      ? { instagram: profile.social_links.instagram }
      : {}),
    ...(profile.social_links.youtube
      ? { youtube: profile.social_links.youtube }
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
        query: interactionToken ? { interaction_token: interactionToken } : {},
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
      body: { interaction_token: interactionToken },
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
