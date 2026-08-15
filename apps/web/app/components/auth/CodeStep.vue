<script setup lang="ts">
const code = defineModel<string>({ required: true });
const props = defineProps<{
  phone: string;
  loading: boolean;
  error: string;
  cooldown: number;
}>();
defineEmits<{ submit: []; resend: []; changePhone: [] }>();

const resendLabel = computed(() => {
  if (props.cooldown >= 3600) return "Reenviar código amanhã";
  if (props.cooldown > 0) return `Reenviar código em ${props.cooldown}s`;
  return "Reenviar código";
});
</script>

<template>
  <section aria-labelledby="code-step-title">
    <button
      class="auth-card__step-back"
      type="button"
      @click="$emit('changePhone')"
    >
      <UIcon name="i-lucide-arrow-left" /> Alterar número
    </button>
    <DesignSystemEyebrow>Confirme seu telefone</DesignSystemEyebrow>
    <h1 id="code-step-title">Digite o código<br />que enviamos.</h1>
    <p class="auth-card__lead">
      SMS enviado para
      <strong>+55 {{ phone }}</strong
      >.
    </p>
    <form @submit.prevent="$emit('submit')">
      <label class="auth-field" for="auth-code">
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
          :aria-describedby="error ? 'code-step-error' : undefined"
          :aria-invalid="error ? 'true' : undefined"
        />
      </label>
      <p v-if="error" id="code-step-error" class="auth-error" role="alert">
        <UIcon name="i-lucide-circle-alert" /> {{ error }}
      </p>
      <UButton
        class="code-step__submit"
        type="submit"
        color="primary"
        :loading="loading"
      >
        Confirmar e continuar
      </UButton>
      <button
        class="resend"
        type="button"
        :disabled="cooldown > 0"
        @click="$emit('resend')"
      >
        {{ resendLabel }}
      </button>
    </form>
  </section>
</template>

<style scoped>
.code-step__submit {
  justify-self: end;
  min-height: 44px;
}
</style>
