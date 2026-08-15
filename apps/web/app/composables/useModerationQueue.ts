import { computed, ref, shallowRef, watch } from "vue";
import type { ModerationQueueItem } from "~/types";
import { normalizeSearchText } from "~/utils/text";

export function useModerationQueue(initialQueue: ModerationQueueItem[]) {
  const queue = ref<ModerationQueueItem[]>([...initialQueue]);
  const selectedId = shallowRef(queue.value[0]?.id ?? "");
  const typeFilter = shallowRef("Todos");
  const searchQuery = shallowRef("");
  const rejectionOpen = shallowRef(false);
  const rejectionReason = shallowRef("");

  const types = computed(() => [
    "Todos",
    ...new Set(queue.value.map((item) => item.type)),
  ]);
  const filteredQueue = computed(() => {
    const search = normalizeSearchText(searchQuery.value);
    return queue.value.filter((item) => {
      const matchesType =
        typeFilter.value === "Todos" || item.type === typeFilter.value;
      const matchesSearch =
        !search ||
        normalizeSearchText(
          `${item.title} ${item.subtitle} ${item.type} ${item.id}`,
        ).includes(search);
      return matchesType && matchesSearch;
    });
  });
  const selected = computed(
    () =>
      filteredQueue.value.find((item) => item.id === selectedId.value) ??
      filteredQueue.value[0],
  );

  watch(filteredQueue, (items) => {
    if (!items.some((item) => item.id === selectedId.value)) {
      selectedId.value = items[0]?.id ?? "";
    }
  });

  function select(id: string) {
    selectedId.value = id;
  }

  function decide() {
    const item = selected.value;
    if (!item) return null;
    queue.value = queue.value.filter((queueItem) => queueItem.id !== item.id);
    rejectionOpen.value = false;
    rejectionReason.value = "";
    return item;
  }

  return {
    queue,
    selectedId,
    typeFilter,
    searchQuery,
    rejectionOpen,
    rejectionReason,
    types,
    filteredQueue,
    selected,
    select,
    decide,
  };
}
