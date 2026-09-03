import type { BerufeApiClient } from "./client";
import { ApiRequestError, normalizeApiError } from "./errors";
import type { components } from "./schema";

export type CurrentSessionData = components["schemas"]["CurrentSessionData"];

export interface CurrentAccount {
  id: string;
  role: "professional" | "admin";
  status: "active";
  registered: boolean;
  verified: boolean;
  registrationCompleted: boolean;
  onboardingCompleted: boolean;
  registrationDisplayName: string | null;
  professionalProfileId: string | null;
  relationshipEligible: boolean;
}

export interface CurrentSession {
  authenticationMethod: "sms_otp" | "password";
  impersonating: boolean;
  authenticatedAt: string;
  idleExpiresAt: string;
  absoluteExpiresAt: string;
}

export interface RestoredApplicationSession {
  account: CurrentAccount;
  session: CurrentSession;
}

export function mapCurrentApplicationSession(
  data: CurrentSessionData,
): RestoredApplicationSession {
  return {
    account: {
      id: data.account.id,
      role: data.account.role,
      status: data.account.status,
      registered: data.account.registered,
      verified: data.account.verified,
      registrationCompleted: data.account.registration_completed,
      onboardingCompleted: data.account.onboarding_completed,
      registrationDisplayName: data.account.registration_display_name,
      professionalProfileId: data.account.professional_profile_id,
      relationshipEligible: data.account.relationship_eligible,
    },
    session: {
      authenticationMethod: data.session.authentication_method,
      impersonating: data.session.impersonating,
      authenticatedAt: data.session.authenticated_at,
      idleExpiresAt: data.session.idle_expires_at,
      absoluteExpiresAt: data.session.absolute_expires_at,
    },
  };
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

  return mapCurrentApplicationSession(data.data);
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
