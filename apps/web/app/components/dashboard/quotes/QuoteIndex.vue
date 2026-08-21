<script setup lang="ts">
import { computed, onScopeDispose, shallowRef } from "vue";
import type {
  Quote,
  QuoteListFilters,
  QuotePage,
  QuoteSortDirection,
  QuoteSortKey,
} from "~/types";
import QuoteFilters from "./QuoteFilters.vue";
import QuotePagination from "./QuotePagination.vue";
import QuoteSummary from "./QuoteSummary.vue";
import QuoteTable from "./QuoteTable.vue";

const props = defineProps<{
  result: QuotePage;
  loading?: boolean;
  error?: string;
}>();
const emit = defineEmits<{
  request: [filters: QuoteListFilters];
}>();

const query = shallowRef("");
const status = shallowRef<Quote["status"] | "all">("all");
const scheduledOn = shallowRef("");
const sort = shallowRef<QuoteSortKey>("updated");
const direction = shallowRef<QuoteSortDirection>("desc");
const page = shallowRef(props.result.meta.page);
let searchTimer: ReturnType<typeof setTimeout> | undefined;

const hasFilters = computed(
  () =>
    query.value.trim().length > 0 ||
    status.value !== "all" ||
    scheduledOn.value.length > 0,
);
const resultRange = computed(() => {
  const { page: currentPage, perPage, totalCount } = props.result.meta;
  const noun = totalCount === 1 ? "orçamento" : "orçamentos";
  if (totalCount === 0) return `0 de 0 ${noun}`;

  const first = (currentPage - 1) * perPage + 1;
  const last = Math.min(currentPage * perPage, totalCount);
  return first === last
    ? `${first} de ${totalCount} ${noun}`
    : `${first}–${last} de ${totalCount} ${noun}`;
});

function currentFilters(): QuoteListFilters {
  return {
    search: query.value.trim(),
    status: status.value,
    scheduledOn: scheduledOn.value,
    sort: sort.value,
    direction: direction.value,
    page: page.value,
    perPage: props.result.meta.perPage,
  };
}

function clearSearchTimer() {
  if (searchTimer) clearTimeout(searchTimer);
  searchTimer = undefined;
}

function requestImmediately() {
  clearSearchTimer();
  emit("request", currentFilters());
}

function setQuery(value: string) {
  query.value = value.slice(0, 100);
  page.value = 1;
  clearSearchTimer();
  searchTimer = setTimeout(() => {
    searchTimer = undefined;
    emit("request", currentFilters());
  }, 250);
}

function setStatus(value: Quote["status"] | "all") {
  status.value = value;
  page.value = 1;
  requestImmediately();
}

function setScheduledOn(value: string) {
  scheduledOn.value = value;
  page.value = 1;
  requestImmediately();
}

function defaultDirection(column: QuoteSortKey): QuoteSortDirection {
  return column === "customer" || column === "status" ? "asc" : "desc";
}

function setSort(column: QuoteSortKey) {
  if (sort.value === column) {
    direction.value = direction.value === "asc" ? "desc" : "asc";
  } else {
    sort.value = column;
    direction.value = defaultDirection(column);
  }
  page.value = 1;
  requestImmediately();
}

function setPage(value: number) {
  page.value = value;
  requestImmediately();
}

function clearFilters() {
  query.value = "";
  status.value = "all";
  scheduledOn.value = "";
  page.value = 1;
  requestImmediately();
}

onScopeDispose(clearSearchTimer);
</script>

<template>
  <div class="quote-index">
    <QuoteSummary :summary="props.result.summary" />

    <QuoteFilters
      :query="query"
      :status="status"
      :scheduled-on="scheduledOn"
      @update:query="setQuery"
      @update:status="setStatus"
      @update:scheduled-on="setScheduledOn"
    />

    <div class="quote-index__summary">
      <p role="status" aria-live="polite">{{ resultRange }}</p>
      <button v-if="hasFilters" type="button" @click="clearFilters">
        Limpar filtros
      </button>
    </div>

    <p v-if="error" class="quote-index__error" role="alert">{{ error }}</p>
    <QuoteTable
      :quotes="result.quotes"
      :filtered="hasFilters"
      :sort="sort"
      :direction="direction"
      :loading="loading"
      @sort="setSort"
    />
    <QuotePagination
      :page="result.meta.page"
      :total-pages="result.meta.totalPages"
      :loading="loading"
      @page="setPage"
    />
  </div>
</template>

<style scoped lang="scss">
.quote-index {
  display: grid;
  gap: 14px;

  &__summary {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    padding: 0 4px;
  }

  &__summary p {
    margin: 0;
    color: var(--ink-soft);
    font-size: 0.82rem;
  }

  &__summary button {
    padding: 0;
    border: 0;
    background: transparent;
    color: var(--color-brand);
    font-size: 0.82rem;
    font-weight: 800;
    cursor: pointer;
  }

  &__summary button:hover,
  &__summary button:focus-visible {
    text-decoration: underline;
  }

  &__error {
    margin: 0;
    color: var(--color-danger);
    font-size: 0.84rem;
  }
}
</style>
