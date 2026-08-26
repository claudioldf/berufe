import createClient, {
  type Client,
  type ClientOptions,
  type Middleware,
} from "openapi-fetch";
import { apiBugsnagContext, notifyBugsnagError } from "@app/utils/bugsnag";
import type { paths } from "./schema";

const requestIdPattern = /^[A-Za-z0-9._-]{1,100}$/;

export type BerufeApiClient = Client<paths>;

interface ApiClientOptions {
  baseUrl: string;
  fetch?: ClientOptions["fetch"];
  origin?: string;
  requireOrigin?: boolean;
  requestId?: () => string | undefined;
  visitorIp?: string;
}

export function createApiClient(options: ApiClientOptions): BerufeApiClient {
  const baseUrl = options.baseUrl.replace(/\/$/, "");
  if (!baseUrl) {
    throw new Error("API base URL is required");
  }
  if (options.requireOrigin && !options.origin) {
    throw new Error("Request origin is required.");
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
      if (
        options.origin &&
        !["GET", "HEAD", "OPTIONS"].includes(request.method)
      ) {
        request.headers.set("Origin", options.origin);
      }
      if (options.visitorIp) {
        request.headers.set("X-Real-IP", options.visitorIp);
      }

      return request;
    },
  };
  const errorMiddleware: Middleware = {
    onResponse({ request, response, schemaPath }) {
      if (response.status < 500) return;

      notifyBugsnagError(
        new Error(`API request failed with status ${response.status}`),
        apiBugsnagContext(request.method, schemaPath),
      );
    },
    onError({ request, schemaPath }) {
      const error = new Error("API request failed before receiving a response");
      notifyBugsnagError(error, apiBugsnagContext(request.method, schemaPath));
      return error;
    },
  };
  client.use(requestMiddleware, errorMiddleware);

  return client;
}

export function useApiClient(): BerufeApiClient {
  const runtimeConfig = useRuntimeConfig();
  const configuredSiteUrl = String(runtimeConfig.public.siteUrl ?? "").trim();
  const inboundRequestId = import.meta.server
    ? useRequestHeader("x-request-id")
    : undefined;
  const inboundVisitorIp = import.meta.server
    ? useRequestHeader("x-real-ip")
    : undefined;
  const visitorIp =
    inboundVisitorIp && /^[0-9a-f:.]{2,64}$/i.test(inboundVisitorIp)
      ? inboundVisitorIp
      : undefined;

  return createApiClient({
    baseUrl: import.meta.server
      ? runtimeConfig.apiInternalBaseUrl
      : runtimeConfig.public.apiBaseUrl,
    origin:
      import.meta.server && configuredSiteUrl
        ? new URL(configuredSiteUrl).origin
        : undefined,
    requireOrigin: import.meta.server,
    requestId: () => inboundRequestId ?? undefined,
    visitorIp,
  });
}
