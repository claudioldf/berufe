import type {
  Quote,
  QuoteItem,
  QuoteItemValidationErrors,
  QuoteMaterialValidationErrors,
  QuoteValidationErrors,
} from "~/types";
import { normalizeBrazilianMobilePhone } from "~/utils/brazilian-phone";

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const INPUT_DATE_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;

export function cloneQuote(quote: Quote): Quote {
  return {
    ...quote,
    changeRequests: quote.changeRequests.map((request) => ({ ...request })),
    items: quote.items.map((item) => ({ ...item })),
    materials: quote.materials.map((material) => ({ ...material })),
  };
}

export function quoteItemTotal(item: QuoteItem) {
  return Number(item.quantity) * Number(item.unitPrice);
}

// The professional's private reference calculation: the sum of any entered
// line items. In `lump_sum` mode this is never the quote's price — it exists
// only to help the professional reach one — and it is never shown to the
// customer.
export function quoteItemsAmount(quote: Quote) {
  return quote.items.reduce((sum, item) => sum + quoteItemTotal(item), 0);
}

export function quoteSubtotal(quote: Quote) {
  return quote.pricingMode === "lump_sum"
    ? Number(quote.lumpSumAmount ?? 0)
    : quoteItemsAmount(quote);
}

export function quoteTotal(quote: Quote) {
  if (quote.pricingMode === "lump_sum")
    return Math.max(0, quoteSubtotal(quote));
  return Math.max(0, quoteSubtotal(quote) - Number(quote.discount));
}

// Positive when the typed price is above the private calculation, negative
// when below. Purely a reference for the professional; never sent or shown
// to the customer.
export function quoteLumpSumDelta(quote: Quote) {
  return Number(quote.lumpSumAmount ?? 0) - quoteItemsAmount(quote);
}

export function quoteDateAfterDays(days: number, from = new Date()) {
  const date = new Date(from);
  date.setDate(date.getDate() + days);

  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export function withDefaultQuoteValidity(quote: Quote, from = new Date()) {
  if (quote.validUntil.trim()) return quote;
  return { ...quote, validUntil: quoteDateAfterDays(30, from) };
}

export function isValidQuoteInputDate(value: string) {
  const match = INPUT_DATE_PATTERN.exec(value);
  if (!match) return false;

  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  const date = new Date(Date.UTC(year, month - 1, day));

  return (
    date.getUTCFullYear() === year &&
    date.getUTCMonth() === month - 1 &&
    date.getUTCDate() === day
  );
}

export function validateQuote(quote: Quote): QuoteValidationErrors {
  const isLumpSum = quote.pricingMode === "lump_sum";
  const subtotal = quoteSubtotal(quote);
  const errors: QuoteValidationErrors = { items: {}, materials: {} };
  const customerName = quote.customerName.trim();
  const customerEmail = quote.customerEmail.trim();
  const serviceDescription = quote.serviceDescription.trim();

  if (!customerName) errors.customerName = "Informe o nome do cliente.";
  else if (customerName.length > 80) {
    errors.customerName = "Use no máximo 80 caracteres.";
  }

  if (!quote.customerPhone.trim()) {
    errors.customerPhone = "Informe o WhatsApp do cliente.";
  } else if (!normalizeBrazilianMobilePhone(quote.customerPhone)) {
    errors.customerPhone = "Informe um celular brasileiro válido com DDD.";
  }

  if (customerEmail && !EMAIL_PATTERN.test(customerEmail)) {
    errors.customerEmail = "Informe um e-mail válido.";
  } else if (customerEmail.length > 254) {
    errors.customerEmail = "Use no máximo 254 caracteres.";
  }

  if (!quote.validUntil.trim()) {
    errors.validUntil = "Informe até quando o orçamento é válido.";
  } else if (!isValidQuoteInputDate(quote.validUntil)) {
    errors.validUntil = "Informe uma data válida.";
  }

  if (quote.scheduledOn && !isValidQuoteInputDate(quote.scheduledOn)) {
    errors.scheduledOn = "Informe uma data válida.";
  }

  if (!serviceDescription) {
    errors.serviceDescription = "Descreva o serviço.";
  } else if (serviceDescription.length > 160) {
    errors.serviceDescription = "Use no máximo 160 caracteres.";
  }

  if (quote.serviceAddress.length > 240) {
    errors.serviceAddress = "Use no máximo 240 caracteres.";
  }

  if (isLumpSum) {
    const lumpSumAmount = Number(quote.lumpSumAmount);
    const lumpSumAmountIsBlank =
      String(quote.lumpSumAmount ?? "").trim() === "";
    if (
      lumpSumAmountIsBlank ||
      !Number.isFinite(lumpSumAmount) ||
      lumpSumAmount < 0
    ) {
      errors.lumpSumAmount = "Informe o valor do serviço.";
    }
  } else if (!quote.items.length) {
    errors.itemsMessage = "Adicione pelo menos um item ao orçamento.";
  }

  for (const item of quote.items) {
    const itemErrors: QuoteItemValidationErrors = {};
    const quantity = Number(item.quantity);
    const unitPrice = Number(item.unitPrice);
    const quantityIsBlank = String(item.quantity).trim() === "";
    const unitPriceIsBlank = String(item.unitPrice).trim() === "";

    if (!item.description.trim()) {
      itemErrors.description = "Descreva este item.";
    } else if (item.description.trim().length > 160) {
      itemErrors.description = "Use no máximo 160 caracteres.";
    }
    if (quantityIsBlank || !Number.isFinite(quantity) || quantity <= 0) {
      itemErrors.quantity = "Informe uma quantidade maior que zero.";
    }
    if (!item.unit.trim()) itemErrors.unit = "Selecione a unidade.";
    if (unitPriceIsBlank || !Number.isFinite(unitPrice) || unitPrice < 0) {
      itemErrors.unitPrice = "Informe um valor igual ou maior que zero.";
    }

    if (Object.keys(itemErrors).length) errors.items[item.id] = itemErrors;
  }

  if (!isLumpSum) {
    const discount = Number(quote.discount);
    if (
      String(quote.discount).trim() === "" ||
      !Number.isFinite(discount) ||
      discount < 0
    ) {
      errors.discount = "Informe um desconto válido.";
    } else if (discount > subtotal) {
      errors.discount = "O desconto não pode ultrapassar o subtotal.";
    }
  }

  for (const material of quote.materials) {
    const materialErrors: QuoteMaterialValidationErrors = {};
    const quantity = Number(material.quantity);
    const quantityIsBlank = String(material.quantity).trim() === "";

    if (!material.description.trim()) {
      materialErrors.description = "Descreva este material.";
    } else if (material.description.trim().length > 160) {
      materialErrors.description = "Use no máximo 160 caracteres.";
    }
    if (quantityIsBlank || !Number.isFinite(quantity) || quantity <= 0) {
      materialErrors.quantity = "Informe uma quantidade maior que zero.";
    }
    if (!material.unit.trim()) materialErrors.unit = "Selecione a unidade.";

    if (Object.keys(materialErrors).length) {
      errors.materials[material.id] = materialErrors;
    }
  }

  if (quote.notes.length > 700) {
    errors.notes = "Use no máximo 700 caracteres.";
  }

  return errors;
}

export function hasQuoteValidationErrors(errors: QuoteValidationErrors) {
  return (
    Object.keys(errors).some((key) => key !== "items" && key !== "materials") ||
    Object.keys(errors.items).length > 0 ||
    Object.keys(errors.materials).length > 0
  );
}

export function isQuoteValid(quote: Quote) {
  return !hasQuoteValidationErrors(validateQuote(quote));
}
