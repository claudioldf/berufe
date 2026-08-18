import { clearNuxtState } from "#app";
import type { RestoredApplicationSession } from "~/services/api/application-session";
import { useApplicationSession } from "~/composables/useApplicationSession";
import { useAppRole } from "~/composables/useAppRole";

const restoredSession: RestoredApplicationSession = {
  account: {
    id: "23a94f5e-1429-4ec7-bbc4-a6f805d5182d",
    role: "professional",
    status: "active",
    registrationCompleted: true,
    professionalProfileId: "fc34e59b-0915-45c1-b0ea-29015578264a",
    relationshipEligible: true,
  },
  session: {
    authenticationMethod: "sms_otp",
    authenticatedAt: "2026-08-15T12:00:00.000Z",
    idleExpiresAt: "2026-08-22T12:00:00.000Z",
    absoluteExpiresAt: "2026-09-14T12:00:00.000Z",
  },
};

beforeEach(() => {
  clearNuxtState();
});

describe("application-session state", () => {
  it("deduplicates concurrent restorations and caches the authenticated result", async () => {
    const { role } = useAppRole();
    let resolveRead:
      ((value: RestoredApplicationSession | null) => void) | undefined;
    const read = vi.fn(
      () =>
        new Promise<RestoredApplicationSession | null>((resolve) => {
          resolveRead = resolve;
        }),
    );
    const workflow = useApplicationSession({ read });

    const firstRestore = workflow.restoreSession();
    const secondRestore = workflow.restoreSession();
    expect(workflow.status.value).toBe("restoring");
    expect(read).toHaveBeenCalledOnce();

    resolveRead?.(restoredSession);
    await expect(firstRestore).resolves.toBe(true);
    await expect(secondRestore).resolves.toBe(true);
    expect(workflow.status.value).toBe("authenticated");
    expect(workflow.account.value).toEqual(restoredSession.account);
    expect(workflow.session.value).toEqual(restoredSession.session);
    expect(role.value).toBe("professional");

    await expect(workflow.restoreSession()).resolves.toBe(true);
    expect(read).toHaveBeenCalledOnce();
  });

  it("caches an anonymous result and clears prior in-memory authorization", async () => {
    const { role, setRole } = useAppRole();
    setRole("admin");
    const read = vi.fn().mockResolvedValue(null);
    const workflow = useApplicationSession({ read });

    await expect(workflow.restoreSession()).resolves.toBe(false);
    await expect(workflow.restoreSession()).resolves.toBe(false);

    expect(read).toHaveBeenCalledOnce();
    expect(workflow.status.value).toBe("anonymous");
    expect(workflow.account.value).toBeNull();
    expect(workflow.session.value).toBeNull();
    expect(role.value).toBe("visitor");
  });

  it("forces a fresh read after authentication changes", async () => {
    const read = vi
      .fn()
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(restoredSession);
    const workflow = useApplicationSession({ read });

    await expect(workflow.restoreSession()).resolves.toBe(false);
    await expect(workflow.refreshSession()).resolves.toBe(true);

    expect(read).toHaveBeenCalledTimes(2);
    expect(workflow.account.value).toEqual(restoredSession.account);
  });

  it("waits for an active restoration before refreshing it", async () => {
    let resolveRead:
      ((value: RestoredApplicationSession | null) => void) | undefined;
    const read = vi
      .fn()
      .mockImplementationOnce(
        () =>
          new Promise<RestoredApplicationSession | null>((resolve) => {
            resolveRead = resolve;
          }),
      )
      .mockResolvedValueOnce(restoredSession);
    const workflow = useApplicationSession({ read });

    const restoration = workflow.restoreSession();
    const refresh = workflow.refreshSession();
    resolveRead?.(null);

    await expect(restoration).resolves.toBe(false);
    await expect(refresh).resolves.toBe(true);
    expect(read).toHaveBeenCalledTimes(2);
  });

  it("refreshes after an overlapping restoration fails", async () => {
    let rejectRead: ((reason: Error) => void) | undefined;
    const read = vi
      .fn()
      .mockImplementationOnce(
        () =>
          new Promise<RestoredApplicationSession | null>((_resolve, reject) => {
            rejectRead = reject;
          }),
      )
      .mockResolvedValueOnce(restoredSession);
    const workflow = useApplicationSession({ read });

    const restoration = workflow.restoreSession();
    const refresh = workflow.refreshSession();
    rejectRead?.(new Error("stale read failed"));

    await expect(restoration).rejects.toThrow("stale read failed");
    await expect(refresh).resolves.toBe(true);
    expect(read).toHaveBeenCalledTimes(2);
  });

  it("allows a failed restoration to be retried", async () => {
    const read = vi
      .fn()
      .mockRejectedValueOnce(new Error("temporary API failure"))
      .mockResolvedValueOnce(restoredSession);
    const workflow = useApplicationSession({ read });

    await expect(workflow.restoreSession()).rejects.toThrow(
      "temporary API failure",
    );
    expect(workflow.status.value).toBe("unknown");

    await expect(workflow.restoreSession()).resolves.toBe(true);
    expect(read).toHaveBeenCalledTimes(2);
  });

  it("ends one session once, then clears account and session state", async () => {
    const { role } = useAppRole();
    let resolveEnd: (() => void) | undefined;
    const end = vi.fn(
      () =>
        new Promise<void>((resolve) => {
          resolveEnd = resolve;
        }),
    );
    const workflow = useApplicationSession({
      read: vi.fn().mockResolvedValue(restoredSession),
      end,
    });
    await workflow.restoreSession();

    const firstLogout = workflow.logout();
    await workflow.logout();
    expect(end).toHaveBeenCalledOnce();
    expect(workflow.isEnding.value).toBe(true);

    resolveEnd?.();
    await firstLogout;
    expect(workflow.isEnding.value).toBe(false);
    expect(workflow.status.value).toBe("anonymous");
    expect(workflow.account.value).toBeNull();
    expect(workflow.session.value).toBeNull();
    expect(role.value).toBe("visitor");
  });

  it("retains a restored session when logout fails and resets its pending state", async () => {
    const workflow = useApplicationSession({
      read: vi.fn().mockResolvedValue(restoredSession),
      end: vi.fn().mockRejectedValue(new Error("logout failed")),
    });
    await workflow.restoreSession();

    await expect(workflow.logout()).rejects.toThrow("logout failed");

    expect(workflow.isEnding.value).toBe(false);
    expect(workflow.status.value).toBe("authenticated");
    expect(workflow.account.value).toEqual(restoredSession.account);
  });

  it("uses the production API dependencies by default", async () => {
    const workflow = useApplicationSession();

    await expect(workflow.restoreSession()).rejects.toThrow();
    await expect(workflow.logout()).rejects.toThrow();
    expect(workflow.isEnding.value).toBe(false);
  });
});
