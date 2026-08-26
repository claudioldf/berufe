import { onScopeDispose, shallowReadonly, shallowRef, watch } from "vue";
import type {
  LocationQueryRaw,
  RouteLocationNormalizedLoaded,
  Router,
} from "vue-router";
import { fetchAdminSearchAudits } from "~/services/api/admin-search-audits";
import { useApiClient } from "~/services/api/client";
import type {
  SearchAuditOutcome,
  SearchAuditPage,
  SearchAuditRequest,
  SearchAuditSort,
} from "~/types";

const emptyPage = (): SearchAuditPage => ({
  items: [],
  summary: {
    total: 0,
    zeroResults: 0,
    notUnderstood: 0,
    thinResults: 0,
    operationalIssue: 0,
    healthy: 0,
  },
  meta: { page: 1, perPage: 20, totalCount: 0, totalPages: 0 },
});

interface AdminSearchAuditDependencies {
  load?: (
    request: SearchAuditRequest,
    signal: AbortSignal,
  ) => Promise<SearchAuditPage>;
  route?: Pick<RouteLocationNormalizedLoaded, "query">;
  router?: Pick<Router, "replace">;
}

const outcomes: SearchAuditOutcome[] = [
  "zero_results",
  "not_understood",
  "thin_results",
  "operational_issue",
  "healthy",
];
const defaultSort: SearchAuditSort = "results_asc";
const sorts: SearchAuditSort[] = [
  defaultSort,
  "gaps",
  "newest",
  "results_desc",
];

function routeString(value: unknown) {
  return String(Array.isArray(value) ? (value[0] ?? "") : (value ?? ""));
}

function positivePage(value: unknown) {
  const candidate = Number.parseInt(routeString(value), 10);
  return Number.isInteger(candidate) && candidate > 0 ? candidate : 1;
}

function routeOutcome(value: unknown): SearchAuditOutcome | null {
  const candidate = routeString(value) as SearchAuditOutcome;
  return outcomes.includes(candidate) ? candidate : null;
}

function routeSort(value: unknown): SearchAuditSort {
  const candidate = routeString(value) as SearchAuditSort;
  return sorts.includes(candidate) ? candidate : defaultSort;
}

export function useAdminSearchAudits(
  dependencies: AdminSearchAuditDependencies = {},
) {
  const route = dependencies.route ?? useRoute();
  const router = dependencies.router ?? useRouter();
  const client = useApiClient();
  const audits = shallowRef<SearchAuditPage>(emptyPage());
  const page = shallowRef(positivePage(route.query.page));
  const q = shallowRef(routeString(route.query.q).trim());
  const outcome = shallowRef<SearchAuditOutcome | null>(
    routeOutcome(route.query.outcome),
  );
  const sort = shallowRef<SearchAuditSort>(routeSort(route.query.sort));
  const isLoading = shallowRef(false);
  const error = shallowRef("");
  let sequence = 0;
  let controller: AbortController | undefined;
  const loadAudits =
    dependencies.load ??
    ((request, signal) => fetchAdminSearchAudits(client, request, signal));

  function request(): SearchAuditRequest {
    return {
      page: page.value,
      q: q.value,
      outcome: outcome.value,
      sort: sort.value,
    };
  }

  async function load() {
    const current = ++sequence;
    controller?.abort();
    const requestController = new AbortController();
    controller = requestController;
    isLoading.value = true;
    error.value = "";
    try {
      const result = await loadAudits(request(), requestController.signal);
      if (current === sequence) audits.value = result;
    } catch (cause) {
      if (requestController.signal.aborted) return;
      if (current === sequence) {
        error.value =
          cause instanceof Error
            ? cause.message
            : "Não foi possível carregar a auditoria de buscas.";
      }
    } finally {
      if (current === sequence) isLoading.value = false;
    }
  }

  function replaceRoute(next: SearchAuditRequest) {
    const query: LocationQueryRaw = { ...route.query };
    delete query.page;
    delete query.q;
    delete query.outcome;
    delete query.sort;
    if (next.page > 1) query.page = String(next.page);
    if (next.q) query.q = next.q;
    if (next.outcome) query.outcome = next.outcome;
    if (next.sort !== defaultSort) query.sort = next.sort;
    return router.replace({ query });
  }

  function setPage(value: number) {
    const lastPage = Math.max(1, audits.value.meta.totalPages);
    return replaceRoute({
      ...request(),
      page: Math.min(Math.max(1, value), lastPage),
    });
  }

  function submitQuery(value: string) {
    const nextQuery = value.trim();
    if (nextQuery === q.value && page.value === 1) return load();
    return replaceRoute({ ...request(), page: 1, q: nextQuery });
  }

  function setOutcome(value: SearchAuditOutcome | null) {
    return replaceRoute({ ...request(), page: 1, outcome: value });
  }

  function setSort(value: SearchAuditSort) {
    return replaceRoute({ ...request(), page: 1, sort: value });
  }

  function clearFilters() {
    return replaceRoute({ ...request(), page: 1, q: "", outcome: null });
  }

  watch(
    () => [
      route.query.page,
      route.query.q,
      route.query.outcome,
      route.query.sort,
    ],
    () => {
      page.value = positivePage(route.query.page);
      q.value = routeString(route.query.q).trim();
      outcome.value = routeOutcome(route.query.outcome);
      sort.value = routeSort(route.query.sort);
    },
    { immediate: true },
  );
  watch([page, q, outcome, sort], () => void load(), { immediate: true });
  onScopeDispose(() => controller?.abort());

  return {
    audits: shallowReadonly(audits),
    page: shallowReadonly(page),
    q: shallowReadonly(q),
    outcome: shallowReadonly(outcome),
    sort: shallowReadonly(sort),
    isLoading: shallowReadonly(isLoading),
    error: shallowReadonly(error),
    load,
    setPage,
    submitQuery,
    setOutcome,
    setSort,
    clearFilters,
  };
}
