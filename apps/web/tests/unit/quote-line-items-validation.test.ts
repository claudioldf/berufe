import { mount } from "@vue/test-utils";
import { defineComponent, nextTick, reactive } from "vue";
import LineItemsEditor from "~/components/dashboard/quote/LineItemsEditor.vue";
import type { Quote } from "~/types";
import { quoteSubtotal, validateQuote } from "~/utils/quotes";

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
    pricingMode: "itemized",
    serviceDescription: "Instalação elétrica",
    serviceAddress: "",
    scheduledOn: "",
    validUntil: "2026-09-28",
    discount: -1,
    fixedPrice: 0,
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
    customerSuppliedMaterials: [],
  }) as Quote;
}

function mountEditor(quote: Quote) {
  return mount(LineItemsEditor, {
    props: {
      modelValue: quote,
      subtotal: quoteSubtotal(quote),
      total: quoteSubtotal(quote),
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

  it("explains and edits an independent customer price in fixed-price mode", async () => {
    const quote = createQuote();
    quote.pricingMode = "fixed_price";
    quote.discount = 0;
    quote.fixedPrice = 2000;
    quote.items[0]!.description = "Mão de obra";
    quote.items[0]!.quantity = 1;
    quote.items[0]!.unit = "serviço";
    quote.items[0]!.unitPrice = 1700;
    const wrapper = mountEditor(quote);

    expect(wrapper.text()).toContain(
      "Os itens abaixo servem apenas para ajudar você a calcular o custo total do serviço.",
    );
    expect(wrapper.text()).toContain(
      "Eles não definem o preço do orçamento e não aparecem para o cliente.",
    );
    expect(wrapper.text()).toContain("Custo total (particular)");
    expect(wrapper.get('input[name="fixed-price"]').element.value).toBe("2000");
    expect(wrapper.text()).not.toContain("Acréscimo");
    expect(wrapper.find('input[name="discount"]').exists()).toBe(false);

    await wrapper.get('input[name="fixed-price"]').setValue("2250");
    expect(quote.fixedPrice).toBe(2250);
  });
});
