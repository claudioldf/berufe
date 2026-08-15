<script setup lang="ts">
const name = defineModel<string>("name", { required: true });
const accepted = defineModel<boolean>("accepted", { required: true });
defineProps<{ error: string }>();
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
          e a
          <NuxtLink to="/privacidade" target="_blank" rel="noopener">
            Política de Privacidade
          </NuxtLink>
          vigentes.
        </span>
      </label>
      <p
        v-if="error"
        id="registration-step-error"
        class="auth-error"
        role="alert"
      >
        <UIcon name="i-lucide-circle-alert" /> {{ error }}
      </p>
      <UButton
        type="submit"
        color="primary"
        block
        trailing-icon="i-lucide-arrow-right"
      >
        Criar meu perfil
      </UButton>
    </form>
  </section>
</template>
