import { mount } from "@vue/test-utils";
import QuotePreview from "~/components/quotes/QuotePreview.vue";
import type { Quote, QuoteProfessional } from "~/types";

const quote: Quote = {
  id: null,
  number: 12,
  revision: 0,
  customerId: null,
  customerName: "Ana Paula",
  customerPhone: "",
  customerEmail: "",
  serviceDescription: "Iluminação da cozinha",
  serviceAddress: "",
  scheduledOn: "",
  validUntil: "2026-08-25",
  pricingMode: "itemized",
  lumpSumAmount: null,
  itemsVisibleToCustomer: true,
  itemsAmount: 0,
  discount: 0,
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
  materials: [],
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

  it("shows only the closed price when the breakdown is hidden", () => {
    const wrapper = mount(QuotePreview, {
      props: {
        quote: {
          ...quote,
          pricingMode: "lump_sum",
          itemsVisibleToCustomer: false,
          subtotal: 2000,
          total: 2000,
        },
        professional,
        authoritativeTotals: true,
      },
      global,
    });

    expect(wrapper.find(".quote-preview__items").exists()).toBe(false);
    const totalsText = wrapper
      .get(".quote-preview__totals")
      .text()
      .replace(/\s/g, " ");
    expect(totalsText).toContain("Valor do serviço");
    expect(totalsText).toContain("R$ 2.000,00");
  });

  it("shows scope without any price when the breakdown is visible", () => {
    const wrapper = mount(QuotePreview, {
      props: {
        quote: {
          ...quote,
          pricingMode: "lump_sum",
          itemsVisibleToCustomer: true,
          subtotal: 2000,
          total: 2000,
        },
        professional,
        authoritativeTotals: true,
      },
      global,
    });
    const items = wrapper.get(".quote-preview__items");

    expect(items.text()).toContain("Material A");
    expect(items.text()).not.toContain("R$");
  });

  it("lists materials without any price, separate from the priced total", () => {
    const wrapper = mount(QuotePreview, {
      props: {
        quote: {
          ...quote,
          materials: [
            {
              id: "material-1",
              description: "Tinta acrílica fosca 18L",
              quantity: 2,
              unit: "lata",
              sortOrder: 0,
            },
          ],
        },
        professional,
      },
      global,
    });
    const materials = wrapper.get(".quote-preview__materials");

    expect(materials.text()).toContain("Tinta acrílica fosca 18L");
    expect(materials.text()).toContain(
      "A compra dos materiais é por conta do cliente.",
    );
    expect(materials.text()).not.toContain("R$");
  });
});
