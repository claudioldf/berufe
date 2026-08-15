import { computed, ref, shallowRef, toValue, watch } from "vue";
import type { MaybeRefOrGetter } from "vue";
import type { Quote } from "~/types";
import {
  cloneQuote,
  isQuoteValid,
  quoteSubtotal,
  quoteTotal,
} from "~/utils/quotes";

export function useQuoteDraft(initialQuote: MaybeRefOrGetter<Quote>) {
  const quote = ref(cloneQuote(toValue(initialQuote)));
  const previewOpen = shallowRef(false);
  const shareOpen = shallowRef(false);
  const isSaved = shallowRef(true);
  const isShared = shallowRef(false);

  const subtotal = computed(() => quoteSubtotal(quote.value));
  const total = computed(() => quoteTotal(quote.value));
  const isValid = computed(() => isQuoteValid(quote.value));

  watch(
    () => toValue(initialQuote).number,
    () => reset(),
  );

  function reset() {
    quote.value = cloneQuote(toValue(initialQuote));
    isSaved.value = true;
    isShared.value = false;
    previewOpen.value = false;
    shareOpen.value = false;
  }

  function markDirty() {
    isSaved.value = false;
    isShared.value = false;
  }

  function addItem() {
    const nextId = Math.max(0, ...quote.value.items.map((item) => item.id)) + 1;
    quote.value.items.push({
      id: nextId,
      description: "",
      quantity: 1,
      unit: "serviço",
      unitPrice: 0,
    });
    markDirty();
  }

  function removeItem(id: number) {
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
    shareOpen.value = false;
  }

  return {
    quote,
    previewOpen,
    shareOpen,
    isSaved,
    isShared,
    subtotal,
    total,
    isValid,
    reset,
    markDirty,
    addItem,
    removeItem,
    markSaved,
    markShared,
  };
}
