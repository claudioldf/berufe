import { computed, onScopeDispose, readonly, shallowRef, watch } from "vue";
import type {
  ModerationDecision,
  ModerationFilters,
  ModerationQueue,
  ModerationQueueItem,
  ModerationStatusFilter,
  ModerationTypeFilter,
} from "~/types";
import {
  createAdminModerationDecision,
  fetchAdminModeration,
  fetchAdminModerationMedia,
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
  loadMedia?: (item: ModerationQueueItem) => Promise<Blob>;
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
  const typeFilter = shallowRef<ModerationTypeFilter>("all");
  const statusFilter = shallowRef<ModerationStatusFilter>("pending_review");
  const searchQuery = shallowRef("");
  const page = shallowRef(1);
  const note = shallowRef("");
  const isLoading = shallowRef(false);
  const isMutating = shallowRef(false);
  const loadError = shallowRef("");
  const mediaUrl = shallowRef("");
  const mediaLoading = shallowRef(false);
  const mediaError = shallowRef("");
  const evidenceLoading = shallowRef(false);
  const evidenceError = shallowRef("");
  let loadSequence = 0;
  let searchTimer: ReturnType<typeof setTimeout> | undefined;
  let mediaSequence = 0;
  let mediaExpiryTimer: ReturnType<typeof setTimeout> | undefined;
  const evidenceExpiryTimers = new Map<string, ReturnType<typeof setTimeout>>();

  const filters = computed<ModerationFilters>(() => ({
    type: typeFilter.value,
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
  const loadTargetMedia =
    dependencies.loadMedia ??
    ((item) => {
      if (
        item.targetType !== "profile_photo" &&
        item.targetType !== "portfolio_item"
      ) {
        throw new Error("Este item não possui imagem de moderação.");
      }
      return fetchAdminModerationMedia(client, item.targetType, item.id);
    });
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

  function adopt(nextQueue: ModerationQueue) {
    queue.value = nextQueue;
    if (!nextQueue.items.some((item) => item.id === selectedId.value)) {
      selectedId.value = nextQueue.items[0]?.id ?? "";
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

  function releaseMedia() {
    mediaSequence += 1;
    if (mediaExpiryTimer) clearTimeout(mediaExpiryTimer);
    mediaExpiryTimer = undefined;
    if (mediaUrl.value) revokeObjectUrl(mediaUrl.value);
    mediaUrl.value = "";
    mediaLoading.value = false;
    mediaError.value = "";
  }

  function releaseEvidence(url: string) {
    const timer = evidenceExpiryTimers.get(url);
    if (timer) clearTimeout(timer);
    evidenceExpiryTimers.delete(url);
    revokeObjectUrl(url);
  }

  async function openEvidence() {
    const item = selected.value;
    if (!item?.verificationFileId || evidenceLoading.value) return null;

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

  async function loadSelectedMedia(item: ModerationQueueItem) {
    releaseMedia();
    if (!item.hasMedia) return;

    const sequence = ++mediaSequence;
    mediaLoading.value = true;
    try {
      const blob = await loadTargetMedia(item);
      if (sequence !== mediaSequence) return;
      mediaUrl.value = createObjectUrl(blob);
      mediaExpiryTimer = setTimeout(releaseMedia, 60_000);
    } catch (error) {
      if (sequence === mediaSequence) {
        mediaError.value =
          error instanceof Error
            ? error.message
            : "Não foi possível abrir a imagem privada.";
      }
    } finally {
      if (sequence === mediaSequence) mediaLoading.value = false;
    }
  }

  function select(id: string) {
    selectedId.value = id;
  }

  function setTypeFilter(value: ModerationTypeFilter) {
    page.value = 1;
    typeFilter.value = value;
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

  watch([typeFilter, statusFilter, searchQuery, page], (current, previous) => {
    if (searchTimer) clearTimeout(searchTimer);
    if (current[2] !== previous[2]) {
      searchTimer = setTimeout(refreshSafely, 250);
    } else {
      refreshSafely();
    }
  });
  watch(selected, (item) => {
    if (item) void loadSelectedMedia(item);
    else releaseMedia();
  });
  onScopeDispose(() => {
    if (searchTimer) clearTimeout(searchTimer);
    releaseMedia();
    for (const url of [...evidenceExpiryTimers.keys()]) releaseEvidence(url);
  });

  return {
    queue: readonly(queue),
    selectedId: readonly(selectedId),
    selected,
    typeFilter: readonly(typeFilter),
    statusFilter: readonly(statusFilter),
    searchQuery: readonly(searchQuery),
    note: readonly(note),
    isLoading: readonly(isLoading),
    isMutating: readonly(isMutating),
    loadError: readonly(loadError),
    mediaUrl: readonly(mediaUrl),
    mediaLoading: readonly(mediaLoading),
    mediaError: readonly(mediaError),
    evidenceLoading: readonly(evidenceLoading),
    evidenceError: readonly(evidenceError),
    load,
    select,
    setTypeFilter,
    setStatusFilter,
    setSearchQuery,
    setPage,
    setNote,
    decide,
    openEvidence,
    releaseMedia,
  };
}
