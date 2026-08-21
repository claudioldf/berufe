import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { components } from "~/services/api/schema";
import type { Quote, QuoteProfessional } from "~/types";

type ContractSharedQuote = components["schemas"]["SharedQuote"];
type ContractSharedProfessional =
  components["schemas"]["SharedQuoteProfessional"];

export interface SharedQuoteResult {
  quote: Quote;
  professional: QuoteProfessional;
}

function requestError(error: unknown, response: Response) {
  return new ApiRequestError(
    normalizeApiError(error, response.headers.get("X-Request-Id") ?? "client"),
  );
}

function mapSharedQuote(quote: ContractSharedQuote): Quote {
  return {
    id: null,
    number: quote.quote_number,
    revision: quote.revision,
    customerId: null,
    customerName: quote.customer_name,
    customerPhone: "",
    customerEmail: "",
    serviceDescription: quote.service_description,
    serviceAddress: quote.service_address ?? "",
    scheduledOn: quote.scheduled_on ?? "",
    validUntil: quote.valid_until ?? "",
    discount: Number(quote.discount_amount),
    notes: quote.notes ?? "",
    status: quote.status,
    subtotal: Number(quote.subtotal_amount),
    total: Number(quote.total_amount),
    sharedAt: null,
    createdAt: null,
    updatedAt: null,
    customerDecisionMessage: quote.customer_decision_message ?? "",
    changeRequests: [],
    serviceJob: quote.service_job
      ? {
          id: null,
          status: quote.service_job.status,
          completionRequestedAt: quote.service_job.completion_requested_at,
          completionIssueMessage:
            quote.service_job.completion_issue_message ?? "",
          completedAt: quote.service_job.completed_at,
          cancelledAt: null,
          recommendationAvailable: quote.service_job.recommendation_available,
        }
      : null,
    items: quote.items.map((item) => ({
      id: `shared-${quote.quote_number}-${item.sort_order}`,
      description: item.description,
      quantity: Number(item.quantity),
      unit: item.unit,
      unitPrice: Number(item.unit_price),
      lineTotal: Number(item.line_total),
      sortOrder: item.sort_order,
    })),
  };
}

function mapSharedProfessional(
  professional: ContractSharedProfessional,
): QuoteProfessional {
  return {
    name: professional.display_name,
    avatar: professional.photo_url,
    primaryService: professional.primary_service ?? "",
    identityVerified: professional.identity_verified,
  };
}

export async function resolveSharedQuote(
  client: BerufeApiClient,
  token: string,
): Promise<SharedQuoteResult> {
  const { data, error, response } = await client.POST(
    "/api/v1/shared-quotes/resolve",
    { body: { token } },
  );
  if (error || !data) throw requestError(error, response);

  return {
    quote: mapSharedQuote(data.data.quote),
    professional: mapSharedProfessional(data.data.professional),
  };
}

export async function decideSharedQuote(
  client: BerufeApiClient,
  token: string,
  input: {
    kind: "approve" | "request_change" | "decline";
    revision: number;
    termsAccepted: boolean;
    message: string;
  },
): Promise<SharedQuoteResult> {
  const { data, error, response } = await client.POST(
    "/api/v1/shared-quotes/decisions",
    {
      body: {
        token,
        decision: {
          kind: input.kind,
          revision: input.revision,
          terms_accepted: input.termsAccepted,
          message: input.message.trim() || null,
        },
      },
    },
  );
  if (error || !data) throw requestError(error, response);
  return {
    quote: mapSharedQuote(data.data.quote),
    professional: mapSharedProfessional(data.data.professional),
  };
}

export async function respondToSharedQuoteCompletion(
  client: BerufeApiClient,
  token: string,
  input: { kind: "confirm" | "report_issue"; message: string },
): Promise<SharedQuoteResult> {
  const { data, error, response } = await client.POST(
    "/api/v1/shared-quotes/completions",
    {
      body: {
        token,
        completion: {
          kind: input.kind,
          message: input.message.trim() || null,
        },
      },
    },
  );
  if (error || !data) throw requestError(error, response);
  return {
    quote: mapSharedQuote(data.data.quote),
    professional: mapSharedProfessional(data.data.professional),
  };
}
