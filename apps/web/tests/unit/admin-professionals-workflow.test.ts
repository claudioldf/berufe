import { flushPromises, mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import Professionals from "@app/components/admin/professionals/Professionals.vue";

const mocks = vi.hoisted(() => ({
  setPublication: vi.fn(),
  startImpersonation: vi.fn(),
}));

vi.mock("@app/composables/useAdminProfessionals", async () => {
  const { readonly, shallowRef } = await import("vue");
  const value = <T>(initial: T) => readonly(shallowRef(initial));
  const professional = {
    id: "account-1",
    professionalProfileId: "profile-1",
    publicSlug: "ana-souza",
    displayName: "Ana Souza",
    profileStatus: "published" as const,
    city: "Joinville",
    state: "SC",
    phoneVerified: true,
    phoneLast4: "4002",
    identityVerified: true,
    accountStatus: "active" as const,
    impersonationEligible: true,
    portfolioCount: 1,
    referenceCount: 0,
    customerCount: 0,
    quoteCount: 0,
    registeredAt: "2026-01-10T12:00:00Z",
    lastLoginAt: null,
    loginCount: 1,
    publishedAt: "2026-01-12T12:00:00Z",
  };

  return {
    useAdminProfessionals: () => ({
      professionals: value({
        items: [professional],
        summary: {
          total: 1,
          published: 1,
          suspended: 0,
          onboardingFinished: 1,
          identityVerified: 1,
        },
        meta: { page: 1, perPage: 20, totalCount: 1, totalPages: 1 },
      }),
      q: value(""),
      phone: value(""),
      city: value(null),
      state: value(null),
      identityVerified: value("all"),
      onboardingFinished: value("all"),
      sort: value("recent"),
      isLoading: value(false),
      error: value(""),
      isMutating: value(false),
      mutationError: value("Não foi possível despublicar o perfil."),
      load: vi.fn(),
      setPage: vi.fn(),
      submitQuery: vi.fn(),
      submitPhone: vi.fn(),
      setCity: vi.fn(),
      setState: vi.fn(),
      setIdentityVerified: vi.fn(),
      setOnboardingFinished: vi.fn(),
      setSort: vi.fn(),
      clearFilters: vi.fn(),
      setPublication: mocks.setPublication,
    }),
  };
});

vi.mock("@app/composables/useAdminImpersonation", async () => {
  const { readonly, shallowRef } = await import("vue");
  return {
    useAdminImpersonation: () => ({
      isChanging: readonly(shallowRef(false)),
      error: readonly(shallowRef("")),
      start: mocks.startImpersonation,
    }),
  };
});

const TableStub = defineComponent({
  props: { items: { type: Array, required: true } },
  emits: ["manage", "unpublish"],
  template:
    "<div><button data-manage @click=\"$emit('manage', items[0])\">Gerenciar</button><button data-unpublish @click=\"$emit('unpublish', items[0])\">Despublicar</button></div>",
});

const DialogStub = defineComponent({
  props: {
    open: { type: Boolean, required: true },
    reason: { type: String, required: true },
  },
  emits: ["update:open", "update:reason", "confirm"],
  template: `
    <section v-if="open" data-dialog>
      <input
        data-reason
        :value="reason"
        @input="$emit('update:reason', $event.target.value)"
      >
      <button data-confirm @click="$emit('confirm')">Confirmar</button>
    </section>
  `,
});

describe("administrator professionals publication workflow", () => {
  it("starts account management from the selected directory row", async () => {
    const wrapper = mount(Professionals, {
      global: {
        stubs: {
          AdminProfessionalsToolbar: true,
          AdminProfessionalsTable: TableStub,
          AdminProfessionalsUnpublishDialog: DialogStub,
          DesignSystemSurfaceCard: true,
          UIcon: true,
        },
      },
    });

    await wrapper.get("[data-manage]").trigger("click");

    expect(mocks.startImpersonation).toHaveBeenCalledWith(
      expect.objectContaining({ id: "account-1" }),
    );
  });

  it("keeps the dialog and reason when unpublishing fails", async () => {
    mocks.setPublication.mockRejectedValueOnce(new Error("Falha temporária."));
    const wrapper = mount(Professionals, {
      global: {
        stubs: {
          AdminProfessionalsToolbar: true,
          AdminProfessionalsTable: TableStub,
          AdminProfessionalsUnpublishDialog: DialogStub,
          DesignSystemSurfaceCard: true,
          UIcon: true,
        },
      },
    });

    await wrapper.get("[data-unpublish]").trigger("click");
    await wrapper
      .get("[data-reason]")
      .setValue("Motivo detalhado para ocultar.");
    await wrapper.get("[data-confirm]").trigger("click");
    await flushPromises();

    expect(mocks.setPublication).toHaveBeenCalledWith(
      expect.objectContaining({ professionalProfileId: "profile-1" }),
      false,
      "Motivo detalhado para ocultar.",
    );
    expect(wrapper.find("[data-dialog]").exists()).toBe(true);
    expect(wrapper.get<HTMLInputElement>("[data-reason]").element.value).toBe(
      "Motivo detalhado para ocultar.",
    );
  });
});
