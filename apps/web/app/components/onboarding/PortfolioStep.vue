<script setup lang="ts">
import type { OnboardingPortfolioItem, PortfolioItemDraft } from "~/types";

defineProps<{
  portfolio: OnboardingPortfolioItem | null;
  serviceOptions: string[];
}>();
defineEmits<{
  back: [];
  complete: [draft: PortfolioItemDraft];
  continue: [];
}>();
</script>

<template>
  <section aria-labelledby="onboarding-portfolio-title">
    <header class="onboarding-step-heading">
      <DesignSystemEyebrow>Etapa 3 de 4</DesignSystemEyebrow>
      <h2 id="onboarding-portfolio-title">Mostre um trabalho bem feito.</h2>
      <p>
        Uma foto já é suficiente para completar esta etapa. Ela ficará marcada
        como “em análise” neste mockup.
      </p>
    </header>

    <DesignSystemSurfaceCard v-if="portfolio" class="onboarding-complete-card">
      <span><UIcon name="i-lucide-check" /></span>
      <div>
        <strong>Primeiro trabalho enviado</strong>
        <p>{{ portfolio.title }} · {{ portfolio.service }}</p>
      </div>
    </DesignSystemSurfaceCard>

    <DesignSystemSurfaceCard v-else class="onboarding-upload-card">
      <DashboardPortfolioUploadForm
        :service-options="serviceOptions"
        submit-label="Salvar e continuar"
        @submitted="$emit('complete', $event)"
      />
    </DesignSystemSurfaceCard>

    <footer v-if="portfolio" class="onboarding-step-actions">
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
        type="button"
        color="primary"
        trailing-icon="i-lucide-arrow-right"
        @click="$emit('continue')"
      >
        Continuar
      </UButton>
    </footer>
    <footer
      v-else
      class="onboarding-step-actions onboarding-step-actions--start"
    >
      <UButton
        type="button"
        color="neutral"
        variant="ghost"
        icon="i-lucide-arrow-left"
        @click="$emit('back')"
      >
        Voltar
      </UButton>
    </footer>
  </section>
</template>
