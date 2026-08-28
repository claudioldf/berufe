<script setup lang="ts">
import { useApiClient } from "~/services/api/client";
import { fetchProfessionalServiceJobs } from "~/services/api/professional-service-jobs";
import { formatCurrency, formatDateTime } from "~/utils/formatters";

definePageMeta({ layout: "workspace" });
useSeoMeta({ title: "Serviços", robots: "noindex, nofollow" });

const client = useApiClient();
const services = await useAsyncData("professional-service-jobs", () =>
  fetchProfessionalServiceJobs(client),
);
const statusLabel = {
  approved: "Aprovado",
  completion_requested: "Aguardando confirmação",
  completion_issue: "Pendência informada",
  completed: "Concluído",
  cancelled: "Cancelado",
} as const;
</script>

<template>
  <div class="service-list-page">
    <section class="service-list-page__heading">
      <DesignSystemContainer>
        <NuxtLink to="/app/professional">
          <UIcon name="i-lucide-arrow-left" /> Voltar ao painel
        </NuxtLink>
        <h1>Serviços</h1>
        <p>Acompanhe os orçamentos aprovados até a conclusão pelo cliente.</p>
      </DesignSystemContainer>
    </section>
    <DesignSystemContainer as="main" class="service-list-page__content">
      <p v-if="services.status.value === 'pending'" aria-live="polite">
        Carregando serviços…
      </p>
      <p v-else-if="services.error.value" role="alert">
        Não foi possível carregar seus serviços.
      </p>
      <DashboardServiceEmptyState
        v-else-if="services.data.value?.length === 0"
      />
      <DesignSystemSurfaceCard v-else class="service-list">
        <NuxtLink
          v-for="service in services.data.value ?? []"
          :key="service.id"
          :to="`/app/professional/services/${service.id}`"
        >
          <span>
            <strong>{{ service.quote.serviceDescription }}</strong>
            <small
              >#{{ service.quote.number }} ·
              {{ service.quote.customerName }}</small
            >
          </span>
          <span>{{ formatCurrency(service.quote.total) }}</span>
          <em :class="service.status">{{ statusLabel[service.status] }}</em>
          <small>{{ formatDateTime(service.updatedAt) }}</small>
          <UIcon name="i-lucide-chevron-right" />
        </NuxtLink>
      </DesignSystemSurfaceCard>
    </DesignSystemContainer>
  </div>
</template>

<style scoped lang="scss">
.service-list-page {
  min-height: 100vh;
  background: var(--color-surface-canvas);

  &__heading {
    padding: 28px 0 34px;
    background: var(--color-brand-strong);
    color: white;
  }

  &__heading a {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    margin-bottom: 24px;
    color: rgb(255 255 255 / 65%);
    text-decoration: none;
  }

  &__heading h1 {
    margin: 6px 0;
    font-family: var(--font-display);
    font-size: 2.7rem;
    font-weight: 500;
  }

  &__heading p {
    margin: 0;
    color: rgb(255 255 255 / 65%);
  }

  &__content {
    padding-top: 24px;
    padding-bottom: 70px;
  }
}

.service-list {
  overflow: hidden;
}

.service-list > a {
  display: grid;
  grid-template-columns: minmax(180px, 1fr) auto auto auto auto;
  gap: 18px;
  align-items: center;
  padding: 16px 18px;
  border-bottom: 1px solid var(--line);
  color: var(--ink);
  text-decoration: none;
}

.service-list > a span:first-child strong,
.service-list > a span:first-child small {
  display: block;
}

.service-list small {
  color: var(--ink-soft);
}

.service-list em {
  padding: 5px 8px;
  border-radius: 999px;
  background: var(--color-brand-tint-muted);
  color: var(--color-brand);
  font-size: 0.78rem;
  font-style: normal;
  font-weight: 800;
}

@media (width <= 720px) {
  .service-list > a {
    grid-template-columns: 1fr auto;
  }

  .service-list > a > small,
  .service-list > a > span:nth-child(2) {
    display: none;
  }
}
</style>
