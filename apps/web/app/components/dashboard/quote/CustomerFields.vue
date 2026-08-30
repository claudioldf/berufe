<script setup lang="ts">
import type { Quote, QuoteValidationErrors } from "~/types";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import {
  searchProfessionalCustomerCandidates,
  type ProfessionalCustomerCandidate,
} from "~/services/api/professional-customers";

const CUSTOMER_SEARCH_DEBOUNCE_MS = 500;

const props = defineProps<{ errors?: QuoteValidationErrors }>();
const quote = defineModel<Quote>({ required: true });
const emit = defineEmits<{ dirty: [] }>();
const client = useApiClient();
const candidates = shallowRef<ProfessionalCustomerCandidate[]>([]);
const candidateSearchPending = shallowRef(false);
const candidateSearchActive = shallowRef(false);
const searchSettled = shallowRef(false);
const searchError = shallowRef("");
const searching = computed(
  () => candidateSearchPending.value || candidateSearchActive.value,
);
let latestSearch = 0;
let selectingCustomer = false;

watch(
  () => quote.value.customerName,
  (name, previousName, onCleanup) => {
    const searchId = ++latestSearch;
    candidateSearchPending.value = false;
    candidateSearchActive.value = false;
    candidates.value = [];
    searchSettled.value = false;
    searchError.value = "";
    if (selectingCustomer) return;
    if (name !== previousName && quote.value.customerId) {
      quote.value.customerId = null;
    }
    const normalized = name.trim();
    if (!normalized) return;

    candidateSearchPending.value = true;
    const timer = window.setTimeout(() => {
      if (searchId !== latestSearch) return;

      candidateSearchPending.value = false;
      if (normalized.length < 2) return;

      candidateSearchActive.value = true;
      void search(normalized, searchId);
    }, CUSTOMER_SEARCH_DEBOUNCE_MS);
    onCleanup(() => {
      window.clearTimeout(timer);
      if (searchId === latestSearch) latestSearch += 1;
    });
  },
);

async function search(query: string, searchId: number) {
  try {
    const result = await searchProfessionalCustomerCandidates(client, query);
    if (searchId !== latestSearch) return;
    candidates.value = result;
    searchSettled.value = true;
  } catch (error) {
    if (searchId !== latestSearch) return;
    candidates.value = [];
    searchSettled.value = true;
    searchError.value =
      error instanceof ApiRequestError
        ? error.message
        : "Não foi possível buscar seus clientes.";
  } finally {
    if (searchId === latestSearch) candidateSearchActive.value = false;
  }
}

function selectCustomer(customer: ProfessionalCustomerCandidate) {
  latestSearch += 1;
  selectingCustomer = true;
  candidateSearchPending.value = false;
  candidateSearchActive.value = false;
  quote.value.customerId = customer.id;
  quote.value.customerName = customer.name;
  quote.value.customerPhone = customer.phone;
  quote.value.customerEmail = customer.email;
  candidates.value = [];
  searchSettled.value = false;
  void nextTick(() => {
    selectingCustomer = false;
  });
  emit("dirty");
}

function markContactDirty() {
  emit("dirty");
}
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="builder-card">
    <header>
      <div>
        <span>01</span>
        <div>
          <h2>Cliente</h2>
          <p>Informe os dados do cliente ou selecione um cadastro existente.</p>
        </div>
      </div>
    </header>
    <div class="builder-fields" @input="markContactDirty">
      <DesignSystemFormField
        v-slot="field"
        class="builder-fields__full customer-lookup"
        label="Nome do cliente"
        :error="props.errors?.customerName"
        required
      >
        <div class="customer-lookup__control">
          <input
            :id="field.controlId"
            v-model="quote.customerName"
            name="customerName"
            autocomplete="off"
            :aria-describedby="field.describedBy"
            :aria-invalid="field.invalid"
            :aria-busy="searching"
            placeholder="Digite para buscar entre seus clientes"
            required
            maxlength="80"
          />
          <UIcon
            v-if="searching"
            name="i-lucide-loader-circle"
            class="customer-lookup__loader"
            aria-hidden="true"
          />
        </div>
        <span
          v-if="searching"
          class="customer-lookup__status"
          role="status"
          aria-live="polite"
        >
          Buscando clientes…
        </span>
        <div
          v-if="candidates.length"
          class="customer-lookup__results"
          aria-label="Clientes encontrados"
        >
          <button
            v-for="customer in candidates"
            :key="customer.id"
            type="button"
            @click="selectCustomer(customer)"
          >
            <span>
              <strong>{{ customer.name }}</strong>
              <small>{{ customer.phone }}</small>
            </span>
            <span>{{ customer.email || "Sem e-mail" }}</span>
          </button>
        </div>
        <p
          v-else-if="searchError"
          class="customer-lookup__message"
          role="status"
        >
          {{ searchError }} Você ainda pode preencher os dados e cadastrar o
          cliente ao salvar o orçamento.
        </p>
        <p
          v-else-if="searchSettled && !quote.customerId"
          class="customer-lookup__message"
        >
          Nenhum cliente encontrado. Ao salvar o orçamento, um novo cliente será
          cadastrado com esses dados.
        </p>
        <p v-if="quote.customerId" class="customer-lookup__selected">
          <UIcon name="i-lucide-circle-check" aria-hidden="true" /> Cliente
          existente selecionado
        </p>
      </DesignSystemFormField>
      <DesignSystemFormField
        v-slot="field"
        label="WhatsApp"
        :error="props.errors?.customerPhone"
        required
      >
        <input
          :id="field.controlId"
          v-model="quote.customerPhone"
          name="customerPhone"
          type="tel"
          autocomplete="tel"
          placeholder="(47) 99999-9999"
          :aria-describedby="field.describedBy"
          :aria-invalid="field.invalid"
          required
          maxlength="20"
        />
      </DesignSystemFormField>
      <DesignSystemFormField
        v-slot="field"
        label="E-mail (opcional)"
        :error="props.errors?.customerEmail"
      >
        <input
          :id="field.controlId"
          v-model="quote.customerEmail"
          name="customerEmail"
          type="email"
          autocomplete="email"
          placeholder="cliente@exemplo.com"
          :aria-describedby="field.describedBy"
          :aria-invalid="field.invalid"
          maxlength="254"
        />
      </DesignSystemFormField>
    </div>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.customer-lookup {
  position: relative;

  &__control {
    position: relative;
  }

  &__loader {
    position: absolute;
    top: 50%;
    right: 12px;
    transform: translateY(-50%);
    color: var(--color-brand);
    font-size: 1.1rem;
    pointer-events: none;
    animation: customer-spin 1s linear infinite;
  }

  &__status {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    overflow: hidden;
    clip-path: inset(50%);
    white-space: nowrap;
    border: 0;
  }

  &__results {
    position: absolute;
    z-index: 20;
    top: calc(100% + 5px);
    right: 0;
    left: 0;
    display: grid;
    max-height: 260px;
    overflow: auto;
    padding: 6px;
    border: 1px solid var(--line);
    border-radius: 12px;
    background: white;
    box-shadow: var(--shadow-md);
  }

  &__results button {
    display: flex;
    justify-content: space-between;
    gap: 12px;
    padding: 10px;
    border: 0;
    border-radius: 8px;
    background: transparent;
    color: var(--ink);
    text-align: left;
    cursor: pointer;
  }

  &__results button:hover,
  &__results button:focus-visible {
    background: var(--color-brand-tint-muted);
  }

  &__results strong,
  &__results small {
    display: block;
  }

  &__results small,
  &__results button > span:last-child,
  &__message,
  &__selected {
    color: var(--ink-soft);
    font-size: 0.78rem;
  }

  &__message,
  &__selected {
    margin: 7px 0 0;
  }

  &__selected {
    display: flex;
    align-items: center;
    gap: 4px;
    color: var(--color-brand);
    font-weight: 800;
  }
}

@keyframes customer-spin {
  from {
    transform: translateY(-50%) rotate(0);
  }

  to {
    transform: translateY(-50%) rotate(1turn);
  }
}

@media (prefers-reduced-motion: reduce) {
  .customer-lookup__loader {
    animation: none;
    transform: translateY(-50%);
  }
}
</style>
