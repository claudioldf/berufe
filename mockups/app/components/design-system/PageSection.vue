<script setup lang="ts">
defineSlots<{
  default(): unknown
}>()
</script>

<template>
  <section class="page-section">
    <slot />
  </section>
</template>

<style scoped>
.page-section {
  padding-block: 80px;
}

@media (max-width: 760px) {
  .page-section {
    padding-block: 56px;
  }
}
</style>
