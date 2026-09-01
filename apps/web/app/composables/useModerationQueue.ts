import { computed, onScopeDispose, readonly, shallowRef, watch } from "vue";
import type {
  ModerationDecision,
  ModerationFilters,
  ModerationQueue,
  ModerationQueueItem,
  ModerationStatusFilter,
} from "~/types";
import {
  createAdminModerationDecision,
  fetchAdminModeration,
  fetchAdminVerificationFile,
} from "~/services/api/admin-moderation";
import { useApiClient } from "~/services/api/client";

const emptyQueue = (): ModerationQueue => ({
  items: [],
  meta: { page: 1, perPage: 20, totalCount: 0, totalPages: 0 },
  summary: {
    pendingCount: 0,
    reviewedTodayCount: 0,
    oldestPendingAt: null,
    oldestPendingAge: "—",
  },
});

interface ModerationQueueDependencies {
  load?: (filters: ModerationFilters) => Promise<ModerationQueue>;
  decide?: (
    item: ModerationQueueItem,
    action: ModerationDecision,
    filters: ModerationFilters,
    attributes: {
      reason?: string;
      note?: string;
      identityMatchConfirmed?: boolean;
    },
  ) => Promise<ModerationQueue>;
  loadEvidence?: (item: ModerationQueueItem) => Promise<Blob>;
  createObjectUrl?: (blob: Blob) => string;
  revokeObjectUrl?: (url: string) => void;
  openEvidenceTarget?: () => {
    navigate: (url: string) => void;
    close: () => void;
  } | null;
}

export function useModerationQueue(
  dependencies: ModerationQueueDependencies = {},
) {
  const client = useApiClient();
  const queue = shallowRef<ModerationQueue>(emptyQueue());
  const selectedId = shallowRef("");
  const statusFilter = shallowRef<ModerationStatusFilter>("pending_review");
  const searchQuery = shallowRef("");
  const page = shallowRef(1);
  const note = shallowRef("");
  const isLoading = shallowRef(false);
  const isMutating = shallowRef(false);
  const loadError = shallowRef("");
  const evidenceLoading = shallowRef(false);
  const evidenceError = shallowRef("");
  let loadSequence = 0;
  let searchTimer: ReturnType<typeof setTimeout> | undefined;
  const evidenceExpiryTimers = new Map<string, ReturnType<typeof setTimeout>>();

  const filters = computed<ModerationFilters>(() => ({
    status: statusFilter.value,
    search: searchQuery.value.trim(),
    page: page.value,
    perPage: queue.value.meta.perPage,
  }));
  const selected = computed(() =>
    queue.value.items.find((item) => item.id === selectedId.value),
  );
  const loadQueue =
    dependencies.load ?? ((input) => fetchAdminModeration(client, input));
  const decideTarget =
    dependencies.decide ??
    ((item, action, input, attributes) =>
      createAdminModerationDecision(
        client,
        item.targetType,
        item.id,
        action,
        input,
        attributes,
      ));
  const loadTargetEvidence =
    dependencies.loadEvidence ??
    ((item) => {
      if (!item.verificationFileId) {
        throw new Error("Este item não possui evidência disponível.");
      }
      return fetchAdminVerificationFile(client, item.verificationFileId);
    });
  const createObjectUrl =
    dependencies.createObjectUrl ?? ((blob: Blob) => URL.createObjectURL(blob));
  const revokeObjectUrl =
    dependencies.revokeObjectUrl ?? ((url: string) => URL.revokeObjectURL(url));
  const openEvidenceTarget =
    dependencies.openEvidenceTarget ??
    (() => {
      const popup = window.open("about:blank", "_blank");
      if (!popup) return null;

      popup.opener = null;
      return {
        navigate: (url: string) => popup.location.replace(url),
        close: () => popup.close(),
      };
    });

  function setSelectedId(id: string) {
    if (selectedId.value === id) return;

    selectedId.value = id;
    note.value = "";
  }

  function adopt(nextQueue: ModerationQueue) {
    queue.value = nextQueue;
    if (!nextQueue.items.some((item) => item.id === selectedId.value)) {
      setSelectedId(nextQueue.items[0]?.id ?? "");
    }
  }

  async function load() {
    const sequence = ++loadSequence;
    isLoading.value = true;
    loadError.value = "";
    try {
      const result = await loadQueue(filters.value);
      if (sequence === loadSequence) adopt(result);
    } catch (error) {
      if (sequence === loadSequence) {
        loadError.value =
          error instanceof Error
            ? error.message
            : "Não foi possível carregar a fila de moderação.";
      }
      throw error;
    } finally {
      if (sequence === loadSequence) isLoading.value = false;
    }
  }

  async function decide(
    action: ModerationDecision,
    attributes: { reason?: string; identityMatchConfirmed?: boolean } = {},
  ) {
    const item = selected.value;
    if (!item || isMutating.value) return null;

    isMutating.value = true;
    try {
      const result = await decideTarget(item, action, filters.value, {
        reason: attributes.reason?.trim(),
        note: note.value.trim(),
        identityMatchConfirmed: attributes.identityMatchConfirmed,
      });
      adopt(result);
      note.value = "";
      if (result.items.length === 0 && page.value > 1) {
        page.value -= 1;
        await load();
      }
      return item;
    } finally {
      isMutating.value = false;
    }
  }

  function releaseEvidence(url: string) {
    const timer = evidenceExpiryTimers.get(url);
    if (timer) clearTimeout(timer);
    evidenceExpiryTimers.delete(url);
    revokeObjectUrl(url);
  }

  async function openEvidence() {
    const item = selected.value;
    if (!item || evidenceLoading.value) return null;
    if (!item.verificationFileId) {
      evidenceError.value = "Este item não possui evidência disponível.";
      throw new Error(evidenceError.value);
    }

    evidenceLoading.value = true;
    evidenceError.value = "";
    const target = openEvidenceTarget();
    if (!target) {
      evidenceLoading.value = false;
      evidenceError.value = "Não foi possível abrir a evidência privada.";
      throw new Error(evidenceError.value);
    }

    let url = "";
    try {
      const blob = await loadTargetEvidence(item);
      url = createObjectUrl(blob);
      evidenceExpiryTimers.set(
        url,
        setTimeout(() => releaseEvidence(url), 60_000),
      );
      target.navigate(url);
      return url;
    } catch (error) {
      if (url) releaseEvidence(url);
      target.close();
      evidenceError.value =
        error instanceof Error
          ? error.message
          : "Não foi possível abrir a evidência privada.";
      throw error;
    } finally {
      evidenceLoading.value = false;
    }
  }

  function select(id: string) {
    setSelectedId(id);
  }

  function setStatusFilter(value: ModerationStatusFilter) {
    page.value = 1;
    statusFilter.value = value;
  }

  function setSearchQuery(value: string) {
    page.value = 1;
    searchQuery.value = value.slice(0, 100);
  }

  function setPage(value: number) {
    const lastPage = Math.max(1, queue.value.meta.totalPages);
    page.value = Math.min(Math.max(1, value), lastPage);
  }

  function setNote(value: string) {
    note.value = value.slice(0, 500);
  }

  function refreshSafely() {
    void load().catch(() => undefined);
  }

  watch([statusFilter, searchQuery, page], (current, previous) => {
    if (searchTimer) clearTimeout(searchTimer);
    if (current[1] !== previous[1]) {
      searchTimer = setTimeout(refreshSafely, 250);
    } else {
      refreshSafely();
    }
  });
  onScopeDispose(() => {
    if (searchTimer) clearTimeout(searchTimer);
    for (const url of [...evidenceExpiryTimers.keys()]) releaseEvidence(url);
  });

  return {
    queue: readonly(queue),
    selectedId: readonly(selectedId),
    selected,
    statusFilter: readonly(statusFilter),
    searchQuery: readonly(searchQuery),
    note: readonly(note),
    isLoading: readonly(isLoading),
    isMutating: readonly(isMutating),
    loadError: readonly(loadError),
    evidenceLoading: readonly(evidenceLoading),
    evidenceError: readonly(evidenceError),
    load,
    select,
    setStatusFilter,
    setSearchQuery,
    setPage,
    setNote,
    decide,
    openEvidence,
  };
}
