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

<style scoped>
.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 999px;
  background: currentColor;
}

.status-dot--neutral { color: #8a9995; }
.status-dot--success { color: #397a69; }
.status-dot--warning { color: #d97706; }
.status-dot--danger { color: #c2412d; }
</style>
