<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  tone?: 'default' | 'inverse'
}

const props = withDefaults(defineProps<Props>(), {
  tone: 'default',
})

defineSlots<{
  default(): unknown
}>()

const classes = computed(() => [
  'eyebrow',
  `eyebrow--${props.tone}`,
])
</script>

<template>
  <p :class="classes">
    <slot />
  </p>
</template>

<style scoped lang="scss">
.eyebrow {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  margin: 0 0 16px;
  color: #397a69;
  font-size: 0.82rem;
  font-weight: 800;
  letter-spacing: 0.14em;
  text-transform: uppercase;

  &::before {
    width: 24px;
    height: 2px;
    background: var(--coral);
    content: "";
  }

  &--inverse {
    color: #a8d8c9;
  }
}
</style>
