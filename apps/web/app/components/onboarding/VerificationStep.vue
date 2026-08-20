<script setup lang="ts">
import type { VerificationSubmission } from "~/types";

defineProps<{
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
        submit-label="Enviar e concluir"
        :submitting="saving"
        @submitted="$emit('complete', submit($event))"
      />
    </DesignSystemSurfaceCard>

    <footer class="onboarding-step-actions">
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
      <UButton
        v-if="!submitted"
        type="button"
        color="neutral"
        variant="outline"
        :loading="submitting"
        :disabled="saving || submitting"
        @click="$emit('skip')"
      >
        Agora não — publicar perfil
      </UButton>
      <UButton
        v-else
        type="button"
        color="primary"
        trailing-icon="i-lucide-check"
        :loading="submitting"
        :disabled="saving || submitting"
        @click="$emit('finish')"
      >
        Publicar perfil
      </UButton>
    </footer>
  </section>
</template>
