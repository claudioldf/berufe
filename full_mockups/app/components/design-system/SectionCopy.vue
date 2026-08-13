<script setup lang="ts">
defineSlots<{
  default(): unknown
}>()
</script>

<template>
  <p class="section-copy">
    <slot />
  </p>
</template>

<style scoped lang="scss">
.section-copy {
  color: var(--ink-soft);
  font-size: 1rem;
  line-height: 1.75;
}
</style>
