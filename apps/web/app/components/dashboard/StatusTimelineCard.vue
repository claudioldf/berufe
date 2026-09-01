<script setup lang="ts">
type StatusTone = "brand" | "warning" | "success" | "neutral" | "danger";
type StepState = "done" | "current" | "upcoming";

interface StatusTimelineStep {
  label: string;
  description: string;
  state: StepState;
}

interface StatusTimelineNote {
  label: string;
  message: string;
  icon: string;
  tone?: "accent" | "neutral";
  quoted?: boolean;
}

const props = withDefaults(
  defineProps<{
    kicker: string;
    title: string;
    description: string;
    icon: string;
    tone: StatusTone;
    steps: StatusTimelineStep[];
    progressLabel: string;
    progressMuted?: boolean;
    note?: StatusTimelineNote;
  }>(),
  {
    progressMuted: false,
    note: undefined,
  },
);
</script>

<template>
  <DesignSystemSurfaceCard
    as="section"
    class="status-card"
    :class="`status-card--${props.tone}`"
  >
    <div class="status-card__summary">
      <span class="status-card__icon" aria-hidden="true">
        <UIcon :name="props.icon" />
      </span>
      <div class="status-card__copy">
        <span class="status-card__kicker">{{ props.kicker }}</span>
        <h2>{{ props.title }}</h2>
        <p>{{ props.description }}</p>
      </div>
    </div>

    <blockquote
      v-if="props.note"
      :class="{
        'status-card__note--neutral': props.note.tone === 'neutral',
      }"
    >
      <UIcon :name="props.note.icon" aria-hidden="true" />
      <div>
        <span>{{ props.note.label }}</span>
        <p>
          {{
            props.note.quoted ? `“${props.note.message}”` : props.note.message
          }}
        </p>
      </div>
    </blockquote>

    <ol
      class="status-card__progress"
      :class="{
        'status-card__progress--muted': props.progressMuted,
      }"
      :aria-label="props.progressLabel"
    >
      <li
        v-for="step in props.steps"
        :key="step.label"
        :class="`status-card__step--${step.state}`"
        :aria-current="step.state === 'current' ? 'step' : undefined"
      >
        <span class="status-card__step-marker" aria-hidden="true">
          <UIcon v-if="step.state === 'done'" name="i-lucide-check" />
          <span v-else />
        </span>
        <span class="status-card__step-copy">
          <strong>{{ step.label }}</strong>
          <small>{{ step.description }}</small>
        </span>
      </li>
    </ol>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.status-card {
  position: relative;
  display: grid;
  grid-template-columns: minmax(260px, 0.82fr) minmax(420px, 1.18fr);
  gap: 36px;
  padding: 30px 32px;
  background: rgb(255 255 255 / 97%);
  box-shadow: 0 24px 60px rgb(24 49 43 / 12%);

  &--warning {
    border-top-color: var(--color-warning);
  }

  &--success {
    border-top-color: #4c8b69;
  }

  &--neutral {
    border-top-color: #84938e;
  }

  &--danger {
    border-top-color: var(--color-danger);
  }

  &__summary {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 15px;
    align-items: start;
  }

  &__icon {
    display: grid;
    place-items: center;
    width: 48px;
    height: 48px;
    border-radius: 15px;
    background: var(--color-brand-tint);
    color: var(--color-brand);
    font-size: 1.3rem;
  }

  &--warning &__icon {
    background: var(--color-warning-tint);
    color: var(--color-warning);
  }

  &--success &__icon {
    background: #e9f5ed;
    color: #397657;
  }

  &--neutral &__icon {
    background: var(--color-surface-muted);
    color: var(--color-text-muted);
  }

  &--danger &__icon {
    background: var(--color-danger-tint);
    color: var(--color-danger);
  }

  &__kicker {
    color: var(--color-text-subtle);
    font-size: 0.7rem;
    font-weight: 850;
    letter-spacing: 0.11em;
    text-transform: uppercase;
  }

  &__copy h2 {
    margin: 3px 0 6px;
    font-family: var(--font-display);
    font-size: 1.75rem;
    font-weight: 600;
    letter-spacing: -0.03em;
    line-height: 1.05;
  }

  &__copy > p {
    max-width: 390px;
    margin: 0;
    color: var(--ink-soft);
    font-size: 0.9rem;
    line-height: 1.55;
  }

  &__progress {
    display: grid;
    grid-auto-columns: 1fr;
    grid-auto-flow: column;
    align-self: center;
    margin: 0;
    padding: 4px 0 0;
    list-style: none;
  }

  &__progress li {
    position: relative;
    display: grid;
    gap: 10px;
  }

  &__progress li:not(:last-child)::after {
    position: absolute;
    top: 13px;
    right: 14px;
    left: 36px;
    height: 2px;
    background: var(--color-border);
    content: "";
  }

  &__progress li.status-card__step--done::after {
    background: var(--color-brand-soft-strong);
  }

  &__step-marker {
    position: relative;
    z-index: 1;
    display: grid;
    place-items: center;
    width: 28px;
    height: 28px;
    border: 2px solid var(--color-border);
    border-radius: 50%;
    background: white;
    color: white;
    font-size: 0.86rem;
  }

  &__step-marker > span {
    width: 16px;
    height: 16px;
    border-radius: 50%;
    background: #ffffff;
  }

  &__step--done &__step-marker {
    border-color: var(--color-brand);
    background: var(--color-brand);
  }

  &__step--current &__step-marker {
    border-color: var(--color-warning);
    box-shadow: 0 0 0 5px var(--color-accent-tint);
    & > span {
      background: var(--color-warning);
    }
  }

  &--warning &__step--current &__step-marker {
    border-color: var(--color-warning);
    box-shadow: 0 0 0 5px var(--color-warning-tint);
  }

  &--warning &__step--current &__step-marker > span {
    background: var(--color-warning);
  }

  &__step-copy {
    display: grid;
    gap: 2px;
    padding-right: 10px;
  }

  &__step-copy strong {
    font-size: 0.76rem;
  }

  &__step-copy small {
    color: var(--color-text-subtle);
    font-size: 0.68rem;
    line-height: 1.35;
  }

  &__step--upcoming &__step-copy strong {
    color: var(--color-text-subtle);
    font-weight: 650;
  }

  &__progress--muted {
    opacity: 0.52;
  }

  & blockquote {
    grid-column: 1 / -1;
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 12px;
    margin: -12px 0 0 63px;
    padding: 13px 15px;
    border: 0;
    border-radius: 12px;
    background: var(--color-accent-tint);
    color: var(--color-danger);
  }

  & blockquote > svg {
    margin-top: 2px;
  }

  & blockquote span {
    font-size: 0.7rem;
    font-weight: 850;
    letter-spacing: 0.08em;
    text-transform: uppercase;
  }

  & blockquote p {
    margin: 2px 0 0;
    color: var(--ink);
    font-size: 0.86rem;
    line-height: 1.45;
  }

  & &__note--neutral {
    background: var(--color-surface-muted);
    color: var(--color-text-muted);
  }
}

@media (width <= 860px) {
  .status-card {
    grid-template-columns: 1fr;
    gap: 28px;

    & blockquote {
      margin-top: -12px;
    }
  }
}

@media (width <= 560px) {
  .status-card {
    gap: 24px;
    padding: 24px 20px;
    border-radius: 18px;

    &__summary {
      grid-template-columns: 1fr;
    }

    &__icon {
      width: 42px;
      height: 42px;
    }

    & blockquote {
      margin-left: 0;
    }

    &__progress {
      grid-template-columns: 1fr;
      grid-auto-flow: row;
      gap: 0;
      padding-left: 5px;
    }

    &__progress li {
      grid-template-columns: auto 1fr;
      gap: 12px;
      padding-bottom: 18px;
    }

    &__progress li:last-child {
      padding-bottom: 0;
    }

    &__progress li:not(:last-child)::after {
      top: 31px;
      bottom: 3px;
      left: 13px;
      width: 2px;
      height: auto;
    }

    &__step-copy {
      padding-top: 3px;
    }
  }
}
</style>
