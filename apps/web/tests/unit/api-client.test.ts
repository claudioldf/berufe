import { createApiClient } from "@app/services/api/client";
import { notifyBugsnagError } from "@app/utils/bugsnag";

vi.mock("@app/utils/bugsnag", () => ({
  apiBugsnagContext: (method: string, path: string) =>
    `api:${method.toUpperCase()}:${path}`,
  notifyBugsnagError: vi.fn(),
}));

afterEach(() => {
  window.localStorage.clear();
  vi.clearAllMocks();
});

describe("API client", () => {
  it("includes credentials and a validated request ID on safe reads", async () => {
    const fetch = vi.fn(async (_request: Request) =>
      Promise.resolve(
        new Response(
          JSON.stringify({
            data: { service: "berufe-api", status: "ok" },
            request_id: "browser-request-123",
          }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        ),
      ),
    );
    const client = createApiClient({
      baseUrl: "http://localhost:3001/",
      fetch,
      origin: "http://localhost:3000",
      requestId: () => "browser-request-123",
    });

    const result = await client.GET("/api/v1/status");
    const request = fetch.mock.calls[0]?.[0];

    expect(result.data?.data.status).toBe("ok");
    expect(request?.credentials).toBe("include");
    expect(request?.headers.get("X-Request-Id")).toBe("browser-request-123");
    expect(request?.headers.get("Origin")).toBeNull();
    expect(request?.url).toBe("http://localhost:3001/api/v1/status");
  });

  it("replaces an unsafe request ID before sending it", async () => {
    const fetch = vi.fn(async () =>
      Promise.resolve(
        new Response(
          JSON.stringify({
            data: { service: "berufe-api", status: "ok" },
            request_id: "generated",
          }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        ),
      ),
    );
    const client = createApiClient({
      baseUrl: "http://localhost:3001",
      fetch,
      requestId: () => "unsafe phone +5547999999999",
    });

    await client.GET("/api/v1/status");

    const requestId = fetch.mock.calls[0]?.[0].headers.get("X-Request-Id");
    expect(requestId).toMatch(/^[0-9a-f-]{36}$/);
    expect(requestId).not.toContain("5547");
  });

  it("adds the configured exact origin to SSR mutations and stores nothing in the browser", async () => {
    const fetch = vi.fn(async () =>
      Promise.resolve(new Response(null, { status: 204 })),
    );
    const client = createApiClient({
      baseUrl: "http://localhost:3001",
      fetch,
      origin: "http://localhost:3000",
    });

    await client.DELETE("/api/v1/session");

    const request = fetch.mock.calls[0]?.[0];
    expect(request?.credentials).toBe("include");
    expect(request?.headers.get("X-Request-Id")).toMatch(/^[0-9a-f-]{36}$/);
    expect(request?.headers.get("Origin")).toBe("http://localhost:3000");
    expect(window.localStorage.length).toBe(0);
  });

  it("forwards a server-resolved visitor IP only when explicitly configured", async () => {
    const fetch = vi.fn(async () =>
      Promise.resolve(
        new Response(
          JSON.stringify({
            data: { service: "berufe-api", status: "ok" },
            request_id: "visitor-ip-request",
          }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        ),
      ),
    );
    const client = createApiClient({
      baseUrl: "http://api:3000",
      fetch,
      visitorIp: "2001:4860:4860::8888",
    });

    await client.GET("/api/v1/status");

    expect(fetch.mock.calls[0]?.[0].headers.get("X-Real-IP")).toBe(
      "2001:4860:4860::8888",
    );
  });

  it("refuses to build a server-side client without a configured origin", () => {
    expect(() =>
      createApiClient({
        baseUrl: "http://localhost:3001",
        requireOrigin: true,
      }),
    ).toThrow(/Request origin is required/);
  });

  it("reports server failures without including the concrete request URL", async () => {
    const fetch = vi.fn(async () =>
      Promise.resolve(new Response(null, { status: 503 })),
    );
    const client = createApiClient({
      baseUrl: "http://localhost:3001",
      fetch,
    });

    await client.GET("/api/v1/status");

    expect(notifyBugsnagError).toHaveBeenCalledOnce();
    expect(notifyBugsnagError).toHaveBeenCalledWith(
      expect.objectContaining({
        message: "API request failed with status 503",
      }),
      "api:GET:/api/v1/status",
    );
    expect(
      JSON.stringify(vi.mocked(notifyBugsnagError).mock.calls),
    ).not.toContain("localhost");
  });

  it("does not report expected client errors", async () => {
    const fetch = vi.fn(async () =>
      Promise.resolve(new Response(null, { status: 422 })),
    );
    const client = createApiClient({
      baseUrl: "http://localhost:3001",
      fetch,
    });

    await client.GET("/api/v1/status");

    expect(notifyBugsnagError).not.toHaveBeenCalled();
  });

  it("reports and rethrows network failures without exposing fetch diagnostics", async () => {
    const failure = new TypeError(
      "fetch failed for http://localhost:3001/private?token=secret",
    );
    const fetch = vi.fn(async () => Promise.reject(failure));
    const client = createApiClient({
      baseUrl: "http://localhost:3001",
      fetch,
    });

    await expect(client.GET("/api/v1/status")).rejects.toThrow(
      "API request failed before receiving a response",
    );

    expect(notifyBugsnagError).toHaveBeenCalledWith(
      expect.objectContaining({
        message: "API request failed before receiving a response",
      }),
      "api:GET:/api/v1/status",
    );
    expect(
      JSON.stringify(vi.mocked(notifyBugsnagError).mock.calls),
    ).not.toContain("secret");
  });
});
