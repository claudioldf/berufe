import { mockNuxtImport } from "@nuxt/test-utils/runtime";
import authenticatedMiddleware, {
  requiredWorkspaceRole,
  requiresApplicationSession,
} from "~/middleware/authenticated.global";

const mocks = vi.hoisted(() => ({
  restoreSession: vi.fn(),
  navigateTo: vi.fn(),
  account: { value: null as { role: "professional" | "admin" } | null },
}));

vi.mock("~/composables/useApplicationSession", () => ({
  useApplicationSession: () => ({
    account: mocks.account,
    restoreSession: mocks.restoreSession,
  }),
}));

mockNuxtImport("navigateTo", () => mocks.navigateTo);

afterEach(() => {
  vi.unstubAllGlobals();
  vi.clearAllMocks();
  mocks.account.value = null;
});

describe("authenticated route middleware", () => {
  it("identifies only the existing private workspace routes", () => {
    expect(requiresApplicationSession("/app/professional")).toBe(true);
    expect(requiresApplicationSession("/app/professional/quotes/new")).toBe(
      true,
    );
    expect(requiresApplicationSession("/app/admin/reports")).toBe(true);
    expect(requiresApplicationSession("/app/professional/login")).toBe(false);
    expect(requiresApplicationSession("/encontrar")).toBe(false);
    expect(requiredWorkspaceRole("/app/professional/profile")).toBe(
      "professional",
    );
    expect(requiredWorkspaceRole("/app/admin/catalog")).toBe("admin");
    expect(requiredWorkspaceRole("/encontrar")).toBeUndefined();
  });

  it("defers restoration to the browser because the cookie is host-only to the API", async () => {
    vi.stubGlobal("window", undefined);

    await authenticatedMiddleware(
      { path: "/app/professional" } as never,
      {} as never,
    );

    expect(mocks.restoreSession).not.toHaveBeenCalled();
  });

  it("does not restore a session for public routes", async () => {
    await authenticatedMiddleware({ path: "/encontrar" } as never, {} as never);

    expect(mocks.restoreSession).not.toHaveBeenCalled();
  });

  it("keeps authenticated users on the requested workspace route", async () => {
    mocks.restoreSession.mockResolvedValue(true);
    mocks.account.value = { role: "professional" };

    await authenticatedMiddleware(
      { path: "/app/professional/profile" } as never,
      {} as never,
    );

    expect(mocks.navigateTo).not.toHaveBeenCalled();
  });

  it.each([
    ["professional", "/app/admin/reports", "/app/professional"],
    ["admin", "/app/professional/profile", "/app/admin"],
  ] as const)(
    "redirects an authenticated %s away from the other role workspace",
    async (role, requestedPath, expectedPath) => {
      mocks.restoreSession.mockResolvedValue(true);
      mocks.account.value = { role };
      mocks.navigateTo.mockResolvedValue(undefined);

      await authenticatedMiddleware(
        { path: requestedPath } as never,
        {} as never,
      );

      expect(mocks.navigateTo).toHaveBeenCalledWith(expectedPath, {
        replace: true,
      });
    },
  );

  it("redirects anonymous users to the existing professional login", async () => {
    mocks.restoreSession.mockResolvedValue(false);
    mocks.navigateTo.mockResolvedValue(undefined);

    await authenticatedMiddleware({ path: "/app/admin" } as never, {} as never);

    expect(mocks.navigateTo).toHaveBeenCalledWith("/app/professional/login", {
      replace: true,
    });
  });
});
