import type { BerufeApiClient } from "./client";
import { ApiRequestError, normalizeApiError } from "./errors";

export interface CurrentAccount {
  id: string;
  role: "professional" | "admin";
  status: "active";
}

export interface CurrentSession {
  authenticationMethod: "sms_otp";
  authenticatedAt: string;
  mfaAuthenticated: boolean;
  idleExpiresAt: string;
  absoluteExpiresAt: string;
}

export interface RestoredApplicationSession {
  account: CurrentAccount;
  session: CurrentSession;
  csrfToken: string;
}

export async function getCurrentApplicationSession(
  client: BerufeApiClient,
): Promise<RestoredApplicationSession | null> {
  const { data, error, response } = await client.GET("/api/v1/session");
  if (response.status === 401) return null;
  if (error || !data) {
    throw new ApiRequestError(
      normalizeApiError(
        error,
        response.headers.get("X-Request-Id") ?? "client",
      ),
    );
  }

  return {
    account: data.data.account,
    session: {
      authenticationMethod: data.data.session.authentication_method,
      authenticatedAt: data.data.session.authenticated_at,
      mfaAuthenticated: data.data.session.mfa_authenticated,
      idleExpiresAt: data.data.session.idle_expires_at,
      absoluteExpiresAt: data.data.session.absolute_expires_at,
    },
    csrfToken: data.data.csrf_token,
  };
}

export async function endCurrentApplicationSession(
  client: BerufeApiClient,
): Promise<void> {
  const { error, response } = await client.DELETE("/api/v1/session");
  if (response.status === 204 || response.status === 401) return;

  throw new ApiRequestError(
    normalizeApiError(error, response.headers.get("X-Request-Id") ?? "client"),
  );
}
