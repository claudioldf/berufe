import type { BerufeApiClient } from "./client";
import { ApiRequestError, normalizeApiError } from "./errors";

export type DataErasureStatus =
  "requested" | "processing" | "retrying" | "completed";

export interface DataErasureRequestStatus {
  reference: string;
  status: DataErasureStatus;
  requestedAt: string;
  unpublishedAt: string;
  completionDeadlineAt: string;
  completedAt: string | null;
}

export interface SubmittedDataErasureRequest {
  statusToken: string;
  request: DataErasureRequestStatus;
}

export async function requestProfessionalDataErasure(
  client: BerufeApiClient,
): Promise<SubmittedDataErasureRequest> {
  const { data, error, response } = await client.POST(
    "/api/v1/professional/data-erasure-request",
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
    statusToken: data.data.status_token,
    request: mapStatus(data.data.request),
  };
}

export async function getDataErasureRequestStatus(
  client: BerufeApiClient,
  statusToken: string,
): Promise<DataErasureRequestStatus> {
  const { data, error, response } = await client.GET(
    "/api/v1/data-erasure-requests/{status_token}",
    { params: { path: { status_token: statusToken } } },
  );
  if (error || !data) {
    throw new ApiRequestError(
      normalizeApiError(
        error,
        response.headers.get("X-Request-Id") ?? "client",
      ),
    );
  }

  return mapStatus(data.data);
}

function mapStatus(data: {
  reference: string;
  status: DataErasureStatus;
  requested_at: string;
  unpublished_at: string;
  completion_deadline_at: string;
  completed_at: string | null;
}): DataErasureRequestStatus {
  return {
    reference: data.reference,
    status: data.status,
    requestedAt: data.requested_at,
    unpublishedAt: data.unpublished_at,
    completionDeadlineAt: data.completion_deadline_at,
    completedAt: data.completed_at,
  };
}
