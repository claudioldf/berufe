<script setup lang="ts">
import { computed, useTemplateRef } from "vue";
import { useBrazilianMobilePhoneMask } from "~/composables/useBrazilianMobilePhoneMask";
import { useInlineFormValidation } from "~/composables/useInlineFormValidation";
import type { ProfessionalAuthMethod } from "~/services/api/phone-auth";
import { normalizeBrazilianMobilePhone } from "~/utils/brazilian-phone";

const name = defineModel<string>("name", { required: true });
const phone = defineModel<string>("phone", { required: true });
const email = defineModel<string>("email", { required: true });
const accepted = defineModel<boolean>("accepted", { required: true });
const props = defineProps<{
  method: ProfessionalAuthMethod;
  error: string;
  fieldErrors: Record<string, string[]>;
  loading: boolean;
}>();
const emit = defineEmits<{ submit: [] }>();
const maskedPhone = useBrazilianMobilePhoneMask(phone);
const formRoot = useTemplateRef<HTMLFormElement>("formRoot");
const { validationAttempted, revealValidation } =
  useInlineFormValidation(formRoot);
const localNameError = computed(() => {
  const length = name.value.trim().length;
  if (length < 3) return "Informe seu nome profissional.";
  if (length > 70) return "Use no máximo 70 caracteres.";
  return "";
});
const normalizedEmail = computed(() => email.value.trim().toLowerCase());
const localContactError = computed(() => {
  if (props.method === "email") {
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
const localTermsError = computed(() =>
  accepted.value
    ? ""
    : "Você precisa aceitar os termos e o aviso de privacidade.",
);
const displayedNameError = computed(
  () =>
    props.fieldErrors.display_name?.[0] ||
    (validationAttempted.value ? localNameError.value : ""),
);
const displayedContactError = computed(
  () =>
    props.fieldErrors[props.method === "phone" ? "email" : "phone"]?.[0] ||
    (validationAttempted.value ? localContactError.value : ""),
);
const displayedTermsError = computed(
  () =>
    props.fieldErrors.accepted?.[0] ||
    (validationAttempted.value ? localTermsError.value : ""),
);
const submitBlockedReason = computed(() =>
  props.loading ? "Aguarde a criação do perfil terminar." : null,
);

function submit() {
  const valid =
    !localNameError.value && !localContactError.value && !localTermsError.value;
  if (props.loading || !revealValidation(valid)) return;
  emit("submit");
}
</script>

<template>
  <section aria-labelledby="registration-step-title">
    <div class="auth-card__success"><UIcon name="i-lucide-check" /></div>
    <DesignSystemEyebrow>Contato confirmado</DesignSystemEyebrow>
    <h1 id="registration-step-title">Como você quer<br />ser encontrado?</h1>
    <p class="auth-card__lead">
      Informe o nome principal do seu perfil e complete seus dados de contato.
      Você poderá preencher as outras informações depois.
    </p>
    <form ref="formRoot" novalidate @submit.prevent="submit">
      <label
        class="auth-field"
        :class="{ 'auth-field--invalid': displayedNameError }"
        for="professional-name"
      >
        <span>Seu nome profissional</span>
        <input
          id="professional-name"
          v-model="name"
          name="name"
          type="text"
          autocomplete="name"
          maxlength="70"
          required
          :aria-describedby="
            displayedNameError ? 'professional-name-error' : undefined
          "
          :aria-invalid="displayedNameError ? 'true' : undefined"
        />
      </label>
      <p
        v-if="displayedNameError"
        id="professional-name-error"
        class="auth-error"
        role="alert"
      >
        <UIcon name="i-lucide-circle-alert" /> {{ displayedNameError }}
      </p>
      <label
        v-if="method === 'phone'"
        class="auth-field"
        :class="{ 'auth-field--invalid': displayedContactError }"
        for="registration-email"
      >
        <span>Seu e-mail</span>
        <input
          id="registration-email"
          v-model="email"
          name="email"
          type="email"
          inputmode="email"
          autocomplete="email"
          placeholder="voce@exemplo.com"
          maxlength="254"
          required
          :aria-describedby="
            displayedContactError ? 'registration-contact-error' : undefined
          "
          :aria-invalid="displayedContactError ? 'true' : undefined"
        />
      </label>
      <label
        v-else
        class="auth-field"
        :class="{ 'auth-field--invalid': displayedContactError }"
        for="registration-phone"
      >
        <span>Seu celular com DDD</span>
        <div>
          <span aria-hidden="true">🇧🇷 +55</span>
          <input
            id="registration-phone"
            v-model="maskedPhone"
            name="phone"
            type="tel"
            inputmode="tel"
            autocomplete="tel"
            placeholder="(47) 9 9999-9999"
            maxlength="16"
            required
            :aria-describedby="
              displayedContactError ? 'registration-contact-error' : undefined
            "
            :aria-invalid="displayedContactError ? 'true' : undefined"
          />
        </div>
      </label>
      <p
        v-if="displayedContactError"
        id="registration-contact-error"
        class="auth-error"
        role="alert"
      >
        <UIcon name="i-lucide-circle-alert" /> {{ displayedContactError }}
      </p>
      <label
        class="auth-check"
        :class="{ 'auth-check--invalid': displayedTermsError }"
      >
        <input
          v-model="accepted"
          name="accepted-terms"
          type="checkbox"
          required
          :aria-describedby="
            displayedTermsError ? 'accepted-terms-error' : undefined
          "
          :aria-invalid="displayedTermsError ? 'true' : undefined"
        />
        <span>
          Li e aceito os
          <NuxtLink to="/termos-de-uso" target="_blank" rel="noopener">
            Termos de Uso
          </NuxtLink>
          e declaro que li a
          <NuxtLink to="/privacidade" target="_blank" rel="noopener">
            Política de Privacidade
          </NuxtLink>
          vigentes.
        </span>
      </label>
      <p
        v-if="displayedTermsError"
        id="accepted-terms-error"
        class="auth-error"
        role="alert"
      >
        <UIcon name="i-lucide-circle-alert" /> {{ displayedTermsError }}
      </p>
      <p
        v-if="props.error"
        id="registration-step-error"
        class="auth-error"
        role="alert"
      >
        <UIcon name="i-lucide-circle-alert" /> {{ props.error }}
      </p>
      <DesignSystemDisabledTooltip
        :reason="submitBlockedReason"
        :loading="loading"
      >
        <UButton
          class="registration-step__submit"
          type="submit"
          color="primary"
          trailing-icon="i-lucide-arrow-right"
          :loading="loading"
          :disabled="loading"
        >
          Criar meu perfil
        </UButton>
      </DesignSystemDisabledTooltip>
    </form>
  </section>
</template>

<style scoped lang="scss">
.registration-step__submit {
  justify-self: end;
  min-height: 2.5rem;
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

.auth-check--invalid {
  border-color: var(--color-danger);
  background: var(--color-danger-tint);

  &:focus-within {
    border-color: var(--color-danger);
    box-shadow: 0 0 0 3px rgb(180 35 24 / 16%);
  }
}
</style>
