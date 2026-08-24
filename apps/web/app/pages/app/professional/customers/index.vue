<script setup lang="ts">
import { shallowRef } from "vue";
import type { CustomerListFilters, CustomerPage } from "~/types";
import { useApiClient } from "~/services/api/client";
import {
  defaultProfessionalCustomerListFilters,
  fetchProfessionalCustomers,
} from "~/services/api/professional-customers";

definePageMeta({ layout: "workspace" });
useSeoMeta({ title: "Clientes", robots: "noindex, nofollow" });

const client = useApiClient();
const initial = await useAsyncData("professional-customers", () =>
  fetchProfessionalCustomers(client, defaultProfessionalCustomerListFilters()),
);
const result = shallowRef<CustomerPage | null>(initial.data.value ?? null);
const loading = shallowRef(false);
const loadError = shallowRef("");
let loadSequence = 0;

async function loadCustomers(filters: CustomerListFilters) {
  const sequence = ++loadSequence;
  loading.value = true;
  loadError.value = "";
  try {
    const nextResult = await fetchProfessionalCustomers(client, filters);
    if (sequence === loadSequence) result.value = nextResult;
  } catch {
    if (sequence === loadSequence) {
      loadError.value =
        "Não foi possível atualizar os clientes. Tente novamente.";
    }
  } finally {
    if (sequence === loadSequence) loading.value = false;
  }
}
</script>

<template>
  <div class="customers-page">
    <section class="customers-page__heading">
      <DesignSystemContainer>
        <NuxtLink to="/app/professional">
          <UIcon name="i-lucide-arrow-left" aria-hidden="true" /> Voltar ao
          painel
        </NuxtLink>
        <div class="customers-page__heading-row">
          <div>
            <h1>Clientes</h1>
            <p>Consulte contatos e retome o histórico de cada cliente.</p>
          </div>
          <UButton
            to="/app/professional/quotes/new"
            color="secondary"
            icon="i-lucide-plus"
          >
            Novo orçamento
          </UButton>
        </div>
      </DesignSystemContainer>
    </section>

    <DesignSystemContainer as="main" class="customers-page__content">
      <DashboardProfessionalWorkspaceTabs />
      <div class="customers-page__main">
        <p v-if="initial.status.value === 'pending'" aria-live="polite">
          Carregando clientes…
        </p>
        <p v-else-if="initial.error.value || !result" role="alert">
          Não foi possível carregar seus clientes. Atualize a página para tentar
          novamente.
        </p>
        <DashboardCustomersCustomerDirectory
          v-else
          :result="result"
          :loading="loading"
          :error="loadError"
          @request="loadCustomers"
        />
      </div>
    </DesignSystemContainer>
  </div>
</template>

<style scoped lang="scss">
.customers-page {
  min-height: 100vh;
  background: var(--color-surface-canvas);

  &__heading {
    padding: 28px 0 34px;
    background: var(--color-brand-strong);
    color: white;
  }

  &__heading a:first-child {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    margin-bottom: 24px;
    color: rgb(255 255 255 / 65%);
    text-decoration: none;
  }

  &__heading-row {
    display: flex;
    align-items: end;
    justify-content: space-between;
    gap: 24px;
  }

  &__heading h1 {
    margin: 0 0 6px;
    font-family: var(--font-display);
    font-size: 2.7rem;
    font-weight: 500;
  }

  &__heading p {
    margin: 0;
    color: rgb(255 255 255 / 65%);
  }

  &__content {
    display: grid;
    grid-template-columns: 190px minmax(0, 1fr);
    gap: 28px;
    padding-top: 26px;
    padding-bottom: 70px;
  }

  &__main {
    min-width: 0;
  }
}

@media (width <= 760px) {
  .customers-page {
    &__content {
      grid-template-columns: 1fr;
    }
  }
}

@media (width <= 620px) {
  .customers-page__heading-row {
    align-items: start;
    flex-direction: column;
  }
}
</style>
