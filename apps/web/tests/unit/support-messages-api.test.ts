import type { BerufeApiClient } from "@app/services/api/client";
import { ApiRequestError } from "@app/services/api/errors";
import { createSupportMessage } from "@app/services/api/support-messages";

const input = {
  name: "  Ana Souza ",
  email: " ana@example.com ",
  phone: "",
  message: " Preciso de ajuda com a conta. ",
  topic: "excluir-conta",
} as const;

describe("support message API", () => {
  it("posts trimmed fields and sends an empty phone as null", async () => {
    const POST = vi.fn().mockResolvedValue({
      data: { data: { received: true }, request_id: "r1" },
      response: new Response(null, { status: 202 }),
    });

    await createSupportMessage({ POST } as unknown as BerufeApiClient, input);

    expect(POST).toHaveBeenCalledWith("/api/v1/public/support-messages", {
      body: {
        support_message: {
          name: "Ana Souza",
          email: "ana@example.com",
          phone: null,
          message: "Preciso de ajuda com a conta.",
          topic: "excluir-conta",
        },
      },
    });
  });

  it("surfaces field errors as an ApiRequestError", async () => {
    const POST = vi.fn().mockResolvedValue({
      error: {
        error: {
          code: "validation_failed",
          message: "Revise os campos da mensagem.",
          request_id: "r2",
          field_errors: { email: ["informe um e-mail válido"] },
        },
      },
      response: new Response(null, {
        status: 422,
        headers: { "X-Request-Id": "r2" },
      }),
    });

    const failure = createSupportMessage(
      { POST } as unknown as BerufeApiClient,
      input,
    );

    await expect(failure).rejects.toBeInstanceOf(ApiRequestError);
    await expect(failure).rejects.toMatchObject({
      fieldErrors: { email: ["informe um e-mail válido"] },
    });
  });
});
