import type { BerufeApiClient } from "~/services/api/client";
import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import type { components } from "~/services/api/schema";
import type { ProfessionalServiceJob } from "~/types";
import { formatBrazilianMobilePhone } from "~/utils/brazilian-phone";

type ContractServiceJob = components["schemas"]["ProfessionalServiceJob"];

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
): Promise<ProfessionalServiceJob> {
  const { data, error, response } = await client.POST(
    "/api/v1/professional/service-jobs/{id}/cancel",
    {
      params: { path: { id } },
      body: { cancellation: { reason: reason.trim() || null } },
    },
  );
  if (error || !data) throw requestError(error, response);
  return mapProfessionalServiceJob(data.data.service_job);
}

export async function completeProfessionalServiceJob(
  client: BerufeApiClient,
  id: string,
  requestRecommendation: boolean,
): Promise<{
  serviceJob: ProfessionalServiceJob;
  shareUrl: string | null;
  whatsappUrl: string | null;
}> {
  const { data, error, response } = await client.POST(
    "/api/v1/professional/service-jobs/{id}/complete",
    {
      params: { path: { id } },
      body: { completion: { request_recommendation: requestRecommendation } },
    },
  );
  if (error || !data) throw requestError(error, response);
  return {
    serviceJob: mapProfessionalServiceJob(data.data.service_job),
    shareUrl: data.data.share_url,
    whatsappUrl: data.data.whatsapp_url,
  };
}
