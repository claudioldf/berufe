import type { BerufeApiClient } from "./client";
import { ApiRequestError, normalizeApiError } from "./errors";

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
  authenticatedAt: string;
  idleExpiresAt: string;
  absoluteExpiresAt: string;
}

export interface RestoredApplicationSession {
  account: CurrentAccount;
  session: CurrentSession;
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
    account: {
      id: data.data.account.id,
      role: data.data.account.role,
      status: data.data.account.status,
      registered: data.data.account.registered,
      verified: data.data.account.verified,
      registrationCompleted: data.data.account.registration_completed,
      onboardingCompleted: data.data.account.onboarding_completed,
      registrationDisplayName: data.data.account.registration_display_name,
      professionalProfileId: data.data.account.professional_profile_id,
      relationshipEligible: data.data.account.relationship_eligible,
    },
    session: {
      authenticationMethod: data.data.session.authentication_method,
      authenticatedAt: data.data.session.authenticated_at,
      idleExpiresAt: data.data.session.idle_expires_at,
      absoluteExpiresAt: data.data.session.absolute_expires_at,
    },
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
