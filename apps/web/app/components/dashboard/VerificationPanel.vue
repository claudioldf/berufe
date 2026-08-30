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
const phoneConfirmation = computed(() =>
  props.evidence.find((item) => item.label === "Telefone confirmado"),
);
const isApproved = computed(() => status.value?.status === "approved");
const canSubmit = computed(
  () => !status.value || ["rejected", "expired"].includes(status.value.status),
);
</script>

<template>
  <div class="verification-panel">
    <DesignSystemSurfaceCard as="section" class="verification-panel__intro"
      ><div>
        <DesignSystemEyebrow>Verificar conta</DesignSystemEyebrow>
        <h2>Verificações</h2>
        <p>
          Os selos explicam exatamente o que a Berufe conferiu. Eles não são uma
          garantia de serviço.
        </p>
      </div>
    </DesignSystemSurfaceCard>
    <DesignSystemSurfaceCard
      v-if="phoneConfirmation"
      as="section"
      class="verification-panel__phone verification-panel__confirmation"
      aria-labelledby="phone-confirmation-title"
    >
      <div
        class="verification-panel__status verification-panel__status--confirmed"
      >
        <span class="verification-panel__status-icon" aria-hidden="true">
          <UIcon name="i-lucide-smartphone" />
        </span>
        <div class="verification-panel__status-copy">
          <span class="verification-panel__status-eyebrow">
            Confirmação concluída
          </span>
          <h3 id="phone-confirmation-title">{{ phoneConfirmation.label }}</h3>
          <p>
            Você confirmou o acesso ao número cadastrado por código SMS. Essa
            confirmação ajuda a proteger sua conta.
          </p>
        </div>
      </div>
    </DesignSystemSurfaceCard>
    <DesignSystemSurfaceCard
      as="section"
      class="verification-panel__request"
      :class="{
        'verification-panel__confirmation': isApproved,
      }"
      :aria-labelledby="status ? 'identity-verification-title' : undefined"
    >
      <div
        v-if="status"
        class="verification-panel__status"
        :class="{
          'verification-panel__status--confirmed': isApproved,
        }"
      >
        <span class="verification-panel__status-icon" aria-hidden="true">
          <UIcon name="i-lucide-shield-check" />
        </span>
        <div class="verification-panel__status-copy">
          <span v-if="isApproved" class="verification-panel__status-eyebrow">
            Verificação concluída
          </span>
          <h3 id="identity-verification-title">
            {{ statusLabels[status.status] }}
          </h3>
          <p v-if="status.rejectionReason">{{ status.rejectionReason }}</p>
          <p v-else-if="status.status === 'pending_review'">
            A evidência está privada enquanto a equipe Berufe faz a conferência.
          </p>
          <p v-else-if="isApproved">
            A equipe Berufe conferiu sua identidade. O selo já está visível no
            seu perfil e o documento enviado continua privado.
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
  & h3 {
    margin: 0;
    font-family: var(--font-display);
    font-size: 1.25rem;
  }
  &__request {
    position: relative;
    overflow: hidden;
    padding: 22px;
  }

  &__confirmation {
    position: relative;
    overflow: hidden;
    padding: 0;
    border-color: var(--color-brand-soft-strong);
    background: linear-gradient(
      120deg,
      var(--color-brand-tint-subtle),
      rgb(255 255 255 / 88%) 68%
    );
    box-shadow: 0 16px 38px rgb(30 82 70 / 10%);
  }

  &__confirmation::before {
    position: absolute;
    inset: 0 auto 0 0;
    width: 4px;
    background: var(--color-brand);
    content: "";
  }

  &__status {
    display: flex;
    gap: 11px;
    align-items: start;
  }

  &__status--confirmed {
    align-items: center;
    gap: 18px;
    min-height: 132px;
    padding: 28px 30px 28px 34px;
  }

  &__status-icon {
    display: grid;
    flex: 0 0 auto;
    place-items: center;
    width: 38px;
    height: 38px;
    border-radius: 50%;
    background: var(--color-brand-tint-subtle);
    color: var(--color-brand);
  }

  &__status--confirmed &__status-icon {
    width: 58px;
    height: 58px;
    border: 1px solid var(--color-brand-soft-strong);
    background: rgb(255 255 255 / 78%);
    box-shadow: 0 8px 20px rgb(18 98 93 / 11%);
    font-size: 1.55rem;
  }

  &__status-copy {
    min-width: 0;
  }

  &__status h3 {
    margin: 0;
    font-family: var(--font-sans);
    font-size: 0.9rem;
  }

  &__status--confirmed h3 {
    margin-top: 3px;
    font-family: var(--font-display);
    font-size: 1.45rem;
    font-weight: 600;
    letter-spacing: -0.015em;
  }

  &__status-eyebrow {
    color: var(--color-brand);
    font-size: 0.7rem;
    font-weight: 850;
    letter-spacing: 0.09em;
    text-transform: uppercase;
  }

  &__status p {
    margin: 4px 0 0;
    color: var(--ink-soft);
    font-size: 0.82rem;
    line-height: 1.5;
  }

  &__status--confirmed p {
    max-width: 640px;
    margin-top: 6px;
    font-size: 0.84rem;
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

@media (width <= 700px) {
  .verification-panel {
    &__status--confirmed {
      display: grid;
      grid-template-columns: auto minmax(0, 1fr);
      align-items: start;
      gap: 14px;
      padding: 22px 20px 22px 24px;
    }

    &__status--confirmed &__status-icon {
      width: 50px;
      height: 50px;
      font-size: 1.35rem;
    }
  }
}
</style>
