import { describe, expect, it } from "vitest";
import quotesData from "@data/quotes.json";
import type { Quote } from "~/types";
import { useQuoteDraft } from "~/composables/useQuoteDraft";
import {
  cloneQuote,
  isQuoteValid,
  quoteSubtotal,
  quoteTotal,
} from "~/utils/quotes";

const source = quotesData.default as Quote;

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
});
