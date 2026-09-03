import { computed, ref, shallowRef, toValue, watch } from "vue";
import type { MaybeRefOrGetter } from "vue";
import type { Quote, QuotePricingMode } from "~/types";
import {
  cloneQuote,
  hasQuoteValidationErrors,
  quoteItemsAmount,
  quoteSubtotal,
  quoteTotal,
  validateQuote,
} from "~/utils/quotes";

export function useQuoteDraft(initialQuote: MaybeRefOrGetter<Quote>) {
  const quote = ref(cloneQuote(toValue(initialQuote)));
  const previewOpen = shallowRef(false);
  const isSaved = shallowRef(Boolean(toValue(initialQuote).id));
  const isShared = shallowRef(
    !["draft", "saved"].includes(toValue(initialQuote).status),
  );

  const subtotal = computed(() => quoteSubtotal(quote.value));
  const total = computed(() => quoteTotal(quote.value));
  const itemsAmount = computed(() => quoteItemsAmount(quote.value));
  const validation = computed(() => validateQuote(quote.value));
  const isValid = computed(() => !hasQuoteValidationErrors(validation.value));

  watch(
    () => [toValue(initialQuote).id, toValue(initialQuote).updatedAt],
    () => reset(),
  );

  function reset() {
    quote.value = cloneQuote(toValue(initialQuote));
    isSaved.value = Boolean(toValue(initialQuote).id);
    isShared.value = !["draft", "saved"].includes(toValue(initialQuote).status);
    previewOpen.value = false;
  }

  function markDirty() {
    isSaved.value = false;
  }

  function addItem() {
    quote.value.items.push({
      id: globalThis.crypto.randomUUID(),
      description: "",
      quantity: 1,
      unit: "serviço",
      unitPrice: 0,
      lineTotal: 0,
      sortOrder: quote.value.items.length,
    });
    markDirty();
  }

  function removeItem(id: string) {
    // Items are the customer-facing content in `itemized` mode, so at least
    // one must remain. In `lump_sum` mode they are an optional private
    // calculation and may go to zero.
    if (
      quote.value.pricingMode !== "lump_sum" &&
      quote.value.items.length === 1
    ) {
      return;
    }
    quote.value.items = quote.value.items.filter((item) => item.id !== id);
    markDirty();
  }

  function addMaterial() {
    quote.value.materials.push({
      id: globalThis.crypto.randomUUID(),
      description: "",
      quantity: 1,
      unit: "unidade",
      sortOrder: quote.value.materials.length,
    });
    markDirty();
  }

  function removeMaterial(id: string) {
    quote.value.materials = quote.value.materials.filter(
      (material) => material.id !== id,
    );
    markDirty();
  }

  function setPricingMode(mode: QuotePricingMode) {
    quote.value.pricingMode = mode;
    if (mode === "lump_sum") {
      // A closed price already reflects any negotiation, so the discount is
      // unavailable in this mode.
      quote.value.discount = 0;
      if (quote.value.lumpSumAmount === null) {
        quote.value.lumpSumAmount = quoteItemsAmount(quote.value);
      }
    }
    markDirty();
  }

  function applyItemsAmountToLumpSum() {
    quote.value.lumpSumAmount = quoteItemsAmount(quote.value);
    markDirty();
  }

  function markSaved() {
    isSaved.value = true;
  }

  function markShared() {
    isShared.value = true;
    isSaved.value = true;
  }

  return {
    quote,
    previewOpen,
    isSaved,
    isShared,
    subtotal,
    total,
    itemsAmount,
    validation,
    isValid,
    reset,
    markDirty,
    addItem,
    removeItem,
    addMaterial,
    removeMaterial,
    setPricingMode,
    applyItemsAmountToLumpSum,
    markSaved,
    markShared,
  };
}
