import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent, ref, shallowRef } from "vue";
import ProfessionalDashboardPage from "@app/pages/app/professional/index.vue";

const mocks = vi.hoisted(() => ({
  useWorkspace: vi.fn(),
  showToast: vi.fn(),
}));

vi.mock("@app/composables/useProfessionalWorkspace", () => ({
  useProfessionalWorkspace: mocks.useWorkspace,
}));
vi.mock("@app/composables/useToast", () => ({
  useToast: () => ({ showToast: mocks.showToast }),
}));

const ButtonStub = defineComponent({
  props: {
    disabled: { type: Boolean, default: false },
    loading: { type: Boolean, default: false },
  },
  emits: ["click"],
  template:
    '<button type="button" :disabled="disabled" :data-loading="loading" @click="$emit(\'click\')"><slot /></button>',
});

const mountOptions = {
  shallow: true,
  global: {
    renderStubDefaultSlot: true,
    stubs: { UButton: ButtonStub },
  },
} as const;

function workspace(options: { pending?: boolean; failed?: boolean } = {}) {
  const respondToRelationship = vi
    .fn()
    .mockResolvedValue({ status: "accepted" });
  return {
    data: ref({
      pendingRelationships: [
        {
          id: "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
          relationshipType: "worked_together",
          contextNote: "Atuamos juntos em uma obra.",
          status: "pending",
          createdAt: "2026-08-17T12:00:00Z",
          respondedAt: null,
          initiator: {
            id: "f39d4810-f28d-4977-b5e5-387131d12942",
            publicSlug: "ana-souza",
            displayName: "Ana Souza",
          },
          recipient: {
            id: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
            publicSlug: "beto-lima",
            displayName: "Beto Lima",
          },
        },
      ],
    }),
    status: shallowRef(options.pending ? "pending" : "success"),
    error: shallowRef(options.failed ? new Error("private failure") : null),
    relationshipRespondingId: shallowRef<string | null>(null),
    relationshipError: shallowRef(""),
    respondToRelationship,
  };
}

describe("professional dashboard relationships", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("renders real inbound workspace data and confirms through Rails before success feedback", async () => {
    const currentWorkspace = workspace();
    mocks.useWorkspace.mockResolvedValue(currentWorkspace);
    const wrapper = await mountSuspended(
      ProfessionalDashboardPage,
      mountOptions,
    );

    const relationshipRow = wrapper
      .findAll("article")
      .find((article) =>
        article.text().includes("Ana Souza trabalhou com você"),
      );
    expect(relationshipRow).toBeDefined();
    expect(relationshipRow!.text()).toContain("Aguardando sua resposta");

    const buttons = relationshipRow!.findAll("button");
    await buttons[1]!.trigger("click");

    expect(currentWorkspace.respondToRelationship).toHaveBeenCalledWith(
      "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
      "accepted",
    );
    expect(mocks.showToast).toHaveBeenCalledWith(
      expect.objectContaining({ title: "Colaboração confirmada" }),
    );
  });

  it("shows safe loading, empty, and failure feedback in the existing pending section", async () => {
    const pendingWorkspace = workspace({ pending: true });
    mocks.useWorkspace.mockResolvedValue(pendingWorkspace);
    const loading = await mountSuspended(
      ProfessionalDashboardPage,
      mountOptions,
    );
    expect(loading.text()).toContain("Carregando solicitações profissionais");

    const failedWorkspace = workspace({ failed: true });
    failedWorkspace.data.value.pendingRelationships = [];
    mocks.useWorkspace.mockResolvedValue(failedWorkspace);
    const failed = await mountSuspended(
      ProfessionalDashboardPage,
      mountOptions,
    );
    expect(failed.text()).toContain(
      "Não foi possível carregar as solicitações profissionais.",
    );
    expect(failed.text()).not.toContain("private failure");

    failedWorkspace.error.value = null;
    await failed.vm.$nextTick();
    expect(failed.text()).toContain(
      "Nenhuma relação profissional aguarda sua resposta.",
    );
  });
});
