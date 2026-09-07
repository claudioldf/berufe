import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { components } from "~/services/api/schema";
import type { Quote, QuoteProfessional, ServiceAdjustment } from "~/types";

type ContractSharedQuote = components["schemas"]["SharedQuote"];
type ContractSharedProfessional =
  components["schemas"]["SharedQuoteProfessional"];
type ContractSharedAdjustment =
  components["schemas"]["SharedServiceAdjustment"];

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
  const itemizedPricing =
    quote.pricing.mode === "itemized" ? quote.pricing : null;
  return {
    id: null,
    number: quote.quote_number,
    revision: quote.revision,
    customerId: null,
    customerName: quote.customer_name,
    customerPhone: "",
    customerEmail: "",
    pricingMode: quote.pricing.mode,
    serviceDescription: quote.service_description,
    serviceAddress: quote.service_address ?? "",
    scheduledOn: quote.scheduled_on ?? "",
    validUntil: quote.valid_until ?? "",
    discount: Number(itemizedPricing?.discount_amount ?? 0),
    fixedPrice:
      quote.pricing.mode === "fixed_price" ? Number(quote.total_amount) : 0,
    notes: quote.notes ?? "",
    status: quote.status,
    subtotal: Number(itemizedPricing?.subtotal_amount ?? 0),
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
          originalTotal: Number(quote.service_job.original_total_amount),
          approvedAdjustmentTotal: Number(
            quote.service_job.approved_adjustment_amount,
          ),
          awaitingDecisionTotal: Number(
            quote.service_job.awaiting_decision_amount,
          ),
          agreedTotal: Number(quote.service_job.agreed_total_amount),
          adjustments: quote.service_job.adjustments.map(mapSharedAdjustment),
        }
      : null,
    items: (itemizedPricing?.items ?? []).map((item) => ({
      id: `shared-${quote.quote_number}-${item.sort_order}`,
      description: item.description,
      quantity: Number(item.quantity),
      unit: item.unit,
      unitPrice: Number(item.unit_price),
      lineTotal: Number(item.line_total),
      sortOrder: item.sort_order,
    })),
    customerSuppliedMaterials: quote.customer_supplied_materials.map(
      (material, index) => ({
        id: `shared-material-${quote.quote_number}-${index}`,
        description: material.description,
        quantity: Number(material.quantity),
        unit: material.unit,
        sortOrder: material.sort_order,
      }),
    ),
  };
}

function mapSharedAdjustment(
  adjustment: ContractSharedAdjustment,
): ServiceAdjustment {
  return {
    id: adjustment.id,
    number: adjustment.adjustment_number,
    revision: adjustment.revision,
    status: adjustment.status,
    title: adjustment.title,
    description: adjustment.description ?? "",
    scheduleImpact: adjustment.schedule_impact ?? "",
    incurredOn: adjustment.incurred_on ?? "",
    total: Number(adjustment.total_amount),
    sharedAt: adjustment.shared_at,
    customerDecidedAt: adjustment.customer_decided_at,
    customerDecisionMessage: adjustment.customer_decision_message ?? "",
    termsAcceptedAt: adjustment.terms_accepted_at,
    acceptedRevision: adjustment.accepted_revision,
    items: adjustment.items.map((item) => ({
      id: item.id,
      kind: item.kind,
      description: item.description,
      quantity: Number(item.quantity),
      unit: item.unit,
      unitPrice: Number(item.unit_price),
      lineTotal: Number(item.line_total),
      sortOrder: item.sort_order,
      receipt: item.receipt
        ? {
            id: item.receipt.id,
            contentType: item.receipt.content_type,
          }
        : null,
    })),
    changeRequests: adjustment.change_requests.map((request) => ({
      revision: request.requested_revision,
      message: request.message,
      requestedAt: request.requested_at,
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

export async function decideSharedServiceAdjustment(
  client: BerufeApiClient,
  token: string,
  adjustmentId: string,
  input: {
    kind: "approve" | "request_change" | "decline";
    revision: number;
    termsAccepted: boolean;
    message: string;
  },
): Promise<SharedQuoteResult> {
  const { data, error, response } = await client.POST(
    "/api/v1/shared-service-adjustments/decisions",
    {
      body: {
        token,
        adjustment_id: adjustmentId,
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

export async function fetchSharedServiceAdjustmentReceipt(
  client: BerufeApiClient,
  token: string,
  receiptId: string,
): Promise<Blob> {
  const result = await client.POST(
    "/api/v1/shared-service-adjustment-receipts/resolve",
    {
      body: { token, receipt_id: receiptId },
      parseAs: "blob",
    },
  );
  if (result.error || !result.data) {
    throw requestError(result.error, result.response);
  }
  return result.data;
}
