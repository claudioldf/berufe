import { mount } from "@vue/test-utils";
import { defineComponent, reactive } from "vue";
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

describe("quote line item validation", () => {
  it("renders inline errors and invalid state for item values and discount", () => {
    const quote = reactive({
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
    }) as Quote;
    const errors = validateQuote(quote);
    const wrapper = mount(LineItemsEditor, {
      props: {
        modelValue: quote,
        subtotal: quoteSubtotal(quote),
        errors,
      },
      global: {
        stubs: {
          DesignSystemSurfaceCard: SurfaceCardStub,
          UButton: ButtonStub,
          UIcon: true,
        },
      },
    });

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
});
