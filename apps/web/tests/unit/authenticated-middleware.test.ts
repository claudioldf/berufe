import { mockNuxtImport } from "@nuxt/test-utils/runtime";
import authenticatedMiddleware, {
  requiredWorkspaceRole,
  requiresApplicationSession,
} from "~/middleware/authenticated.global";

const mocks = vi.hoisted(() => ({
  restoreSession: vi.fn(),
  navigateTo: vi.fn(),
  account: {
    value: null as {
      role: "professional" | "admin";
      registrationCompleted: boolean;
      onboardingCompleted: boolean;
    } | null,
  },
  session: {
    value: null as { authenticationMethod: "sms_otp" | "password" } | null,
  },
}));

vi.mock("~/composables/useApplicationSession", () => ({
  useApplicationSession: () => ({
    account: mocks.account,
    session: mocks.session,
    restoreSession: mocks.restoreSession,
  }),
}));

mockNuxtImport("navigateTo", () => mocks.navigateTo);

afterEach(() => {
  vi.unstubAllGlobals();
  vi.resetAllMocks();
  mocks.account.value = null;
  mocks.session.value = null;
});

describe("authenticated route middleware", () => {
  it("identifies only the existing private workspace routes", () => {
    expect(requiresApplicationSession("/app/professional")).toBe(true);
    expect(requiresApplicationSession("/app/professional/quotes/new")).toBe(
      true,
    );
    expect(requiresApplicationSession("/app/admin/reports")).toBe(true);
    expect(requiresApplicationSession("/app/admin/login")).toBe(false);
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
    mocks.account.value = {
      role: "professional",
      registrationCompleted: true,
      onboardingCompleted: false,
    };
    mocks.session.value = { authenticationMethod: "sms_otp" };

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
      mocks.account.value = {
        role,
        registrationCompleted: true,
        onboardingCompleted: role === "professional",
      };
      mocks.session.value = {
        authenticationMethod: role === "admin" ? "password" : "sms_otp",
      };
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

  it("redirects anonymous users to the login dedicated to the requested role", async () => {
    mocks.restoreSession.mockResolvedValue(false);
    mocks.navigateTo.mockResolvedValue(undefined);

    await authenticatedMiddleware({ path: "/app/admin" } as never, {} as never);

    expect(mocks.navigateTo).toHaveBeenCalledWith("/app/admin/login", {
      replace: true,
    });

    await authenticatedMiddleware(
      { path: "/app/professional" } as never,
      {} as never,
    );
    expect(mocks.navigateTo).toHaveBeenLastCalledWith(
      "/app/professional/login",
      { replace: true },
    );
  });

  it("requires a password-authenticated session for the admin workspace", async () => {
    mocks.restoreSession.mockResolvedValue(true);
    mocks.account.value = {
      role: "admin",
      registrationCompleted: false,
      onboardingCompleted: false,
    };
    mocks.session.value = { authenticationMethod: "sms_otp" };
    mocks.navigateTo.mockResolvedValue(undefined);

    await authenticatedMiddleware({ path: "/app/admin" } as never, {} as never);

    expect(mocks.navigateTo).toHaveBeenCalledWith("/app/admin/login", {
      replace: true,
    });
  });

  it("returns an incomplete professional to the existing registration flow", async () => {
    mocks.restoreSession.mockResolvedValue(true);
    mocks.account.value = {
      role: "professional",
      registrationCompleted: false,
      onboardingCompleted: false,
    };
    mocks.navigateTo.mockResolvedValue(undefined);

    await authenticatedMiddleware(
      { path: "/app/professional" } as never,
      {} as never,
    );

    expect(mocks.navigateTo).toHaveBeenCalledWith("/app/professional/login", {
      replace: true,
    });
  });

  it.each([
    [false, "/app/professional/onboarding"],
    [true, "/app/professional"],
  ] as const)(
    "redirects a registered professional with onboarding %s away from login",
    async (onboardingCompleted, expectedPath) => {
      mocks.restoreSession.mockResolvedValue(true);
      mocks.account.value = {
        role: "professional",
        registrationCompleted: true,
        onboardingCompleted,
      };

      await authenticatedMiddleware(
        { path: "/app/professional/login" } as never,
        {} as never,
      );

      expect(mocks.navigateTo).toHaveBeenCalledWith(expectedPath, {
        replace: true,
      });
    },
  );

  it("redirects completed onboarding away from the onboarding route", async () => {
    mocks.restoreSession.mockResolvedValue(true);
    mocks.account.value = {
      role: "professional",
      registrationCompleted: true,
      onboardingCompleted: true,
    };
    mocks.session.value = { authenticationMethod: "sms_otp" };

    await authenticatedMiddleware(
      { path: "/app/professional/onboarding" } as never,
      {} as never,
    );

    expect(mocks.navigateTo).toHaveBeenCalledWith("/app/professional", {
      replace: true,
    });
  });

  it("keeps the completed onboarding success state on same-route navigation", async () => {
    mocks.restoreSession.mockResolvedValue(true);
    mocks.account.value = {
      role: "professional",
      registrationCompleted: true,
      onboardingCompleted: true,
    };
    mocks.session.value = { authenticationMethod: "sms_otp" };

    await authenticatedMiddleware(
      { path: "/app/professional/onboarding" } as never,
      { path: "/app/professional/onboarding" } as never,
    );

    expect(mocks.navigateTo).not.toHaveBeenCalled();
  });

  it("waits for pending restoration before resolving the login route", async () => {
    let resolveRestoration: ((authenticated: boolean) => void) | undefined;
    mocks.restoreSession.mockImplementation(
      () =>
        new Promise<boolean>((resolve) => {
          resolveRestoration = resolve;
        }),
    );

    const navigation = authenticatedMiddleware(
      { path: "/app/professional/login" } as never,
      {} as never,
    );
    expect(mocks.navigateTo).not.toHaveBeenCalled();

    mocks.account.value = {
      role: "professional",
      registrationCompleted: true,
      onboardingCompleted: true,
    };
    resolveRestoration?.(true);
    await navigation;

    expect(mocks.navigateTo).toHaveBeenCalledWith("/app/professional", {
      replace: true,
    });
  });

  it("keeps the login route available when restoration fails", async () => {
    mocks.restoreSession.mockRejectedValue(new Error("session unavailable"));

    await expect(
      authenticatedMiddleware(
        { path: "/app/professional/login" } as never,
        {} as never,
      ),
    ).resolves.toBeUndefined();
    expect(mocks.navigateTo).not.toHaveBeenCalled();
  });
});
