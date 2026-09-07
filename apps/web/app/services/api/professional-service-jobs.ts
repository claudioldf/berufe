import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { components } from "~/services/api/schema";
import type {
  ProfessionalServiceJob,
  ServiceAdjustment,
  ServiceAdjustmentDraft,
} from "~/types";
import { formatBrazilianMobilePhone } from "~/utils/brazilian-phone";

type ContractServiceJob = components["schemas"]["ProfessionalServiceJob"];
type ContractServiceAdjustment =
  components["schemas"]["ProfessionalServiceAdjustment"];

function requestError(error: unknown, response: Response) {
  return new ApiRequestError(
    normalizeApiError(error, response.headers.get("X-Request-Id") ?? "client"),
  );
}

export function mapProfessionalServiceJob(
  job: ContractServiceJob,
): ProfessionalServiceJob {
  return {
    id: job.id,
    status: job.status,
    quote: {
      id: job.quote.id,
      number: job.quote.quote_number,
      customerName: job.quote.customer_name,
      customerPhone: formatBrazilianMobilePhone(job.quote.customer_phone_e164),
      customerEmail: job.quote.customer_email ?? "",
      serviceDescription: job.quote.service_description,
      serviceAddress: job.quote.service_address ?? "",
      scheduledOn: job.quote.scheduled_on ?? "",
      total: Number(job.quote.total_amount),
    },
    originalTotal: Number(job.original_total_amount ?? job.quote.total_amount),
    approvedAdjustmentTotal: Number(job.approved_adjustment_amount ?? 0),
    awaitingDecisionTotal: Number(job.awaiting_decision_amount ?? 0),
    agreedTotal: Number(job.agreed_total_amount ?? job.quote.total_amount),
    hasUnresolvedAdjustments: job.has_unresolved_adjustments ?? false,
    adjustments: (job.adjustments ?? []).map(mapProfessionalServiceAdjustment),
    customerFeedbackMessage: job.customer_feedback_message ?? "",
    completedAt: job.completed_at,
    cancelledAt: job.cancelled_at,
    cancellationReason: job.cancellation_reason ?? "",
    recommendation: job.recommendation
      ? {
          status: job.recommendation.status,
          deliveryChannel: job.recommendation.delivery_channel,
          sentAt: job.recommendation.sent_at,
        }
      : null,
    createdAt: job.created_at,
    updatedAt: job.updated_at,
  };
}

export function mapProfessionalServiceAdjustment(
  adjustment: ContractServiceAdjustment,
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
    acceptedCustomer: adjustment.accepted_customer
      ? {
          name: adjustment.accepted_customer.name,
          phone: formatBrazilianMobilePhone(
            adjustment.accepted_customer.phone_e164,
          ),
          email: adjustment.accepted_customer.email ?? "",
        }
      : null,
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
            mediaUploadId: item.receipt.media_upload_id,
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

function adjustmentBody(input: ServiceAdjustmentDraft) {
  return {
    adjustment: {
      revision: input.revision,
      title: input.title.trim(),
      description: input.description.trim() || null,
      schedule_impact: input.scheduleImpact.trim() || null,
      incurred_on: input.incurredOn || null,
      items: input.items.map((item) => ({
        kind: item.kind,
        description: item.description.trim(),
        quantity: item.quantity,
        unit: item.unit.trim(),
        unit_price: item.unitPrice,
        media_upload_id: item.mediaUploadId,
      })),
    },
  };
}

export async function createProfessionalServiceAdjustment(
  client: BerufeApiClient,
  serviceJobId: string,
  input: ServiceAdjustmentDraft,
): Promise<ProfessionalServiceJob> {
  const { data, error, response } = await client.POST(
    "/api/v1/professional/service-jobs/{service_job_id}/adjustments",
    {
      params: { path: { service_job_id: serviceJobId } },
      body: adjustmentBody(input),
    },
  );
  if (error || !data) throw requestError(error, response);
  return mapProfessionalServiceJob(data.data.service_job);
}

export async function updateProfessionalServiceAdjustment(
  client: BerufeApiClient,
  serviceJobId: string,
  adjustmentId: string,
  input: ServiceAdjustmentDraft,
): Promise<ProfessionalServiceJob> {
  const { data, error, response } = await client.PATCH(
    "/api/v1/professional/service-jobs/{service_job_id}/adjustments/{id}",
    {
      params: { path: { service_job_id: serviceJobId, id: adjustmentId } },
      body: adjustmentBody(input),
    },
  );
  if (error || !data) throw requestError(error, response);
  return mapProfessionalServiceJob(data.data.service_job);
}

export async function shareProfessionalServiceAdjustment(
  client: BerufeApiClient,
  serviceJobId: string,
  adjustmentId: string,
  method: "copy" | "whatsapp",
): Promise<{
  serviceJob: ProfessionalServiceJob;
  shareUrl: string;
  whatsappUrl: string;
}> {
  const { data, error, response } = await client.POST(
    "/api/v1/professional/service-jobs/{service_job_id}/adjustments/{id}/share",
    {
      params: { path: { service_job_id: serviceJobId, id: adjustmentId } },
      body: { share: { method } },
    },
  );
  if (error || !data) throw requestError(error, response);
  return {
    serviceJob: mapProfessionalServiceJob(data.data.service_job),
    shareUrl: data.data.share_url,
    whatsappUrl: data.data.whatsapp_url,
  };
}

export async function cancelProfessionalServiceAdjustment(
  client: BerufeApiClient,
  serviceJobId: string,
  adjustmentId: string,
): Promise<ProfessionalServiceJob> {
  const { data, error, response } = await client.POST(
    "/api/v1/professional/service-jobs/{service_job_id}/adjustments/{id}/cancel",
    { params: { path: { service_job_id: serviceJobId, id: adjustmentId } } },
  );
  if (error || !data) throw requestError(error, response);
  return mapProfessionalServiceJob(data.data.service_job);
}

export async function fetchProfessionalServiceJobs(
  client: BerufeApiClient,
): Promise<ProfessionalServiceJob[]> {
  const { data, error, response } = await client.GET(
    "/api/v1/professional/service-jobs",
  );
  if (error || !data) throw requestError(error, response);
  return data.data.service_jobs.map(mapProfessionalServiceJob);
}

export async function fetchProfessionalServiceJob(
  client: BerufeApiClient,
  id: string,
): Promise<ProfessionalServiceJob> {
  const { data, error, response } = await client.GET(
    "/api/v1/professional/service-jobs/{id}",
    { params: { path: { id } } },
  );
  if (error || !data) throw requestError(error, response);
  return mapProfessionalServiceJob(data.data.service_job);
}

export async function requestProfessionalServiceRecommendation(
  client: BerufeApiClient,
  id: string,
): Promise<{
  serviceJob: ProfessionalServiceJob;
  shareUrl: string;
  whatsappUrl: string;
}> {
  const { data, error, response } = await client.POST(
    "/api/v1/professional/service-jobs/{id}/recommendation-request",
    { params: { path: { id } } },
  );
  if (error || !data) throw requestError(error, response);
  return {
    serviceJob: mapProfessionalServiceJob(data.data.service_job),
    shareUrl: data.data.share_url,
    whatsappUrl: data.data.whatsapp_url,
  };
}

export async function cancelProfessionalServiceJob(
  client: BerufeApiClient,
  id: string,
  reason: string,
  acknowledgeOpenAdjustments = false,
): Promise<ProfessionalServiceJob> {
  const cancellation: {
    reason: string | null;
    acknowledge_open_adjustments?: boolean;
  } = { reason: reason.trim() || null };
  if (acknowledgeOpenAdjustments)
    cancellation.acknowledge_open_adjustments = true;
  const { data, error, response } = await client.POST(
    "/api/v1/professional/service-jobs/{id}/cancel",
    {
      params: { path: { id } },
      body: { cancellation },
    },
  );
  if (error || !data) throw requestError(error, response);
  return mapProfessionalServiceJob(data.data.service_job);
}

export async function completeProfessionalServiceJob(
  client: BerufeApiClient,
  id: string,
  requestRecommendation: boolean,
  acknowledgeOpenAdjustments = false,
): Promise<{
  serviceJob: ProfessionalServiceJob;
  shareUrl: string | null;
  whatsappUrl: string | null;
}> {
  const completion: {
    request_recommendation: boolean;
    acknowledge_open_adjustments?: boolean;
  } = { request_recommendation: requestRecommendation };
  if (acknowledgeOpenAdjustments)
    completion.acknowledge_open_adjustments = true;
  const { data, error, response } = await client.POST(
    "/api/v1/professional/service-jobs/{id}/complete",
    {
      params: { path: { id } },
      body: { completion },
    },
  );
  if (error || !data) throw requestError(error, response);
  return {
    serviceJob: mapProfessionalServiceJob(data.data.service_job),
    shareUrl: data.data.share_url,
    whatsappUrl: data.data.whatsapp_url,
  };
}
