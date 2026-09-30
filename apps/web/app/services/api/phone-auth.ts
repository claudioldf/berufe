import type { BerufeApiClient } from "~/services/api/client";
import {
  ApiRequestError,
  normalizeApiError,
  type NormalizedApiError,
} from "~/services/api/errors";
import { sanitizeBrazilianMobilePhone } from "~/utils/brazilian-phone";

export type ProfessionalAuthMethod = "phone" | "email";

export interface RequestedProfessionalOtp {
  challengeToken: string;
  expiresIn: number;
  resendAvailableIn: number;
}

export interface RequestProfessionalOtpInput {
  method: ProfessionalAuthMethod;
  identifier: string;
}

export interface VerifyProfessionalOtpInput {
  challengeToken: string;
  code: string;
}

export class ProfessionalOtpRequestError extends ApiRequestError {
  readonly retryAfter?: number;

  constructor(error: NormalizedApiError, retryAfter?: number) {
    super(error);
    this.name = "ProfessionalOtpRequestError";
    this.retryAfter = retryAfter;
  }
}

export async function requestProfessionalOtp(
  client: BerufeApiClient,
  input: RequestProfessionalOtpInput,
): Promise<RequestedProfessionalOtp> {
  const body =
    input.method === "phone"
      ? { phone: sanitizeBrazilianMobilePhone(input.identifier) }
      : { email: input.identifier.trim().toLocaleLowerCase("pt-BR") };
  const { data, error, response } = await client.POST(
    "/api/v1/auth/otp/challenges",
    { body },
  );
  if (error || !data) {
    throw new ProfessionalOtpRequestError(
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

export async function verifyProfessionalOtp(
  client: BerufeApiClient,
  input: VerifyProfessionalOtpInput,
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
