<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  name: string
  src?: string
  alt?: string
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'profile'
  shape?: 'circle' | 'rounded'
  verified?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  src: undefined,
  alt: undefined,
  size: 'md',
  shape: 'circle',
  verified: false,
})

const initials = computed(() => props.name
  .trim()
  .split(/\s+/)
  .slice(0, 2)
  .map(part => part.charAt(0))
  .join('')
  .toLocaleUpperCase('pt-BR'))

const classes = computed(() => [
  'avatar',
  `avatar--${props.size}`,
  `avatar--${props.shape}`,
])
</script>

<template>
  <span :class="classes">
    <img v-if="src" class="avatar__image" :src="src" :alt="alt ?? `Foto de ${name}`">
    <span v-else class="avatar__fallback" :aria-label="name">{{ initials }}</span>
    <span v-if="verified" class="avatar__verified" aria-label="Identidade verificada">
      <UIcon name="i-lucide-badge-check" />
    </span>
  </span>
</template>

<style scoped>
.avatar {
  position: relative;
  display: inline-grid;
  flex: 0 0 auto;
  overflow: visible;
}

.avatar--xs { width: 35px; height: 35px; }
.avatar--sm { width: 42px; height: 42px; }
.avatar--md { width: 54px; height: 54px; }
.avatar--lg { width: 74px; height: 74px; }
.avatar--profile { width: 165px; height: 185px; }

.avatar__image,
.avatar__fallback {
  width: 100%;
  height: 100%;
  overflow: hidden;
  background: var(--mint);
  object-fit: cover;
}

.avatar--circle .avatar__image,
.avatar--circle .avatar__fallback {
  border-radius: 999px;
}

.avatar--rounded .avatar__image,
.avatar--rounded .avatar__fallback {
  border-radius: 16px;
}

.avatar--profile .avatar__image,
.avatar--profile .avatar__fallback {
  border-radius: 28px;
}

.avatar__fallback {
  display: grid;
  place-items: center;
  color: #397a69;
  font-weight: 900;
}

.avatar__verified {
  position: absolute;
  right: -3px;
  bottom: -3px;
  display: grid;
  place-items: center;
  width: 20px;
  height: 20px;
  border: 3px solid var(--paper);
  border-radius: 999px;
  background: var(--coral);
  color: white;
  font-size: .75rem;
}

.avatar--profile .avatar__verified {
  right: 4px;
  bottom: 4px;
  width: 38px;
  height: 38px;
  border-width: 4px;
  border-color: #17352f;
  font-size: 1.1rem;
}

@media (max-width: 680px) {
  .avatar--lg {
    width: 54px;
    height: 54px;
  }

  .avatar--profile {
    width: 90px;
    height: 108px;
  }

  .avatar--profile .avatar__verified {
    width: 30px;
    height: 30px;
  }
}
</style>
