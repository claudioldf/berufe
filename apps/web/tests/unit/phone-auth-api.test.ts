import type { BerufeApiClient } from "@app/services/api/client";
import { requestPhoneOtp } from "@app/services/api/phone-auth";
import type { PhoneOtpRequestError } from "@app/services/api/phone-auth";

function apiClientReturning(result: object) {
  return {
    POST: vi.fn().mockResolvedValue(result),
  } as unknown as BerufeApiClient;
}

describe("phone OTP API", () => {
  it("requests a challenge through the generated operation and maps its safe data", async () => {
    const client = apiClientReturning({
      data: {
        data: {
          status: "accepted",
          challenge_token: "browser-challenge-token",
          expires_in: 600,
          resend_available_in: 30,
        },
        request_id: "otp-201",
      },
      error: undefined,
      response: new Response(null),
    });

    await expect(requestPhoneOtp(client, "+5547999991111")).resolves.toEqual({
      challengeToken: "browser-challenge-token",
      expiresIn: 600,
      resendAvailableIn: 30,
    });
    expect(client.POST).toHaveBeenCalledWith("/api/v1/auth/otp/challenges", {
      body: { phone: "+5547999991111" },
    });
  });

  it("preserves contracted safe errors and valid Retry-After timing", async () => {
    const client = apiClientReturning({
      data: undefined,
      error: {
        error: {
          code: "otp_rate_limited",
          message: "Aguarde antes de pedir outro código.",
          request_id: "otp-429",
        },
      },
      response: new Response(null, {
        headers: {
          "Retry-After": "20",
          "X-Request-Id": "otp-429",
        },
      }),
    });

    await expect(
      requestPhoneOtp(client, "+5547999991111"),
    ).rejects.toMatchObject({
      name: "PhoneOtpRequestError",
      code: "otp_rate_limited",
      retryAfter: 20,
      requestId: "otp-429",
    } satisfies Partial<PhoneOtpRequestError>);
  });

  it("ignores unsafe Retry-After values and handles missing success data", async () => {
    for (const retryAfter of [null, "0", "1.5", "9007199254740992"]) {
      const headers = retryAfter ? { "Retry-After": retryAfter } : undefined;
      const client = apiClientReturning({
        data: undefined,
        error: undefined,
        response: new Response(null, { headers }),
      });

      await expect(
        requestPhoneOtp(client, "+5547999991111"),
      ).rejects.toMatchObject({
        code: "unexpected_error",
        retryAfter: undefined,
      });
    }
  });
});
