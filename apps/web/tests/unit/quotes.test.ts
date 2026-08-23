import { describe, expect, it } from "vitest";
import type { Quote } from "~/types";
import { useQuoteDraft } from "~/composables/useQuoteDraft";
import {
  cloneQuote,
  isQuoteValid,
  quoteSubtotal,
  quoteTotal,
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
});
