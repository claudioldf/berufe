import { mount } from "@vue/test-utils";
import { defineComponent, nextTick, reactive } from "vue";
import LineItemsEditor from "~/components/dashboard/quote/LineItemsEditor.vue";
import type { Quote } from "~/types";
import { quoteItemsAmount, quoteSubtotal, validateQuote } from "~/utils/quotes";

const SurfaceCardStub = defineComponent({
  template: "<section><slot /></section>",
});
const ButtonStub = defineComponent({
  emits: ["click"],
  template: "<button @click=\"$emit('click')\"><slot /></button>",
});

function createQuote(): Quote {
  return reactive({
    id: null,
    number: null,
    revision: 0,
    customerId: null,
    customerName: "Ana Cliente",
    customerPhone: "(47) 99999-2222",
    customerEmail: "",
    serviceDescription: "Instalação elétrica",
    serviceAddress: "",
    scheduledOn: "",
    validUntil: "2026-09-28",
    pricingMode: "itemized",
    lumpSumAmount: null,
    itemsVisibleToCustomer: true,
    itemsAmount: 0,
    discount: -1,
    notes: "",
    status: "draft",
    subtotal: 0,
    total: 0,
    sharedAt: null,
    createdAt: null,
    updatedAt: null,
    customerDecisionMessage: "",
    changeRequests: [],
    serviceJob: null,
    items: [
      {
        id: "draft-item",
        description: "",
        quantity: 0,
        unit: "",
        unitPrice: -1,
        lineTotal: 0,
        sortOrder: 0,
      },
    ],
    materials: [],
  }) as Quote;
}

function mountEditor(quote: Quote) {
  return mount(LineItemsEditor, {
    props: {
      modelValue: quote,
      subtotal: quoteSubtotal(quote),
      itemsAmount: quoteItemsAmount(quote),
      errors: validateQuote(quote),
    },
    global: {
      stubs: {
        DesignSystemSurfaceCard: SurfaceCardStub,
        UButton: ButtonStub,
        UIcon: true,
      },
    },
  });
}

describe("quote line item validation", () => {
  it("renders inline errors and invalid state for item values and discount", () => {
    const wrapper = mountEditor(createQuote());

    expect(
      wrapper
        .get('input[name="item-draft-item-description"]')
        .attributes("aria-invalid"),
    ).toBe("true");
    expect(
      wrapper
        .get('input[name="item-draft-item-quantity"]')
        .attributes("aria-invalid"),
    ).toBe("true");
    expect(
      wrapper
        .get('select[name="item-draft-item-unit"]')
        .attributes("aria-invalid"),
    ).toBe("true");
    expect(
      wrapper
        .get('input[name="item-draft-item-unit-price"]')
        .attributes("aria-invalid"),
    ).toBe("true");
    expect(
      wrapper.get('input[name="discount"]').attributes("aria-invalid"),
    ).toBe("true");
    expect(wrapper.text()).toContain("Item 1");
    expect(wrapper.text()).toContain("Descrição do item 1");
    expect(wrapper.text()).toContain("Total do item 1");
    expect(wrapper.text()).toContain("Descreva este item.");
    expect(wrapper.text()).toContain("Informe um desconto válido.");
  });

  it("only shows item delete buttons when more than one item exists", async () => {
    const quote = createQuote();
    const wrapper = mountEditor(quote);

    expect(wrapper.find('[aria-label="Remover item 1"]').exists()).toBe(false);

    quote.items.push({
      ...quote.items[0],
      id: "second-draft-item",
      sortOrder: 1,
    });
    await nextTick();

    expect(wrapper.find('[aria-label="Remover item 1"]').exists()).toBe(true);
    expect(wrapper.find('[aria-label="Remover item 2"]').exists()).toBe(true);
  });

  it("switches between the itemized and closed-price layouts", async () => {
    const quote = createQuote();
    const wrapper = mountEditor(quote);

    expect(wrapper.find('input[name="discount"]').exists()).toBe(true);
    expect(wrapper.find('input[name="lump-sum-amount"]').exists()).toBe(false);

    quote.pricingMode = "lump_sum";
    await nextTick();

    expect(wrapper.find('input[name="discount"]').exists()).toBe(false);
    expect(wrapper.find('input[name="lump-sum-amount"]').exists()).toBe(true);
    expect(wrapper.text()).toContain("Cálculo interno");
  });

  it("emits a pricing-mode change when the closed-price option is selected", async () => {
    const wrapper = mountEditor(createQuote());

    await wrapper.find('input[type="radio"][value="lump_sum"]').setValue();

    expect(wrapper.emitted("setPricingMode")).toEqual([["lump_sum"]]);
  });
});
