import { createApiClient } from "@app/services/api/client";

afterEach(() => {
  window.localStorage.clear();
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
      requestId: () => "browser-request-123",
    });

    const result = await client.GET("/api/v1/status");
    const request = fetch.mock.calls[0]?.[0];

    expect(result.data?.data.status).toBe("ok");
    expect(request?.credentials).toBe("include");
    expect(request?.headers.get("X-Request-Id")).toBe("browser-request-123");
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

  it("authorizes mutations with the session cookie alone and stores nothing in the browser", async () => {
    const fetch = vi.fn(async () =>
      Promise.resolve(new Response(null, { status: 204 })),
    );
    const client = createApiClient({
      baseUrl: "http://localhost:3001",
      fetch,
    });

    await client.DELETE("/api/v1/session");

    const request = fetch.mock.calls[0]?.[0];
    expect(request?.credentials).toBe("include");
    expect(request?.headers.get("X-Request-Id")).toMatch(/^[0-9a-f-]{36}$/);
    expect(window.localStorage.length).toBe(0);
  });
});
