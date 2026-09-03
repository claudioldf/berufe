import { mountSuspended } from "@nuxt/test-utils/runtime";
import { flushPromises } from "@vue/test-utils";
import { defineComponent } from "vue";
import type { Quote } from "@app/types";
import ProfessionalQuotePage from "@app/pages/app/professional/quotes/new.vue";
import { quoteDateAfterDays } from "@app/utils/quotes";

const mocks = vi.hoisted(() => ({
  client: {},
  fetchWorkspace: vi.fn(),
  fetchCustomer: vi.fn(),
  fetchQuote: vi.fn(),
  createQuote: vi.fn(),
  updateQuote: vi.fn(),
  shareQuote: vi.fn(),
  revokeShare: vi.fn(),
  showToast: vi.fn(),
  copyText: vi.fn(),
}));

vi.mock("@app/services/api/client", () => ({
  useApiClient: () => mocks.client,
}));
vi.mock("@app/services/api/professional-workspace", () => ({
  fetchProfessionalWorkspace: mocks.fetchWorkspace,
}));
vi.mock("@app/services/api/professional-customers", () => ({
  fetchProfessionalCustomer: mocks.fetchCustomer,
}));
vi.mock("@app/services/api/professional-quotes", () => ({
  createProfessionalQuote: mocks.createQuote,
  fetchProfessionalQuote: mocks.fetchQuote,
  revokeProfessionalQuoteShare: mocks.revokeShare,
  shareProfessionalQuote: mocks.shareQuote,
  updateProfessionalQuote: mocks.updateQuote,
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
      account: ref({
        role: "professional",
        registrationCompleted: true,
      }),
      restoreSession: vi.fn().mockResolvedValue(true),
    }),
  };
});

const customerId = "a3f42858-40bc-4bda-bb66-35f32eece27c";
const quoteId = "50e943de-3761-41cf-95c6-1fd12d6d3802";
const ContainerStub = defineComponent({
  template: "<div><slot /></div>",
});
const QuoteBuilderStub = defineComponent({
  name: "DashboardQuoteBuilder",
  props: {
    initialQuote: { type: Object, required: true },
    shareOpen: Boolean,
    saveError: { type: String, default: "" },
  },
  emits: ["prepareShare", "update:shareOpen"],
  template: `
    <div>
      <button class="prepare-share" @click="$emit('prepareShare', initialQuote)">
        Prepare share
      </button>
      <p class="save-error">{{ saveError }}</p>
    </div>
  `,
});
const existingQuote: Quote = {
  id: quoteId,
  number: 7,
  revision: 0,
  customerId,
  customerName: "Cliente do orçamento",
  customerPhone: "(47) 99999-1111",
  customerEmail: "quote@example.com",
  pricingMode: "itemized",
  serviceDescription: "Adequação elétrica",
  serviceAddress: "",
  scheduledOn: "",
  validUntil: "",
  discount: 0,
  markup: 0,
  notes: "",
  status: "draft",
  subtotal: 100,
  total: 100,
  sharedAt: null,
  createdAt: "2026-08-18T12:00:00Z",
  updatedAt: "2026-08-18T12:01:00Z",
  customerDecisionMessage: "",
  changeRequests: [],
  serviceJob: null,
  items: [],
  customerSuppliedMaterials: [],
};

beforeEach(async () => {
  vi.clearAllMocks();
  clearNuxtData();
  mocks.fetchWorkspace.mockResolvedValue({
    quoteDefaults: { pricingMode: "fixed_price" },
    profile: {
      isPublic: true,
      services: [{ name: "Eletricista", isPrimary: true }],
      identity: { name: "Ana Profissional" },
      photo: { imageUrl: null },
    },
    dashboard: { readiness: { steps: { approvedIdentity: true } } },
  });
  mocks.fetchCustomer.mockResolvedValue({
    id: customerId,
    name: "Ana Cliente",
    phone: "(47) 99999-2222",
    email: "cliente@example.com",
    emailVerified: false,
    quoteCount: 2,
    lastQuoteAt: "2026-08-18T12:00:00Z",
  });
  mocks.fetchQuote.mockResolvedValue(existingQuote);
});

describe("new quote customer prefill", () => {
  it("prefills canonical customer contact from the customer query", async () => {
    const wrapper = await mountSuspended(ProfessionalQuotePage, {
      shallow: true,
      route: `/app/professional/quotes/new?customer=${customerId}`,
      global: {
        renderStubDefaultSlot: true,
        stubs: {
          DesignSystemContainer: ContainerStub,
          DashboardQuoteBuilder: QuoteBuilderStub,
        },
      },
    });
    await flushPromises();

    expect(mocks.fetchCustomer).toHaveBeenCalledWith(mocks.client, customerId);
    expect(mocks.fetchQuote).not.toHaveBeenCalled();
    expect(
      wrapper
        .getComponent({ name: "DashboardQuoteBuilder" })
        .props("initialQuote"),
    ).toMatchObject({
      customerId,
      customerName: "Ana Cliente",
      customerPhone: "(47) 99999-2222",
      customerEmail: "cliente@example.com",
      pricingMode: "fixed_price",
      validUntil: quoteDateAfterDays(30),
    });
    expect(
      wrapper.getComponent({ name: "DashboardQuoteStatusCard" }).props("quote"),
    ).toMatchObject({
      id: null,
      customerId,
      status: "draft",
    });
  });

  it("gives an existing quote precedence over a customer query", async () => {
    const wrapper = await mountSuspended(ProfessionalQuotePage, {
      shallow: true,
      route: `/app/professional/quotes/new?quote=${quoteId}&customer=${customerId}`,
      global: {
        renderStubDefaultSlot: true,
        stubs: {
          DesignSystemContainer: ContainerStub,
          DashboardQuoteBuilder: QuoteBuilderStub,
        },
      },
    });
    await flushPromises();

    expect(mocks.fetchQuote).toHaveBeenCalledWith(mocks.client, quoteId);
    expect(mocks.fetchCustomer).not.toHaveBeenCalled();
    expect(
      wrapper
        .getComponent({ name: "DashboardQuoteBuilder" })
        .props("initialQuote"),
    ).toMatchObject({
      id: quoteId,
      customerName: "Cliente do orçamento",
      validUntil: quoteDateAfterDays(30),
    });
    expect(
      wrapper.getComponent({ name: "DashboardQuoteStatusCard" }).props("quote"),
    ).toMatchObject({
      id: quoteId,
      status: "draft",
    });
  });

  it("preserves the saved validity when editing an existing quote", async () => {
    mocks.fetchQuote.mockResolvedValue({
      ...existingQuote,
      validUntil: "2026-10-15",
    });
    const wrapper = await mountSuspended(ProfessionalQuotePage, {
      shallow: true,
      route: `/app/professional/quotes/new?quote=${quoteId}`,
      global: {
        renderStubDefaultSlot: true,
        stubs: {
          DesignSystemContainer: ContainerStub,
          DashboardQuoteBuilder: QuoteBuilderStub,
        },
      },
    });
    await flushPromises();

    expect(
      wrapper
        .getComponent({ name: "DashboardQuoteBuilder" })
        .props("initialQuote"),
    ).toMatchObject({ validUntil: "2026-10-15" });
  });

  it("creates a new quote before opening the share dialog", async () => {
    mocks.createQuote.mockResolvedValue({ ...existingQuote, status: "saved" });
    const wrapper = await mountSuspended(ProfessionalQuotePage, {
      shallow: true,
      route: "/app/professional/quotes/new",
      global: {
        renderStubDefaultSlot: true,
        stubs: {
          DesignSystemContainer: ContainerStub,
          DashboardQuoteBuilder: QuoteBuilderStub,
        },
      },
    });
    await flushPromises();

    await wrapper.get(".prepare-share").trigger("click");
    await flushPromises();

    expect(mocks.createQuote).toHaveBeenCalledTimes(1);
    expect(mocks.shareQuote).not.toHaveBeenCalled();
    expect(
      wrapper
        .getComponent({ name: "DashboardQuoteBuilder" })
        .props("shareOpen"),
    ).toBe(true);

    wrapper
      .getComponent({ name: "DashboardQuoteBuilder" })
      .vm.$emit("update:shareOpen", false);
    await nextTick();

    expect(mocks.shareQuote).not.toHaveBeenCalled();
  });

  it("updates an edited quote before reopening share options", async () => {
    const updatedQuote = {
      ...existingQuote,
      revision: 1,
      updatedAt: "2026-08-18T12:02:00Z",
    };
    mocks.updateQuote.mockResolvedValue(updatedQuote);
    const wrapper = await mountSuspended(ProfessionalQuotePage, {
      shallow: true,
      route: `/app/professional/quotes/new?quote=${quoteId}`,
      global: {
        renderStubDefaultSlot: true,
        stubs: {
          DesignSystemContainer: ContainerStub,
          DashboardQuoteBuilder: QuoteBuilderStub,
        },
      },
    });
    await flushPromises();

    await wrapper.get(".prepare-share").trigger("click");
    await flushPromises();

    expect(mocks.updateQuote).toHaveBeenCalledWith(
      mocks.client,
      quoteId,
      expect.objectContaining({ id: quoteId }),
    );
    expect(mocks.shareQuote).not.toHaveBeenCalled();
    expect(
      wrapper
        .getComponent({ name: "DashboardQuoteBuilder" })
        .props("shareOpen"),
    ).toBe(true);
  });

  it("keeps share options closed when saving fails", async () => {
    mocks.createQuote.mockRejectedValue(new Error("offline"));
    const wrapper = await mountSuspended(ProfessionalQuotePage, {
      shallow: true,
      route: "/app/professional/quotes/new",
      global: {
        renderStubDefaultSlot: true,
        stubs: {
          DesignSystemContainer: ContainerStub,
          DashboardQuoteBuilder: QuoteBuilderStub,
        },
      },
    });
    await flushPromises();

    await wrapper.get(".prepare-share").trigger("click");
    await flushPromises();

    expect(mocks.shareQuote).not.toHaveBeenCalled();
    expect(
      wrapper
        .getComponent({ name: "DashboardQuoteBuilder" })
        .props("shareOpen"),
    ).toBe(false);
    expect(wrapper.get(".save-error").text()).toBe(
      "Não foi possível salvar o orçamento. Tente novamente.",
    );
  });
});
