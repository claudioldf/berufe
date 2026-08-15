import type { BerufeApiClient } from "~/services/api/client";
import {
  ApiRequestError,
  normalizeApiError,
  type NormalizedApiError,
} from "~/services/api/errors";

export interface RequestedPhoneOtp {
  challengeToken: string;
  expiresIn: number;
  resendAvailableIn: number;
}

export interface VerifyPhoneOtpInput {
  challengeToken: string;
  code: string;
}

export class PhoneOtpRequestError extends ApiRequestError {
  readonly retryAfter?: number;

  constructor(error: NormalizedApiError, retryAfter?: number) {
    super(error);
    this.name = "PhoneOtpRequestError";
    this.retryAfter = retryAfter;
  }
}

export async function requestPhoneOtp(
  client: BerufeApiClient,
  phone: string,
): Promise<RequestedPhoneOtp> {
  const { data, error, response } = await client.POST(
    "/api/v1/auth/otp/challenges",
    { body: { phone } },
  );
  if (error || !data) {
    throw new PhoneOtpRequestError(
      normalizeApiError(
        error,
        response.headers.get("X-Request-Id") ?? "client",
      ),
      parseRetryAfter(response.headers.get("Retry-After")),
    );
  }

  return {
    challengeToken: data.data.challenge_token,
    expiresIn: data.data.expires_in,
    resendAvailableIn: data.data.resend_available_in,
  };
}

export async function verifyPhoneOtp(
  client: BerufeApiClient,
  input: VerifyPhoneOtpInput,
): Promise<void> {
  const { data, error, response } = await client.POST(
    "/api/v1/auth/otp/verifications",
    {
      body: {
        challenge_token: input.challengeToken,
        code: input.code,
      },
    },
  );
  if (error || !data) {
    throw new ApiRequestError(
      normalizeApiError(
        error,
        response.headers.get("X-Request-Id") ?? "client",
      ),
    );
  }
}

function parseRetryAfter(value: string | null): number | undefined {
  if (!value || !/^\d+$/.test(value)) return undefined;

  const seconds = Number(value);
  return Number.isSafeInteger(seconds) && seconds > 0 ? seconds : undefined;
}
