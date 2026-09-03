import { effectScope } from "vue";
import { useAdminImpersonation } from "@app/composables/useAdminImpersonation";
import type { RestoredApplicationSession } from "@app/services/api/application-session";
import type { AdminProfessionalItem } from "@app/types";

vi.mock("@app/services/api/client", () => ({ useApiClient: () => ({}) }));
vi.mock("@app/composables/useApplicationSession", () => ({
  useApplicationSession: () => ({ replaceSession: vi.fn() }),
}));

const professional: AdminProfessionalItem = {
  id: "account-1",
  professionalProfileId: "profile-1",
  publicSlug: "ana-souza",
  displayName: "Ana Souza",
  profileStatus: "published",
  city: "Joinville",
  state: "SC",
  phoneVerified: true,
  phoneLast4: "4002",
  identityVerified: true,
  accountStatus: "active",
  impersonationEligible: true,
  portfolioCount: 1,
  referenceCount: 0,
  customerCount: 0,
  quoteCount: 0,
  registeredAt: "2026-01-10T12:00:00Z",
  lastLoginAt: null,
  loginCount: 1,
  publishedAt: "2026-01-12T12:00:00Z",
};

function restored(role: "professional" | "admin"): RestoredApplicationSession {
  return {
    account: {
      id: role === "professional" ? professional.id : "admin-1",
      role,
      status: "active",
      registered: role === "professional",
      verified: role === "professional",
      registrationCompleted: role === "professional",
      onboardingCompleted: role === "professional",
      registrationDisplayName: role === "professional" ? "Ana Souza" : null,
      professionalProfileId:
        role === "professional" ? professional.professionalProfileId : null,
      relationshipEligible: false,
    },
    session: {
      authenticationMethod: "password",
      impersonating: role === "professional",
      authenticatedAt: "2026-09-02T12:00:00Z",
      idleExpiresAt: "2026-09-02T12:30:00Z",
      absoluteExpiresAt: "2026-09-03T00:00:00Z",
    },
  };
}

function memoryStorage() {
  const values = new Map<string, string>();
  return {
    getItem: vi.fn((key: string) => values.get(key) ?? null),
    setItem: vi.fn((key: string, value: string) => values.set(key, value)),
    removeItem: vi.fn((key: string) => values.delete(key)),
  };
}

describe("administrator impersonation composable", () => {
  it("enters the professional workspace and returns to the remembered directory URL", async () => {
    const start = vi.fn().mockResolvedValue(restored("professional"));
    const stop = vi.fn().mockResolvedValue(restored("admin"));
    const replaceSession = vi.fn();
    const clearProfessionalData = vi.fn();
    const router = { replace: vi.fn().mockResolvedValue(undefined) };
    const storage = memoryStorage();
    const scope = effectScope();
    const workflow = scope.run(() =>
      useAdminImpersonation({
        start,
        stop,
        replaceSession,
        route: { fullPath: "/app/admin/professionals?q=ana&page=2" },
        router,
        storage,
        clearProfessionalData,
      }),
    )!;

    await expect(workflow.start(professional)).resolves.toBe(true);
    expect(start).toHaveBeenCalledWith(professional.id);
    expect(replaceSession).toHaveBeenLastCalledWith(restored("professional"));
    expect(clearProfessionalData).toHaveBeenCalledOnce();
    expect(router.replace).toHaveBeenLastCalledWith("/app/professional");

    await expect(workflow.stop()).resolves.toBe(true);
    expect(replaceSession).toHaveBeenLastCalledWith(restored("admin"));
    expect(router.replace).toHaveBeenLastCalledWith(
      "/app/admin/professionals?q=ana&page=2",
    );
    scope.stop();
  });

  it("ignores ineligible rows and exposes request failures", async () => {
    const start = vi.fn().mockRejectedValue(new Error("Falha ao gerenciar."));
    const scope = effectScope();
    const workflow = scope.run(() =>
      useAdminImpersonation({
        start,
        stop: vi.fn(),
        replaceSession: vi.fn(),
        route: { fullPath: "/app/admin/professionals" },
        router: { replace: vi.fn() },
        storage: memoryStorage(),
        clearProfessionalData: vi.fn(),
      }),
    )!;

    await expect(
      workflow.start({ ...professional, impersonationEligible: false }),
    ).resolves.toBe(false);
    expect(start).not.toHaveBeenCalled();

    await expect(workflow.start(professional)).resolves.toBe(false);
    expect(workflow.error.value).toBe("Falha ao gerenciar.");
    expect(workflow.isChanging.value).toBe(false);
    scope.stop();
  });
});
