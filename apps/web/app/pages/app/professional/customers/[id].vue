<script setup lang="ts">
import { shallowRef } from "vue";
import type {
  ProfessionalCustomer,
  ProfessionalCustomerDraft,
  QuotePage,
} from "~/types";
import { useToast } from "~/composables/useToast";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import {
  fetchProfessionalCustomer,
  updateProfessionalCustomer,
} from "~/services/api/professional-customers";
import {
  defaultProfessionalQuoteListFilters,
  fetchProfessionalQuotes,
} from "~/services/api/professional-quotes";

definePageMeta({ layout: "workspace" });
useSeoMeta({ title: "Cliente", robots: "noindex, nofollow" });

const route = useRoute();
const client = useApiClient();
const { showToast } = useToast();
const customerId = Array.isArray(route.params.id)
  ? route.params.id[0]!
  : String(route.params.id);
const initial = await useAsyncData(
  `professional-customer-${customerId}`,
  async () => {
    const filters = {
      ...defaultProfessionalQuoteListFilters(),
      customerId,
    };
    const [customer, quotes] = await Promise.all([
      fetchProfessionalCustomer(client, customerId),
      fetchProfessionalQuotes(client, filters),
    ]);
    return { customer, quotes };
  },
);
const customer = shallowRef<ProfessionalCustomer | null>(
  initial.data.value?.customer ?? null,
);
const quotes = shallowRef<QuotePage | null>(initial.data.value?.quotes ?? null);
const saving = shallowRef(false);
const saveError = shallowRef("");
const fieldErrors = shallowRef<Record<string, string[]>>({});
const historyLoading = shallowRef(false);
const historyError = shallowRef("");

async function saveCustomer(draft: ProfessionalCustomerDraft) {
  if (saving.value || !customer.value) return;
  saving.value = true;
  saveError.value = "";
  fieldErrors.value = {};
  try {
    customer.value = await updateProfessionalCustomer(
      client,
      customer.value.id,
      draft,
    );
    showToast({
      title: "Cliente atualizado",
      description: "Os novos dados serão usados nos próximos orçamentos.",
    });
  } catch (error) {
    if (error instanceof ApiRequestError) {
      saveError.value = error.message;
      fieldErrors.value = error.fieldErrors;
    } else {
      saveError.value = "Não foi possível salvar o cliente. Tente novamente.";
    }
  } finally {
    saving.value = false;
  }
}

async function loadHistory(page: number) {
  if (!customer.value || historyLoading.value) return;
  historyLoading.value = true;
  historyError.value = "";
  try {
    quotes.value = await fetchProfessionalQuotes(client, {
      ...defaultProfessionalQuoteListFilters(),
      customerId: customer.value.id,
      page,
    });
  } catch {
    historyError.value = "Não foi possível carregar esta página de orçamentos.";
  } finally {
    historyLoading.value = false;
  }
}
</script>

<template>
  <div class="customer-page">
    <section class="customer-page__heading">
      <DesignSystemContainer>
        <NuxtLink to="/app/professional/customers">
          <UIcon name="i-lucide-arrow-left" aria-hidden="true" /> Voltar aos
          clientes
        </NuxtLink>
        <div class="customer-page__heading-row">
          <div>
            <DesignSystemEyebrow tone="inverse">Cliente</DesignSystemEyebrow>
            <h1>{{ customer?.name ?? "Dados do cliente" }}</h1>
            <p>Atualize o contato e consulte os orçamentos anteriores.</p>
          </div>
          <UButton
            v-if="customer"
            :to="`/app/professional/quotes/new?customer=${customer.id}`"
            color="secondary"
            icon="i-lucide-plus"
          >
            Novo orçamento
          </UButton>
        </div>
      </DesignSystemContainer>
    </section>

    <DesignSystemContainer as="main" class="customer-page__content">
      <DashboardProfessionalWorkspaceTabs />
      <div class="customer-page__main">
        <p v-if="initial.status.value === 'pending'" aria-live="polite">
          Carregando cliente…
        </p>
        <p v-else-if="initial.error.value || !customer || !quotes" role="alert">
          Não foi possível carregar este cliente. Volte à lista e tente
          novamente.
        </p>
        <template v-else>
          <DashboardCustomersCustomerContactForm
            :customer="customer"
            :saving="saving"
            :error="saveError"
            :field-errors="fieldErrors"
            @save="saveCustomer"
          />
          <DashboardCustomersCustomerQuoteHistory
            :result="quotes"
            :loading="historyLoading"
            :error="historyError"
            @page="loadHistory"
          />
        </template>
      </div>
    </DesignSystemContainer>
  </div>
</template>

<style scoped lang="scss">
.customer-page {
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
    display: grid;
    grid-template-columns: 190px minmax(0, 1fr);
    gap: 28px;
    padding-top: 26px;
    padding-bottom: 70px;
  }

  &__main {
    min-width: 0;
    display: grid;
    gap: 20px;
  }
}

@media (width <= 760px) {
  .customer-page__content {
    grid-template-columns: 1fr;
  }
}

@media (width <= 620px) {
  .customer-page__heading-row {
    align-items: start;
    flex-direction: column;
  }
}
</style>
