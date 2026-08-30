import { mountSuspended } from "@nuxt/test-utils/runtime";
import { flushPromises } from "@vue/test-utils";
import { defineComponent, reactive } from "vue";
import CustomerFields from "@app/components/dashboard/quote/CustomerFields.vue";
import type { Quote, QuoteValidationErrors } from "@app/types";

const mocks = vi.hoisted(() => ({
  client: {},
  searchCustomers: vi.fn(),
}));

vi.mock("@app/services/api/client", () => ({
  useApiClient: () => mocks.client,
}));
vi.mock("@app/services/api/professional-customers", () => ({
  searchProfessionalCustomerCandidates: mocks.searchCustomers,
}));

const SurfaceCardStub = defineComponent({
  template: "<section><slot /></section>",
});
const FieldStub = defineComponent({
  props: {
    label: { type: String, default: "" },
    error: { type: String, default: "" },
  },
  template:
    '<label>{{ label }}<slot :control-id="\'customer-field\'" :described-by="error ? \'customer-field-error\' : null" :invalid="Boolean(error)" /></label>',
});
const IconStub = defineComponent({
  props: { name: { type: String, required: true } },
  template: '<i :data-icon="name" />',
});

function quoteFixture(): Quote {
  return {
    id: null,
    number: null,
    revision: 0,
    customerId: null,
    customerName: "",
    customerPhone: "",
    customerEmail: "",
    serviceDescription: "Instalação elétrica",
    serviceAddress: "",
    scheduledOn: "",
    validUntil: "",
    discount: 0,
    notes: "",
    status: "draft",
    subtotal: 100,
    total: 100,
    sharedAt: null,
    createdAt: null,
    updatedAt: null,
    customerDecisionMessage: "",
    changeRequests: [],
    serviceJob: null,
    items: [
      {
        id: "draft-item",
        description: "Instalação",
        quantity: 1,
        unit: "serviço",
        unitPrice: 100,
        lineTotal: 100,
        sortOrder: 0,
      },
    ],
  };
}

async function mountCustomerFields(errors?: QuoteValidationErrors) {
  const quote = reactive(quoteFixture());
  const wrapper = await mountSuspended(CustomerFields, {
    props: { modelValue: quote, errors },
    global: {
      stubs: {
        DesignSystemSurfaceCard: SurfaceCardStub,
        DesignSystemFormField: FieldStub,
        UIcon: IconStub,
      },
    },
  });
  return { quote, wrapper };
}

describe("quote customer fields", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.searchCustomers.mockResolvedValue([]);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("keeps only customer data in the first card", async () => {
    const { wrapper } = await mountCustomerFields();

    expect(wrapper.get("header").text()).toContain("01");
    expect(wrapper.get("h2").text()).toBe("Cliente");
    expect(wrapper.find('input[name="validUntil"]').exists()).toBe(false);
    expect(wrapper.find('input[name="serviceDescription"]').exists()).toBe(
      false,
    );
  });

  it("connects contact errors to their corresponding controls", async () => {
    const { wrapper } = await mountCustomerFields({
      customerName: "Informe o nome do cliente.",
      customerPhone: "Informe o WhatsApp do cliente.",
      customerEmail: "Informe um e-mail válido.",
      items: {},
    });

    expect(
      wrapper.get('input[name="customerName"]').attributes("aria-invalid"),
    ).toBe("true");
    expect(
      wrapper.get('input[name="customerPhone"]').attributes("aria-invalid"),
    ).toBe("true");
    expect(
      wrapper.get('input[name="customerEmail"]').attributes("aria-invalid"),
    ).toBe("true");
  });

  it("shows loading immediately and searches only after typing pauses", async () => {
    const { wrapper } = await mountCustomerFields();
    vi.useFakeTimers();
    const input = wrapper.get('input[name="customerName"]');

    await input.setValue("M");
    expect(input.attributes("aria-busy")).toBe("true");
    expect(wrapper.find(".customer-lookup__loader").exists()).toBe(true);
    expect(wrapper.get(".customer-lookup__status").text()).toBe(
      "Buscando clientes…",
    );

    await vi.advanceTimersByTimeAsync(300);
    await input.setValue("Marina");
    await vi.advanceTimersByTimeAsync(499);
    expect(mocks.searchCustomers).not.toHaveBeenCalled();
    expect(input.attributes("aria-busy")).toBe("true");

    await vi.advanceTimersByTimeAsync(1);
    await flushPromises();
    expect(mocks.searchCustomers).toHaveBeenCalledOnce();
    expect(mocks.searchCustomers).toHaveBeenCalledWith(mocks.client, "Marina");
    expect(input.attributes("aria-busy")).toBe("false");
  });

  it("ends the pending state without searching for a one-character name", async () => {
    const { wrapper } = await mountCustomerFields();
    vi.useFakeTimers();
    const input = wrapper.get('input[name="customerName"]');

    await input.setValue("M");
    expect(input.attributes("aria-busy")).toBe("true");
    await vi.advanceTimersByTimeAsync(500);

    expect(mocks.searchCustomers).not.toHaveBeenCalled();
    expect(input.attributes("aria-busy")).toBe("false");
    expect(wrapper.find(".customer-lookup__loader").exists()).toBe(false);
  });

  it("keeps a late response from replacing the latest customer results", async () => {
    let resolveFirst:
      ((value: Array<{ id: string; name: string }>) => void) | undefined;
    mocks.searchCustomers
      .mockImplementationOnce(
        () =>
          new Promise((resolve) => {
            resolveFirst = resolve;
          }),
      )
      .mockResolvedValueOnce([
        {
          id: "latest-customer",
          name: "Marina Costa",
          phone: "(47) 99999-1111",
          email: "marina@example.com",
          emailVerified: false,
        },
      ]);
    const { wrapper } = await mountCustomerFields();
    vi.useFakeTimers();
    const input = wrapper.get('input[name="customerName"]');

    await input.setValue("Ma");
    await vi.advanceTimersByTimeAsync(500);
    await input.setValue("Marina");
    await vi.advanceTimersByTimeAsync(500);
    await flushPromises();
    expect(wrapper.text()).toContain("Marina Costa");

    resolveFirst?.([{ id: "stale", name: "Maria Antiga" }]);
    await flushPromises();
    expect(wrapper.text()).toContain("Marina Costa");
    expect(wrapper.text()).not.toContain("Maria Antiga");
  });

  it("prefills contact data and clears lookup state when a customer is selected", async () => {
    mocks.searchCustomers.mockResolvedValue([
      {
        id: "customer-id",
        name: "Marina Costa",
        phone: "(47) 99999-1111",
        email: "marina@example.com",
        emailVerified: false,
      },
    ]);
    const { quote, wrapper } = await mountCustomerFields();
    vi.useFakeTimers();
    const input = wrapper.get('input[name="customerName"]');

    await input.setValue("Marina");
    await vi.advanceTimersByTimeAsync(500);
    await flushPromises();
    const dirtyBeforeSelection = wrapper.emitted("dirty")?.length ?? 0;
    await wrapper.get(".customer-lookup__results button").trigger("click");

    expect(quote).toMatchObject({
      customerId: "customer-id",
      customerName: "Marina Costa",
      customerPhone: "(47) 99999-1111",
      customerEmail: "marina@example.com",
    });
    expect(wrapper.find(".customer-lookup__results").exists()).toBe(false);
    expect(wrapper.text()).toContain("Cliente existente selecionado");
    expect(wrapper.emitted("dirty")).toHaveLength(dirtyBeforeSelection + 1);
  });

  it("clears loading after a failed search and keeps manual entry available", async () => {
    mocks.searchCustomers.mockRejectedValue(new Error("network unavailable"));
    const { wrapper } = await mountCustomerFields();
    vi.useFakeTimers();
    const input = wrapper.get('input[name="customerName"]');

    await input.setValue("Marina");
    await vi.advanceTimersByTimeAsync(500);
    await flushPromises();

    expect(input.attributes("aria-busy")).toBe("false");
    expect(wrapper.text()).toContain("Não foi possível buscar seus clientes.");
    expect(
      wrapper.get('input[name="customerPhone"]').attributes("disabled"),
    ).toBeUndefined();
  });
});
