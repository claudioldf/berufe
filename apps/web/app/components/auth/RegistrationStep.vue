<script setup lang="ts">
import LegalInlineNotice from "~/components/legal/LegalInlineNotice.vue";

const name = defineModel<string>("name", { required: true });
const accepted = defineModel<boolean>("accepted", { required: true });
defineProps<{ error: string; loading: boolean }>();
defineEmits<{ submit: [] }>();
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
    <form @submit.prevent="$emit('submit')">
      <label class="auth-field" for="professional-name">
        <span>Seu nome profissional</span>
        <input
          id="professional-name"
          v-model="name"
          name="name"
          type="text"
          autocomplete="name"
          maxlength="70"
          :aria-describedby="error ? 'registration-step-error' : undefined"
        />
      </label>
      <label class="auth-check">
        <input v-model="accepted" name="accepted-terms" type="checkbox" />
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
      <LegalInlineNotice title="Registro legal">
        Guardamos a data, a versão dos Termos aceita e a versão do aviso de
        privacidade apresentada. A conta profissional é destinada somente a
        pessoas com 18 anos ou mais.
      </LegalInlineNotice>
      <p
        v-if="error"
        id="registration-step-error"
        class="auth-error"
        role="alert"
      >
        <UIcon name="i-lucide-circle-alert" /> {{ error }}
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
</style>
