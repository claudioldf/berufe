import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { components } from "~/services/api/schema";
import type {
  Quote,
  QuoteDraft,
  QuoteListFilters,
  QuotePage,
  QuoteShareMethod,
} from "~/types";
import {
  formatBrazilianMobilePhone,
  normalizeBrazilianMobilePhone,
} from "~/utils/brazilian-phone";

type ContractQuote = components["schemas"]["ProfessionalQuote"];

export function defaultProfessionalQuoteListFilters(): QuoteListFilters {
  return {
    search: "",
    status: "all",
    scheduledOn: "",
    sort: "updated",
    direction: "desc",
    page: 1,
    perPage: 20,
  };
}

function requestError(error: unknown, response: Response) {
  return new ApiRequestError(
    normalizeApiError(error, response.headers.get("X-Request-Id") ?? "client"),
  );
}

export function mapProfessionalQuote(quote: ContractQuote): Quote {
  return {
    id: quote.id,
    number: quote.quote_number,
    revision: quote.revision,
    customerId: quote.customer.id,
    customerName: quote.customer_name,
    customerPhone: formatBrazilianMobilePhone(quote.customer_phone_e164),
    customerEmail: quote.customer_email ?? "",
    serviceDescription: quote.service_description,
    serviceAddress: quote.service_address ?? "",
    scheduledOn: quote.scheduled_on ?? "",
    validUntil: quote.valid_until ?? "",
    discount: Number(quote.discount_amount),
    notes: quote.notes ?? "",
    status: quote.status,
    subtotal: Number(quote.subtotal_amount),
    total: Number(quote.total_amount),
    sharedAt: quote.shared_at,
    createdAt: quote.created_at,
    updatedAt: quote.updated_at,
    customerDecisionMessage: quote.customer_decision_message ?? "",
    changeRequests: quote.change_requests.map((request) => ({
      id: request.id,
      revision: request.revision,
      message: request.message,
      requestedAt: request.requested_at,
    })),
    serviceJob: quote.service_job
      ? {
          id: quote.service_job.id,
          status: quote.service_job.status,
          completionRequestedAt: quote.service_job.completion_requested_at,
          completionIssueMessage:
            quote.service_job.completion_issue_message ?? "",
          completedAt: quote.service_job.completed_at,
          cancelledAt: quote.service_job.cancelled_at,
          recommendationAvailable:
            quote.service_job.recommendation_request_status === "open",
        }
      : null,
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

export async function fetchProfessionalQuotes(
  client: BerufeApiClient,
  filters: QuoteListFilters,
): Promise<QuotePage> {
  const { data, error, response } = await client.GET(
    "/api/v1/professional/quotes",
    {
      params: {
        query: {
          search: filters.search || undefined,
          customer_id: filters.customerId || undefined,
          status: filters.status,
          scheduled_on: filters.scheduledOn || undefined,
          sort: filters.sort,
          direction: filters.direction,
          page: filters.page,
          per_page: filters.perPage,
        },
      },
    },
  );
  if (error || !data) throw requestError(error, response);

  return {
    quotes: data.data.quotes.map(mapProfessionalQuote),
    meta: {
      page: data.data.meta.page,
      perPage: data.data.meta.per_page,
      totalCount: data.data.meta.total_count,
      totalPages: data.data.meta.total_pages,
    },
  };
}

function writeBody(quote: QuoteDraft) {
  return {
    quote: {
      ...(quote.id ? { revision: quote.revision } : {}),
      customer: {
        id: quote.customerId,
        name: quote.customerName,
        whatsapp_e164:
          normalizeBrazilianMobilePhone(quote.customerPhone) ??
          quote.customerPhone,
        email: quote.customerEmail.trim() || null,
      },
      service_description: quote.serviceDescription,
      service_address: quote.serviceAddress.trim() || null,
      scheduled_on: quote.scheduledOn || null,
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
  method: QuoteShareMethod,
): Promise<{ quote: Quote; shareUrl: string; whatsappUrl: string }> {
  const { data, error, response } = await client.POST(
    "/api/v1/professional/quotes/{id}/share",
    {
      params: { path: { id } },
      body: { share: { method } },
    },
  );
  if (error || !data) throw requestError(error, response);

  return {
    quote: mapProfessionalQuote(data.data.quote),
    shareUrl: data.data.share_url,
    whatsappUrl: data.data.whatsapp_url,
  };
}

export async function revokeProfessionalQuoteShare(
  client: BerufeApiClient,
  id: string,
): Promise<Quote> {
  const { data, error, response } = await client.DELETE(
    "/api/v1/professional/quotes/{id}/share",
    { params: { path: { id } } },
  );
  if (error || !data) throw requestError(error, response);

  return mapProfessionalQuote(data.data.quote);
}
