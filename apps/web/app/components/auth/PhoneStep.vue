<script setup lang="ts">
const phone = defineModel<string>({ required: true });
defineProps<{ loading: boolean; error: string }>();
defineEmits<{ submit: [] }>();
</script>

<template>
  <section aria-labelledby="phone-step-title">
    <DesignSystemEyebrow>Acesso profissional</DesignSystemEyebrow>
    <h1 id="phone-step-title">Entre com seu<br />telefone.</h1>
    <p class="auth-card__lead">
      Você receberá um código por SMS. Sem senha para lembrar.
    </p>
    <form @submit.prevent="$emit('submit')">
      <label class="auth-field" for="auth-phone">
        <span>Celular com DDD</span>
        <div>
          <span aria-hidden="true">🇧🇷 +55</span>
          <input
            id="auth-phone"
            v-model="phone"
            name="phone"
            type="tel"
            inputmode="tel"
            autocomplete="tel"
            :aria-describedby="error ? 'phone-step-error' : undefined"
            :aria-invalid="error ? 'true' : undefined"
          />
        </div>
      </label>
      <p v-if="error" id="phone-step-error" class="auth-error" role="alert">
        <UIcon name="i-lucide-circle-alert" /> {{ error }}
      </p>
      <UButton
        class="phone-step__submit"
        type="submit"
        color="primary"
        :loading="loading"
        trailing-icon="i-lucide-arrow-right"
      >
        Receber código
      </UButton>
    </form>
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
</style>
