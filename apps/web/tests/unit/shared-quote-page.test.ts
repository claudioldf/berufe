import { mountSuspended } from "@nuxt/test-utils/runtime";
import { flushPromises } from "@vue/test-utils";
import { defineComponent } from "vue";
import SharedQuotePage from "@app/pages/orcamento/[token].vue";
import type { SharedQuoteResult } from "@app/services/api/shared-quotes";

const mocks = vi.hoisted(() => ({
  client: {},
  resolveQuote: vi.fn(),
  decideQuote: vi.fn(),
}));

vi.mock("@app/services/api/client", () => ({
  useApiClient: () => mocks.client,
}));
vi.mock("@app/services/api/shared-quotes", () => ({
  resolveSharedQuote: mocks.resolveQuote,
  decideSharedQuote: mocks.decideQuote,
}));

const token = "bq_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
const result: SharedQuoteResult = {
  quote: {
    id: null,
    number: 12,
    revision: 2,
    customerId: null,
    customerName: "Marina Oliveira",
    customerPhone: "",
    customerEmail: "",
    serviceDescription: "Instalação de luminárias",
    serviceAddress: "Rua das Flores, 10",
    scheduledOn: "2026-09-08",
    validUntil: "2026-09-30",
    discount: 0,
    notes: "",
    status: "shared",
    subtotal: 300,
    total: 300,
    sharedAt: null,
    createdAt: null,
    updatedAt: null,
    customerDecisionMessage: "",
    changeRequests: [],
    serviceJob: null,
    items: [
      {
        id: "shared-12-0",
        description: "Instalação",
        quantity: 1,
        unit: "serviço",
        unitPrice: 300,
        lineTotal: 300,
        sortOrder: 0,
      },
    ],
  },
  professional: {
    name: "Claudio Dias",
    avatar: null,
    primaryService: "Eletricista",
    identityVerified: true,
  },
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

async function mountPage() {
  const wrapper = await mountSuspended(SharedQuotePage, {
    shallow: false,
    route: `/orcamento/${token}`,
    global: {
      renderStubDefaultSlot: true,
      stubs: {
        DesignSystemBrand: true,
        DesignSystemContainer: SlotStub,
        DesignSystemEyebrow: SlotStub,
        QuotesQuotePreview: true,
        UButton: ButtonStub,
        UIcon: true,
      },
    },
  });
  await flushPromises();
  return wrapper;
}

function actionButton(
  wrapper: Awaited<ReturnType<typeof mountPage>>,
  label: string,
) {
  return wrapper.findAll("button").find((button) => button.text() === label)!;
}

describe("shared quote decision form", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    clearNuxtData();
    mocks.resolveQuote.mockResolvedValue(result);
    mocks.decideQuote.mockResolvedValue(result);
  });

  it("keeps change requests available and validates their message inline", async () => {
    const wrapper = await mountPage();
    const requestChanges = actionButton(wrapper, "Solicitar alterações");
    const approve = actionButton(wrapper, "Aprovar orçamento");
    const message = wrapper.get("textarea");
    const terms = wrapper.get('input[type="checkbox"]');

    expect(requestChanges.attributes("disabled")).toBeUndefined();
    expect(approve.attributes("disabled")).toBeUndefined();

    await requestChanges.trigger("click");

    expect(mocks.decideQuote).not.toHaveBeenCalled();
    expect(message.attributes("aria-invalid")).toBe("true");
    expect(message.attributes("aria-describedby")).toBe(
      "quote-decision-message-error",
    );
    expect(wrapper.text()).toContain("Explique o que precisa ser alterado.");
    expect(terms.attributes("aria-invalid")).toBe("false");

    await message.setValue("Trocar as luminárias por luz quente.");
    expect(wrapper.text()).not.toContain(
      "Explique o que precisa ser alterado.",
    );

    await requestChanges.trigger("click");
    await flushPromises();

    expect(mocks.decideQuote).toHaveBeenCalledWith(mocks.client, token, {
      kind: "request_change",
      revision: 2,
      termsAccepted: false,
      message: "Trocar as luminárias por luz quente.",
    });
  });

  it("keeps approval available and validates acceptance inline", async () => {
    const wrapper = await mountPage();
    const approve = actionButton(wrapper, "Aprovar orçamento");
    const terms = wrapper.get('input[type="checkbox"]');
    const message = wrapper.get("textarea");

    await approve.trigger("click");

    expect(mocks.decideQuote).not.toHaveBeenCalled();
    expect(terms.attributes("aria-invalid")).toBe("true");
    expect(terms.attributes("aria-describedby")).toBe(
      "quote-terms-accepted-error",
    );
    expect(wrapper.text()).toContain(
      "Confirme que você revisou o escopo, o valor e a validade.",
    );
    expect(message.attributes("aria-invalid")).toBe("false");

    await terms.setValue(true);
    expect(wrapper.text()).not.toContain(
      "Confirme que você revisou o escopo, o valor e a validade.",
    );

    await approve.trigger("click");
    await flushPromises();

    expect(mocks.decideQuote).toHaveBeenCalledWith(mocks.client, token, {
      kind: "approve",
      revision: 2,
      termsAccepted: true,
      message: "",
    });
  });

  it("places the destructive decline action on the left", async () => {
    const wrapper = await mountPage();
    const actions = wrapper
      .get(".shared-quote-page__actions")
      .findAll("button");

    expect(actions.map((button) => button.text())).toEqual([
      "Recusar",
      "Solicitar alterações",
      "Aprovar orçamento",
    ]);
    expect(actions[0]?.attributes("color")).toBe("error");
  });
});
