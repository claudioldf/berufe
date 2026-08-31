import { mountSuspended } from "@nuxt/test-utils/runtime";
import { flushPromises } from "@vue/test-utils";
import { defineComponent } from "vue";
import ProfessionalServicePage from "@app/pages/app/professional/services/[id].vue";
import type { ProfessionalServiceJob } from "@app/types";

const mocks = vi.hoisted(() => ({
  client: {},
  fetchService: vi.fn(),
  completeService: vi.fn(),
  requestRecommendation: vi.fn(),
  cancelService: vi.fn(),
  showToast: vi.fn(),
}));

vi.mock("@app/services/api/client", () => ({
  useApiClient: () => mocks.client,
}));
vi.mock("@app/services/api/professional-service-jobs", () => ({
  fetchProfessionalServiceJob: mocks.fetchService,
  completeProfessionalServiceJob: mocks.completeService,
  requestProfessionalServiceRecommendation: mocks.requestRecommendation,
  cancelProfessionalServiceJob: mocks.cancelService,
}));
vi.mock("@app/composables/useToast", () => ({
  useToast: () => ({ showToast: mocks.showToast }),
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
  customerFeedbackMessage: "",
  completedAt: null,
  cancelledAt: null,
  cancellationReason: "",
  recommendation: null,
  createdAt: "2026-08-29T12:00:00Z",
  updatedAt: "2026-08-29T12:00:00Z",
};

const SlotStub = defineComponent({ template: "<div><slot /></div>" });
const ButtonStub = defineComponent({
  props: {
    disabled: { type: Boolean, default: false },
    loading: { type: Boolean, default: false },
  },
  emits: ["click"],
  template:
    '<button type="button" :disabled="disabled" :data-loading="loading" @click="$emit(\'click\')"><slot /></button>',
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
    shallow: false,
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
  it("links back to the quote that originated the service", async () => {
    const wrapper = await mountPage();

    const quoteLink = wrapper.get(
      `a[href="/app/professional/quotes/new?quote=${service.quote.id}"]`,
    );
    expect(quoteLink.text()).toContain("Ver orçamento");
    expect(quoteLink.attributes("aria-label")).toBe(
      `Abrir orçamento #${service.quote.number}`,
    );
  });

  it("lets the professional complete without requesting an evaluation", async () => {
    mocks.completeService.mockResolvedValue({
      serviceJob: {
        ...service,
        status: "completed",
        completedAt: "2026-08-29T15:00:00Z",
        recommendation: null,
      },
      shareUrl: null,
      whatsappUrl: null,
    });
    const wrapper = await mountPage();

    expect(
      wrapper.findAll("button").some((button) => button.text() === "Concluído"),
    ).toBe(true);
    await wrapper
      .findAll("button")
      .find((button) => button.text() === "Concluído")
      ?.trigger("click");
    await nextTick();
    await wrapper
      .findAll("button")
      .find((button) =>
        button.text().includes("Concluir sem solicitar avaliação"),
      )
      ?.trigger("click");
    await flushPromises();

    expect(mocks.completeService).toHaveBeenCalledWith(
      mocks.client,
      serviceId,
      false,
    );
    expect(wrapper.text()).toContain("Serviço concluído");
    expect(wrapper.text()).toContain(
      "Registrado por você sem solicitar uma avaliação ao cliente.",
    );
    expect(
      wrapper.findAll("button").some((button) => button.text() === "Concluído"),
    ).toBe(false);
  });

  it("closes the confirmation without changing the service", async () => {
    const wrapper = await mountPage();

    await wrapper
      .findAll("button")
      .find((button) => button.text() === "Concluído")
      ?.trigger("click");
    await nextTick();
    await wrapper
      .findAll("button")
      .find((button) => button.text() === "Cancelar")
      ?.trigger("click");
    await flushPromises();

    expect(mocks.completeService).not.toHaveBeenCalled();
    expect(
      wrapper.findAll("button").some((button) => button.text() === "Concluído"),
    ).toBe(true);
  });

  it("requests an email evaluation only after explicit confirmation", async () => {
    mocks.completeService.mockResolvedValue({
      serviceJob: {
        ...service,
        status: "completed",
        completedAt: "2026-08-29T15:00:00Z",
        recommendation: {
          status: "open",
          deliveryChannel: "email",
          sentAt: null,
        },
      },
      shareUrl: null,
      whatsappUrl: null,
    });
    const wrapper = await mountPage();

    await wrapper
      .findAll("button")
      .find((button) => button.text() === "Concluído")
      ?.trigger("click");
    await nextTick();
    await wrapper
      .findAll("button")
      .find((button) =>
        button.text().includes("Concluir e solicitar avaliação"),
      )
      ?.trigger("click");
    await flushPromises();

    expect(mocks.completeService).toHaveBeenCalledWith(
      mocks.client,
      serviceId,
      true,
    );
    expect(mocks.showToast).toHaveBeenCalledWith(
      expect.objectContaining({
        description:
          "O pedido de avaliação foi enfileirado para envio por e-mail.",
      }),
    );
  });

  it("opens the prepared WhatsApp evaluation after completion when email is absent", async () => {
    mocks.fetchService.mockResolvedValue({
      ...service,
      quote: { ...service.quote, customerEmail: "" },
    });
    mocks.completeService.mockResolvedValue({
      serviceJob: {
        ...service,
        status: "completed",
        completedAt: "2026-08-29T15:00:00Z",
        quote: { ...service.quote, customerEmail: "" },
        recommendation: {
          status: "open",
          deliveryChannel: "whatsapp",
          sentAt: "2026-08-29T15:00:00Z",
        },
      },
      shareUrl: "http://localhost:3000/recomendacao/token",
      whatsappUrl: "https://wa.me/5547999991111?text=avaliacao",
    });
    const replace = vi.fn();
    const close = vi.fn();
    const handoff = {
      opener: window,
      location: { replace },
      close,
    } as unknown as Window;
    const open = vi.spyOn(window, "open").mockReturnValue(handoff);
    const wrapper = await mountPage();

    await wrapper
      .findAll("button")
      .find((button) => button.text() === "Concluído")
      ?.trigger("click");
    await nextTick();
    await wrapper
      .findAll("button")
      .find((button) =>
        button.text().includes("Concluir e solicitar avaliação"),
      )
      ?.trigger("click");
    await flushPromises();

    expect(open).toHaveBeenCalledWith("about:blank", "_blank");
    expect(replace).toHaveBeenCalledWith(
      "https://wa.me/5547999991111?text=avaliacao",
    );
    expect(close).not.toHaveBeenCalled();
    open.mockRestore();
  });

  it("keeps the confirmation open when completion fails", async () => {
    mocks.completeService.mockRejectedValue(new Error("offline"));
    const wrapper = await mountPage();

    await wrapper
      .findAll("button")
      .find((button) => button.text() === "Concluído")
      ?.trigger("click");
    await nextTick();
    await wrapper
      .findAll("button")
      .find((button) =>
        button.text().includes("Concluir sem solicitar avaliação"),
      )
      ?.trigger("click");
    await flushPromises();

    expect(wrapper.text()).toContain("Não foi possível concluir o serviço.");
    expect(wrapper.text()).toContain("Concluir sem solicitar avaliação");
    expect(
      wrapper.findAll("button").some((button) => button.text() === "Concluído"),
    ).toBe(true);
  });

  it("offers a WhatsApp recommendation handoff only when the request has no email to deliver to", async () => {
    mocks.fetchService.mockResolvedValue({
      ...service,
      status: "completed",
      completedAt: "2026-08-29T15:00:00Z",
      recommendation: {
        status: "open",
        deliveryChannel: "whatsapp",
        sentAt: null,
      },
    });
    const wrapper = await mountPage();

    expect(
      wrapper
        .findAll("button")
        .some((button) =>
          button.text().includes("Pedir a recomendação pelo WhatsApp"),
        ),
    ).toBe(true);
  });

  it("does not offer a WhatsApp handoff for an email evaluation request", async () => {
    mocks.fetchService.mockResolvedValue({
      ...service,
      status: "completed",
      completedAt: "2026-08-29T15:00:00Z",
      recommendation: {
        status: "open",
        deliveryChannel: "email",
        sentAt: null,
      },
    });
    const wrapper = await mountPage();

    expect(
      wrapper
        .findAll("button")
        .some((button) => button.text().includes("recomendação")),
    ).toBe(false);
  });
});
