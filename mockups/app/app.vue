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

      <Transition name="toast">
        <button
          v-if="toast"
          class="mock-toast"
          type="button"
          aria-live="polite"
          @click="clearToast"
        >
          <span class="mock-toast__icon">
            <UIcon name="i-lucide-check" />
          </span>
          <span>
            <strong>{{ toast.title }}</strong>
            <small>{{ toast.description }}</small>
          </span>
          <UIcon name="i-lucide-x" />
        </button>
      </Transition>
    </div>
  </UApp>
</template>
