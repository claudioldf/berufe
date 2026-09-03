import type { BerufeApiClient } from "./client";
import { ApiRequestError, normalizeApiError } from "./errors";
import {
  mapCurrentApplicationSession,
  type RestoredApplicationSession,
} from "./application-session";

function requireSession(
  result: Awaited<ReturnType<BerufeApiClient["POST"]>>,
): RestoredApplicationSession {
  if (result.error || !result.data || !("data" in result.data)) {
    throw new ApiRequestError(
      normalizeApiError(
        result.error,
        result.response.headers.get("X-Request-Id") ?? "client",
      ),
    );
  }

  return mapCurrentApplicationSession(result.data.data);
}

export async function startAdminProfessionalImpersonation(
  client: BerufeApiClient,
  professionalAccountId: string,
): Promise<RestoredApplicationSession> {
  return requireSession(
    await client.POST("/api/v1/admin/impersonation", {
      body: { professional_account_id: professionalAccountId },
    }),
  );
}

export async function stopAdminProfessionalImpersonation(
  client: BerufeApiClient,
): Promise<RestoredApplicationSession> {
  const result = await client.DELETE("/api/v1/admin/impersonation");
  if (result.error || !result.data) {
    throw new ApiRequestError(
      normalizeApiError(
        result.error,
        result.response.headers.get("X-Request-Id") ?? "client",
      ),
    );
  }

  return mapCurrentApplicationSession(result.data.data);
}
