import { computed, ref, shallowRef, toValue, watch } from "vue";
import type { MaybeRefOrGetter } from "vue";
import type { Quote, QuotePricingMode } from "~/types";
import {
  cloneQuote,
  hasQuotePricingValues,
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
  const pricingModeConfirmationOpen = shallowRef(false);
  const pendingPricingMode = shallowRef<QuotePricingMode | null>(null);

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
    pricingModeConfirmationOpen.value = false;
    pendingPricingMode.value = null;
  }

  function markDirty() {
    isSaved.value = false;
  }

  function addItem() {
    if (quote.value.items.length >= 20) return;
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

  function addMaterial() {
    if (quote.value.customerSuppliedMaterials.length >= 20) return;
    quote.value.customerSuppliedMaterials.push({
      id: globalThis.crypto.randomUUID(),
      description: "",
      quantity: 1,
      unit: "unidade",
      sortOrder: quote.value.customerSuppliedMaterials.length,
    });
    markDirty();
  }

  function removeMaterial(id: string) {
    quote.value.customerSuppliedMaterials =
      quote.value.customerSuppliedMaterials.filter(
        (material) => material.id !== id,
      );
    markDirty();
  }

  function requestPricingMode(mode: QuotePricingMode) {
    if (mode === quote.value.pricingMode) return;
    if (hasQuotePricingValues(quote.value)) {
      pendingPricingMode.value = mode;
      pricingModeConfirmationOpen.value = true;
      return;
    }
    applyPricingMode(mode);
  }

  function cancelPricingModeChange() {
    pendingPricingMode.value = null;
    pricingModeConfirmationOpen.value = false;
  }

  function confirmPricingModeChange() {
    if (pendingPricingMode.value) applyPricingMode(pendingPricingMode.value);
    cancelPricingModeChange();
  }

  function applyPricingMode(mode: QuotePricingMode) {
    quote.value.pricingMode = mode;
    quote.value.fixedPrice = 0;
    quote.value.discount = 0;
    quote.value.items = [
      {
        id: globalThis.crypto.randomUUID(),
        description: "",
        quantity: 1,
        unit: "serviço",
        unitPrice: 0,
        lineTotal: 0,
        sortOrder: 0,
      },
    ];
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
    pricingModeConfirmationOpen,
    pendingPricingMode,
    subtotal,
    total,
    validation,
    isValid,
    reset,
    markDirty,
    addItem,
    removeItem,
    addMaterial,
    removeMaterial,
    requestPricingMode,
    cancelPricingModeChange,
    confirmPricingModeChange,
    markSaved,
    markShared,
  };
}
