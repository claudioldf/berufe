import { describe, expect, it } from "vitest";
import type { Quote } from "~/types";
import { useQuoteDraft } from "~/composables/useQuoteDraft";
import {
  cloneQuote,
  isQuoteValid,
  isValidQuoteInputDate,
  quoteDateAfterDays,
  quoteItemsAmount,
  quoteLumpSumDelta,
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
  serviceDescription: "Adequação elétrica",
  serviceAddress: "Rua das Flores, 10",
  scheduledOn: "2026-08-22",
  validUntil: "2026-08-25",
  pricingMode: "itemized",
  lumpSumAmount: null,
  itemsVisibleToCustomer: true,
  itemsAmount: 1520,
  discount: 75,
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
  materials: [
    {
      id: "6b46e3a1-3a0b-4d40-9b0a-2a6f7f2e5c11",
      description: "Fita isolante",
      quantity: 3,
      unit: "rolo",
      sortOrder: 0,
    },
  ],
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

  it("clones line items and materials without mutating the source", () => {
    const clone = cloneQuote(source);
    clone.items[0]!.description = "Alterado";
    clone.materials[0]!.description = "Alterado";
    expect(source.items[0]!.description).not.toBe("Alterado");
    expect(source.materials[0]!.description).not.toBe("Alterado");
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
});

describe("lump-sum pricing", () => {
  const lumpSum: Quote = {
    ...source,
    pricingMode: "lump_sum",
    lumpSumAmount: 2000,
    discount: 0,
  };

  it("prices the quote from the typed amount, not the item sum", () => {
    expect(quoteItemsAmount(lumpSum)).toBe(1520);
    expect(quoteSubtotal(lumpSum)).toBe(2000);
    expect(quoteTotal(lumpSum)).toBe(2000);
  });

  it("floors the total at zero for a negative typed amount", () => {
    expect(quoteTotal({ ...lumpSum, lumpSumAmount: -10 })).toBe(0);
  });

  it("reports the delta between the typed amount and the private calculation", () => {
    expect(quoteLumpSumDelta(lumpSum)).toBe(480);
    expect(quoteLumpSumDelta({ ...lumpSum, lumpSumAmount: 1000 })).toBe(-520);
  });

  it("requires a lump sum amount instead of a minimum item count", () => {
    const blank = { ...lumpSum, lumpSumAmount: null, items: [] };
    const errors = validateQuote(blank);
    expect(errors.lumpSumAmount).toBe("Informe o valor do serviço.");
    expect(errors.itemsMessage).toBeUndefined();
    expect(isQuoteValid(blank)).toBe(false);
  });

  it("makes the discount unavailable", () => {
    const errors = validateQuote({ ...lumpSum, discount: -5 });
    expect(errors.discount).toBeUndefined();
  });

  it("validates materials in both pricing modes", () => {
    const invalidMaterial = {
      ...lumpSum,
      materials: [
        { ...lumpSum.materials[0]!, description: "", quantity: 0, unit: "" },
      ],
    };
    expect(validateQuote(invalidMaterial).materials).toMatchObject({
      [lumpSum.materials[0]!.id]: {
        description: "Descreva este material.",
        quantity: "Informe uma quantidade maior que zero.",
        unit: "Selecione a unidade.",
      },
    });
    expect(isQuoteValid(invalidMaterial)).toBe(false);
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

  it("switches pricing mode, zeroing the discount and seeding the price", () => {
    const draft = useQuoteDraft(source);
    expect(draft.itemsAmount.value).toBe(1520);

    draft.setPricingMode("lump_sum");

    expect(draft.quote.value.pricingMode).toBe("lump_sum");
    expect(draft.quote.value.discount).toBe(0);
    expect(draft.quote.value.lumpSumAmount).toBe(1520);
    expect(draft.total.value).toBe(1520);
  });

  it("does not overwrite an already-typed lump sum amount when switching back", () => {
    const draft = useQuoteDraft(source);
    draft.setPricingMode("lump_sum");
    draft.quote.value.lumpSumAmount = 2000;
    draft.setPricingMode("itemized");
    draft.setPricingMode("lump_sum");

    expect(draft.quote.value.lumpSumAmount).toBe(2000);
  });

  it("applies the private calculation to the typed price on demand", () => {
    const draft = useQuoteDraft(source);
    draft.setPricingMode("lump_sum");
    draft.quote.value.lumpSumAmount = 2000;

    draft.applyItemsAmountToLumpSum();

    expect(draft.quote.value.lumpSumAmount).toBe(1520);
  });

  it("removes the last item only in lump_sum mode", () => {
    const draft = useQuoteDraft({ ...source, items: [source.items[0]!] });
    draft.removeItem(source.items[0]!.id);
    expect(draft.quote.value.items).toHaveLength(1);

    draft.setPricingMode("lump_sum");
    draft.removeItem(source.items[0]!.id);
    expect(draft.quote.value.items).toHaveLength(0);
  });

  it("adds and removes materials freely, down to zero", () => {
    const draft = useQuoteDraft(source);
    const [existing] = draft.quote.value.materials;
    draft.addMaterial();
    expect(draft.quote.value.materials).toHaveLength(2);

    draft.removeMaterial(existing!.id);
    draft.removeMaterial(draft.quote.value.materials[0]!.id);
    expect(draft.quote.value.materials).toHaveLength(0);
  });
});
