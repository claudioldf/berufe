<script setup lang="ts">
defineSlots<{
  default(): unknown;
}>();
</script>

<template>
  <p class="kicker"><slot /></p>
</template>

<style scoped lang="scss">
.kicker {
  margin: 0;
  color: var(--color-success);
  font-size: var(--font-size-min);
  font-weight: 900;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}
</style>
