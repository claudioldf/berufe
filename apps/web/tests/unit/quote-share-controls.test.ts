import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import QuoteBuilder from "~/components/dashboard/QuoteBuilder.vue";
import type { Quote, QuoteProfessional } from "~/types";

const quote: Quote = {
  id: "4ec62fe9-f61a-4df0-967f-628cd9a05486",
  number: 12,
  customerName: "Ana Paula",
  serviceDescription: "Iluminação da cozinha",
  validUntil: "2026-08-25",
  discount: 0,
  notes: "",
  status: "draft",
  subtotal: 100,
  total: 100,
  sharedAt: null,
  createdAt: "2026-08-18T12:00:00Z",
  updatedAt: "2026-08-18T12:00:00Z",
  items: [
    {
      id: "0cfa24cf-dd67-4ff5-b0ea-e9812fa97766",
      description: "Instalação",
      quantity: 1,
      unit: "serviço",
      unitPrice: 100,
      lineTotal: 100,
      sortOrder: 0,
    },
  ],
};
const professional: QuoteProfessional = {
  name: "Ana Souza",
  avatar: null,
  primaryService: "Eletricista",
  identityVerified: true,
};
const ModalStub = defineComponent({
  template: '<div><slot name="body" /><slot name="footer" /></div>',
});
const ButtonStub = defineComponent({
  props: { disabled: Boolean, loading: Boolean },
  emits: ["click"],
  template:
    '<button :disabled="disabled" @click="$emit(\'click\')"><slot /></button>',
});

describe("quote share controls", () => {
  it("keeps copy and WhatsApp as explicit user-selected actions", async () => {
    const wrapper = mount(QuoteBuilder, {
      props: {
        initialQuote: quote,
        professional,
        saving: false,
        saveError: "",
        sharingMethod: null,
        shareError: "",
        shareUrl: "",
        shareEnabled: true,
      },
      global: {
        stubs: {
          DashboardQuoteCustomerFields: true,
          DashboardQuoteLineItemsEditor: true,
          DashboardQuoteNotesField: true,
          DashboardQuoteSaveBar: true,
          QuotesQuotePreview: true,
          UModal: ModalStub,
          UButton: ButtonStub,
          UIcon: true,
        },
      },
    });
    const buttons = wrapper.findAll("button");
    const copy = buttons.find((button) => button.text() === "Copiar link");
    const whatsapp = buttons.find(
      (button) => button.text() === "Abrir WhatsApp",
    );

    await copy?.trigger("click");
    await whatsapp?.trigger("click");

    expect(wrapper.emitted("share")).toEqual([["copy"], ["whatsapp"]]);
  });
});
