import type { components } from "./schema";

type ContractErrorResponse = components["schemas"]["ErrorResponse"];
type FieldErrors = Record<string, string[]>;

export interface NormalizedApiError {
  code: string;
  message: string;
  fieldErrors: FieldErrors;
  requestId: string;
}

export class ApiRequestError extends Error {
  readonly code: string;
  readonly fieldErrors: FieldErrors;
  readonly requestId: string;

  constructor(error: NormalizedApiError) {
    super(error.message);
    this.name = "ApiRequestError";
    this.code = error.code;
    this.fieldErrors = error.fieldErrors;
    this.requestId = error.requestId;
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function normalizeFieldErrors(value: unknown): FieldErrors {
  if (!isRecord(value)) {
    return {};
  }

  return Object.fromEntries(
    Object.entries(value).flatMap(([field, messages]) => {
      if (!Array.isArray(messages)) {
        return [];
      }

      const safeMessages = messages.filter(
        (message): message is string =>
          typeof message === "string" && message.length > 0,
      );
      return safeMessages.length > 0 ? [[field, safeMessages]] : [];
    }),
  );
}

export function normalizeApiError(
  input: unknown,
  fallbackRequestId = "client",
): NormalizedApiError {
  const response = isRecord(input) ? input : undefined;
  const candidate =
    response && isRecord(response.error) ? response.error : undefined;

  if (
    candidate &&
    typeof candidate.code === "string" &&
    typeof candidate.message === "string" &&
    typeof candidate.request_id === "string"
  ) {
    const contractError = input as ContractErrorResponse;
    return {
      code: contractError.error.code,
      message: contractError.error.message,
      fieldErrors: normalizeFieldErrors(contractError.error.field_errors),
      requestId: contractError.error.request_id,
    };
  }

  return {
    code: "unexpected_error",
    message: "Não foi possível concluir a solicitação.",
    fieldErrors: {},
    requestId: fallbackRequestId,
  };
}
