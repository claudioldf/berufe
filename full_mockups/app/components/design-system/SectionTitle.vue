<script setup lang="ts">
interface Props {
  as?: 'h1' | 'h2' | 'h3'
}

withDefaults(defineProps<Props>(), {
  as: 'h2',
})

defineSlots<{
  default(): unknown
}>()
</script>

<template>
  <component :is="as" class="section-title">
    <slot />
  </component>
</template>

<style scoped lang="scss">
.section-title {
  margin: 0;
  font-family: Georgia, "Times New Roman", serif;
  font-size: clamp(2rem, 4vw, 3.6rem);
  font-weight: 500;
  letter-spacing: -0.04em;
  line-height: 1.02;
}
</style>
