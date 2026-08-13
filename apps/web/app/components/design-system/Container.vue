<script setup lang="ts">
interface Props {
  as?: 'div' | 'header' | 'main'
}

withDefaults(defineProps<Props>(), {
  as: 'div',
})

defineSlots<{
  default(): unknown
}>()
</script>

<template>
  <component :is="as" class="container">
    <slot />
  </component>
</template>

<style scoped lang="scss">
.container {
  width: min(var(--ui-container), calc(100% - 40px));
  margin-inline: auto;
}

@media (max-width: 760px) {
  .container {
    width: min(100% - 28px, var(--ui-container));
  }
}
</style>
