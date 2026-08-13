<script setup lang="ts">
interface Props {
  tone?: 'neutral' | 'success' | 'warning' | 'danger'
}

withDefaults(defineProps<Props>(), {
  tone: 'neutral',
})
</script>

<template>
  <span class="status-dot" :class="`status-dot--${tone}`" aria-hidden="true" />
</template>

<style scoped lang="scss">
.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 999px;
  background: currentColor;

  &--neutral {
    color: #8a9995;
  }
  &--success {
    color: #397a69;
  }
  &--warning {
    color: #d97706;
  }
  &--danger {
    color: #c2412d;
  }
}
</style>
