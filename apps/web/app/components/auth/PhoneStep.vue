<script setup lang="ts">
import type { ProfessionalPhoneStepContent } from "~/utils/professional-auth";

const phone = defineModel<string>({ required: true });
defineProps<{
  loading: boolean;
  error: string;
  content: ProfessionalPhoneStepContent;
}>();
defineEmits<{ submit: [] }>();
</script>

<template>
  <section aria-labelledby="phone-step-title">
    <DesignSystemEyebrow>{{ content.eyebrow }}</DesignSystemEyebrow>
    <h1 id="phone-step-title">{{ content.title }}</h1>
    <p class="auth-card__lead">{{ content.description }}</p>
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
        <UIcon name="i-lucide-circle-alert" aria-hidden="true" /> {{ error }}
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
