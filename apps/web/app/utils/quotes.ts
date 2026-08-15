import type { Quote, QuoteItem } from "~/types";

export function cloneQuote(quote: Quote): Quote {
  return {
    ...quote,
    items: quote.items.map((item) => ({ ...item })),
  };
}

export function quoteItemTotal(item: QuoteItem) {
  return Number(item.quantity) * Number(item.unitPrice);
}

export function quoteSubtotal(quote: Quote) {
  return quote.items.reduce((sum, item) => sum + quoteItemTotal(item), 0);
}

export function quoteTotal(quote: Quote) {
  return Math.max(0, quoteSubtotal(quote) - Number(quote.discount));
}

export function isQuoteValid(quote: Quote) {
  const subtotal = quoteSubtotal(quote);
  return (
    quote.customerName.trim().length > 0 &&
    quote.serviceDescription.trim().length > 0 &&
    quote.items.length > 0 &&
    quote.items.every(
      (item) =>
        item.description.trim().length > 0 &&
        Number.isFinite(Number(item.quantity)) &&
        Number(item.quantity) > 0 &&
        Number.isFinite(Number(item.unitPrice)) &&
        Number(item.unitPrice) >= 0,
    ) &&
    Number.isFinite(Number(quote.discount)) &&
    Number(quote.discount) >= 0 &&
    Number(quote.discount) <= subtotal
  );
}
