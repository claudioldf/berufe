<script setup lang="ts">
interface Props {
  as?: "h1" | "h2" | "h3" | "h4";
  variant?: "display" | "section" | "workspace";
  tone?: "default" | "inverse";
}

withDefaults(defineProps<Props>(), {
  as: "h2",
  variant: "section",
  tone: "default",
});

defineSlots<{
  default(): unknown;
}>();
</script>

<template>
  <component
    :is="as"
    class="heading"
    :class="[`heading--${variant}`, `heading--${tone}`]"
  >
    <slot />
  </component>
</template>

<style scoped lang="scss">
.heading {
  margin: 0;
  font-family: var(--font-display);
  font-weight: 500;
  text-wrap: balance;

  &--display {
    font-size: clamp(2.6rem, 6vw, 5.8rem);
    letter-spacing: -0.055em;
    line-height: 0.96;
  }

  &--section {
    font-size: clamp(2rem, 4vw, 3.6rem);
    letter-spacing: -0.04em;
    line-height: 1.02;
  }

  &--workspace {
    font-size: clamp(1.8rem, 3vw, 2.8rem);
    letter-spacing: -0.035em;
    line-height: 1.05;
  }

  &--inverse {
    color: var(--color-text-inverse);
  }
}
</style>
