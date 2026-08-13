<script setup lang="ts">
interface Props {
  size?: 'sm' | 'md' | 'lg'
}

withDefaults(defineProps<Props>(), {
  size: 'md',
})
</script>

<template>
  <NuxtLink class="brand" :class="`brand--${size}`" to="/" aria-label="Berufe — início">
    berufe<span>.</span>
  </NuxtLink>
</template>

<style scoped>
.brand {
  color: inherit;
  font-family: Georgia, "Times New Roman", serif;
  font-weight: 700;
  letter-spacing: -.045em;
  line-height: 1;
  text-decoration: none;
}

.brand--sm { font-size: 1.35rem; }
.brand--md { font-size: 1.72rem; }
.brand--lg { font-size: 2rem; }

.brand span {
  color: var(--coral);
}
</style>
