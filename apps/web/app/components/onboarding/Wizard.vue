<script setup lang="ts">
import { computed, nextTick, shallowRef, useTemplateRef, watch } from "vue";
import type {
  Neighborhood,
  OnboardingStepId,
  PortfolioItemDraft,
  ProfessionalProfileDraft,
  ProfessionalWorkspace,
  Service,
} from "~/types";
import {
  professionalOnboardingSteps,
  useProfessionalOnboarding,
} from "~/composables/useProfessionalOnboarding";

const props = defineProps<{
  services: Service[];
  neighborhoods: Neighborhood[];
  workspace: ProfessionalWorkspace;
  saveIdentity: (
    draft: ProfessionalProfileDraft,
  ) => Promise<ProfessionalProfileDraft>;
  saveSupply: (
    draft: ProfessionalProfileDraft,
  ) => Promise<ProfessionalProfileDraft>;
}>();

const route = useRoute();
const router = useRouter();
const {
  state,
  hydrated,
  stepCompletion,
  progress,
  isComplete,
  firstIncompleteStep,
  completeProfile,
  completeServices,
  completePortfolio,
  completeVerification,
  initializeFromWorkspace,
  profileSaving,
  profileError,
  supplySaving,
  supplyError,
} = useProfessionalOnboarding({
  saveIdentity: props.saveIdentity,
  saveSupply: props.saveSupply,
});

const activeStep = shallowRef<OnboardingStepId>("profile");
const reviewing = shallowRef(false);
const panel = useTemplateRef<HTMLElement>("step-panel");
const activeStepIndex = computed(() =>
  professionalOnboardingSteps.findIndex((step) => step.id === activeStep.value),
);
const firstIncompleteIndex = computed(() =>
  professionalOnboardingSteps.findIndex(
    (step) => step.id === firstIncompleteStep.value,
  ),
);
const professionalName = computed(
  () => state.value.profile.name.trim().split(" ")[0] || "profissional",
);
const editableProfile = computed<ProfessionalProfileDraft>(() => ({
  ...state.value.profile,
  selectedServices: [...state.value.profile.selectedServices],
  selectedNeighborhoods: [...state.value.profile.selectedNeighborhoods],
}));
const selectedServices = computed(() => [
  ...state.value.profile.selectedServices,
]);
const availableSteps = computed(() =>
  professionalOnboardingSteps
    .filter((step) => canVisitStep(step.id))
    .map((step) => step.id),
);

function isStepId(value: unknown): value is OnboardingStepId {
  return professionalOnboardingSteps.some((step) => step.id === value);
}

function canVisitStep(stepId: OnboardingStepId) {
  if (isComplete.value) return true;
  const index = professionalOnboardingSteps.findIndex(
    (step) => step.id === stepId,
  );
  return index <= firstIncompleteIndex.value || stepCompletion.value[stepId];
}

async function focusPanel() {
  await nextTick();
  panel.value?.focus();
}

async function goToStep(stepId: OnboardingStepId) {
  if (!canVisitStep(stepId)) return;
  activeStep.value = stepId;
  await router.replace({ query: { step: stepId } });
  await focusPanel();
}

function previousStep() {
  const previous = professionalOnboardingSteps[activeStepIndex.value - 1];
  if (previous) void goToStep(previous.id);
}

async function handleProfile(draft: ProfessionalProfileDraft) {
  if (await completeProfile(draft)) void goToStep("services");
}

async function handleServices(draft: ProfessionalProfileDraft) {
  if (await completeServices(draft)) void goToStep("portfolio");
}

function handlePortfolio(draft: PortfolioItemDraft) {
  if (completePortfolio(draft)) void goToStep("verification");
}

function handleVerification(file: File) {
  if (!completeVerification(file)) return;
  reviewing.value = false;
  void router.replace({ query: {} });
}

function reviewSteps() {
  reviewing.value = true;
  void goToStep("profile");
}

function finishReview() {
  reviewing.value = false;
  void router.replace({ query: {} });
}

watch(
  [hydrated, () => route.query.step],
  ([isHydrated, requestedStep]) => {
    if (!isHydrated || (isComplete.value && !reviewing.value)) return;
    const stepId = isStepId(requestedStep)
      ? requestedStep
      : firstIncompleteStep.value;
    activeStep.value = canVisitStep(stepId)
      ? stepId
      : firstIncompleteStep.value;
  },
  { immediate: true },
);

watch(
  () => props.workspace.profile.identity,
  (identity) => {
    const selections = props.workspace.profile.services;
    initializeFromWorkspace({
      ...editableProfile.value,
      ...identity,
      selectedServices: selections.map((selection) => selection.name),
      primaryService:
        selections.find((selection) => selection.isPrimary)?.name ?? "",
      serviceNotes: Object.fromEntries(
        selections.map((selection) => [selection.name, selection.note]),
      ),
      allJoinville: props.workspace.profile.coverage.allJoinville,
      selectedNeighborhoods: props.workspace.profile.coverage.neighborhoods.map(
        (neighborhood) => neighborhood.name,
      ),
    });
  },
  { immediate: true },
);
</script>

<template>
  <div class="onboarding-page">
    <section class="onboarding-hero">
      <DesignSystemContainer class="onboarding-hero__inner">
        <div>
          <DesignSystemEyebrow>Primeiros passos</DesignSystemEyebrow>
          <h1>Vamos deixar seu perfil pronto, {{ professionalName }}.</h1>
          <p>
            Complete quatro etapas simples para apresentar seu trabalho com
            clareza. Você pode sair e continuar depois.
          </p>
        </div>
        <UButton to="/app/professional" color="neutral" variant="outline">
          Pular por agora
        </UButton>
      </DesignSystemContainer>
    </section>

    <DesignSystemContainer class="onboarding-content">
      <DesignSystemSurfaceCard
        v-if="!hydrated"
        as="section"
        class="onboarding-loading"
        aria-live="polite"
      >
        <UIcon name="i-lucide-circle-dot" />
        <p>Preparando suas etapas…</p>
      </DesignSystemSurfaceCard>

      <OnboardingSuccess
        v-else-if="isComplete && !reviewing"
        @review="reviewSteps"
      />

      <div v-else class="onboarding-workspace">
        <OnboardingProgress
          :progress="progress"
          :steps="professionalOnboardingSteps"
          :completion="stepCompletion"
          :active-step="activeStep"
          :available-steps="availableSteps"
          @select="goToStep"
        />

        <DesignSystemSurfaceCard
          ref="step-panel"
          class="onboarding-panel"
          tabindex="-1"
        >
          <OnboardingProfileStep
            v-if="activeStep === 'profile'"
            :key="`profile-${state.completion.profile ?? 'new'}`"
            :draft="editableProfile"
            :saving="profileSaving"
            :server-error="profileError"
            @complete="handleProfile"
          />
          <OnboardingServicesStep
            v-else-if="activeStep === 'services'"
            :key="`services-${state.completion.services ?? 'new'}`"
            :draft="editableProfile"
            :services="services"
            :neighborhoods="neighborhoods"
            :saving="supplySaving"
            :server-error="supplyError"
            @back="previousStep"
            @complete="handleServices"
          />
          <OnboardingPortfolioStep
            v-else-if="activeStep === 'portfolio'"
            :portfolio="state.portfolio"
            :service-options="selectedServices"
            @back="previousStep"
            @complete="handlePortfolio"
            @continue="goToStep('verification')"
          />
          <OnboardingVerificationStep
            v-else
            :submitted="state.verificationStatus === 'submitted'"
            @back="previousStep"
            @complete="handleVerification"
            @finish="finishReview"
          />
        </DesignSystemSurfaceCard>
      </div>
    </DesignSystemContainer>
  </div>
</template>

<style scoped lang="scss">
.onboarding-page {
  min-height: 100vh;
  background: var(--color-surface-canvas);
}

.onboarding-hero {
  padding: 42px 0 46px;
  background: var(--color-brand-strong);
  color: white;

  &__inner {
    display: flex;
    justify-content: space-between;
    align-items: end;
    gap: 30px;
  }
  & h1 {
    max-width: 760px;
    margin: 9px 0 0;
    font-family: var(--font-display);
    font-size: clamp(2.3rem, 5vw, 4rem);
    font-weight: 500;
    letter-spacing: -0.045em;
    line-height: 1;
  }
  & p {
    max-width: 680px;
    margin: 15px 0 0;
    color: rgb(255 255 255 / 68%);
    font-size: 0.9rem;
    line-height: 1.65;
  }
}

.onboarding-content {
  padding-top: 26px;
  padding-bottom: 80px;
}

.onboarding-workspace {
  display: grid;
  grid-template-columns: 290px minmax(0, 1fr);
  align-items: start;
  gap: 18px;
}

.onboarding-panel {
  min-width: 0;
  padding: 28px;
}

.onboarding-panel:focus {
  outline: none;
}

:deep() {
  .onboarding-step-heading {
    padding-bottom: 23px;
  }
  .onboarding-step-heading h2 {
    margin: 7px 0 0;
    font-family: var(--font-display);
    font-size: clamp(1.9rem, 4vw, 2.7rem);
    font-weight: 500;
    letter-spacing: -0.035em;
  }
  .onboarding-step-heading > p {
    max-width: 690px;
    margin: 10px 0 0;
    color: var(--ink-soft);
    font-size: 0.88rem;
    line-height: 1.6;
  }
  .onboarding-step-form {
    display: grid;
    gap: 16px;
  }
  .onboarding-step-error {
    display: flex;
    align-items: center;
    gap: 7px;
    margin: 0;
    padding: 11px 13px;
    border-radius: 10px;
    background: var(--color-danger-tint);
    color: var(--color-danger);
    font-size: 0.84rem;
    font-weight: 750;
  }
  .onboarding-step-actions {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 10px;
    margin-top: 20px;
    padding-top: 18px;
    border-top: 1px solid var(--line);
  }
  .onboarding-step-actions--end {
    justify-content: flex-end;
  }
  .onboarding-step-actions--start {
    justify-content: flex-start;
  }
  .onboarding-step-actions button,
  .onboarding-upload-card button {
    min-height: 44px;
  }
  .onboarding-upload-card {
    padding: 22px;
  }
  .onboarding-complete-card {
    display: grid;
    grid-template-columns: auto 1fr;
    align-items: center;
    gap: 13px;
    padding: 20px;
    border-color: #b6d9cd;
    background: #eef8f4;
  }
  .onboarding-complete-card > span {
    display: grid;
    place-items: center;
    width: 42px;
    height: 42px;
    border-radius: 12px;
    background: white;
    color: var(--color-brand);
  }
  .onboarding-complete-card strong,
  .onboarding-complete-card p {
    margin: 0;
  }
  .onboarding-complete-card p {
    margin-top: 4px;
    color: var(--ink-soft);
    font-size: 0.84rem;
  }
}

.onboarding-loading {
  min-height: 360px;
  padding: 38px;
}

.onboarding-loading {
  display: grid;
  place-items: center;
  align-content: center;
  gap: 10px;
  color: var(--ink-soft);
}

@media (width <= 900px) {
  .onboarding-workspace {
    grid-template-columns: 1fr;
  }
}

@media (width <= 650px) {
  .onboarding-hero {
    &__inner {
      display: grid;
    }
  }
  .onboarding-panel {
    padding: 20px;
  }
}
</style>
