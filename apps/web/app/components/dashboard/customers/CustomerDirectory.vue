<script setup lang="ts">
import { computed, onScopeDispose, shallowRef } from "vue";
import type { CustomerListFilters, CustomerPage } from "~/types";
import CustomerList from "./CustomerList.vue";
import CustomerPagination from "./CustomerPagination.vue";

const props = defineProps<{
  result: CustomerPage;
  loading?: boolean;
  error?: string;
}>();

const emit = defineEmits<{
  request: [filters: CustomerListFilters];
}>();

const query = shallowRef("");
const page = shallowRef(props.result.meta.page);
let searchTimer: ReturnType<typeof setTimeout> | undefined;

const filtered = computed(() => query.value.trim().length > 0);
const firstUseEmpty = computed(
  () =>
    props.result.meta.totalCount === 0 &&
    !filtered.value &&
    !props.loading &&
    !props.error,
);
const emptyStateBenefits = [
  "Contatos organizados automaticamente",
  "Histórico de propostas por cliente",
  "Conversas mais fáceis de retomar",
];
const emptyStateVisual = {
  icon: "i-lucide-contact-round",
  title: "Sua carteira",
  caption: "Clientes ligados aos orçamentos",
  metaLabel: "Organização",
  metaValue: "Tudo em um lugar",
  badge: "Pronto para continuar",
  badgeIcon: "i-lucide-users-round",
};
const resultRange = computed(() => {
  const { page: currentPage, perPage, totalCount } = props.result.meta;
  const noun = totalCount === 1 ? "cliente" : "clientes";
  if (totalCount === 0) return `0 ${noun}`;
  const first = (currentPage - 1) * perPage + 1;
  const last = Math.min(currentPage * perPage, totalCount);
  return first === last
    ? `${first} de ${totalCount} ${noun}`
    : `${first}–${last} de ${totalCount} ${noun}`;
});

function currentFilters(): CustomerListFilters {
  return {
    search: query.value.trim(),
    page: page.value,
    perPage: props.result.meta.perPage,
  };
}

function clearSearchTimer() {
  if (searchTimer) clearTimeout(searchTimer);
  searchTimer = undefined;
}

function setQuery(value: string) {
  query.value = value.slice(0, 100);
  page.value = 1;
  clearSearchTimer();
  searchTimer = setTimeout(() => {
    searchTimer = undefined;
    emit("request", currentFilters());
  }, 300);
}

function setPage(value: number) {
  page.value = value;
  clearSearchTimer();
  emit("request", currentFilters());
}

function clearSearch() {
  query.value = "";
  page.value = 1;
  clearSearchTimer();
  emit("request", currentFilters());
}

onScopeDispose(clearSearchTimer);
</script>

<template>
  <div class="customer-directory">
    <DesignSystemFeatureEmptyState
      v-if="firstUseEmpty"
      eyebrow="Relacionamentos que viram recorrência"
      title="Cada orçamento começa a construir sua carteira."
      description="Ao criar uma proposta, o cliente entra automaticamente na sua agenda com contato e histórico para você atender melhor hoje e no próximo serviço."
      :items="emptyStateBenefits"
      cta-label="Criar meu primeiro orçamento"
      cta-to="/app/professional/quotes/new"
      :visual="emptyStateVisual"
    />
    <template v-else>
      <DesignSystemSurfaceCard as="section" class="customer-directory__search">
        <label for="customer-search">Buscar clientes</label>
        <div>
          <UIcon name="i-lucide-search" aria-hidden="true" />
          <input
            id="customer-search"
            name="customerSearch"
            type="search"
            maxlength="100"
            autocomplete="off"
            placeholder="Nome, WhatsApp ou e-mail"
            :value="query"
            @input="setQuery(($event.target as HTMLInputElement).value)"
          />
          <button
            v-if="filtered"
            type="button"
            aria-label="Limpar busca"
            @click="clearSearch"
          >
            <UIcon name="i-lucide-x" aria-hidden="true" />
          </button>
        </div>
      </DesignSystemSurfaceCard>

      <div class="customer-directory__summary">
        <p role="status" aria-live="polite">{{ resultRange }}</p>
      </div>
      <p v-if="error" class="customer-directory__error" role="alert">
        {{ error }}
      </p>
      <CustomerList
        :customers="result.customers"
        :filtered="filtered"
        :loading="loading"
      />
      <CustomerPagination
        :page="result.meta.page"
        :total-pages="result.meta.totalPages"
        :loading="loading"
        @page="setPage"
      />
    </template>
  </div>
</template>

<style scoped lang="scss">
.customer-directory {
  display: grid;
  gap: 14px;

  &__search {
    padding: 18px;
  }

  &__search > label {
    display: block;
    margin-bottom: 8px;
    color: var(--ink);
    font-size: 0.82rem;
    font-weight: 850;
  }

  &__search > div {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 0 12px;
    border: 1px solid var(--line);
    border-radius: var(--radius-md);
    background: white;
    color: var(--ink-soft);
  }

  &__search input {
    width: 100%;
    height: 46px;
    border: 0;
    outline: 0;
    background: transparent;
    color: var(--ink);
  }

  &__search input::-webkit-search-cancel-button {
    appearance: none;
  }

  &__search button {
    display: grid;
    flex: 0 0 auto;
    place-items: center;
    padding: 5px;
    border: 0;
    background: transparent;
    color: var(--ink-soft);
    cursor: pointer;
  }

  &__summary {
    padding: 0 4px;
  }

  &__summary p,
  &__error {
    margin: 0;
    color: var(--ink-soft);
    font-size: 0.82rem;
  }

  &__error {
    color: var(--color-danger);
  }
}
</style>
