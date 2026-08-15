<script setup lang="ts">
import type { ToastMessage } from "~/types";

defineProps<{
  message: ToastMessage | null;
}>();

const emit = defineEmits<{
  dismiss: [];
}>();
</script>

<template>
  <Transition name="toast">
    <div v-if="message" class="toast" role="status" aria-live="polite">
      <span class="toast__icon" aria-hidden="true">
        <UIcon name="i-lucide-check" />
      </span>
      <span class="toast__content">
        <strong>{{ message.title }}</strong>
        <small>{{ message.description }}</small>
      </span>
      <button
        class="toast__dismiss"
        type="button"
        aria-label="Dispensar notificação"
        @click="emit('dismiss')"
      >
        <UIcon name="i-lucide-x" aria-hidden="true" />
      </button>
    </div>
  </Transition>
</template>

<style scoped lang="scss">
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
  border: 1px solid rgb(255 255 255 / 14%);
  border-radius: var(--radius-lg);
  background: var(--color-brand-strong);
  color: var(--color-text-inverse);
  text-align: left;
  box-shadow: var(--shadow-lg);

  &__icon {
    display: grid;
    place-items: center;
    width: 32px;
    height: 32px;
    border-radius: var(--radius-md);
    background: var(--color-brand-soft);
    color: var(--color-brand-strong);
  }

  &__content {
    min-width: 0;
  }

  &__content strong,
  &__content small {
    display: block;
  }

  &__content small {
    margin-top: 2px;
    color: rgb(255 255 255 / 68%);
    overflow-wrap: anywhere;
  }

  &__dismiss {
    display: grid;
    place-items: center;
    width: 36px;
    height: 36px;
    padding: 0;
    border: 0;
    border-radius: var(--radius-md);
    background: transparent;
    color: inherit;
    cursor: pointer;
  }

  &__dismiss:hover {
    background: rgb(255 255 255 / 12%);
  }
}

.toast-enter-active,
.toast-leave-active {
  transition:
    opacity var(--motion-normal) ease,
    transform var(--motion-normal) ease;
}

.toast-enter-from,
.toast-leave-to {
  opacity: 0;
  transform: translateY(12px);
}

@media (width <= 760px) {
  .toast {
    right: 16px;
    bottom: max(16px, env(safe-area-inset-bottom));
  }
}
</style>
