import { onScopeDispose, shallowReadonly, shallowRef, watch } from "vue";
import { fetchAdminSearchAudits } from "~/services/api/admin-search-audits";
import { useApiClient } from "~/services/api/client";
import type { SearchAuditPage } from "~/types";

const emptyPage = (): SearchAuditPage => ({
  items: [],
  meta: { page: 1, perPage: 20, totalCount: 0, totalPages: 0 },
});

interface AdminSearchAuditDependencies {
  load?: (page: number, signal: AbortSignal) => Promise<SearchAuditPage>;
}

export function useAdminSearchAudits(
  dependencies: AdminSearchAuditDependencies = {},
) {
  const client = useApiClient();
  const audits = shallowRef<SearchAuditPage>(emptyPage());
  const page = shallowRef(1);
  const isLoading = shallowRef(false);
  const error = shallowRef("");
  let sequence = 0;
  let controller: AbortController | undefined;
  const loadAudits =
    dependencies.load ??
    ((requestedPage, signal) =>
      fetchAdminSearchAudits(client, requestedPage, signal));

  async function load() {
    const current = ++sequence;
    controller?.abort();
    const requestController = new AbortController();
    controller = requestController;
    isLoading.value = true;
    error.value = "";
    try {
      const result = await loadAudits(page.value, requestController.signal);
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

  function setPage(value: number) {
    const lastPage = Math.max(1, audits.value.meta.totalPages);
    page.value = Math.min(Math.max(1, value), lastPage);
  }

  watch(page, load, { immediate: true });
  onScopeDispose(() => controller?.abort());

  return {
    audits: shallowReadonly(audits),
    page: shallowReadonly(page),
    isLoading: shallowReadonly(isLoading),
    error: shallowReadonly(error),
    load,
    setPage,
  };
}
