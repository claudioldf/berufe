import { ApiRequestError, normalizeApiError } from "@app/services/api/errors";

describe("API errors", () => {
  it("normalizes the contracted error envelope and field messages", () => {
    const normalized = normalizeApiError({
      error: {
        code: "validation_failed",
        message: "Revise os campos informados.",
        field_errors: { phone: ["é obrigatório"] },
        request_id: "request-422",
      },
    });

    expect(normalized).toEqual({
      code: "validation_failed",
      message: "Revise os campos informados.",
      fieldErrors: { phone: ["é obrigatório"] },
      requestId: "request-422",
    });
    expect(new ApiRequestError(normalized)).toMatchObject({
      name: "ApiRequestError",
      code: "validation_failed",
      requestId: "request-422",
    });
  });

  it("uses a safe fallback without exposing an unknown payload", () => {
    const normalized = normalizeApiError(
      { exception: "database password is secret" },
      "request-fallback",
    );

    expect(normalized).toEqual({
      code: "unexpected_error",
      message: "Não foi possível concluir a solicitação.",
      fieldErrors: {},
      requestId: "request-fallback",
    });
    expect(JSON.stringify(normalized)).not.toContain("database password");
  });
});
