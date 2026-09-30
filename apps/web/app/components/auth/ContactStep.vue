<script setup lang="ts">
import { computed, useTemplateRef, watch } from "vue";
import { useBrazilianMobilePhoneMask } from "~/composables/useBrazilianMobilePhoneMask";
import { useInlineFormValidation } from "~/composables/useInlineFormValidation";
import type { ProfessionalAuthMethod } from "~/services/api/phone-auth";
import type { ProfessionalContactStepContent } from "~/utils/professional-auth";
import { normalizeBrazilianMobilePhone } from "~/utils/brazilian-phone";

const method = defineModel<ProfessionalAuthMethod>("method", {
  required: true,
});
const phone = defineModel<string>("phone", { required: true });
const email = defineModel<string>("email", { required: true });
const props = defineProps<{
  loading: boolean;
  error: string;
  content: ProfessionalContactStepContent;
}>();
const emit = defineEmits<{ submit: [] }>();
const maskedPhone = useBrazilianMobilePhoneMask(phone);
const formRoot = useTemplateRef<HTMLFormElement>("formRoot");
const { validationAttempted, revealValidation, resetValidation } =
  useInlineFormValidation(formRoot);
const normalizedEmail = computed(() => email.value.trim().toLowerCase());
const localError = computed(() => {
  if (method.value === "phone") {
    return normalizeBrazilianMobilePhone(phone.value)
      ? ""
      : "Digite um número de celular válido.";
  }

  return normalizedEmail.value.length >= 3 &&
    normalizedEmail.value.length <= 254 &&
    /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail.value)
    ? ""
    : "Digite um e-mail válido.";
});
const displayedError = computed(
  () => props.error || (validationAttempted.value ? localError.value : ""),
);
const errorId = computed(() =>
  method.value === "phone" ? "phone-step-error" : "email-step-error",
);
const finePrint = computed(() =>
  method.value === "phone"
    ? "Ao continuar, você confirma que este número é seu."
    : "Ao continuar, você confirma que este e-mail é seu.",
);

watch(method, resetValidation);

function submit() {
  if (props.loading || !revealValidation(!localError.value)) return;
  emit("submit");
}
</script>

<template>
  <section aria-labelledby="contact-step-title">
    <DesignSystemEyebrow>{{ content.eyebrow }}</DesignSystemEyebrow>
    <h1 id="contact-step-title">{{ content.title }}</h1>
    <p class="auth-card__lead">{{ content.description }}</p>
    <form ref="formRoot" novalidate @submit.prevent="submit">
      <fieldset class="contact-step__methods">
        <legend>Receber código por</legend>
        <div>
          <label :class="{ active: method === 'phone' }">
            <input v-model="method" type="radio" value="phone" />
            <UIcon name="i-lucide-smartphone" aria-hidden="true" />
            Celular
          </label>
          <label :class="{ active: method === 'email' }">
            <input v-model="method" type="radio" value="email" />
            <UIcon name="i-lucide-mail" aria-hidden="true" />
            E-mail
          </label>
        </div>
      </fieldset>

      <label
        v-if="method === 'phone'"
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
            :aria-describedby="displayedError ? errorId : undefined"
            :aria-invalid="displayedError ? 'true' : undefined"
          />
        </div>
      </label>

      <label
        v-else
        class="auth-field"
        :class="{ 'auth-field--invalid': displayedError }"
        for="auth-email"
      >
        <span>Seu e-mail</span>
        <input
          id="auth-email"
          v-model="email"
          name="email"
          type="email"
          inputmode="email"
          autocomplete="email"
          placeholder="voce@exemplo.com"
          maxlength="254"
          required
          :aria-describedby="displayedError ? errorId : undefined"
          :aria-invalid="displayedError ? 'true' : undefined"
        />
      </label>

      <p v-if="displayedError" :id="errorId" class="auth-error" role="alert">
        <UIcon name="i-lucide-circle-alert" aria-hidden="true" />
        {{ displayedError }}
      </p>
      <UButton
        class="contact-step__submit"
        type="submit"
        color="primary"
        :loading="loading"
        trailing-icon="i-lucide-arrow-right"
      >
        {{ content.submitLabel }}
      </UButton>
    </form>
    <p class="contact-step__alternate">
      {{ content.alternatePrompt }}
      <NuxtLink :to="content.alternateTo">
        {{ content.alternateLabel }}
      </NuxtLink>
    </p>
    <p class="auth-card__fineprint">
      {{ finePrint }} Aplicamos limites de segurança e nunca informamos se uma
      conta já existe.
    </p>
  </section>
</template>

<style scoped lang="scss">
.contact-step {
  &__methods {
    display: grid;
    gap: 7px;
    margin: 0;
    padding: 0;
    border: 0;

    & legend {
      margin-bottom: 7px;
      color: var(--ink);
      font-size: 0.86rem;
      font-weight: 850;
    }

    & > div {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 4px;
      padding: 4px;
      border: 1px solid var(--line);
      border-radius: 12px;
      background: rgb(255 255 255 / 55%);
    }

    & label {
      position: relative;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 7px;
      min-height: 40px;
      border-radius: 9px;
      color: var(--ink-soft);
      font-size: 0.86rem;
      font-weight: 800;
      cursor: pointer;

      &.active {
        background: white;
        color: var(--color-brand);
        box-shadow: var(--shadow-sm);
      }

      &:focus-within {
        outline: 2px solid var(--color-brand);
        outline-offset: 1px;
      }
    }

    & input {
      position: absolute;
      width: 1px;
      height: 1px;
      opacity: 0;
    }
  }

  &__submit {
    justify-self: end;
    min-height: 2.5rem;
  }

  &__alternate {
    margin: 20px 0 0;
    color: var(--ink-soft);
    font-size: 0.88rem;
    text-align: center;

    & a {
      color: var(--color-brand);
      font-weight: 800;

      &:focus-visible {
        border-radius: 4px;
        outline: 2px solid var(--color-brand);
        outline-offset: 3px;
      }
    }
  }
}

.auth-field--invalid {
  & > div,
  & > input {
    border-color: var(--color-danger);
    background: var(--color-danger-tint);
  }

  & > div:focus-within,
  & > input:focus {
    border-color: var(--color-danger);
    box-shadow: 0 0 0 3px rgb(180 35 24 / 16%);
  }
}
</style>
