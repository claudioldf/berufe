import type {
  PublicProfessionalCard,
  PublicProfessionalProfile,
  PublicProfessionalProfileResult,
  PublicProfessionalSearchResult,
  SearchLocation,
  StructuredSearchPayload,
} from "~/types";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { BerufeApiClient } from "~/services/api/client";
import type { components } from "~/services/api/schema";

type ContractProfessionalCard = components["schemas"]["PublicProfessionalCard"];
type ContractProfessionalProfile =
  components["schemas"]["PublicProfessionalProfile"];
type ContractVerificationLabel =
  components["schemas"]["PublicVerificationLabel"];
type ContractSearchData = components["schemas"]["PublicProfessionalSearchData"];
type ContractCoverage = components["schemas"]["PublicProfessionalCoverage"];

function mapCoverage(coverage: ContractCoverage) {
  return {
    city: coverage.city
      ? {
          code: coverage.city.code,
          name: coverage.city.name,
          slug: coverage.city.slug,
          stateCode: coverage.city.state_code,
          stateAbbreviation: coverage.city.state_abbreviation,
          stateName: coverage.city.state_name,
        }
      : null,
    wholeCity: coverage.whole_city,
    neighborhoods: coverage.neighborhoods,
  };
}

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
    coverage: mapCoverage(card.coverage),
    verificationLabels: card.verification_labels.map(mapVerificationLabel),
    portfolioCount: card.portfolio_count,
    relationshipCount: card.relationship_count,
    publicSnapshotUpdatedAt: card.public_snapshot_updated_at,
  };
}

interface PublicProfessionalSearchInput {
  expression: string;
  defaultLocation?: Pick<SearchLocation, "cityCode">;
  page?: number;
  perPage?: number;
}

interface StructuredProfessionalSearchInput extends Pick<
  StructuredSearchPayload,
  "serviceId" | "cityCode"
> {
  page?: number;
  perPage?: number;
}

function mapPublicProfessionalSearchResult(
  data: ContractSearchData,
): PublicProfessionalSearchResult {
  return {
    professionals: data.professionals.map(mapPublicProfessionalCard),
    relatedServices: data.related_services,
    page: data.meta.page,
    perPage: data.meta.per_page,
    totalCount: data.meta.total_count,
    totalPages: data.meta.total_pages,
    interpretation: {
      services: data.interpretation.services,
      locations: data.interpretation.locations.map((location) => ({
        cityCode: location.city_code,
        stateCode: location.state_code,
        city: location.city,
        neighborhood: location.neighborhood,
      })),
      normalizedRequest: data.interpretation.normalized_request,
    },
    interaction: data.interaction && {
      searchEventId: data.interaction.search_event_id,
      token: data.interaction.token,
    },
  };
}

export async function searchPublicProfessionals(
  client: BerufeApiClient,
  input: PublicProfessionalSearchInput,
): Promise<PublicProfessionalSearchResult> {
  const { data, error, response } = await client.POST(
    "/api/v1/public/professional-searches",
    {
      body: {
        expression: input.expression,
        ...(input.defaultLocation
          ? {
              default_location: {
                city_code: input.defaultLocation.cityCode,
              },
            }
          : {}),
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

  return mapPublicProfessionalSearchResult(data.data);
}

export async function searchStructuredProfessionals(
  client: BerufeApiClient,
  input: StructuredProfessionalSearchInput,
): Promise<PublicProfessionalSearchResult> {
  const { data, error, response } = await client.POST(
    "/api/v1/public/professional-searches",
    {
      body: {
        service_id: input.serviceId,
        city_code: input.cityCode,
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

  return mapPublicProfessionalSearchResult(data.data);
}

export async function fetchFeaturedProfessionals(
  client: BerufeApiClient,
  cityCode?: string,
): Promise<PublicProfessionalCard[]> {
  const { data, error, response } = cityCode
    ? await client.GET("/api/v1/public/professionals/featured", {
        params: { query: { city_code: cityCode } },
      })
    : await client.GET("/api/v1/public/professionals/featured");
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
    coverage: mapCoverage(profile.coverage),
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
