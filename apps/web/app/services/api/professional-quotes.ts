import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { components } from "~/services/api/schema";
import type { Quote, QuoteDraft } from "~/types";

type ContractQuote = components["schemas"]["ProfessionalQuote"];

function requestError(error: unknown, response: Response) {
  return new ApiRequestError(
    normalizeApiError(error, response.headers.get("X-Request-Id") ?? "client"),
  );
}

export function mapProfessionalQuote(quote: ContractQuote): Quote {
  return {
    id: quote.id,
    number: quote.quote_number,
    customerName: quote.customer_name,
    serviceDescription: quote.service_description,
    validUntil: quote.valid_until ?? "",
    discount: Number(quote.discount_amount),
    notes: quote.notes ?? "",
    status: quote.status,
    subtotal: Number(quote.subtotal_amount),
    total: Number(quote.total_amount),
    sharedAt: quote.shared_at,
    createdAt: quote.created_at,
    updatedAt: quote.updated_at,
    items: quote.items.map((item) => ({
      id: item.id,
      description: item.description,
      quantity: Number(item.quantity),
      unit: item.unit,
      unitPrice: Number(item.unit_price),
      lineTotal: Number(item.line_total),
      sortOrder: item.sort_order,
    })),
  };
}

function writeBody(quote: QuoteDraft) {
  return {
    quote: {
      customer_name: quote.customerName,
      service_description: quote.serviceDescription,
      discount_amount: Number(quote.discount),
      valid_until: quote.validUntil || null,
      notes: quote.notes || null,
      items: quote.items.map((item) => ({
        description: item.description,
        quantity: Number(item.quantity),
        unit: item.unit,
        unit_price: Number(item.unitPrice),
      })),
    },
  };
}

export async function fetchProfessionalQuote(
  client: BerufeApiClient,
  id: string,
): Promise<Quote> {
  const { data, error, response } = await client.GET(
    "/api/v1/professional/quotes/{id}",
    { params: { path: { id } } },
  );
  if (error || !data) throw requestError(error, response);

  return mapProfessionalQuote(data.data.quote);
}

export async function createProfessionalQuote(
  client: BerufeApiClient,
  quote: QuoteDraft,
): Promise<Quote> {
  const { data, error, response } = await client.POST(
    "/api/v1/professional/quotes",
    { body: writeBody(quote) },
  );
  if (error || !data) throw requestError(error, response);

  return mapProfessionalQuote(data.data.quote);
}

export async function updateProfessionalQuote(
  client: BerufeApiClient,
  id: string,
  quote: QuoteDraft,
): Promise<Quote> {
  const { data, error, response } = await client.PATCH(
    "/api/v1/professional/quotes/{id}",
    { params: { path: { id } }, body: writeBody(quote) },
  );
  if (error || !data) throw requestError(error, response);

  return mapProfessionalQuote(data.data.quote);
}

export async function shareProfessionalQuote(
  client: BerufeApiClient,
  id: string,
): Promise<{ quote: Quote; shareUrl: string }> {
  const { data, error, response } = await client.POST(
    "/api/v1/professional/quotes/{id}/share",
    { params: { path: { id } } },
  );
  if (error || !data) throw requestError(error, response);

  return {
    quote: mapProfessionalQuote(data.data.quote),
    shareUrl: data.data.share_url,
  };
}
