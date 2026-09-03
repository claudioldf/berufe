import { flushPromises } from "@vue/test-utils";
import { effectScope, reactive } from "vue";
import type { RouteLocationNormalizedLoaded, Router } from "vue-router";
import { useAdminProfessionals } from "@app/composables/useAdminProfessionals";
import type { AdminProfessionalItem, AdminProfessionalPage } from "@app/types";

vi.mock("@app/services/api/client", () => ({ useApiClient: () => ({}) }));

const page = (value: number): AdminProfessionalPage => ({
  items: [],
  summary: {
    total: 4,
    published: 2,
    suspended: 1,
    onboardingFinished: 3,
    identityVerified: 1,
  },
  meta: { page: value, perPage: 20, totalCount: 4, totalPages: 2 },
});

const item: AdminProfessionalItem = {
  id: "account-1",
  professionalProfileId: "profile-1",
  publicSlug: "ana-souza",
  displayName: "Ana Souza",
  profileStatus: "published",
  city: "Joinville",
  state: "SC",
  phoneVerified: true,
  phoneLast4: "4002",
  identityVerified: true,
  accountStatus: "active",
  impersonationEligible: true,
  portfolioCount: 1,
  referenceCount: 0,
  customerCount: 0,
  quoteCount: 0,
  registeredAt: null,
  lastLoginAt: null,
  loginCount: 3,
  publishedAt: null,
};

describe("administrator professional directory composable", () => {
  function routeDependencies() {
    const routeState = reactive<{ query: Record<string, unknown> }>({
      query: {},
    });
    const route = routeState as unknown as Pick<
      RouteLocationNormalizedLoaded,
      "query"
    >;
    const router = {
      replace: vi.fn(async (location: { query?: Record<string, unknown> }) => {
        routeState.query = { ...location.query };
      }),
    } as unknown as Pick<Router, "replace">;
    return { route, router, routeState };
  }

  it("loads URL-backed filters, pages through results, and exposes retry errors", async () => {
    const load = vi
      .fn()
      .mockResolvedValueOnce(page(1))
      .mockResolvedValueOnce(page(2))
      .mockRejectedValueOnce(new Error("Profissionais indisponíveis."));
    const { route, router, routeState } = routeDependencies();
    const scope = effectScope();
    const workflow = scope.run(() =>
      useAdminProfessionals({ load, route, router }),
    )!;

    await flushPromises();
    expect(workflow.professionals.value.meta.page).toBe(1);
    expect(load).toHaveBeenCalledWith(
      {
        page: 1,
        q: "",
        phone: "",
        city: null,
        state: null,
        identityVerified: "all",
        onboardingFinished: "all",
        sort: "recent",
      },
      expect.any(AbortSignal),
    );

    await workflow.setPage(2);
    await flushPromises();
    expect(workflow.professionals.value.meta.page).toBe(2);
    expect(routeState.query).toEqual({ page: "2" });

    await workflow.load();
    expect(workflow.error.value).toBe("Profissionais indisponíveis.");
    expect(workflow.isLoading.value).toBe(false);
    scope.stop();
  });

  it("resets pagination when a filter changes and shares state through the URL", async () => {
    const load = vi.fn().mockResolvedValue(page(1));
    const { route, router, routeState } = routeDependencies();
    const scope = effectScope();
    const workflow = scope.run(() =>
      useAdminProfessionals({ load, route, router }),
    )!;
    await flushPromises();

    await workflow.setPage(2);
    await workflow.submitQuery("  ana souza  ");
    await flushPromises();

    expect(routeState.query).toEqual({ q: "ana souza" });
    expect(load).toHaveBeenLastCalledWith(
      {
        page: 1,
        q: "ana souza",
        phone: "",
        city: null,
        state: null,
        identityVerified: "all",
        onboardingFinished: "all",
        sort: "recent",
      },
      expect.any(AbortSignal),
    );

    await workflow.setState("SC");
    await workflow.setCity("4209102");
    await workflow.setIdentityVerified("yes");
    await flushPromises();
    expect(routeState.query).toEqual({
      q: "ana souza",
      city: "4209102",
      state: "SC",
      identity_verified: "yes",
    });

    await workflow.clearFilters();
    await flushPromises();
    expect(routeState.query).toEqual({});
  });

  it("clears the city filter when a different state is selected", async () => {
    const load = vi.fn().mockResolvedValue(page(1));
    const { route, router, routeState } = routeDependencies();
    const scope = effectScope();
    const workflow = scope.run(() =>
      useAdminProfessionals({ load, route, router }),
    )!;
    await flushPromises();

    await workflow.setState("SC");
    await workflow.setCity("4209102");
    await flushPromises();
    expect(routeState.query).toEqual({ city: "4209102", state: "SC" });

    await workflow.setState("PR");
    await flushPromises();
    expect(routeState.query).toEqual({ state: "PR" });
  });

  it("mutates the publication and adopts the refreshed page", async () => {
    const load = vi.fn().mockResolvedValue(page(1));
    const mutate = vi.fn().mockResolvedValue(page(1));
    const { route, router } = routeDependencies();
    const scope = effectScope();
    const workflow = scope.run(() =>
      useAdminProfessionals({ load, mutate, route, router }),
    )!;
    await flushPromises();

    await workflow.setPublication(
      item,
      false,
      "Motivo com detalhes suficientes.",
    );

    expect(mutate).toHaveBeenCalledWith(
      "profile-1",
      false,
      "Motivo com detalhes suficientes.",
      expect.objectContaining({ page: 1 }),
    );
    expect(workflow.isMutating.value).toBe(false);
    expect(workflow.mutationError.value).toBe("");
  });

  it("does not mutate a professional without a profile and surfaces failures", async () => {
    const load = vi.fn().mockResolvedValue(page(1));
    const mutate = vi
      .fn()
      .mockRejectedValue(new Error("Conflito ao publicar."));
    const { route, router } = routeDependencies();
    const scope = effectScope();
    const workflow = scope.run(() =>
      useAdminProfessionals({ load, mutate, route, router }),
    )!;
    await flushPromises();

    await workflow.setPublication(
      { ...item, professionalProfileId: null },
      true,
    );
    expect(mutate).not.toHaveBeenCalled();

    await expect(workflow.setPublication(item, true)).rejects.toThrow(
      "Conflito ao publicar.",
    );
    expect(workflow.mutationError.value).toBe("Conflito ao publicar.");
  });
});
