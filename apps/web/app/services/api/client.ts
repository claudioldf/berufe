import createClient, {
  type Client,
  type ClientOptions,
  type Middleware,
} from "openapi-fetch";
import type { paths } from "./schema";

const requestIdPattern = /^[A-Za-z0-9._-]{1,100}$/;

export type BerufeApiClient = Client<paths>;

interface ApiClientOptions {
  baseUrl: string;
  fetch?: ClientOptions["fetch"];
  requestId?: () => string | undefined;
}

export function createApiClient(options: ApiClientOptions): BerufeApiClient {
  const baseUrl = options.baseUrl.replace(/\/$/, "");
  if (!baseUrl) {
    throw new Error("API base URL is required");
  }

  const client = createClient<paths>({
    baseUrl,
    credentials: "include",
    fetch: options.fetch,
  });
  const requestMiddleware: Middleware = {
    onRequest({ request }) {
      const suppliedRequestId = options.requestId?.();
      const requestId =
        suppliedRequestId && requestIdPattern.test(suppliedRequestId)
          ? suppliedRequestId
          : globalThis.crypto.randomUUID();
      request.headers.set("X-Request-Id", requestId);

      return request;
    },
  };
  client.use(requestMiddleware);

  return client;
}

export function useApiClient(): BerufeApiClient {
  const runtimeConfig = useRuntimeConfig();
  const inboundRequestId = import.meta.server
    ? useRequestHeader("x-request-id")
    : undefined;

  return createApiClient({
    baseUrl: import.meta.server
      ? runtimeConfig.apiInternalBaseUrl
      : runtimeConfig.public.apiBaseUrl,
    requestId: () => inboundRequestId ?? undefined,
  });
}
