import type { ProfessionalNotification } from "~/types";

export function useProfessionalNotificationState() {
  const notifications = useState<ProfessionalNotification[]>(
    "professional-notifications-items",
    () => [],
  );
  const unreadCount = useState<number>(
    "professional-notifications-unread-count",
    () => 0,
  );
  const nextCursor = useState<string | null>(
    "professional-notifications-next-cursor",
    () => null,
  );
  const loadError = useState<string | null>(
    "professional-notifications-load-error",
    () => null,
  );
  const mutationError = useState<string | null>(
    "professional-notifications-mutation-error",
    () => null,
  );
  const isRefreshing = useState<boolean>(
    "professional-notifications-is-refreshing",
    () => false,
  );
  const isLoadingMore = useState<boolean>(
    "professional-notifications-is-loading-more",
    () => false,
  );
  const readingIds = useState<string[]>(
    "professional-notifications-reading-ids",
    () => [],
  );
  const isReadingAll = useState<boolean>(
    "professional-notifications-is-reading-all",
    () => false,
  );
  const revision = useState<number>(
    "professional-notifications-revision",
    () => 0,
  );

  return {
    notifications,
    unreadCount,
    nextCursor,
    loadError,
    mutationError,
    isRefreshing,
    isLoadingMore,
    readingIds,
    isReadingAll,
    revision,
  };
}

export function clearProfessionalNotificationState() {
  const state = useProfessionalNotificationState();
  state.revision.value += 1;
  state.notifications.value = [];
  state.unreadCount.value = 0;
  state.nextCursor.value = null;
  state.loadError.value = null;
  state.mutationError.value = null;
  state.isRefreshing.value = false;
  state.isLoadingMore.value = false;
  state.readingIds.value = [];
  state.isReadingAll.value = false;
}
