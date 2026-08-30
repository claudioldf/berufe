import { useDocumentVisibility, useIntervalFn } from "@vueuse/core";
import {
  computed,
  onScopeDispose,
  readonly,
  toValue,
  watch,
  type MaybeRefOrGetter,
} from "vue";
import { useApplicationSession } from "~/composables/useApplicationSession";
import {
  clearProfessionalNotificationState,
  useProfessionalNotificationState,
} from "~/composables/useProfessionalNotificationState";
import {
  getProfessionalNotifications,
  readAllProfessionalNotifications,
  readProfessionalNotification,
} from "~/services/api/professional-notifications";
import { useApiClient } from "~/services/api/client";
import type { ProfessionalNotificationPage } from "~/types";

const pollInterval = 60_000;
const pageLimit = 20;

interface ProfessionalNotificationDependencies {
  load?: (options?: {
    cursor?: string;
    limit?: number;
  }) => Promise<ProfessionalNotificationPage>;
  read?: (id: string) => Promise<{ unreadCount: number }>;
  readAll?: () => Promise<{ unreadCount: number }>;
  visibility?: MaybeRefOrGetter<DocumentVisibilityState>;
  interval?: number;
}

export function useProfessionalNotifications(
  dependencies: ProfessionalNotificationDependencies = {},
) {
  const { account, status } = useApplicationSession();
  const state = useProfessionalNotificationState();
  const client = useApiClient();
  const load =
    dependencies.load ??
    ((options) => getProfessionalNotifications(client, options));
  const read =
    dependencies.read ?? ((id) => readProfessionalNotification(client, id));
  const readAll =
    dependencies.readAll ?? (() => readAllProfessionalNotifications(client));
  const documentVisibility = dependencies.visibility ?? useDocumentVisibility();
  const visibility = computed(() => toValue(documentVisibility));
  const eligibleAccountId = computed(() => {
    if (
      status.value !== "authenticated" ||
      account.value?.role !== "professional" ||
      !account.value.registrationCompleted
    ) {
      return null;
    }
    return account.value.id;
  });

  async function refresh() {
    const accountId = eligibleAccountId.value;
    if (!accountId || state.isRefreshing.value) return;

    const revision = state.revision.value;
    state.isRefreshing.value = true;
    state.loadError.value = null;
    try {
      const page = await load({ limit: pageLimit });
      if (
        eligibleAccountId.value !== accountId ||
        state.revision.value !== revision
      ) {
        return;
      }
      state.notifications.value = page.notifications;
      state.unreadCount.value = page.unreadCount;
      state.nextCursor.value = page.nextCursor;
    } catch {
      if (
        eligibleAccountId.value === accountId &&
        state.revision.value === revision
      ) {
        state.loadError.value =
          "Não foi possível atualizar suas notificações agora.";
      }
    } finally {
      if (
        eligibleAccountId.value === accountId &&
        state.revision.value === revision
      ) {
        state.isRefreshing.value = false;
      }
    }
  }

  async function loadMore() {
    const accountId = eligibleAccountId.value;
    const cursor = state.nextCursor.value;
    if (!accountId || !cursor || state.isLoadingMore.value) return;

    const revision = state.revision.value;
    state.isLoadingMore.value = true;
    state.loadError.value = null;
    try {
      const page = await load({ cursor, limit: pageLimit });
      if (
        eligibleAccountId.value !== accountId ||
        state.revision.value !== revision
      ) {
        return;
      }
      const existingIds = new Set(
        state.notifications.value.map((notification) => notification.id),
      );
      state.notifications.value = [
        ...state.notifications.value,
        ...page.notifications.filter(
          (notification) => !existingIds.has(notification.id),
        ),
      ];
      state.unreadCount.value = page.unreadCount;
      state.nextCursor.value = page.nextCursor;
    } catch {
      if (
        eligibleAccountId.value === accountId &&
        state.revision.value === revision
      ) {
        state.loadError.value =
          "Não foi possível carregar mais notificações agora.";
      }
    } finally {
      if (
        eligibleAccountId.value === accountId &&
        state.revision.value === revision
      ) {
        state.isLoadingMore.value = false;
      }
    }
  }

  async function markRead(id: string) {
    const accountId = eligibleAccountId.value;
    if (!accountId || state.readingIds.value.includes(id)) {
      return false;
    }

    const revision = state.revision.value;
    state.readingIds.value = [...state.readingIds.value, id];
    state.mutationError.value = null;
    try {
      const result = await read(id);
      if (
        eligibleAccountId.value !== accountId ||
        state.revision.value !== revision
      ) {
        return false;
      }
      state.notifications.value = state.notifications.value.filter(
        (notification) => notification.id !== id,
      );
      state.unreadCount.value = result.unreadCount;
      return true;
    } catch {
      if (
        eligibleAccountId.value === accountId &&
        state.revision.value === revision
      ) {
        state.mutationError.value =
          "A notificação não pôde ser marcada como lida.";
      }
      return false;
    } finally {
      if (
        eligibleAccountId.value === accountId &&
        state.revision.value === revision
      ) {
        state.readingIds.value = state.readingIds.value.filter(
          (readingId) => readingId !== id,
        );
      }
    }
  }

  async function markAllRead() {
    const accountId = eligibleAccountId.value;
    if (!accountId || state.isReadingAll.value) return false;

    const revision = state.revision.value;
    state.isReadingAll.value = true;
    state.mutationError.value = null;
    try {
      const result = await readAll();
      if (
        eligibleAccountId.value !== accountId ||
        state.revision.value !== revision
      ) {
        return false;
      }
      state.notifications.value = [];
      state.unreadCount.value = result.unreadCount;
      state.nextCursor.value = null;
      if (result.unreadCount > 0) await refresh();
      return true;
    } catch {
      if (
        eligibleAccountId.value === accountId &&
        state.revision.value === revision
      ) {
        state.mutationError.value =
          "As notificações não puderam ser marcadas como lidas.";
      }
      return false;
    } finally {
      if (
        eligibleAccountId.value === accountId &&
        state.revision.value === revision
      ) {
        state.isReadingAll.value = false;
      }
    }
  }

  const { pause, resume } = useIntervalFn(
    () => void refresh(),
    dependencies.interval ?? pollInterval,
    { immediate: false },
  );

  if (import.meta.client) {
    watch(
      eligibleAccountId,
      (accountId, previousAccountId) => {
        if (!accountId) {
          pause();
          clearProfessionalNotificationState();
          return;
        }
        if (accountId !== previousAccountId) {
          clearProfessionalNotificationState();
        }
        if (visibility.value === "visible") resume();
        void refresh();
      },
      { immediate: true, flush: "sync" },
    );
    watch(visibility, (nextVisibility, previousVisibility) => {
      if (!eligibleAccountId.value || nextVisibility !== "visible") {
        pause();
        return;
      }
      resume();
      if (previousVisibility && previousVisibility !== "visible") {
        void refresh();
      }
    });
  }

  onScopeDispose(pause);

  return {
    notifications: readonly(state.notifications),
    unreadCount: readonly(state.unreadCount),
    nextCursor: readonly(state.nextCursor),
    loadError: readonly(state.loadError),
    mutationError: readonly(state.mutationError),
    isRefreshing: readonly(state.isRefreshing),
    isLoadingMore: readonly(state.isLoadingMore),
    readingIds: readonly(state.readingIds),
    isReadingAll: readonly(state.isReadingAll),
    hasMore: computed(() => Boolean(state.nextCursor.value)),
    isInitialLoading: computed(
      () => state.isRefreshing.value && state.notifications.value.length === 0,
    ),
    refresh,
    loadMore,
    markRead,
    markAllRead,
  };
}
