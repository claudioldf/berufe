<script setup lang="ts">
const { data, error, status, refresh } = await useApiStatus();
</script>

<template>
  <UContainer class="py-12">
    <h1 class="text-2xl font-semibold">Fundação da integração</h1>
    <p v-if="status === 'pending'" role="status">Verificando a API…</p>
    <p v-else-if="error" role="alert">
      Não foi possível consultar a API. {{ error.message }}
    </p>
    <p v-else data-testid="api-status">
      {{ data?.data.service }}: {{ data?.data.status }}
    </p>
    <UButton type="button" @click="() => refresh()">
      Verificar novamente
    </UButton>
  </UContainer>
</template>
