<script setup lang="ts">
import { useBrazilianMobilePhoneMask } from "~/composables/useBrazilianMobilePhoneMask";

const phone = defineModel<string>({ required: true });
const maskedPhone = useBrazilianMobilePhoneMask(phone);

const props = withDefaults(defineProps<{ error?: string }>(), { error: "" });
</script>

<template>
  <DesignSystemFormField
    id="external-professional-phone"
    v-slot="field"
    label="Celular com DDD"
    :error="props.error"
    required
  >
    <input
      :id="field.controlId"
      v-model="maskedPhone"
      name="external-phone"
      type="tel"
      inputmode="tel"
      autocomplete="tel-national"
      placeholder="(47) 9 9999-9999"
      maxlength="16"
      required
      :aria-describedby="field.describedBy"
      :aria-invalid="field.invalid"
    />
  </DesignSystemFormField>
</template>
