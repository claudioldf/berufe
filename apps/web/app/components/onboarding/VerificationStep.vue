<script setup lang="ts">
import type { VerificationSubmission } from "~/types";

defineProps<{ submitted: boolean }>();
defineEmits<{
  back: [];
  complete: [file: File];
  finish: [];
}>();

function submit(submission: VerificationSubmission) {
  return submission.file;
}
</script>

<template>
  <section aria-labelledby="onboarding-verification-title">
    <header class="onboarding-step-heading">
      <DesignSystemEyebrow>Etapa 4 de 4</DesignSystemEyebrow>
      <h2 id="onboarding-verification-title">Finalize com sua identidade.</h2>
      <p>
        O envio conta para a conclusão; a análise pode continuar pendente. Como
        este é um mockup, nenhum arquivo é transmitido ou armazenado.
      </p>
    </header>

    <DesignSystemSurfaceCard v-if="submitted" class="onboarding-complete-card">
      <span><UIcon name="i-lucide-check" /></span>
      <div>
        <strong>Verificação enviada</strong>
        <p>A evidência está marcada como aguardando análise.</p>
      </div>
    </DesignSystemSurfaceCard>

    <DesignSystemSurfaceCard v-else class="onboarding-upload-card">
      <DashboardVerificationIdentityUploadForm
        submit-label="Enviar e concluir"
        @submitted="$emit('complete', submit($event))"
      />
    </DesignSystemSurfaceCard>

    <footer class="onboarding-step-actions">
      <UButton
        type="button"
        color="neutral"
        variant="ghost"
        icon="i-lucide-arrow-left"
        @click="$emit('back')"
      >
        Voltar
      </UButton>
      <UButton
        v-if="submitted"
        type="button"
        color="primary"
        trailing-icon="i-lucide-check"
        @click="$emit('finish')"
      >
        Concluir onboarding
      </UButton>
    </footer>
  </section>
</template>
