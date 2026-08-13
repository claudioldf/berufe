<script setup lang="ts">
import { useMockupApp } from '~/composables/useMockupApp'

const { toast, clearToast } = useMockupApp()
</script>

<template>
  <UApp>
    <div class="app-shell">
      <AppHeader />
      <main class="app-main">
        <NuxtPage />
      </main>
      <AppFooter />
      <DesignSystemToast :message="toast" @dismiss="clearToast" />
    </div>
  </UApp>
</template>

<style scoped>
.app-shell {
  display: flex;
  min-height: 100vh;
  flex-direction: column;
}

.app-main {
  flex: 1;
}
</style>
