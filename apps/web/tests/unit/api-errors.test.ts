import {
  ApiRequestError,
  hasApiErrorCode,
  normalizeApiError,
} from "@app/services/api/errors";

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

  it("recognizes an ApiRequestError code", () => {
    const error = new ApiRequestError({
      code: "not_found",
      message: "Recurso não encontrado.",
      fieldErrors: {},
      requestId: "request-id",
    });

    expect(hasApiErrorCode(error, "not_found")).toBe(true);
    expect(hasApiErrorCode(error, "validation_failed")).toBe(false);
  });

  it("recognizes a structurally preserved code after SSR serialization", () => {
    expect(
      hasApiErrorCode(
        {
          name: "ApiRequestError",
          code: "not_found",
          message: "Recurso não encontrado.",
        },
        "not_found",
      ),
    ).toBe(true);
    expect(hasApiErrorCode(new Error("unavailable"), "not_found")).toBe(false);
  });

  it("recognizes an API error wrapped by the server runtime", () => {
    expect(
      hasApiErrorCode(
        {
          statusCode: 500,
          cause: {
            data: {
              error: { code: "not_found" },
            },
          },
        },
        "not_found",
      ),
    ).toBe(true);
  });
});
