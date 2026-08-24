<script setup lang="ts">
import { computed } from "vue";

interface Props {
  name: string;
  src?: string;
  alt?: string;
  fallbackIcon?: string;
  size?: "xs" | "sm" | "md" | "lg" | "profile";
  shape?: "circle" | "rounded";
  verified?: boolean;
  loading?: "eager" | "lazy";
}

const props = withDefaults(defineProps<Props>(), {
  src: undefined,
  alt: undefined,
  fallbackIcon: undefined,
  size: "md",
  shape: "circle",
  verified: false,
  loading: "lazy",
});

const dimensions = {
  xs: { width: 35, height: 35 },
  sm: { width: 42, height: 42 },
  md: { width: 54, height: 54 },
  lg: { width: 74, height: 74 },
  profile: { width: 165, height: 185 },
} as const;

const imageDimensions = computed(() => dimensions[props.size]);

const initials = computed(() => {
  const value = props.name
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((part) => part.charAt(0))
    .join("")
    .toLocaleUpperCase("pt-BR");
  return value || "?";
});

const classes = computed(() => [
  "avatar",
  `avatar--${props.size}`,
  `avatar--${props.shape}`,
]);
</script>

<template>
  <span :class="classes">
    <img
      v-if="src"
      class="avatar__image"
      :src="src"
      :alt="alt ?? `Foto de ${name}`"
      :width="imageDimensions.width"
      :height="imageDimensions.height"
      :loading="loading"
    />
    <span v-else class="avatar__fallback" :aria-label="name || 'Avatar'">
      <UIcon
        v-if="fallbackIcon"
        class="avatar__fallback-icon"
        :name="fallbackIcon"
        aria-hidden="true"
      />
      <template v-else>{{ initials }}</template>
    </span>
    <span
      v-if="verified"
      class="avatar__verified"
      aria-label="Identidade verificada"
    >
      <UIcon name="i-lucide-badge-check" aria-hidden="true" />
    </span>
  </span>
</template>

<style scoped lang="scss">
.avatar {
  position: relative;
  display: inline-grid;
  flex: 0 0 auto;
  overflow: visible;

  &--xs {
    width: 35px;
    height: 35px;
  }
  &--sm {
    width: 42px;
    height: 42px;
  }
  &--md {
    width: 54px;
    height: 54px;
  }
  &--lg {
    width: 74px;
    height: 74px;
  }
  &--profile {
    width: 165px;
    height: 185px;
  }

  &__image,
  &__fallback {
    width: 100%;
    height: 100%;
    overflow: hidden;
    background: var(--mint);
    object-fit: cover;
  }

  &--circle &__image,
  &--circle &__fallback {
    border-radius: 999px;
  }

  &--rounded &__image,
  &--rounded &__fallback {
    border-radius: 16px;
  }

  &--profile &__image,
  &--profile &__fallback {
    border-radius: 28px;
  }

  &__fallback {
    display: grid;
    place-items: center;
    color: var(--color-brand);
    font-weight: 900;
  }

  &__fallback-icon {
    width: 45%;
    height: 45%;
  }

  &__verified {
    position: absolute;
    right: -3px;
    bottom: -3px;
    display: grid;
    place-items: center;
    width: 20px;
    height: 20px;
    border: 3px solid var(--paper);
    border-radius: var(--radius-pill);
    background: var(--coral);
    color: white;
    font-size: 0.75rem;
  }

  &--profile &__verified {
    right: 4px;
    bottom: 4px;
    width: 38px;
    height: 38px;
    border-width: 4px;
    border-color: var(--color-brand-strong);
    font-size: 1.1rem;
  }
}

@media (width <= 680px) {
  .avatar {
    &--lg {
      width: 54px;
      height: 54px;
    }

    &--profile {
      width: 90px;
      height: 108px;
    }

    &--profile &__verified {
      width: 30px;
      height: 30px;
    }
  }
}
</style>
