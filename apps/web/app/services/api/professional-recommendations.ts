import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { components } from "~/services/api/schema";

type ContractRecommendation =
  components["schemas"]["ProfessionalRecommendation"];

export interface ProfessionalRecommendation {
  id: string;
  displayName: string;
  recommendationText: string;
  deliveryChannel: "email" | "whatsapp";
  submittedAt: string;
  customerName: string;
  serviceDescription: string;
  hiddenAt: string | null;
  hiddenReason: string;
}

function requestError(error: unknown, response: Response) {
  return new ApiRequestError(
    normalizeApiError(error, response.headers.get("X-Request-Id") ?? "client"),
  );
}

function mapProfessionalRecommendation(
  recommendation: ContractRecommendation,
): ProfessionalRecommendation {
  return {
    id: recommendation.id,
    displayName: recommendation.display_name,
    recommendationText: recommendation.recommendation_text,
    deliveryChannel: recommendation.delivery_channel,
    submittedAt: recommendation.submitted_at,
    customerName: recommendation.customer_name,
    serviceDescription: recommendation.service_description,
    hiddenAt: recommendation.hidden_at,
    hiddenReason: recommendation.hidden_reason ?? "",
  };
}

export async function fetchProfessionalRecommendations(
  client: BerufeApiClient,
): Promise<ProfessionalRecommendation[]> {
  const { data, error, response } = await client.GET(
    "/api/v1/professional/recommendations",
  );
  if (error || !data) throw requestError(error, response);
  return data.data.recommendations.map(mapProfessionalRecommendation);
}

export async function hideProfessionalRecommendation(
  client: BerufeApiClient,
  id: string,
  reason: string,
): Promise<ProfessionalRecommendation> {
  const { data, error, response } = await client.POST(
    "/api/v1/professional/recommendations/{id}/hide",
    {
      params: { path: { id } },
      body: { hide: { reason: reason.trim() || null } },
    },
  );
  if (error || !data) throw requestError(error, response);
  return mapProfessionalRecommendation(data.data.recommendation);
}

export async function unhideProfessionalRecommendation(
  client: BerufeApiClient,
  id: string,
): Promise<ProfessionalRecommendation> {
  const { data, error, response } = await client.POST(
    "/api/v1/professional/recommendations/{id}/unhide",
    { params: { path: { id } } },
  );
  if (error || !data) throw requestError(error, response);
  return mapProfessionalRecommendation(data.data.recommendation);
}
