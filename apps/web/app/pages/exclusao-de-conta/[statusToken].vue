<script setup lang="ts">
import { getDataErasureRequestStatus } from "~/services/api/professional-data-erasure";
import { useApiClient } from "~/services/api/client";

const route = useRoute();
const statusToken = String(route.params.statusToken ?? "");
const {
  data: request,
  error,
  status,
  refresh,
} = await useAsyncData(`data-erasure-request-status:${statusToken}`, () =>
  getDataErasureRequestStatus(useApiClient(), statusToken),
);

useSeoMeta({
  title: "Estado da exclusão da conta",
  description: "Consulte o estado de uma solicitação de exclusão da Berufe.",
  robots: "noindex, nofollow",
});
</script>

<template>
  <main class="erasure-status-page">
    <DesignSystemContainer class="erasure-status-page__content">
      <AccountErasureRequestStatus
        v-if="request"
        :request="request"
        :refreshing="status === 'pending'"
        @refresh="refresh"
      />
      <DesignSystemSurfaceCard
        v-else-if="status === 'pending'"
        as="section"
        class="erasure-status-page__state"
        aria-live="polite"
      >
        <UIcon name="i-lucide-clock-3" aria-hidden="true" />
        <h1>Consultando a solicitação…</h1>
      </DesignSystemSurfaceCard>
      <DesignSystemSurfaceCard
        v-else
        as="section"
        class="erasure-status-page__state"
      >
        <UIcon name="i-lucide-shield-alert" aria-hidden="true" />
        <h1>Não foi possível consultar este protocolo.</h1>
        <p role="alert">
          O link pode estar incorreto ou o período de retenção já terminou.
          Tente novamente ou fale com
          <a href="mailto:suporte@berufe.com.br">suporte@berufe.com.br</a>.
        </p>
        <UButton
          type="button"
          color="neutral"
          variant="outline"
          @click="refresh()"
        >
          Tentar novamente
        </UButton>
      </DesignSystemSurfaceCard>
      <span v-if="error" class="sr-only">Falha ao consultar protocolo.</span>
    </DesignSystemContainer>
  </main>
</template>

<style scoped lang="scss">
.erasure-status-page {
  min-height: calc(100vh - 76px);
  padding: clamp(42px, 8vw, 90px) 0;
  background:
    radial-gradient(circle at 12% 10%, var(--mint), transparent 34%),
    var(--color-surface-canvas);

  &__content {
    width: min(100% - 28px, 820px);
  }

  &__state {
    display: grid;
    justify-items: start;
    gap: 16px;
    padding: clamp(26px, 5vw, 44px);
  }

  &__state > svg {
    color: var(--color-brand);
    font-size: 1.6rem;
  }

  &__state h1 {
    margin: 0;
    font-family: var(--font-display);
    font-size: clamp(2rem, 5vw, 3.2rem);
    font-weight: 550;
    letter-spacing: -0.04em;
  }

  &__state p {
    margin: 0;
    color: var(--ink-soft);
    line-height: 1.65;
  }

  &__state a {
    color: var(--color-brand);
    font-weight: 800;
  }
}
</style>
