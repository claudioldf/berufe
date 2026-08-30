<script setup lang="ts">
import { computed, useTemplateRef } from "vue";
import { useBrazilianMobilePhoneMask } from "~/composables/useBrazilianMobilePhoneMask";
import { useInlineFormValidation } from "~/composables/useInlineFormValidation";
import type { ProfessionalPhoneStepContent } from "~/utils/professional-auth";
import { normalizeBrazilianMobilePhone } from "~/utils/brazilian-phone";

const phone = defineModel<string>({ required: true });
const props = defineProps<{
  loading: boolean;
  error: string;
  content: ProfessionalPhoneStepContent;
}>();
const emit = defineEmits<{ submit: [] }>();
const maskedPhone = useBrazilianMobilePhoneMask(phone);
const formRoot = useTemplateRef<HTMLFormElement>("formRoot");
const { validationAttempted, revealValidation } =
  useInlineFormValidation(formRoot);
const localError = computed(() =>
  normalizeBrazilianMobilePhone(phone.value)
    ? ""
    : "Digite um número de celular válido.",
);
const displayedError = computed(
  () => props.error || (validationAttempted.value ? localError.value : ""),
);

function submit() {
  if (props.loading || !revealValidation(!localError.value)) return;
  emit("submit");
}
</script>

<template>
  <section aria-labelledby="phone-step-title">
    <DesignSystemEyebrow>{{ content.eyebrow }}</DesignSystemEyebrow>
    <h1 id="phone-step-title">{{ content.title }}</h1>
    <p class="auth-card__lead">{{ content.description }}</p>
    <form ref="formRoot" novalidate @submit.prevent="submit">
      <label
        class="auth-field"
        :class="{ 'auth-field--invalid': displayedError }"
        for="auth-phone"
      >
        <span>Celular com DDD</span>
        <div>
          <span aria-hidden="true">🇧🇷 +55</span>
          <input
            id="auth-phone"
            v-model="maskedPhone"
            name="phone"
            type="tel"
            inputmode="tel"
            autocomplete="tel"
            placeholder="(47) 9 9999-9999"
            maxlength="16"
            required
            :aria-describedby="displayedError ? 'phone-step-error' : undefined"
            :aria-invalid="displayedError ? 'true' : undefined"
          />
        </div>
      </label>
      <p
        v-if="displayedError"
        id="phone-step-error"
        class="auth-error"
        role="alert"
      >
        <UIcon name="i-lucide-circle-alert" aria-hidden="true" />
        {{ displayedError }}
      </p>
      <UButton
        class="phone-step__submit"
        type="submit"
        color="primary"
        :loading="loading"
        trailing-icon="i-lucide-arrow-right"
      >
        {{ content.submitLabel }}
      </UButton>
    </form>
    <p class="phone-step__alternate">
      {{ content.alternatePrompt }}
      <NuxtLink :to="content.alternateTo">
        {{ content.alternateLabel }}
      </NuxtLink>
    </p>
    <p class="auth-card__fineprint">
      Ao continuar, você confirma que este número é seu. Aplicamos limites de
      segurança e nunca informamos se uma conta já existe.
    </p>
  </section>
</template>

<style scoped>
.phone-step__submit {
  justify-self: end;
  min-height: 2.5rem;
}

.auth-field--invalid > div {
  border-color: var(--color-danger);
  background: var(--color-danger-tint);
}

.auth-field--invalid > div:focus-within {
  border-color: var(--color-danger);
  box-shadow: 0 0 0 3px rgb(180 35 24 / 16%);
}

.phone-step__alternate {
  margin: 20px 0 0;
  color: var(--ink-soft);
  font-size: 0.88rem;
  text-align: center;
}

.phone-step__alternate a {
  color: var(--color-brand);
  font-weight: 800;
}

.phone-step__alternate a:focus-visible {
  border-radius: 4px;
  outline: 2px solid var(--color-brand);
  outline-offset: 3px;
}
</style>
