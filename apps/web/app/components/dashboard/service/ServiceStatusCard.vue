<script setup lang="ts">
import { computed } from "vue";
import type { ProfessionalServiceJob } from "~/types";

type StatusTone = "brand" | "warning" | "success" | "neutral";
type StepState = "done" | "current" | "upcoming";

const props = defineProps<{
  service: ProfessionalServiceJob;
  title: string;
  description: string;
  icon: string;
  tone: StatusTone;
}>();

const currentStep = computed(() => {
  if (props.service.status === "completed") return 1;
  return 0;
});

const progressSteps = computed<
  Array<{ label: string; description: string; state: StepState }>
>(() => {
  const steps = [
    { label: "Aprovado", description: "Aceito pelo cliente" },
    {
      label: "Concluído",
      description:
        props.service.status === "completed"
          ? "Registrado por você"
          : "Etapa final",
    },
  ];

  return steps.map((step, index) => ({
    ...step,
    state:
      props.service.status === "cancelled"
        ? "upcoming"
        : index < currentStep.value
          ? "done"
          : index === currentStep.value
            ? "current"
            : "upcoming",
  }));
});
</script>

<template>
  <DesignSystemSurfaceCard
    as="section"
    class="status-card"
    :class="`status-card--${tone}`"
  >
    <div class="status-card__summary">
      <span class="status-card__icon" aria-hidden="true">
        <UIcon :name="icon" />
      </span>
      <div class="status-card__copy">
        <span class="status-card__kicker">Status do serviço</span>
        <h2>{{ title }}</h2>
        <p>{{ description }}</p>
      </div>
    </div>

    <blockquote v-if="service.customerFeedbackMessage">
      <UIcon name="i-lucide-message-circle" aria-hidden="true" />
      <div>
        <span>Mensagem do cliente</span>
        <p>“{{ service.customerFeedbackMessage }}”</p>
      </div>
    </blockquote>

    <blockquote
      v-else-if="service.status === 'cancelled' && service.cancellationReason"
      class="status-card__cancellation"
    >
      <UIcon name="i-lucide-info" aria-hidden="true" />
      <div>
        <span>Motivo do cancelamento</span>
        <p>{{ service.cancellationReason }}</p>
      </div>
    </blockquote>

    <ol
      class="status-card__progress"
      :class="{
        'status-card__progress--cancelled': service.status === 'cancelled',
      }"
      aria-label="Etapas do serviço"
    >
      <li
        v-for="step in progressSteps"
        :key="step.label"
        :class="`status-card__step--${step.state}`"
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
  border-top: 4px solid var(--color-brand);
  background: rgb(255 255 255 / 96%);
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
    grid-template-columns: repeat(2, 1fr);
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
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background: var(--color-border-strong);
  }

  &__step--done &__step-marker {
    border-color: var(--color-brand);
    background: var(--color-brand);
  }

  &__step--current &__step-marker {
    border-color: var(--color-brand);
    box-shadow: 0 0 0 5px var(--color-brand-tint);
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

  &__progress--cancelled {
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

  & &__cancellation {
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
