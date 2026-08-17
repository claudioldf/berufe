<script setup lang="ts">
import { computed } from "vue";
import type {
  Evidence,
  ProfessionalVerificationState,
  VerificationSubmission,
} from "~/types";

const props = defineProps<{
  evidence: Evidence[];
  verification: ProfessionalVerificationState;
  submitting?: boolean;
  serverError?: string;
}>();
const emit = defineEmits<{
  submitted: [submission: VerificationSubmission];
}>();
const status = computed(() => props.verification.current);
const statusLabels = {
  pending_review: "Aguardando análise",
  approved: "Identidade verificada",
  rejected: "Evidência recusada",
  expired: "Verificação expirada",
} as const;
const canSubmit = computed(
  () => !status.value || ["rejected", "expired"].includes(status.value.status),
);
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
      <div v-if="status" class="verification-panel__status">
        <span><UIcon name="i-lucide-shield-check" /></span>
        <div>
          <strong>{{ statusLabels[status.status] }}</strong>
          <p v-if="status.rejectionReason">{{ status.rejectionReason }}</p>
          <p v-else-if="status.status === 'pending_review'">
            A evidência está privada enquanto a equipe Berufe faz a conferência.
          </p>
        </div>
      </div>
      <p
        v-if="props.serverError"
        class="verification-panel__error"
        role="alert"
      >
        {{ props.serverError }}
      </p>
      <DashboardVerificationIdentityUploadForm
        v-if="canSubmit"
        :submitting="props.submitting"
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
  &__status {
    display: flex;
    gap: 11px;
    align-items: start;
  }
  &__status > span {
    display: grid;
    place-items: center;
    width: 38px;
    height: 38px;
    border-radius: 50%;
    background: var(--color-brand-tint-subtle);
    color: var(--color-brand);
  }
  &__status strong {
    font-size: 0.9rem;
  }
  &__status p {
    margin: 4px 0 0;
    color: var(--ink-soft);
    font-size: 0.82rem;
    line-height: 1.5;
  }
  &__status + .identity-upload-form {
    margin-top: 20px;
    padding-top: 20px;
    border-top: 1px solid var(--line);
  }
  &__error {
    margin: 0 0 14px;
    color: var(--color-danger);
    font-size: 0.84rem;
    font-weight: 700;
  }
}
</style>
