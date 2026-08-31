import { effectScope, nextTick } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useModerationQueue } from "@app/composables/useModerationQueue";
import type { ModerationQueue, ModerationQueueItem } from "@app/types";

vi.mock("@app/services/api/client", () => ({
  useApiClient: () => ({}),
}));

const item = (id = "verification-id"): ModerationQueueItem => ({
  id,
  targetType: "verification_request",
  status: "pending_review",
  type: "Verificação",
  title: "Verificação de identidade · Ana Souza",
  subtitle: "Eletricista · Toda Joinville",
  submittedAt: "17 de ago., 09:00",
  age: "há 3h",
  details: "Documento enviado para análise.",
  preview: "Documento privado",
  claimedBirthdate: "1990-04-12",
  verificationFileId: `${id}-file`,
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
    const scope = effectScope();
    const workflow = scope.run(() =>
      useModerationQueue({
        load,
        decide,
      }),
    )!;

    await workflow.load();
    await nextTick();
    expect(workflow.selected.value?.id).toBe("verification-id");
    expect(load).toHaveBeenCalledWith({
      status: "pending_review",
      search: "",
      page: 1,
      perPage: 20,
    });

    workflow.setNote("  Conferida.  ");
    const decided = await workflow.decide("rejected", {
      reason: "  A imagem precisa ser substituída.  ",
    });

    expect(decided?.id).toBe("verification-id");
    expect(decide).toHaveBeenCalledWith(
      expect.objectContaining({ id: "verification-id" }),
      "rejected",
      expect.objectContaining({ status: "pending_review" }),
      {
        reason: "A imagem precisa ser substituída.",
        note: "Conferida.",
        identityMatchConfirmed: undefined,
      },
    );
    expect(workflow.queue.value.items).toEqual([]);
    scope.stop();
  });

  it("debounces identity queue searches", async () => {
    vi.useFakeTimers();
    const load = vi.fn().mockResolvedValue(queue());
    const scope = effectScope();
    const workflow = scope.run(() =>
      useModerationQueue({
        load,
      }),
    )!;

    await workflow.load();
    await nextTick();

    workflow.setSearchQuery("Ana");
    await nextTick();
    expect(load).toHaveBeenCalledTimes(1);
    await vi.advanceTimersByTimeAsync(250);
    expect(load).toHaveBeenLastCalledWith(
      expect.objectContaining({ search: "Ana", page: 1 }),
    );

    scope.stop();
  });

  it("changes selection within identity requests and contains load failures", async () => {
    const second = item("second-verification-id");
    const load = vi.fn().mockResolvedValue(queue([item(), second]));
    const scope = effectScope();
    const workflow = scope.run(() => useModerationQueue({ load }))!;

    await workflow.load();
    workflow.setNote("Nota do primeiro item");
    workflow.select("second-verification-id");
    await nextTick();
    expect(workflow.selected.value?.id).toBe("second-verification-id");
    expect(workflow.note.value).toBe("");

    load.mockRejectedValueOnce(new Error("Fila indisponível."));
    await expect(workflow.load()).rejects.toThrow("Fila indisponível.");
    expect(workflow.loadError.value).toBe("Fila indisponível.");
    scope.stop();
  });

  it("opens the existing document action and revokes its temporary URL after sixty seconds", async () => {
    vi.useFakeTimers();
    const verification: ModerationQueueItem = {
      ...item("verification-id"),
      targetType: "verification_request",
      type: "Verificação",
      verificationFileId: "verification-file-id",
    };
    const revokeObjectUrl = vi.fn();
    const navigate = vi.fn();
    const close = vi.fn();
    const openEvidenceTarget = vi.fn(() => ({ navigate, close }));
    const scope = effectScope();
    const workflow = scope.run(() =>
      useModerationQueue({
        load: vi.fn().mockResolvedValue(queue([verification])),
        loadEvidence: vi
          .fn()
          .mockResolvedValue(new Blob(["identity"], { type: "image/png" })),
        createObjectUrl: () => "blob:identity-evidence",
        revokeObjectUrl,
        openEvidenceTarget,
      }),
    )!;

    await workflow.load();
    await expect(workflow.openEvidence()).resolves.toBe(
      "blob:identity-evidence",
    );
    expect(openEvidenceTarget).toHaveBeenCalledOnce();
    expect(navigate).toHaveBeenCalledWith("blob:identity-evidence");
    expect(close).not.toHaveBeenCalled();

    await vi.advanceTimersByTimeAsync(60_000);
    expect(revokeObjectUrl).toHaveBeenCalledWith("blob:identity-evidence");
    scope.stop();
  });

  it("closes the reserved document tab when private evidence cannot load", async () => {
    const verification: ModerationQueueItem = {
      ...item("verification-id"),
      targetType: "verification_request",
      type: "Verificação",
      verificationFileId: "verification-file-id",
    };
    const close = vi.fn();
    const scope = effectScope();
    const workflow = scope.run(() =>
      useModerationQueue({
        load: vi.fn().mockResolvedValue(queue([verification])),
        loadEvidence: vi
          .fn()
          .mockRejectedValue(new Error("Documento indisponível.")),
        openEvidenceTarget: () => ({ navigate: vi.fn(), close }),
      }),
    )!;

    await workflow.load();
    await expect(workflow.openEvidence()).rejects.toThrow(
      "Documento indisponível.",
    );
    expect(close).toHaveBeenCalledOnce();
    scope.stop();
  });

  it("reports reviewed work whose retained evidence is no longer available", async () => {
    const reviewed = {
      ...item("reviewed-verification-id"),
      status: "approved" as const,
      verificationFileId: null,
    };
    const scope = effectScope();
    const workflow = scope.run(() =>
      useModerationQueue({
        load: vi.fn().mockResolvedValue(queue([reviewed])),
        openEvidenceTarget: vi.fn(),
      }),
    )!;

    await workflow.load();
    await expect(workflow.openEvidence()).rejects.toThrow(
      "Este item não possui evidência disponível.",
    );
    expect(workflow.evidenceError.value).toBe(
      "Este item não possui evidência disponível.",
    );
    scope.stop();
  });
});
