<script setup lang="ts">
interface Props {
  as?: 'article' | 'div' | 'section'
}

withDefaults(defineProps<Props>(), {
  as: 'div',
})

defineSlots<{
  default(): unknown
}>()
</script>

<template>
  <component :is="as" class="surface-card">
    <slot />
  </component>
</template>

<style scoped lang="scss">
.surface-card {
  border: 1px solid var(--line);
  border-radius: 22px;
  background: rgba(255, 255, 255, 0.76);
  box-shadow: var(--shadow-sm);
}
</style>
