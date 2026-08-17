import type { BerufeApiClient } from "./client";
import { ApiRequestError, normalizeApiError } from "./errors";

export interface CreateAdminSessionInput {
  email: string;
  password: string;
}

export async function createAdminSession(
  client: BerufeApiClient,
  input: CreateAdminSessionInput,
): Promise<void> {
  const { error, response } = await client.POST("/api/v1/admin/session", {
    body: input,
  });
  if (!error && response.status === 200) return;

  throw new ApiRequestError(
    normalizeApiError(error, response.headers.get("X-Request-Id") ?? "client"),
  );
}
