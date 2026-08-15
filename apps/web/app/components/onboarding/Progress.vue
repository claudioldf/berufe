<script setup lang="ts">
import type { OnboardingStepDefinition, OnboardingStepId } from "~/types";

defineProps<{
  progress: number;
  steps: OnboardingStepDefinition[];
  completion: Record<OnboardingStepId, boolean>;
  activeStep: OnboardingStepId;
  availableSteps: OnboardingStepId[];
}>();
defineEmits<{ select: [stepId: OnboardingStepId] }>();
</script>

<template>
  <DesignSystemSurfaceCard as="aside" class="onboarding-progress">
    <header>
      <div>
        <span>Progresso do perfil</span>
        <strong>{{ progress }}% completo</strong>
      </div>
      <span>{{ progress }}%</span>
    </header>
    <div
      class="onboarding-progress__track"
      role="progressbar"
      aria-label="Progresso do perfil"
      aria-valuemin="0"
      aria-valuemax="100"
      :aria-valuenow="progress"
    >
      <span :style="{ width: `${progress}%` }" />
    </div>
    <nav aria-label="Etapas do onboarding">
      <button
        v-for="(step, index) in steps"
        :key="step.id"
        type="button"
        :class="{
          active: activeStep === step.id,
          done: completion[step.id],
        }"
        :disabled="!availableSteps.includes(step.id)"
        :aria-current="activeStep === step.id ? 'step' : undefined"
        @click="$emit('select', step.id)"
      >
        <span>
          <UIcon :name="completion[step.id] ? 'i-lucide-check' : step.icon" />
        </span>
        <span>
          <small>Etapa {{ index + 1 }}</small>
          <strong>{{ step.label }}</strong>
          <em>{{ step.description }}</em>
        </span>
      </button>
    </nav>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.onboarding-progress {
  position: sticky;
  top: 18px;
  padding: 20px;

  & header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 12px;
  }
  & header span,
  & header strong {
    display: block;
  }
  & header div > span {
    color: var(--ink-soft);
    font-size: 0.82rem;
    font-weight: 750;
  }
  & header strong {
    margin-top: 3px;
    font-family: var(--font-display);
    font-size: 1.3rem;
  }
  & header > span {
    color: var(--color-brand);
    font-size: 0.86rem;
    font-weight: 900;
  }
  &__track {
    height: 7px;
    overflow: hidden;
    margin: 15px 0 18px;
    border-radius: var(--radius-pill);
    background: var(--color-surface-disabled);
  }
  &__track span {
    display: block;
    height: 100%;
    border-radius: inherit;
    background: var(--color-brand);
    transition: width var(--motion-normal) ease;
  }
  & nav {
    display: grid;
    gap: 5px;
  }
  & nav button {
    display: grid;
    grid-template-columns: auto 1fr;
    align-items: center;
    gap: 10px;
    width: 100%;
    padding: 11px;
    border: 1px solid transparent;
    border-radius: 12px;
    background: transparent;
    color: var(--ink);
    text-align: left;
    cursor: pointer;
  }
  & nav button:hover:not(:disabled),
  & nav button.active {
    border-color: var(--line);
    background: var(--color-brand-tint-subtle);
  }
  & nav button:disabled {
    cursor: not-allowed;
    opacity: 0.45;
  }
  & nav button > span:first-child {
    display: grid;
    place-items: center;
    width: 34px;
    height: 34px;
    border-radius: 10px;
    background: var(--paper-strong);
    color: var(--color-text-subtle);
  }
  & nav button.done > span:first-child {
    background: var(--mint);
    color: var(--color-brand);
  }
  & nav small,
  & nav strong,
  & nav em {
    display: block;
  }
  & nav small {
    color: var(--color-text-subtle);
    font-size: var(--font-size-min);
    font-weight: 750;
    text-transform: uppercase;
  }
  & nav strong {
    margin-top: 2px;
    font-size: 0.84rem;
  }
  & nav em {
    margin-top: 2px;
    color: var(--ink-soft);
    font-size: 0.78rem;
    font-style: normal;
  }
}

@media (width <= 900px) {
  .onboarding-progress {
    position: static;
  }
  .onboarding-progress nav {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (width <= 650px) {
  .onboarding-progress nav {
    grid-template-columns: 1fr;
  }
}
</style>
