import { onScopeDispose, shallowReadonly, shallowRef, watch } from "vue";
import type {
  LocationQueryRaw,
  RouteLocationNormalizedLoaded,
  Router,
} from "vue-router";
import {
  fetchAdminProfessionals,
  setAdminProfessionalPublication,
} from "~/services/api/admin-professionals";
import { useApiClient } from "~/services/api/client";
import type {
  AdminProfessionalFilters,
  AdminProfessionalItem,
  AdminProfessionalPage,
  AdminProfessionalSort,
  AdminProfessionalTriState,
} from "~/types";

const emptyPage = (): AdminProfessionalPage => ({
  items: [],
  summary: {
    total: 0,
    published: 0,
    suspended: 0,
    onboardingFinished: 0,
    identityVerified: 0,
  },
  meta: { page: 1, perPage: 20, totalCount: 0, totalPages: 0 },
});

interface AdminProfessionalsDependencies {
  load?: (
    filters: AdminProfessionalFilters,
    signal: AbortSignal,
  ) => Promise<AdminProfessionalPage>;
  mutate?: (
    professionalProfileId: string,
    published: boolean,
    reason: string | null,
    filters: AdminProfessionalFilters,
  ) => Promise<AdminProfessionalPage>;
  route?: Pick<RouteLocationNormalizedLoaded, "query">;
  router?: Pick<Router, "replace">;
}

const defaultSort: AdminProfessionalSort = "recent";
const sorts: AdminProfessionalSort[] = [
  defaultSort,
  "last_login_desc",
  "name_asc",
];
const triStates: AdminProfessionalTriState[] = ["yes", "no"];

function routeString(value: unknown) {
  return String(Array.isArray(value) ? (value[0] ?? "") : (value ?? ""));
}

function positivePage(value: unknown) {
  const candidate = Number.parseInt(routeString(value), 10);
  return Number.isInteger(candidate) && candidate > 0 ? candidate : 1;
}

function routeCity(value: unknown): string | null {
  const candidate = routeString(value).trim();
  return /^\d{7}$/.test(candidate) ? candidate : null;
}

function routeState(value: unknown): string | null {
  const candidate = routeString(value).trim().toUpperCase();
  return /^[A-Z]{2}$/.test(candidate) ? candidate : null;
}

function routeTriState(value: unknown): AdminProfessionalTriState {
  const candidate = routeString(value) as AdminProfessionalTriState;
  return triStates.includes(candidate) ? candidate : "all";
}

function routeSort(value: unknown): AdminProfessionalSort {
  const candidate = routeString(value) as AdminProfessionalSort;
  return sorts.includes(candidate) ? candidate : defaultSort;
}

export function useAdminProfessionals(
  dependencies: AdminProfessionalsDependencies = {},
) {
  const route = dependencies.route ?? useRoute();
  const router = dependencies.router ?? useRouter();
  const client = useApiClient();
  const professionals = shallowRef<AdminProfessionalPage>(emptyPage());
  const page = shallowRef(positivePage(route.query.page));
  const q = shallowRef(routeString(route.query.q).trim());
  const phone = shallowRef(routeString(route.query.phone).trim());
  const city = shallowRef(routeCity(route.query.city));
  const state = shallowRef(routeState(route.query.state));
  const identityVerified = shallowRef(
    routeTriState(route.query.identity_verified),
  );
  const onboardingFinished = shallowRef(
    routeTriState(route.query.onboarding_finished),
  );
  const sort = shallowRef(routeSort(route.query.sort));
  const isLoading = shallowRef(false);
  const error = shallowRef("");
  const isMutating = shallowRef(false);
  const mutationError = shallowRef("");
  let sequence = 0;
  let controller: AbortController | undefined;
  const loadProfessionals =
    dependencies.load ??
    ((filters, signal) => fetchAdminProfessionals(client, filters, signal));
  const mutatePublication =
    dependencies.mutate ??
    ((professionalProfileId, published, reason, filters) =>
      setAdminProfessionalPublication(
        client,
        professionalProfileId,
        published,
        reason,
        filters,
      ));

  function filters(): AdminProfessionalFilters {
    return {
      page: page.value,
      q: q.value,
      phone: phone.value,
      city: city.value,
      state: state.value,
      identityVerified: identityVerified.value,
      onboardingFinished: onboardingFinished.value,
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
      const result = await loadProfessionals(
        filters(),
        requestController.signal,
      );
      if (current === sequence) professionals.value = result;
    } catch (cause) {
      if (requestController.signal.aborted) return;
      if (current === sequence) {
        error.value =
          cause instanceof Error
            ? cause.message
            : "Não foi possível carregar os profissionais.";
      }
    } finally {
      if (current === sequence) isLoading.value = false;
    }
  }

  function replaceRoute(next: AdminProfessionalFilters) {
    const query: LocationQueryRaw = { ...route.query };
    delete query.page;
    delete query.q;
    delete query.phone;
    delete query.city;
    delete query.state;
    delete query.identity_verified;
    delete query.onboarding_finished;
    delete query.sort;
    if (next.page > 1) query.page = String(next.page);
    if (next.q) query.q = next.q;
    if (next.phone) query.phone = next.phone;
    if (next.city) query.city = next.city;
    if (next.state) query.state = next.state;
    if (next.identityVerified !== "all")
      query.identity_verified = next.identityVerified;
    if (next.onboardingFinished !== "all") {
      query.onboarding_finished = next.onboardingFinished;
    }
    if (next.sort !== defaultSort) query.sort = next.sort;
    return router.replace({ query });
  }

  function setPage(value: number) {
    const lastPage = Math.max(1, professionals.value.meta.totalPages);
    return replaceRoute({
      ...filters(),
      page: Math.min(Math.max(1, value), lastPage),
    });
  }

  function submitQuery(value: string) {
    return replaceRoute({ ...filters(), page: 1, q: value.trim() });
  }

  function submitPhone(value: string) {
    return replaceRoute({ ...filters(), page: 1, phone: value.trim() });
  }

  function setCity(value: string | null) {
    return replaceRoute({ ...filters(), page: 1, city: value });
  }

  function setState(value: string | null) {
    return replaceRoute({ ...filters(), page: 1, state: value, city: null });
  }

  function setIdentityVerified(value: AdminProfessionalTriState) {
    return replaceRoute({ ...filters(), page: 1, identityVerified: value });
  }

  function setOnboardingFinished(value: AdminProfessionalTriState) {
    return replaceRoute({ ...filters(), page: 1, onboardingFinished: value });
  }

  function setSort(value: AdminProfessionalSort) {
    return replaceRoute({ ...filters(), page: 1, sort: value });
  }

  function clearFilters() {
    return replaceRoute({
      page: 1,
      q: "",
      phone: "",
      city: null,
      state: null,
      identityVerified: "all",
      onboardingFinished: "all",
      sort: defaultSort,
    });
  }

  async function setPublication(
    item: AdminProfessionalItem,
    published: boolean,
    reason: string | null = null,
  ) {
    if (!item.professionalProfileId || isMutating.value) return;

    isMutating.value = true;
    mutationError.value = "";
    try {
      professionals.value = await mutatePublication(
        item.professionalProfileId,
        published,
        reason,
        filters(),
      );
    } catch (cause) {
      mutationError.value =
        cause instanceof Error
          ? cause.message
          : "Não foi possível atualizar a publicação deste perfil.";
      throw cause;
    } finally {
      isMutating.value = false;
    }
  }

  watch(
    () => [
      route.query.page,
      route.query.q,
      route.query.phone,
      route.query.city,
      route.query.state,
      route.query.identity_verified,
      route.query.onboarding_finished,
      route.query.sort,
    ],
    () => {
      page.value = positivePage(route.query.page);
      q.value = routeString(route.query.q).trim();
      phone.value = routeString(route.query.phone).trim();
      city.value = routeCity(route.query.city);
      state.value = routeState(route.query.state);
      identityVerified.value = routeTriState(route.query.identity_verified);
      onboardingFinished.value = routeTriState(route.query.onboarding_finished);
      sort.value = routeSort(route.query.sort);
    },
    { immediate: true },
  );
  watch(
    [page, q, phone, city, state, identityVerified, onboardingFinished, sort],
    () => void load(),
    { immediate: true },
  );
  onScopeDispose(() => controller?.abort());

  return {
    professionals: shallowReadonly(professionals),
    page: shallowReadonly(page),
    q: shallowReadonly(q),
    phone: shallowReadonly(phone),
    city: shallowReadonly(city),
    state: shallowReadonly(state),
    identityVerified: shallowReadonly(identityVerified),
    onboardingFinished: shallowReadonly(onboardingFinished),
    sort: shallowReadonly(sort),
    isLoading: shallowReadonly(isLoading),
    error: shallowReadonly(error),
    isMutating: shallowReadonly(isMutating),
    mutationError: shallowReadonly(mutationError),
    load,
    setPage,
    submitQuery,
    submitPhone,
    setCity,
    setState,
    setIdentityVerified,
    setOnboardingFinished,
    setSort,
    clearFilters,
    setPublication,
  };
}
