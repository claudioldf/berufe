import type { BerufeApiClient } from "@app/services/api/client";
import {
  endCurrentApplicationSession,
  getCurrentApplicationSession,
} from "@app/services/api/application-session";

function apiClientReturning(result: object) {
  return {
    GET: vi.fn().mockResolvedValue(result),
    DELETE: vi.fn().mockResolvedValue(result),
  } as unknown as BerufeApiClient;
}

describe("application-session API", () => {
  it("maps the contracted account and session summary", async () => {
    const client = apiClientReturning({
      data: {
        data: {
          account: {
            id: "23a94f5e-1429-4ec7-bbc4-a6f805d5182d",
            role: "professional",
            status: "active",
            registration_completed: true,
            professional_profile_id: "fc34e59b-0915-45c1-b0ea-29015578264a",
            relationship_eligible: true,
          },
          session: {
            authentication_method: "sms_otp",
            authenticated_at: "2026-08-15T12:00:00.000Z",
            idle_expires_at: "2026-08-22T12:00:00.000Z",
            absolute_expires_at: "2026-09-14T12:00:00.000Z",
          },
        },
        request_id: "session-current",
      },
      error: undefined,
      response: new Response(null, { status: 200 }),
    });

    await expect(getCurrentApplicationSession(client)).resolves.toEqual({
      account: {
        id: "23a94f5e-1429-4ec7-bbc4-a6f805d5182d",
        role: "professional",
        status: "active",
        registrationCompleted: true,
        professionalProfileId: "fc34e59b-0915-45c1-b0ea-29015578264a",
        relationshipEligible: true,
      },
      session: {
        authenticationMethod: "sms_otp",
        authenticatedAt: "2026-08-15T12:00:00.000Z",
        idleExpiresAt: "2026-08-22T12:00:00.000Z",
        absoluteExpiresAt: "2026-09-14T12:00:00.000Z",
      },
    });
    expect(client.GET).toHaveBeenCalledWith("/api/v1/session");
  });

  it("treats a contracted unauthorized result as an absent session", async () => {
    const client = apiClientReturning({
      data: undefined,
      error: {
        error: {
          code: "authentication_required",
          message: "Entre novamente para continuar.",
          request_id: "session-401",
        },
      },
      response: new Response(null, { status: 401 }),
    });

    await expect(getCurrentApplicationSession(client)).resolves.toBeNull();
  });

  it("normalizes unavailable and malformed current-session responses", async () => {
    const unavailable = apiClientReturning({
      data: undefined,
      error: {
        error: {
          code: "session_unavailable",
          message: "Não foi possível consultar sua sessão agora.",
          request_id: "session-503",
        },
      },
      response: new Response(null, {
        status: 503,
        headers: { "X-Request-Id": "session-503" },
      }),
    });
    await expect(
      getCurrentApplicationSession(unavailable),
    ).rejects.toMatchObject({
      name: "ApiRequestError",
      code: "session_unavailable",
      requestId: "session-503",
    });

    const malformed = apiClientReturning({
      data: undefined,
      error: undefined,
      response: new Response(null, { status: 200 }),
    });
    await expect(getCurrentApplicationSession(malformed)).rejects.toMatchObject(
      {
        code: "unexpected_error",
        requestId: "client",
      },
    );
  });

  it("ends active or already-absent sessions without returning cookie material", async () => {
    for (const status of [204, 401]) {
      const client = apiClientReturning({
        data: undefined,
        error: status === 401 ? { error: {} } : undefined,
        response: new Response(null, { status }),
      });

      await expect(
        endCurrentApplicationSession(client),
      ).resolves.toBeUndefined();
      expect(client.DELETE).toHaveBeenCalledWith("/api/v1/session");
    }
  });

  it("normalizes logout failures", async () => {
    const client = apiClientReturning({
      data: undefined,
      error: {
        error: {
          code: "session_unavailable",
          message: "Não foi possível consultar sua sessão agora.",
          request_id: "logout-503",
        },
      },
      response: new Response(null, {
        status: 503,
        headers: { "X-Request-Id": "logout-503" },
      }),
    });

    await expect(endCurrentApplicationSession(client)).rejects.toMatchObject({
      name: "ApiRequestError",
      code: "session_unavailable",
      requestId: "logout-503",
    });

    const malformed = apiClientReturning({
      data: undefined,
      error: undefined,
      response: new Response(null, { status: 503 }),
    });
    await expect(endCurrentApplicationSession(malformed)).rejects.toMatchObject(
      {
        code: "unexpected_error",
        requestId: "client",
      },
    );
  });
});
