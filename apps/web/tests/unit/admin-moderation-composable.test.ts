import { effectScope, nextTick } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useModerationQueue } from "@app/composables/useModerationQueue";
import type { ModerationQueue, ModerationQueueItem } from "@app/types";

vi.mock("@app/services/api/client", () => ({
  useApiClient: () => ({}),
}));

const item = (id = "photo-id"): ModerationQueueItem => ({
  id,
  targetType: "profile_photo",
  status: "pending_review",
  type: "Foto",
  title: "Foto de perfil · Ana Souza",
  subtitle: "Eletricista · Toda Joinville",
  submittedAt: "17 de ago., 09:00",
  age: "há 3h",
  details: "Foto enviada para análise.",
  preview: "Imagem privada",
  hasMedia: true,
  verificationFileId: null,
});

const queue = (items = [item()]): ModerationQueue => ({
  items,
  meta: {
    page: 1,
    perPage: 20,
    totalCount: items.length,
    totalPages: items.length ? 1 : 0,
  },
  summary: {
    pendingCount: items.length,
    reviewedTodayCount: 0,
    oldestPendingAt: items.length ? "2026-08-17T12:00:00Z" : null,
    oldestPendingAge: items.length ? "há 3h" : "—",
  },
});

afterEach(() => {
  vi.useRealTimers();
});

describe("administrator moderation composable", () => {
  it("loads server-owned filters, selects queue work, and commits a decision", async () => {
    const load = vi.fn().mockResolvedValue(queue());
    const decide = vi.fn().mockResolvedValue(queue([]));
    const loadMedia = vi
      .fn()
      .mockResolvedValue(new Blob(["image"], { type: "image/jpeg" }));
    const scope = effectScope();
    const workflow = scope.run(() =>
      useModerationQueue({
        load,
        decide,
        loadMedia,
        createObjectUrl: () => "blob:moderation-preview",
        revokeObjectUrl: vi.fn(),
      }),
    )!;

    await workflow.load();
    await nextTick();
    expect(workflow.selected.value?.id).toBe("photo-id");
    expect(load).toHaveBeenCalledWith({
      type: "all",
      status: "pending_review",
      search: "",
      page: 1,
      perPage: 20,
    });

    workflow.setNote("  Conferida.  ");
    const decided = await workflow.decide("rejected", {
      reason: "  A imagem precisa ser substituída.  ",
    });

    expect(decided?.id).toBe("photo-id");
    expect(decide).toHaveBeenCalledWith(
      expect.objectContaining({ id: "photo-id" }),
      "rejected",
      expect.objectContaining({ status: "pending_review" }),
      {
        reason: "A imagem precisa ser substituída.",
        note: "Conferida.",
      },
    );
    expect(workflow.queue.value.items).toEqual([]);
    scope.stop();
  });

  it("debounces search filters and releases Blob URLs after sixty seconds", async () => {
    vi.useFakeTimers();
    const load = vi.fn().mockResolvedValue(queue());
    const revokeObjectUrl = vi.fn();
    const scope = effectScope();
    const workflow = scope.run(() =>
      useModerationQueue({
        load,
        loadMedia: vi
          .fn()
          .mockResolvedValue(new Blob(["image"], { type: "image/jpeg" })),
        createObjectUrl: () => "blob:moderation-preview",
        revokeObjectUrl,
      }),
    )!;

    await workflow.load();
    await nextTick();
    await vi.runAllTicks();
    expect(workflow.mediaUrl.value).toBe("blob:moderation-preview");

    workflow.setSearchQuery("Ana");
    await nextTick();
    expect(load).toHaveBeenCalledTimes(1);
    await vi.advanceTimersByTimeAsync(250);
    expect(load).toHaveBeenLastCalledWith(
      expect.objectContaining({ search: "Ana", page: 1 }),
    );

    await vi.advanceTimersByTimeAsync(60_000);
    expect(revokeObjectUrl).toHaveBeenCalledWith("blob:moderation-preview");
    expect(workflow.mediaUrl.value).toBe("");
    scope.stop();
  });

  it("revokes the previous preview when selection changes and contains failures", async () => {
    const second = { ...item("portfolio-id"), targetType: "portfolio_item" };
    const load = vi.fn().mockResolvedValue(queue([item(), second]));
    const revokeObjectUrl = vi.fn();
    const loadMedia = vi
      .fn()
      .mockResolvedValueOnce(new Blob(["one"]))
      .mockRejectedValueOnce(new Error("Imagem indisponível."));
    const scope = effectScope();
    const workflow = scope.run(() =>
      useModerationQueue({
        load,
        loadMedia,
        createObjectUrl: () => "blob:first",
        revokeObjectUrl,
      }),
    )!;

    await workflow.load();
    await nextTick();
    workflow.select("portfolio-id");
    await nextTick();
    await Promise.resolve();

    expect(revokeObjectUrl).toHaveBeenCalledWith("blob:first");
    expect(workflow.mediaError.value).toBe("Imagem indisponível.");
    scope.stop();
  });
});
