<script setup lang="ts">
import { computed, useTemplateRef } from "vue";
import { useInlineFormValidation } from "~/composables/useInlineFormValidation";

const name = defineModel<string>("name", { required: true });
const accepted = defineModel<boolean>("accepted", { required: true });
const props = defineProps<{ error: string; loading: boolean }>();
const emit = defineEmits<{ submit: [] }>();
const formRoot = useTemplateRef<HTMLFormElement>("formRoot");
const { validationAttempted, revealValidation } =
  useInlineFormValidation(formRoot);
const nameError = computed(() => {
  const length = name.value.trim().length;
  if (length < 3) return "Informe seu nome profissional.";
  if (length > 70) return "Use no máximo 70 caracteres.";
  return "";
});
const termsError = computed(() =>
  accepted.value
    ? ""
    : "Você precisa aceitar os termos e o aviso de privacidade.",
);
const displayedNameError = computed(() =>
  validationAttempted.value ? nameError.value : "",
);
const displayedTermsError = computed(() =>
  validationAttempted.value ? termsError.value : "",
);

function submit() {
  const valid = !nameError.value && !termsError.value;
  if (props.loading || !revealValidation(valid)) return;
  emit("submit");
}
</script>

<template>
  <section aria-labelledby="registration-step-title">
    <div class="auth-card__success"><UIcon name="i-lucide-check" /></div>
    <DesignSystemEyebrow>Telefone confirmado</DesignSystemEyebrow>
    <h1 id="registration-step-title">Como você quer<br />ser encontrado?</h1>
    <p class="auth-card__lead">
      Este será o nome principal do seu perfil. Você poderá completar as outras
      informações depois.
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
    </form>
  </section>
</template>

<style scoped>
.registration-step__submit {
  justify-self: end;
  min-height: 2.5rem;
}

.auth-field--invalid input,
.auth-check--invalid {
  border-color: var(--color-danger);
  background: var(--color-danger-tint);
}

.auth-field--invalid input:focus,
.auth-check--invalid:focus-within {
  border-color: var(--color-danger);
  box-shadow: 0 0 0 3px rgb(180 35 24 / 16%);
}
</style>
