import { mount } from "@vue/test-utils";
import QuotePreview from "~/components/quotes/QuotePreview.vue";
import type { Quote, QuoteProfessional } from "~/types";

const quote: Quote = {
  id: null,
  number: 12,
  customerName: "Ana Paula",
  serviceDescription: "Iluminação da cozinha",
  validUntil: "2026-08-25",
  discount: 0,
  notes: "",
  status: "shared",
  subtotal: 0,
  total: 0,
  sharedAt: null,
  createdAt: null,
  updatedAt: null,
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
    expect(unverified.text()).not.toContain(
      "Identidade profissional conferida",
    );
    expect(verified.text()).toContain("Identidade verificada");
    expect(verified.text()).toContain("Identidade profissional conferida");
  });
});
