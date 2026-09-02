<script setup lang="ts">
const NAVIGATION_DURATION_MS = 2_000;
const NAVIGATION_HIDE_DELAY_MS = 150;
const NAVIGATION_RESET_DELAY_MS = 200;

const { isLoading } = useLoadingIndicator({
  duration: NAVIGATION_DURATION_MS,
  throttle: 0,
  hideDelay: NAVIGATION_HIDE_DELAY_MS,
  resetDelay: NAVIGATION_RESET_DELAY_MS,
});
</script>

<template>
  <NuxtLoadingIndicator
    class="app-navigation-progress"
    :throttle="0"
    :duration="NAVIGATION_DURATION_MS"
    :hide-delay="NAVIGATION_HIDE_DELAY_MS"
    :reset-delay="NAVIGATION_RESET_DELAY_MS"
    :height="4"
    color="linear-gradient(90deg, var(--color-accent), var(--color-brand))"
    error-color="var(--color-danger)"
    aria-hidden="true"
  />

  <Transition name="navigation-feedback">
    <div
      v-if="isLoading"
      class="app-navigation-status"
      role="status"
      aria-live="polite"
      aria-atomic="true"
    >
      <span class="app-navigation-status__spinner" aria-hidden="true" />
      <span>Carregando página…</span>
    </div>
  </Transition>
</template>

<style scoped lang="scss">
.app-navigation-progress {
  box-shadow: 0 1px 10px rgb(248 117 93 / 42%);
}

.app-navigation-status {
  position: fixed;
  z-index: 999998;
  top: max(14px, env(safe-area-inset-top));
  right: max(14px, env(safe-area-inset-right));
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 9px 12px;
  border: 1px solid rgb(255 255 255 / 18%);
  border-radius: var(--radius-pill);
  background: var(--color-brand-strong);
  box-shadow: var(--shadow-sm);
  color: var(--color-text-inverse);
  font-size: 0.82rem;
  font-weight: 800;
  pointer-events: none;

  &__spinner {
    width: 14px;
    height: 14px;
    border: 2px solid rgb(255 255 255 / 42%);
    border-top-color: currentcolor;
    border-radius: 50%;
    animation: navigation-spinner 0.7s linear infinite;
  }
}

.navigation-feedback-enter-active {
  transition:
    transform var(--motion-fast) ease 0.35s,
    opacity var(--motion-fast) ease 0.35s;
}

.navigation-feedback-leave-active {
  transition:
    transform 0.1s ease,
    opacity 0.1s ease;
}

.navigation-feedback-enter-from,
.navigation-feedback-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

@keyframes navigation-spinner {
  to {
    transform: rotate(360deg);
  }
}

@media (prefers-reduced-motion: reduce) {
  .app-navigation-status__spinner {
    animation: none;
  }

  .navigation-feedback-enter-active {
    transition-delay: 0s;
  }
}

@media (forced-colors: active) {
  .app-navigation-status {
    border-color: CanvasText;
    background: Canvas;
    color: CanvasText;
  }
}
</style>
