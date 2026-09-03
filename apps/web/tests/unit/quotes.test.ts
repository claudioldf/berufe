import { describe, expect, it } from "vitest";
import type { Quote } from "~/types";
import { useQuoteDraft } from "~/composables/useQuoteDraft";
import {
  cloneQuote,
  isQuoteValid,
  isValidQuoteInputDate,
  quoteDateAfterDays,
  quoteSubtotal,
  quoteTotal,
  validateQuote,
  withDefaultQuoteValidity,
} from "~/utils/quotes";

const source: Quote = {
  id: "0fd22016-3021-46cc-8e31-a83e2f2d9180",
  number: 1043,
  revision: 0,
  customerId: "a3f42858-40bc-4bda-bb66-35f32eece27c",
  customerName: "Ana Paula",
  customerPhone: "(47) 99999-1111",
  customerEmail: "ana@example.com",
  pricingMode: "itemized",
  serviceDescription: "Adequação elétrica",
  serviceAddress: "Rua das Flores, 10",
  scheduledOn: "2026-08-22",
  validUntil: "2026-08-25",
  discount: 75,
  fixedPrice: 0,
  notes: "Materiais a definir.",
  status: "draft",
  subtotal: 1520,
  total: 1445,
  sharedAt: null,
  createdAt: "2026-08-18T12:00:00Z",
  updatedAt: "2026-08-18T12:00:00Z",
  customerDecisionMessage: "",
  changeRequests: [],
  serviceJob: null,
  items: [
    {
      id: "9e918053-d334-45e2-ae6c-3eeb28240438",
      description: "Revisão do circuito",
      quantity: 1,
      unit: "serviço",
      unitPrice: 680,
      lineTotal: 680,
      sortOrder: 0,
    },
    {
      id: "14b9f55b-b03f-47f9-92f7-d28ca56a4cf2",
      description: "Pontos de iluminação",
      quantity: 4,
      unit: "ponto",
      unitPrice: 210,
      lineTotal: 840,
      sortOrder: 1,
    },
  ],
  customerSuppliedMaterials: [],
};

describe("quote utilities", () => {
  it("calculates subtotal, discounts, and a non-negative total", () => {
    const quote = cloneQuote(source);
    const subtotal = quote.items.reduce(
      (sum, item) => sum + item.quantity * item.unitPrice,
      0,
    );
    expect(quoteSubtotal(quote)).toBe(subtotal);
    expect(quoteTotal(quote)).toBe(Math.max(0, subtotal - quote.discount));
    quote.discount = subtotal + 1;
    expect(quoteTotal(quote)).toBe(0);
  });

  it("clones line items without mutating the source", () => {
    const clone = cloneQuote(source);
    clone.items[0]!.description = "Alterado";
    expect(source.items[0]!.description).not.toBe("Alterado");
  });

  it("validates customer, service, items, and discount constraints", () => {
    expect(isQuoteValid(source)).toBe(true);
    expect(isQuoteValid({ ...source, customerName: "" })).toBe(false);
    expect(
      isQuoteValid({ ...source, discount: quoteSubtotal(source) + 1 }),
    ).toBe(false);
  });

  it("returns field-level messages for invalid quote values", () => {
    const invalid = cloneQuote(source);
    invalid.customerName = "";
    invalid.customerPhone = "123";
    invalid.customerEmail = "email-inválido";
    invalid.validUntil = "2026-02-30";
    invalid.scheduledOn = "30/09/2026";
    invalid.serviceDescription = "";
    invalid.items[0]!.description = "";
    invalid.items[0]!.quantity = 0;
    invalid.items[0]!.unit = "";
    invalid.items[0]!.unitPrice = -1;
    invalid.discount = quoteSubtotal(invalid) + 1;

    expect(validateQuote(invalid)).toMatchObject({
      customerName: "Informe o nome do cliente.",
      customerPhone: "Informe um celular brasileiro válido com DDD.",
      customerEmail: "Informe um e-mail válido.",
      validUntil: "Informe uma data válida.",
      scheduledOn: "Informe uma data válida.",
      serviceDescription: "Descreva o serviço.",
      discount: "O desconto não pode ultrapassar o subtotal.",
      items: {
        [source.items[0]!.id]: {
          description: "Descreva este item.",
          quantity: "Informe uma quantidade maior que zero.",
          unit: "Selecione a unidade.",
          unitPrice: "Informe um valor igual ou maior que zero.",
        },
      },
    });
  });

  it("requires validity and strictly validates calendar dates", () => {
    expect(validateQuote({ ...source, validUntil: "" }).validUntil).toBe(
      "Informe até quando o orçamento é válido.",
    );
    expect(isValidQuoteInputDate("2028-02-29")).toBe(true);
    expect(isValidQuoteInputDate("2027-02-29")).toBe(false);
    expect(isValidQuoteInputDate("29/02/2028")).toBe(false);
  });

  it("defaults an empty validity to D+30 without replacing a saved date", () => {
    const from = new Date(2026, 7, 29, 12);
    expect(quoteDateAfterDays(30, from)).toBe("2026-09-28");
    expect(
      withDefaultQuoteValidity({ ...source, validUntil: "" }, from).validUntil,
    ).toBe("2026-09-28");
    expect(withDefaultQuoteValidity(source, from)).toBe(source);
  });

  it("keeps the fixed customer price independent from private costs", () => {
    const fixed = {
      ...cloneQuote(source),
      pricingMode: "fixed_price" as const,
      fixedPrice: 2000,
      discount: 0,
      items: [
        { ...source.items[0]!, quantity: 1, unitPrice: 1500 },
        { ...source.items[1]!, quantity: 1, unitPrice: 200 },
      ],
    };

    expect(quoteSubtotal(fixed)).toBe(1700);
    expect(quoteTotal(fixed)).toBe(2000);
    expect(validateQuote(fixed).discount).toBeUndefined();
  });

  it("validates every customer-supplied material without adding it to the price", () => {
    const quote = cloneQuote(source);
    quote.customerSuppliedMaterials = [
      {
        id: "material-1",
        description: "",
        quantity: 0,
        unit: "",
        sortOrder: 0,
      },
    ];

    expect(validateQuote(quote).materials["material-1"]).toEqual({
      description: "Descreva este material.",
      quantity: "Informe uma quantidade maior que zero.",
      unit: "Informe a unidade.",
    });
    expect(quoteTotal(quote)).toBe(source.total);
  });
});

describe("quote draft state", () => {
  it("starts a new quote as unsaved", () => {
    const draft = useQuoteDraft({
      ...source,
      id: null,
      number: null,
      createdAt: null,
      updatedAt: null,
    });

    expect(draft.isSaved.value).toBe(false);
  });

  it("owns item mutations and saved/shared state", () => {
    const draft = useQuoteDraft(source);
    expect(draft.isSaved.value).toBe(true);
    draft.addItem();
    expect(draft.quote.value.items).toHaveLength(source.items.length + 1);
    expect(draft.isSaved.value).toBe(false);
    draft.markShared();
    expect(draft.isShared.value).toBe(true);
    expect(draft.isSaved.value).toBe(true);
  });

  it("keeps a shared quote shared while its owner edits it", () => {
    const shared: Quote = {
      ...source,
      status: "shared",
      sharedAt: "2026-08-18T12:10:00Z",
    };
    const draft = useQuoteDraft(shared);

    draft.markDirty();

    expect(draft.isSaved.value).toBe(false);
    expect(draft.isShared.value).toBe(true);
  });

  it("confirms mode changes only when monetary values would be discarded", () => {
    const draft = useQuoteDraft(source);

    draft.requestPricingMode("fixed_price");
    expect(draft.pricingModeConfirmationOpen.value).toBe(true);
    expect(draft.quote.value.pricingMode).toBe("itemized");

    draft.confirmPricingModeChange();
    expect(draft.quote.value).toMatchObject({
      pricingMode: "fixed_price",
      fixedPrice: 0,
      discount: 0,
    });
    expect(draft.quote.value.items).toHaveLength(1);
    expect(draft.quote.value.items[0]?.unitPrice).toBe(0);
  });

  it("switches an unpriced draft immediately and preserves its materials", () => {
    const draft = useQuoteDraft({
      ...cloneQuote(source),
      items: [{ ...source.items[0]!, unitPrice: 0, lineTotal: 0 }],
      discount: 0,
      customerSuppliedMaterials: [
        {
          id: "material-1",
          description: "Lixa",
          quantity: 10,
          unit: "folha",
          sortOrder: 0,
        },
      ],
    });

    draft.requestPricingMode("fixed_price");

    expect(draft.pricingModeConfirmationOpen.value).toBe(false);
    expect(draft.quote.value.pricingMode).toBe("fixed_price");
    expect(draft.quote.value.customerSuppliedMaterials).toHaveLength(1);
  });
});
