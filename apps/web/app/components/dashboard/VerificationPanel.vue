<script setup lang="ts">
import type { Evidence, VerificationSubmission } from "~/types";

defineProps<{ evidence: Evidence[] }>();
const emit = defineEmits<{
  submitted: [submission: VerificationSubmission];
}>();
</script>

<template>
  <div class="verification-panel">
    <DesignSystemSurfaceCard as="section" class="verification-panel__intro"
      ><div>
        <DesignSystemEyebrow>Evidências específicas</DesignSystemEyebrow>
        <h2>Verificações</h2>
        <p>
          Os selos explicam exatamente o que a Berufe conferiu. Eles não são uma
          garantia de serviço.
        </p>
      </div>
      <UIcon name="i-lucide-shield-check"
    /></DesignSystemSurfaceCard>
    <DesignSystemSurfaceCard as="section" class="verification-panel__current"
      ><h3>Selos do seu perfil</h3>
      <div>
        <PublicEvidenceBadge
          v-for="item in evidence"
          :key="item.id"
          :evidence="item"
        /></div
    ></DesignSystemSurfaceCard>
    <DesignSystemSurfaceCard as="section" class="verification-panel__request">
      <DashboardVerificationIdentityUploadForm
        @submitted="emit('submitted', $event)"
      />
    </DesignSystemSurfaceCard>
  </div>
</template>

<style scoped lang="scss">
.verification-panel {
  display: grid;
  gap: 14px;
  &__intro {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 26px;
  }
  &__intro h2 {
    margin: 0;
    font-family: var(--font-display);
    font-size: 2rem;
  }
  &__intro p:last-child {
    max-width: 580px;
    margin: 7px 0 0;
    color: var(--ink-soft);
    font-size: 0.82rem;
    line-height: 1.5;
  }
  &__intro > svg {
    color: var(--color-brand);
    font-size: 3.5rem;
    opacity: 0.25;
  }
  &__current {
    padding: 22px;
  }
  & h3 {
    margin: 0;
    font-family: var(--font-display);
    font-size: 1.25rem;
  }
  &__current > div {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-top: 15px;
  }
  &__request {
    padding: 22px;
  }
}
</style>
