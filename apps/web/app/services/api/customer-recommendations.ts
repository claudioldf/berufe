import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";

export interface CustomerRecommendationContext {
  customerName: string;
  serviceDescription: string;
  professional: { name: string; slug: string };
  expiresAt: string;
}

function requestError(error: unknown, response: Response) {
  return new ApiRequestError(
    normalizeApiError(error, response.headers.get("X-Request-Id") ?? "client"),
  );
}

export async function resolveCustomerRecommendation(
  client: BerufeApiClient,
  token: string,
): Promise<CustomerRecommendationContext> {
  const { data, error, response } = await client.POST(
    "/api/v1/customer-recommendations/resolve",
    { body: { token } },
  );
  if (error || !data) throw requestError(error, response);
  const request = data.data.recommendation_request;
  return {
    customerName: request.customer_name,
    serviceDescription: request.service_description,
    professional: {
      name: request.professional.display_name,
      slug: request.professional.public_slug,
    },
    expiresAt: request.expires_at,
  };
}

export async function createCustomerRecommendation(
  client: BerufeApiClient,
  token: string,
  input: {
    displayName: string;
    text: string;
    serviceConfirmed: boolean;
    publicationConsent: boolean;
  },
): Promise<void> {
  const { data, error, response } = await client.POST(
    "/api/v1/customer-recommendations",
    {
      body: {
        token,
        recommendation: {
          display_name: input.displayName,
          recommendation_text: input.text,
          service_confirmed: input.serviceConfirmed,
          publication_consent: input.publicationConsent,
        },
      },
    },
  );
  if (error || !data) throw requestError(error, response);
}

export async function createCustomerFeedbackIssue(
  client: BerufeApiClient,
  token: string,
  message: string,
): Promise<void> {
  const { data, error, response } = await client.POST(
    "/api/v1/customer-recommendations/issues",
    { body: { token, message } },
  );
  if (error || !data) throw requestError(error, response);
}
