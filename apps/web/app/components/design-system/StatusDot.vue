<script setup lang="ts">
interface Props {
  tone?: "neutral" | "success" | "warning" | "danger";
}

withDefaults(defineProps<Props>(), {
  tone: "neutral",
});
</script>

<template>
  <span class="status-dot" :class="`status-dot--${tone}`" aria-hidden="true" />
</template>

<style scoped lang="scss">
.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 999px;
  background: currentcolor;

  &--neutral {
    color: var(--color-text-subtle);
  }
  &--success {
    color: var(--color-brand);
  }
  &--warning {
    color: var(--color-warning);
  }
  &--danger {
    color: var(--color-danger);
  }
}
</style>
