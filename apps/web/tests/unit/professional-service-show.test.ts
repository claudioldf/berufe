import { mountSuspended } from "@nuxt/test-utils/runtime";
import { flushPromises } from "@vue/test-utils";
import { defineComponent } from "vue";
import ProfessionalServicePage from "@app/pages/app/professional/services/[id].vue";
import type { ProfessionalServiceJob } from "@app/types";

const mocks = vi.hoisted(() => ({
  client: {},
  fetchService: vi.fn(),
  completeService: vi.fn(),
  requestCompletion: vi.fn(),
  cancelService: vi.fn(),
  showToast: vi.fn(),
  copyText: vi.fn(),
}));

vi.mock("@app/services/api/client", () => ({
  useApiClient: () => mocks.client,
}));
vi.mock("@app/services/api/professional-service-jobs", () => ({
  fetchProfessionalServiceJob: mocks.fetchService,
  completeProfessionalServiceJob: mocks.completeService,
  requestProfessionalServiceCompletion: mocks.requestCompletion,
  cancelProfessionalServiceJob: mocks.cancelService,
}));
vi.mock("@app/composables/useToast", () => ({
  useToast: () => ({ showToast: mocks.showToast }),
}));
vi.mock("@app/composables/useShare", () => ({
  useShare: () => ({ copyText: mocks.copyText }),
}));
vi.mock("~/composables/useApplicationSession", async () => {
  const { ref } = await import("vue");
  return {
    useApplicationSession: () => ({
      account: ref({ role: "professional", registrationCompleted: true }),
      restoreSession: vi.fn().mockResolvedValue(true),
    }),
  };
});

const serviceId = "7a2ffba8-2e04-4237-94e6-3bc06c2de888";
const service: ProfessionalServiceJob = {
  id: serviceId,
  status: "approved",
  quote: {
    id: "50e943de-3761-41cf-95c6-1fd12d6d3802",
    number: 7,
    customerName: "Ana Paula",
    customerPhone: "(47) 99999-1111",
    customerEmail: "ana@example.com",
    serviceDescription: "Adequação elétrica",
    serviceAddress: "Rua das Flores, 10",
    scheduledOn: "2026-08-22",
    total: 120,
  },
  completionRequestedAt: null,
  completionIssueAt: null,
  completionIssueMessage: "",
  completedAt: null,
  completionConfirmedBy: null,
  cancelledAt: null,
  cancellationReason: "",
  recommendationRequestStatus: null,
  createdAt: "2026-08-29T12:00:00Z",
  updatedAt: "2026-08-29T12:00:00Z",
};

const SlotStub = defineComponent({ template: "<div><slot /></div>" });
const ButtonStub = defineComponent({
  emits: ["click"],
  template: '<button type="button" @click="$emit(\'click\')"><slot /></button>',
});
const ModalStub = defineComponent({
  props: { open: Boolean },
  emits: ["update:open"],
  template: `
    <div v-if="open" class="modal">
      <slot name="body" />
      <slot name="footer" />
    </div>
  `,
});

async function mountPage() {
  const wrapper = await mountSuspended(ProfessionalServicePage, {
    shallow: true,
    route: `/app/professional/services/${serviceId}`,
    global: {
      renderStubDefaultSlot: true,
      stubs: {
        DesignSystemContainer: SlotStub,
        DesignSystemSurfaceCard: SlotStub,
        UButton: ButtonStub,
        UModal: ModalStub,
        UIcon: true,
      },
    },
  });
  await flushPromises();
  return wrapper;
}

beforeEach(() => {
  vi.clearAllMocks();
  clearNuxtData();
  mocks.fetchService.mockResolvedValue({ ...service });
});

describe("professional service show page", () => {
  it("allows the professional to confirm completion and records the source", async () => {
    mocks.completeService.mockResolvedValue({
      ...service,
      status: "completed",
      completedAt: "2026-08-29T15:00:00Z",
      completionConfirmedBy: "professional",
    });
    const wrapper = await mountPage();

    await wrapper
      .findAll("button")
      .find((button) => button.text() === "Marcar como concluído")
      ?.trigger("click");
    await nextTick();
    await wrapper
      .findAll("button")
      .find((button) => button.text() === "Confirmar conclusão")
      ?.trigger("click");
    await flushPromises();

    expect(mocks.completeService).toHaveBeenCalledWith(mocks.client, serviceId);
    expect(wrapper.text()).toContain(
      "A conclusão foi confirmada pelo profissional.",
    );
    expect(wrapper.text()).not.toContain("Marcar como concluído");
  });

  it("keeps customer-confirmed completion copy for the customer flow", async () => {
    mocks.fetchService.mockResolvedValue({
      ...service,
      status: "completed",
      completedAt: "2026-08-29T15:00:00Z",
      completionConfirmedBy: "customer",
    });
    const wrapper = await mountPage();

    expect(wrapper.text()).toContain(
      "A conclusão foi confirmada pelo cliente.",
    );
  });
});
