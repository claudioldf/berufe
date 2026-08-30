import { computed } from "vue";
import type { Ref, WritableComputedRef } from "vue";
import { maskBrazilianMobilePhone } from "~/utils/brazilian-phone";

export function useBrazilianMobilePhoneMask(
  phone: Ref<string> | WritableComputedRef<string>,
) {
  return computed({
    get: () => maskBrazilianMobilePhone(phone.value),
    set: (value: string) => {
      phone.value = maskBrazilianMobilePhone(value);
    },
  });
}
