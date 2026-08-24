import type { Event } from "@bugsnag/js";
import {
  apiBugsnagContext,
  normalizeBugsnagContext,
  notifyBugsnagError,
  removePrivateDiagnostics,
} from "@app/utils/bugsnag";

const bugsnagMocks = vi.hoisted(() => ({
  isStarted: vi.fn(() => true),
  notify: vi.fn(),
}));

vi.mock("@bugsnag/js", () => ({
  default: bugsnagMocks,
}));

describe("Bugsnag diagnostics", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    bugsnagMocks.isStarted.mockReturnValue(true);
  });

  it("removes private diagnostics while retaining a response status", () => {
    const metadata = {
      request: { url: "https://example.test/private?token=secret" },
      user: { email: "private@example.test" },
    };
    const event = {
      breadcrumbs: [{ name: "private" }],
      clearMetadata: vi.fn((section: string) => {
        Reflect.deleteProperty(metadata, section);
      }),
      context: "nuxt:profissionais-slug",
      request: { url: "https://example.test/private" },
      response: { statusCode: 503, headers: { authorization: "secret" } },
      setUser: vi.fn(),
      toJSON: () => ({ metaData: metadata }),
    } as unknown as Event;

    expect(removePrivateDiagnostics(event)).toBe(true);

    expect(metadata).toEqual({});
    expect(event.setUser).toHaveBeenCalledWith();
    expect(event.breadcrumbs).toEqual([]);
    expect(event.request).toEqual({});
    expect(event.response).toEqual({ statusCode: 503, headers: {} });
    expect(event.context).toBe("nuxt:profissionais-slug");
  });

  it("allows only normalized route templates as context", () => {
    expect(apiBugsnagContext("get", "/api/v1/professionals/{id}")).toBe(
      "api:GET:/api/v1/professionals/{id}",
    );
    expect(normalizeBugsnagContext("GET /private?token=a-secret-value")).toBe(
      "nuxt",
    );
  });

  it("reports an error once and applies the normalized context", () => {
    const error = new Error("boom");

    expect(notifyBugsnagError(error, "nuxt:home")).toBe(true);
    expect(notifyBugsnagError(error, "nuxt:home")).toBe(false);
    expect(bugsnagMocks.notify).toHaveBeenCalledOnce();

    const callback = bugsnagMocks.notify.mock.calls[0]?.[1] as (
      event: Event,
    ) => boolean;
    const event = { context: undefined } as Event;
    expect(callback(event)).toBe(true);
    expect(event.context).toBe("nuxt:home");
  });

  it("never lets a reporting failure affect the application", () => {
    bugsnagMocks.notify.mockImplementationOnce(() => {
      throw new Error("transport failed");
    });

    expect(notifyBugsnagError(new Error("boom"), "nuxt")).toBe(false);
  });
});
