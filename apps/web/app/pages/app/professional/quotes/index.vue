<script setup lang="ts">
import { shallowRef } from "vue";
import type { QuoteListFilters, QuotePage } from "~/types";
import { useApiClient } from "~/services/api/client";
import {
  defaultProfessionalQuoteListFilters,
  fetchProfessionalQuotes,
} from "~/services/api/professional-quotes";

definePageMeta({ layout: "workspace" });
useSeoMeta({ title: "Orçamentos", robots: "noindex, nofollow" });

const client = useApiClient();
const initialFilters = defaultProfessionalQuoteListFilters();
const initial = await useAsyncData("professional-quotes", () =>
  fetchProfessionalQuotes(client, initialFilters),
);
const result = shallowRef<QuotePage | null>(initial.data.value ?? null);
const loading = shallowRef(false);
const loadError = shallowRef("");
let loadSequence = 0;

async function loadQuotes(filters: QuoteListFilters) {
  const sequence = ++loadSequence;
  loading.value = true;
  loadError.value = "";
  try {
    const nextResult = await fetchProfessionalQuotes(client, filters);
    if (sequence === loadSequence) result.value = nextResult;
  } catch {
    if (sequence === loadSequence) {
      loadError.value =
        "Não foi possível atualizar os orçamentos. Tente novamente.";
    }
  } finally {
    if (sequence === loadSequence) loading.value = false;
  }
}
</script>

<template>
  <div class="quote-list-page">
    <section class="quote-list-page__heading">
      <DesignSystemContainer>
        <NuxtLink to="/app/professional">
          <UIcon name="i-lucide-arrow-left" aria-hidden="true" /> Voltar ao
          painel
        </NuxtLink>
        <div class="quote-list-page__heading-row">
          <div>
            <DesignSystemEyebrow tone="inverse"
              >Ferramentas</DesignSystemEyebrow
            >
            <h1>Orçamentos</h1>
            <p>Encontre, revise e acompanhe as respostas dos clientes.</p>
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

    <DesignSystemContainer as="main" class="quote-list-page__content">
      <p v-if="initial.status.value === 'pending'" aria-live="polite">
        Carregando orçamentos…
      </p>
      <p v-else-if="initial.error.value || !result" role="alert">
        Não foi possível carregar seus orçamentos. Atualize a página para tentar
        novamente.
      </p>
      <DashboardQuotesQuoteIndex
        v-else
        :result="result"
        :loading="loading"
        :error="loadError"
        @request="loadQuotes"
      />
    </DesignSystemContainer>
  </div>
</template>

<style scoped lang="scss">
.quote-list-page {
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
    padding-top: 24px;
    padding-bottom: 70px;
  }
}

@media (width <= 620px) {
  .quote-list-page__heading-row {
    align-items: start;
    flex-direction: column;
  }
}
</style>
