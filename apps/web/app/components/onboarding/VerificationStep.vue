<script setup lang="ts">
import type { VerificationSubmission } from "~/types";

const props = defineProps<{
  submitted: boolean;
  saving?: boolean;
  submitting?: boolean;
  serverError?: string;
}>();
defineEmits<{
  back: [];
  complete: [file: File];
  finish: [];
  skip: [];
}>();

function submit(submission: VerificationSubmission) {
  return submission.file;
}

const verificationFormId = "onboarding-identity-verification";
const busyReason = computed(() => {
  if (props.saving) return "Aguarde o envio da verificação terminar.";
  if (props.submitting) return "Aguarde a publicação do perfil terminar.";
  return null;
});
</script>

<template>
  <section aria-labelledby="onboarding-verification-title">
    <header class="onboarding-step-heading">
      <DesignSystemEyebrow>Etapa 3 de 3</DesignSystemEyebrow>
      <h2 id="onboarding-verification-title">Quer verificar sua identidade?</h2>
      <p>
        Esta etapa é opcional. Você pode enviar a evidência agora ou publicar o
        perfil e fazer isso depois pelo painel.
      </p>
    </header>

    <p v-if="serverError" class="onboarding-step-error" role="alert">
      <UIcon name="i-lucide-circle-alert" /> {{ serverError }}
    </p>

    <DesignSystemSurfaceCard v-if="submitted" class="onboarding-complete-card">
      <span><UIcon name="i-lucide-check" /></span>
      <div>
        <strong>Verificação enviada</strong>
        <p>A evidência está marcada como aguardando análise.</p>
      </div>
    </DesignSystemSurfaceCard>

    <DesignSystemSurfaceCard v-else class="onboarding-upload-card">
      <DashboardVerificationIdentityUploadForm
        :form-id="verificationFormId"
        :show-submit="false"
        :submitting="saving"
        @submitted="$emit('complete', submit($event))"
      />
    </DesignSystemSurfaceCard>

    <footer class="onboarding-step-actions">
      <DesignSystemDisabledTooltip :reason="busyReason">
        <UButton
          type="button"
          color="neutral"
          variant="ghost"
          icon="i-lucide-arrow-left"
          :disabled="saving || submitting"
          @click="$emit('back')"
        >
          Voltar
        </UButton>
      </DesignSystemDisabledTooltip>
      <div class="onboarding-verification-actions">
        <template v-if="!submitted">
          <DesignSystemDisabledTooltip :reason="busyReason">
            <UButton
              type="button"
              color="neutral"
              variant="outline"
              :loading="submitting"
              :disabled="saving || submitting"
              @click="$emit('skip')"
            >
              Pular verificação e publicar perfil
            </UButton>
          </DesignSystemDisabledTooltip>
          <DesignSystemDisabledTooltip :reason="busyReason">
            <UButton
              type="submit"
              :form="verificationFormId"
              color="primary"
              :loading="saving"
              :disabled="saving || submitting"
            >
              Enviar e concluir
            </UButton>
          </DesignSystemDisabledTooltip>
        </template>
        <DesignSystemDisabledTooltip v-else :reason="busyReason">
          <UButton
            type="button"
            color="primary"
            trailing-icon="i-lucide-check"
            :loading="submitting"
            :disabled="saving || submitting"
            @click="$emit('finish')"
          >
            Publicar perfil
          </UButton>
        </DesignSystemDisabledTooltip>
      </div>
    </footer>
  </section>
</template>

<style scoped lang="scss">
.onboarding-verification-actions {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 8px;
}

@media (width <= 700px) {
  .onboarding-step-actions {
    align-items: stretch;
    flex-direction: column;
  }

  .onboarding-verification-actions {
    display: grid;
  }
}
</style>
