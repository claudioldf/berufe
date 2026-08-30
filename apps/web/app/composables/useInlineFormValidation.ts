import { nextTick, readonly, shallowRef, toValue } from "vue";
import type { MaybeRefOrGetter } from "vue";

export function useInlineFormValidation(
  formRoot: MaybeRefOrGetter<HTMLElement | null | undefined>,
) {
  const validationAttempted = shallowRef(false);

  function revealValidation(isValid: boolean) {
    validationAttempted.value = true;
    if (isValid) return true;

    void nextTick(() => {
      const firstInvalidField = toValue(formRoot)?.querySelector<HTMLElement>(
        '[aria-invalid="true"]',
      );
      if (!firstInvalidField) return;

      firstInvalidField.focus({ preventScroll: true });
      firstInvalidField.scrollIntoView({
        block: "center",
        inline: "nearest",
      });
    });
    return false;
  }

  function resetValidation() {
    validationAttempted.value = false;
  }

  return {
    validationAttempted: readonly(validationAttempted),
    revealValidation,
    resetValidation,
  };
}
