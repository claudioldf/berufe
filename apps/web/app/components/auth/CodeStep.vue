<script setup lang="ts">
import { computed, useTemplateRef } from "vue";
import { useInlineFormValidation } from "~/composables/useInlineFormValidation";
import type { ProfessionalAuthMethod } from "~/services/api/phone-auth";

const code = defineModel<string>({ required: true });
const props = defineProps<{
  method: ProfessionalAuthMethod;
  destination: string;
  loading: boolean;
  error: string;
  cooldown: number;
}>();
const emit = defineEmits<{
  submit: [];
  resend: [];
  changeDestination: [];
}>();
const formRoot = useTemplateRef<HTMLFormElement>("formRoot");
const { validationAttempted, revealValidation } =
  useInlineFormValidation(formRoot);
const localError = computed(() =>
  /^\d{6}$/.test(code.value) ? "" : "Digite o código de 6 dígitos.",
);
const displayedError = computed(
  () => props.error || (validationAttempted.value ? localError.value : ""),
);
const channelLabel = computed(() =>
  props.method === "phone" ? "telefone" : "e-mail",
);
const destinationLabel = computed(() =>
  props.method === "phone" ? `+55 ${props.destination}` : props.destination,
);

const resendLabel = computed(() => {
  if (props.cooldown >= 3600) return "Reenviar código amanhã";
  if (props.cooldown > 0) return `Reenviar código em ${props.cooldown}s`;
  return "Reenviar código";
});
const resendBlockedReason = computed(() => {
  if (props.cooldown >= 3600) {
    return "O limite de reenvios foi atingido. Tente novamente amanhã.";
  }
  if (props.cooldown > 0) {
    return `Aguarde ${props.cooldown}s para solicitar outro código.`;
  }
  return null;
});

function submit() {
  if (props.loading || !revealValidation(!localError.value)) return;
  emit("submit");
}
</script>

<template>
  <section aria-labelledby="code-step-title">
    <button
      class="auth-card__step-back"
      type="button"
      @click="$emit('changeDestination')"
    >
      <UIcon name="i-lucide-arrow-left" /> Alterar {{ channelLabel }}
    </button>
    <DesignSystemEyebrow>Confirme seu {{ channelLabel }}</DesignSystemEyebrow>
    <h1 id="code-step-title">Digite o código<br />que enviamos.</h1>
    <p class="auth-card__lead">
      Código enviado por {{ method === "phone" ? "SMS" : "e-mail" }} para
      <strong class="code-step__destination">{{ destinationLabel }}</strong
      >.
    </p>
    <form ref="formRoot" novalidate @submit.prevent="submit">
      <label
        class="auth-field"
        :class="{ 'auth-field--invalid': displayedError }"
        for="auth-code"
      >
        <span>Código de 6 dígitos</span>
        <input
          id="auth-code"
          v-model="code"
          class="auth-code"
          name="one-time-code"
          type="text"
          inputmode="numeric"
          pattern="[0-9]{6}"
          maxlength="6"
          autocomplete="one-time-code"
          placeholder="000000"
          required
          :aria-describedby="displayedError ? 'code-step-error' : undefined"
          :aria-invalid="displayedError ? 'true' : undefined"
        />
      </label>
      <p
        v-if="displayedError"
        id="code-step-error"
        class="auth-error"
        role="alert"
      >
        <UIcon name="i-lucide-circle-alert" /> {{ displayedError }}
      </p>
      <UButton
        class="code-step__submit"
        type="submit"
        color="primary"
        :loading="loading"
      >
        Confirmar e continuar
      </UButton>
      <DesignSystemDisabledTooltip :reason="resendBlockedReason">
        <button
          class="resend"
          type="button"
          :disabled="cooldown > 0"
          @click="$emit('resend')"
        >
          {{ resendLabel }}
        </button>
      </DesignSystemDisabledTooltip>
    </form>
  </section>
</template>

<style scoped>
.code-step__destination {
  overflow-wrap: anywhere;
}

.code-step__submit {
  justify-self: end;
  min-height: 44px;
}

.auth-field--invalid input {
  border-color: var(--color-danger);
  background: var(--color-danger-tint);
}

.auth-field--invalid input:focus {
  border-color: var(--color-danger);
  box-shadow: 0 0 0 3px rgb(180 35 24 / 16%);
}
</style>
