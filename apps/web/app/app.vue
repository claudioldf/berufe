<script setup lang="ts">
import { useToast } from "~/composables/useToast";

const { toast, clearToast } = useToast();
</script>

<template>
  <UApp>
    <div class="app-shell">
      <a class="skip-link" href="#main-content">Pular para o conteúdo</a>
      <AppHeader />
      <main id="main-content" class="app-main" tabindex="-1">
        <NuxtPage />
      </main>
      <AppFooter />
      <DesignSystemToast :message="toast" @dismiss="clearToast" />
    </div>
  </UApp>
</template>

<style scoped lang="scss">
.app-shell {
  display: flex;
  min-height: 100vh;
  flex-direction: column;
}

.app-main {
  flex: 1;
}
</style>
