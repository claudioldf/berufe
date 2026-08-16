<script setup lang="ts">
const email = defineModel<string>("email", { required: true });
const password = defineModel<string>("password", { required: true });
defineProps<{ loading: boolean; error: string }>();
defineEmits<{ submit: [] }>();
</script>

<template>
  <section aria-labelledby="admin-login-title">
    <DesignSystemEyebrow>Acesso administrativo</DesignSystemEyebrow>
    <h1 id="admin-login-title">Entre com seu<br />e-mail e senha.</h1>
    <p class="auth-card__lead">Acesso restrito a contas administrativas.</p>
    <form @submit.prevent="$emit('submit')">
      <label class="auth-field" for="admin-email">
        <span>E-mail</span>
        <input
          id="admin-email"
          v-model="email"
          name="email"
          type="email"
          inputmode="email"
          autocomplete="username"
          :aria-describedby="error ? 'admin-login-error' : undefined"
          :aria-invalid="error ? 'true' : undefined"
        />
      </label>
      <label class="auth-field" for="admin-password">
        <span>Senha</span>
        <input
          id="admin-password"
          v-model="password"
          name="password"
          type="password"
          autocomplete="current-password"
          :aria-describedby="error ? 'admin-login-error' : undefined"
          :aria-invalid="error ? 'true' : undefined"
        />
      </label>
      <p v-if="error" id="admin-login-error" class="auth-error" role="alert">
        <UIcon name="i-lucide-circle-alert" /> {{ error }}
      </p>
      <UButton
        class="admin-login-form__submit"
        type="submit"
        color="primary"
        :loading="loading"
        trailing-icon="i-lucide-arrow-right"
      >
        Entrar
      </UButton>
    </form>
  </section>
</template>

<style scoped>
.admin-login-form__submit {
  justify-self: end;
  min-height: 2.5rem;
}
</style>
