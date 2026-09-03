import type { BerufeApiClient } from "./client";
import { ApiRequestError, normalizeApiError } from "./errors";
import {
  mapCurrentApplicationSession,
  type CurrentSessionData,
  type RestoredApplicationSession,
} from "./application-session";

interface ApiResult<T> {
  data?: T;
  error?: unknown;
  response: Response;
}

function requireSession(
  result: ApiResult<{ data: CurrentSessionData }>,
): RestoredApplicationSession {
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
  return requireSession(await client.DELETE("/api/v1/admin/impersonation"));
}
