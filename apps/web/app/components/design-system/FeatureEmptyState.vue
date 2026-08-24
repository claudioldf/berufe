<script setup lang="ts">
interface FeatureEmptyStateVisual {
  icon: string;
  title: string;
  caption: string;
  metaLabel: string;
  metaValue: string;
  badge: string;
  badgeIcon?: string;
}

interface Props {
  eyebrow: string;
  title: string;
  description: string;
  items?: string[];
  ctaLabel?: string;
  ctaTo?: string;
  ctaIcon?: string;
  visual: FeatureEmptyStateVisual;
}

const props = withDefaults(defineProps<Props>(), {
  items: () => [],
  ctaLabel: "",
  ctaTo: undefined,
  ctaIcon: "i-lucide-plus",
});

const emit = defineEmits<{
  action: [];
}>();

function handleAction() {
  if (!props.ctaTo) emit("action");
}
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="feature-empty">
    <div class="feature-empty__copy">
      <span class="feature-empty__kicker">
        <UIcon name="i-lucide-sparkles" aria-hidden="true" />
        {{ eyebrow }}
      </span>
      <h3>{{ title }}</h3>
      <p>{{ description }}</p>
      <ul v-if="items.length">
        <li v-for="item in items" :key="item">
          <UIcon name="i-lucide-circle-check" aria-hidden="true" />
          {{ item }}
        </li>
      </ul>
      <UButton
        v-if="ctaLabel"
        :to="ctaTo"
        color="primary"
        :icon="ctaIcon"
        size="lg"
        @click="handleAction"
      >
        {{ ctaLabel }}
      </UButton>
    </div>

    <div class="feature-empty__visual" aria-hidden="true">
      <div class="feature-empty__document">
        <header>
          <span><UIcon :name="visual.icon" /></span>
          <div>
            <strong>{{ visual.title }}</strong>
            <small>{{ visual.caption }}</small>
          </div>
        </header>
        <div class="feature-empty__line feature-empty__line--wide" />
        <div class="feature-empty__line" />
        <div class="feature-empty__line feature-empty__line--short" />
        <footer>
          <span>{{ visual.metaLabel }}</span>
          <strong>{{ visual.metaValue }}</strong>
        </footer>
      </div>
      <span class="feature-empty__badge">
        <UIcon :name="visual.badgeIcon ?? 'i-lucide-sparkles'" />
        {{ visual.badge }}
      </span>
    </div>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.feature-empty {
  position: relative;
  isolation: isolate;
  display: grid;
  grid-template-columns: minmax(0, 1.2fr) minmax(230px, 0.8fr);
  gap: clamp(28px, 5vw, 64px);
  overflow: hidden;
  padding: clamp(24px, 4vw, 44px);
  background:
    radial-gradient(circle at 92% 12%, rgb(182 223 207 / 62%), transparent 34%),
    linear-gradient(135deg, #fff 0%, var(--color-brand-tint-subtle) 100%);

  &::before {
    position: absolute;
    z-index: -1;
    right: -80px;
    bottom: -120px;
    width: 280px;
    height: 280px;
    border: 1px solid rgb(18 98 93 / 12%);
    border-radius: 50%;
    content: "";
  }

  &__copy {
    position: relative;
    z-index: 1;
    align-self: center;
  }

  &__kicker {
    display: inline-flex;
    align-items: center;
    gap: 7px;
    color: var(--color-brand);
    font-size: 0.78rem;
    font-weight: 850;
    letter-spacing: 0.04em;
    text-transform: uppercase;
  }

  &__copy h3 {
    max-width: 540px;
    margin: 12px 0 10px;
    font-family: var(--font-display);
    font-size: clamp(1.75rem, 4vw, 2.45rem);
    font-weight: 500;
    letter-spacing: -0.04em;
    line-height: 1.02;
  }

  &__copy > p {
    max-width: 590px;
    margin: 0;
    color: var(--ink-soft);
    font-size: 0.94rem;
    line-height: 1.65;
  }

  &__copy ul {
    display: grid;
    gap: 9px;
    margin: 20px 0 24px;
    padding: 0;
    list-style: none;
  }

  &__copy li {
    display: flex;
    align-items: center;
    gap: 9px;
    color: var(--ink);
    font-size: 0.84rem;
    font-weight: 720;
  }

  &__copy li svg {
    flex: 0 0 auto;
    color: var(--color-brand);
  }

  &__visual {
    position: relative;
    display: grid;
    place-items: center;
    min-height: 280px;
  }

  &__visual::before {
    position: absolute;
    width: min(100%, 310px);
    aspect-ratio: 1;
    border-radius: 50%;
    background: rgb(255 255 255 / 54%);
    content: "";
  }

  &__document {
    position: relative;
    width: min(88%, 270px);
    padding: 20px;
    border: 1px solid rgb(18 98 93 / 14%);
    border-radius: 18px;
    background: white;
    box-shadow: 0 24px 52px rgb(23 53 47 / 16%);
    transform: rotate(-3deg);
  }

  &__document header {
    display: flex;
    align-items: center;
    gap: 11px;
    margin-bottom: 22px;
  }

  &__document header > span {
    display: grid;
    place-items: center;
    width: 38px;
    height: 38px;
    border-radius: 11px;
    background: var(--mint);
    color: var(--color-brand);
  }

  &__document header strong,
  &__document header small {
    display: block;
  }

  &__document header strong {
    font-size: 0.86rem;
  }

  &__document header small {
    margin-top: 2px;
    color: var(--ink-soft);
    font-size: 0.7rem;
  }

  &__line {
    width: 72%;
    height: 8px;
    margin-top: 10px;
    border-radius: 99px;
    background: #e8ece9;
  }

  &__line--wide {
    width: 100%;
  }

  &__line--short {
    width: 48%;
  }

  &__document footer {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-top: 25px;
    padding-top: 16px;
    border-top: 1px solid var(--line);
    font-size: 0.78rem;
  }

  &__document footer span {
    color: var(--ink-soft);
  }

  &__document footer strong {
    color: var(--color-brand);
  }

  &__badge {
    position: absolute;
    right: 0;
    bottom: 28px;
    display: inline-flex;
    align-items: center;
    gap: 7px;
    padding: 9px 12px;
    border: 1px solid rgb(18 98 93 / 14%);
    border-radius: 999px;
    background: white;
    box-shadow: var(--shadow-sm);
    color: var(--color-brand);
    font-size: 0.72rem;
    font-weight: 850;
  }
}

@media (width <= 760px) {
  .feature-empty {
    grid-template-columns: 1fr;

    &__visual {
      min-height: 230px;
    }

    &__badge {
      right: 8%;
      bottom: 8px;
    }
  }
}
</style>
