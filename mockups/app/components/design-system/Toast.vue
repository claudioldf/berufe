<script setup lang="ts">
import type { ToastMessage } from '~/types'

defineProps<{
  message: ToastMessage | null
}>()

const emit = defineEmits<{
  dismiss: []
}>()
</script>

<template>
  <Transition name="toast">
    <button
      v-if="message"
      class="toast"
      type="button"
      aria-live="polite"
      @click="emit('dismiss')"
    >
      <span class="toast__icon">
        <UIcon name="i-lucide-check" />
      </span>
      <span>
        <strong>{{ message.title }}</strong>
        <small>{{ message.description }}</small>
      </span>
      <UIcon name="i-lucide-x" />
    </button>
  </Transition>
</template>

<style scoped>
.toast {
  position: fixed;
  right: 24px;
  bottom: 24px;
  z-index: 100;
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 12px;
  width: min(380px, calc(100vw - 32px));
  padding: 14px 16px;
  border: 1px solid rgba(255, 255, 255, .14);
  border-radius: 16px;
  background: #183c35;
  color: white;
  text-align: left;
  box-shadow: var(--shadow-lg);
}

.toast__icon {
  display: grid;
  place-items: center;
  width: 32px;
  height: 32px;
  border-radius: 10px;
  background: #d8f0e7;
  color: #183c35;
}

.toast strong,
.toast small {
  display: block;
}

.toast small {
  margin-top: 2px;
  color: rgba(255, 255, 255, .68);
}

.toast-enter-active,
.toast-leave-active {
  transition: .2s ease;
}

.toast-enter-from,
.toast-leave-to {
  opacity: 0;
  transform: translateY(12px);
}

@media (max-width: 760px) {
  .toast {
    right: 16px;
    bottom: 16px;
  }
}
</style>
