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
    pricingMode: quote.pricing_mode,
    // The private calculation is owner-only and never appears in this
    // response — these fields are meaningless here and go unused because
    // the customer page always reads the server's authoritative totals.
    lumpSumAmount: null,
    itemsVisibleToCustomer: quote.items_visible_to_customer,
    itemsAmount: 0,
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
          completedAt: quote.service_job.completed_at,
          cancelledAt: null,
        }
      : null,
    items: quote.items.map((item) => ({
      id: `shared-${quote.quote_number}-${item.sort_order}`,
      description: item.description,
      quantity: Number(item.quantity),
      unit: item.unit,
      // Null in `lump_sum` mode — a visible scope item never carries a
      // price. Coerced to 0 here only because QuoteItem stays a plain
      // number; the preview branches on pricingMode, not on this value.
      unitPrice: Number(item.unit_price ?? 0),
      lineTotal: Number(item.line_total ?? 0),
      sortOrder: item.sort_order,
    })),
    materials: quote.materials.map((material) => ({
      id: `shared-material-${quote.quote_number}-${material.sort_order}`,
      description: material.description,
      quantity: Number(material.quantity),
      unit: material.unit,
      sortOrder: material.sort_order,
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
