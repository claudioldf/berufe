import { computed, ref, shallowRef, toValue, watch } from "vue";
import type { MaybeRefOrGetter } from "vue";
import type { Quote } from "~/types";
import {
  cloneQuote,
  hasQuoteValidationErrors,
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
    if (quote.value.items.length === 1) return;
    quote.value.items = quote.value.items.filter((item) => item.id !== id);
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
    validation,
    isValid,
    reset,
    markDirty,
    addItem,
    removeItem,
    markSaved,
    markShared,
  };
}
