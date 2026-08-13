<script setup lang="ts">
interface Props {
  as?: 'h1' | 'h2'
}

withDefaults(defineProps<Props>(), {
  as: 'h1',
})

defineSlots<{
  default(): unknown
}>()
</script>

<template>
  <component :is="as" class="display-title">
    <slot />
  </component>
</template>

<style scoped lang="scss">
.display-title {
  margin: 0;
  font-family: Georgia, "Times New Roman", serif;
  font-size: clamp(2.6rem, 6vw, 5.8rem);
  font-weight: 500;
  letter-spacing: -0.055em;
  line-height: 0.96;
}
</style>
