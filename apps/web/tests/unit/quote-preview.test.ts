import { mount } from "@vue/test-utils";
import QuotePreview from "~/components/quotes/QuotePreview.vue";
import type { Quote, QuoteProfessional } from "~/types";

const quote: Quote = {
  id: null,
  number: 12,
  revision: 2,
  customerId: null,
  customerName: "Ana Paula",
  customerPhone: "",
  customerEmail: "",
  pricingMode: "itemized",
  serviceDescription: "Iluminação da cozinha",
  serviceAddress: "",
  scheduledOn: "",
  validUntil: "2026-08-25",
  discount: 0,
  markup: 0,
  notes: "",
  status: "shared",
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
      id: "shared-12-0",
      description: "Material A",
      quantity: 0.333,
      unit: "unidade",
      unitPrice: 0.01,
      lineTotal: 0,
      sortOrder: 0,
    },
    {
      id: "shared-12-1",
      description: "Material B",
      quantity: 0.333,
      unit: "unidade",
      unitPrice: 0.01,
      lineTotal: 0,
      sortOrder: 1,
    },
  ],
  customerSuppliedMaterials: [],
};
const professional: QuoteProfessional = {
  name: "Ana Souza",
  avatar: null,
  primaryService: "Eletricista",
  identityVerified: false,
};
const global = {
  stubs: {
    DesignSystemAvatar: { template: "<span />" },
    UIcon: { template: "<span />" },
  },
};

describe("quote customer preview", () => {
  it("uses Rails-calculated amounts on the bearer-private customer page", () => {
    const browserPreview = mount(QuotePreview, {
      props: { quote, professional },
      global,
    });
    const customerPreview = mount(QuotePreview, {
      props: { quote, professional, authoritativeTotals: true },
      global,
    });

    expect(browserPreview.get(".quote-preview__totals").text()).toContain(
      "R$ 0,01",
    );
    expect(customerPreview.get(".quote-preview__totals").text()).not.toContain(
      "R$ 0,01",
    );
  });

  it("shows identity claims only for an actually approved identity", () => {
    const unverified = mount(QuotePreview, {
      props: { quote, professional },
      global,
    });
    const verified = mount(QuotePreview, {
      props: {
        quote,
        professional: { ...professional, identityVerified: true },
      },
      global,
    });

    expect(unverified.text()).not.toContain("Identidade verificada");
    expect(verified.text().match(/Identidade verificada/g)).toHaveLength(2);
  });

  it("uses clear customer, schedule, and legal copy", () => {
    const wrapper = mount(QuotePreview, {
      props: {
        quote: { ...quote, scheduledOn: "2026-08-22" },
        professional,
      },
      global,
    });

    expect(wrapper.text()).toContain("Cliente");
    expect(wrapper.text()).toContain("Data prevista do serviço");
    expect(wrapper.text()).toContain(
      "Este orçamento não é um contrato nem um comprovante de pagamento.",
    );
    expect(wrapper.text()).not.toContain("Preparado para");
    expect(wrapper.text()).not.toContain("Data combinada");
  });

  it("shows only one customer price for a fixed quote and lists required materials", () => {
    const wrapper = mount(QuotePreview, {
      props: {
        quote: {
          ...quote,
          pricingMode: "fixed_price",
          subtotal: 1700,
          markup: 400,
          discount: 100,
          total: 2000,
          items: quote.items.map((item, index) => ({
            ...item,
            description: `Custo reservado ${index + 1}`,
          })),
          customerSuppliedMaterials: [
            {
              id: "material-1",
              description: "Tinta acrílica branca 18 L",
              quantity: 2,
              unit: "lata",
              sortOrder: 0,
            },
            {
              id: "material-2",
              description: "Lixa para parede",
              quantity: 10,
              unit: "folha",
              sortOrder: 1,
            },
          ],
        },
        professional,
        authoritativeTotals: true,
      },
      global,
    });

    expect(wrapper.text()).toContain("Valor do serviço");
    expect(wrapper.text()).toContain("R$ 2.000,00");
    expect(wrapper.text()).toContain("2 lata");
    expect(wrapper.text()).toContain("Tinta acrílica branca 18 L");
    expect(wrapper.text()).not.toContain("Custo reservado");
    expect(wrapper.text()).not.toContain("Subtotal");
    expect(wrapper.text()).not.toContain("Desconto");
    expect(wrapper.text()).not.toContain("R$ 1.700,00");
  });
});
