import { flushPromises } from "@vue/test-utils";
import { nextTick, ref } from "vue";
import { useApplicationSession } from "@app/composables/useApplicationSession";
import { useProfessionalNotifications } from "@app/composables/useProfessionalNotifications";
import type {
  ProfessionalNotification,
  ProfessionalNotificationPage,
} from "@app/types";

vi.mock("@app/services/api/client", () => ({ useApiClient: () => ({}) }));

const notification = (
  id: string,
  title = "Orçamento aprovado",
): ProfessionalNotification => ({
  id,
  notificationType: "quote_approved",
  status: "unread",
  title,
  description: "Um cliente aprovou um orçamento.",
  route: `/app/professional/quotes/new?quote=${id}`,
  occurredAt: "2026-08-30T12:00:00Z",
  readAt: null,
});

const page = (
  notifications: ProfessionalNotification[],
  unreadCount = notifications.length,
  nextCursor: string | null = null,
): ProfessionalNotificationPage => ({
  notifications,
  unreadCount,
  nextCursor,
});

async function authenticate() {
  const session = useApplicationSession({
    read: vi.fn().mockResolvedValue({
      account: {
        id: "23a94f5e-1429-4ec7-bbc4-a6f805d5182d",
        role: "professional",
        status: "active",
        registered: true,
        verified: true,
        registrationCompleted: true,
        onboardingCompleted: true,
        registrationDisplayName: "Ana Souza",
        professionalProfileId: "fc34e59b-0915-45c1-b0ea-29015578264a",
        relationshipEligible: true,
      },
      session: {
        authenticationMethod: "sms_otp",
        impersonating: false,
        authenticatedAt: "2026-08-30T12:00:00Z",
        idleExpiresAt: "2026-08-30T12:30:00Z",
        absoluteExpiresAt: "2026-08-31T00:00:00Z",
      },
    }),
  });
  await session.restoreSession();
  return session;
}

beforeEach(() => {
  clearNuxtState();
  vi.useRealTimers();
});

describe("professional notifications composable", () => {
  it("loads cursor pages and applies exact server counts after mutations", async () => {
    await authenticate();
    const first = notification("first");
    const second = notification("second", "Nova solicitação");
    const load = vi
      .fn()
      .mockResolvedValueOnce(page([first], 2, "next"))
      .mockResolvedValueOnce(page([second], 2));
    const read = vi.fn().mockResolvedValue({ unreadCount: 1 });
    const readAll = vi.fn().mockResolvedValue({ unreadCount: 0 });
    const subject = useProfessionalNotifications({
      load,
      read,
      readAll,
      visibility: ref("visible"),
    });

    await flushPromises();
    expect(subject.notifications.value).toEqual([first]);
    expect(subject.unreadCount.value).toBe(2);

    await subject.loadMore();
    expect(subject.notifications.value).toEqual([first, second]);
    expect(subject.hasMore.value).toBe(false);

    await expect(subject.markRead(first.id)).resolves.toBe(true);
    expect(subject.notifications.value).toEqual([second]);
    expect(subject.unreadCount.value).toBe(1);

    await expect(subject.markAllRead()).resolves.toBe(true);
    expect(subject.notifications.value).toEqual([]);
    expect(subject.unreadCount.value).toBe(0);
  });

  it("keeps an item when marking it read fails and clears state on logout", async () => {
    const session = await authenticate();
    const item = notification("first");
    const subject = useProfessionalNotifications({
      load: vi.fn().mockResolvedValue(page([item], 1)),
      read: vi.fn().mockRejectedValue(new Error("offline")),
      visibility: ref("visible"),
    });
    await flushPromises();

    await expect(subject.markRead(item.id)).resolves.toBe(false);
    expect(subject.notifications.value).toEqual([item]);
    expect(subject.mutationError.value).toContain("não pôde");

    session.clearSession();
    expect(subject.notifications.value).toEqual([]);
    expect(subject.unreadCount.value).toBe(0);
    expect(subject.mutationError.value).toBeNull();
  });

  it("ignores an in-flight mutation result after the session is cleared", async () => {
    const session = await authenticate();
    const item = notification("first");
    let resolveRead!: (result: { unreadCount: number }) => void;
    const pendingRead = new Promise<{ unreadCount: number }>((resolve) => {
      resolveRead = resolve;
    });
    const subject = useProfessionalNotifications({
      load: vi.fn().mockResolvedValue(page([item], 1)),
      read: vi.fn().mockReturnValue(pendingRead),
      visibility: ref("visible"),
    });
    await flushPromises();

    const mutation = subject.markRead(item.id);
    session.clearSession();
    resolveRead({ unreadCount: 7 });

    await expect(mutation).resolves.toBe(false);
    expect(subject.notifications.value).toEqual([]);
    expect(subject.unreadCount.value).toBe(0);
  });

  it("pauses polling while hidden and refreshes on visibility return", async () => {
    vi.useFakeTimers();
    await authenticate();
    const visibility = ref<DocumentVisibilityState>("visible");
    const load = vi.fn().mockResolvedValue(page([]));
    useProfessionalNotifications({ load, visibility, interval: 1_000 });
    await flushPromises();
    expect(load).toHaveBeenCalledOnce();

    visibility.value = "hidden";
    await nextTick();
    await vi.advanceTimersByTimeAsync(2_000);
    expect(load).toHaveBeenCalledOnce();

    visibility.value = "visible";
    await nextTick();
    await flushPromises();
    expect(load).toHaveBeenCalledTimes(2);
  });
});
