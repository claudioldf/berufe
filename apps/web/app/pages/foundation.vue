<script setup lang="ts">
import type { FoundationFeedback } from "~/components/foundation/FeedbackForm.vue";
import { useToast } from "~/composables/useToast";

const { data, error, status, refresh } = await useApiStatus();
const { showToast } = useToast();

useSeoMeta({
  title: "Fundação da interface",
  description:
    "Referência interna dos componentes, estados e integração da Berufe.",
  robots: "noindex, nofollow",
});

async function retryApi() {
  await refresh();
}

function submitFeedback(feedback: FoundationFeedback) {
  showToast({
    title: "Demonstração enviada",
    description: `Obrigado, ${feedback.name}. Nenhum dado foi persistido.`,
  });
}

function showDemoAction(action: string) {
  showToast({
    title: "Ação disponível",
    description: `${action} é uma demonstração da fundação visual.`,
  });
}
</script>

<template>
  <UContainer class="foundation-page">
    <header class="foundation-page__hero">
      <UBadge color="secondary" variant="soft">Referência interna</UBadge>
      <h1>Uma base coerente para construir o produto.</h1>
      <p>
        Tokens centralizados, Nuxt UI, layouts responsivos e estados acessíveis
        para as próximas histórias do MVP.
      </p>
      <nav aria-label="Seções da fundação">
        <UButton to="#integration" variant="solid">Integração</UButton>
        <UButton to="#form" color="neutral" variant="outline">
          Formulário
        </UButton>
        <UButton to="#states" color="neutral" variant="ghost">
          Estados
        </UButton>
      </nav>
    </header>

    <FoundationApiStatusCard
      id="integration"
      :status="status"
      :service="data?.data.service"
      :service-status="data?.data.status"
      :error-message="error?.message"
      @retry="retryApi"
    />

    <FoundationFeedbackForm id="form" @submitted="submitFeedback" />

    <FoundationStateGallery
      id="states"
      @create="showDemoAction('Criar item')"
      @retry="showDemoAction('Tentar novamente')"
    />
  </UContainer>
</template>

<style scoped lang="scss">
.foundation-page {
  display: grid;
  gap: clamp(52px, 8vw, 88px);
  padding-block: clamp(56px, 8vw, 96px);

  &__hero {
    max-width: 800px;
  }

  &__hero h1 {
    max-width: 720px;
    margin: 16px 0;
    font-family: var(--font-display);
    font-size: clamp(2.7rem, 8vw, 5.5rem);
    font-weight: 500;
    line-height: 0.98;
    letter-spacing: -0.055em;
  }

  &__hero p {
    max-width: 650px;
    margin: 0;
    color: var(--color-text-muted);
    font-size: clamp(1rem, 2vw, 1.16rem);
    line-height: 1.7;
  }

  &__hero nav {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    margin-top: 28px;
  }
}
</style>
