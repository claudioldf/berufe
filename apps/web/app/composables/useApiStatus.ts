import { ApiRequestError, normalizeApiError } from "~/services/api/errors";
import { useApiClient } from "~/services/api/client";

export function useApiStatus() {
  const client = useApiClient();

  return useAsyncData("api-foundation-status", async () => {
    const { data, error, response } = await client.GET("/api/v1/status");
    if (error) {
      throw new ApiRequestError(
        normalizeApiError(
          error,
          response.headers.get("X-Request-Id") ?? "client",
        ),
      );
    }

    return data;
  });
}
