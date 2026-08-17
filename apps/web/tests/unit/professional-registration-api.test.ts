import type { BerufeApiClient } from "@app/services/api/client";
import { completeProfessionalRegistration } from "@app/services/api/professional-registration";

function apiClientReturning(result: object) {
  return {
    PUT: vi.fn().mockResolvedValue(result),
  } as unknown as BerufeApiClient;
}

describe("professional registration API", () => {
  it("submits the existing fields and maps the draft profile", async () => {
    const client = apiClientReturning({
      data: {
        data: {
          status: "completed",
          profile: {
            id: "23a94f5e-1429-4ec7-bbc4-a6f805d5182d",
            display_name: "Ana Reparos",
            profile_status: "draft",
          },
        },
        request_id: "registration-complete",
      },
      error: undefined,
      response: new Response(null),
    });

    await expect(
      completeProfessionalRegistration(client, {
        displayName: "Ana Reparos",
        accepted: true,
      }),
    ).resolves.toEqual({
      id: "23a94f5e-1429-4ec7-bbc4-a6f805d5182d",
      displayName: "Ana Reparos",
      profileStatus: "draft",
    });
    expect(client.PUT).toHaveBeenCalledWith(
      "/api/v1/professional-registration",
      {
        body: { display_name: "Ana Reparos", accepted: true },
      },
    );
  });

  it("preserves safe validation failures", async () => {
    const client = apiClientReturning({
      data: undefined,
      error: {
        error: {
          code: "validation_failed",
          message: "Revise os campos informados.",
          field_errors: { display_name: ["deve ter entre 3 e 70 caracteres"] },
          request_id: "registration-invalid",
        },
      },
      response: new Response(null, {
        status: 422,
        headers: { "X-Request-Id": "registration-invalid" },
      }),
    });

    await expect(
      completeProfessionalRegistration(client, {
        displayName: "A",
        accepted: true,
      }),
    ).rejects.toMatchObject({
      name: "ApiRequestError",
      code: "validation_failed",
      requestId: "registration-invalid",
      fieldErrors: {
        display_name: ["deve ter entre 3 e 70 caracteres"],
      },
    });
  });

  it("normalizes a malformed success response", async () => {
    const client = apiClientReturning({
      data: undefined,
      error: undefined,
      response: new Response(null),
    });

    await expect(
      completeProfessionalRegistration(client, {
        displayName: "Ana Reparos",
        accepted: true,
      }),
    ).rejects.toMatchObject({
      code: "unexpected_error",
      requestId: "client",
    });
  });
});
