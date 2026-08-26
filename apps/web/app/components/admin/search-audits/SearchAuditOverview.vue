<script setup lang="ts">
import { computed, shallowRef, watch } from "vue";
import type {
  SearchAuditOutcome,
  SearchAuditPage,
  SearchAuditSort,
} from "~/types";

const props = defineProps<{
  summary: SearchAuditPage["summary"];
  q: string;
  outcome: SearchAuditOutcome | null;
  sort: SearchAuditSort;
  isLoading: boolean;
}>();

const emit = defineEmits<{
  search: [value: string];
  outcome: [value: SearchAuditOutcome | null];
  sort: [value: SearchAuditSort];
  clear: [];
}>();

const queryInput = shallowRef(props.q);

watch(
  () => props.q,
  (value) => {
    queryInput.value = value;
  },
);

const summaryCards = computed<
  Array<{
    label: string;
    value: number;
    outcome: SearchAuditOutcome | null;
    hint: string;
  }>
>(() => [
  {
    label: "Buscas",
    value: props.summary.total,
    outcome: null,
    hint: "Total dentro da pesquisa textual",
  },
  {
    label: "Sem resultados",
    value: props.summary.zeroResults,
    outcome: "zero_results",
    hint: "Oportunidades de catálogo ou cobertura",
  },
  {
    label: "Não compreendidas",
    value: props.summary.notUnderstood,
    outcome: "not_understood",
    hint: "Vocabulário que o interpretador rejeitou",
  },
  {
    label: "Poucos resultados",
    value: props.summary.thinResults,
    outcome: "thin_results",
    hint: "Buscas com apenas um ou dois profissionais",
  },
  {
    label: "Falhas operacionais",
    value: props.summary.operationalIssue,
    outcome: "operational_issue",
    hint: "Limites, indisponibilidade ou erro de busca",
  },
  {
    label: "Saudáveis",
    value: props.summary.healthy,
    outcome: "healthy",
    hint: "Buscas com três ou mais profissionais",
  },
]);

function changeOutcome(event: Event) {
  const value = (event.target as HTMLSelectElement).value;
  emit("outcome", (value || null) as SearchAuditOutcome | null);
}

function changeSort(event: Event) {
  emit("sort", (event.target as HTMLSelectElement).value as SearchAuditSort);
}
</script>

<template>
  <section class="audit-overview" aria-labelledby="audit-overview-title">
    <div class="audit-overview__heading">
      <div>
        <h2 id="audit-overview-title">Sinais dos últimos seis meses</h2>
        <p>
          Priorize buscas sem resposta, linguagem não compreendida e baixa
          oferta.
        </p>
      </div>
      <span v-if="isLoading" class="audit-overview__loading" role="status">
        <UIcon name="i-lucide-loader-circle" aria-hidden="true" />
        Atualizando…
      </span>
    </div>

    <div class="audit-overview__cards" aria-label="Resumo por resultado">
      <button
        v-for="card in summaryCards"
        :key="card.label"
        type="button"
        class="audit-overview__card"
        :class="{ 'audit-overview__card--active': outcome === card.outcome }"
        :aria-pressed="outcome === card.outcome"
        :title="card.hint"
        @click="emit('outcome', card.outcome)"
      >
        <span>{{ card.label }}</span>
        <strong>{{ card.value }}</strong>
      </button>
    </div>

    <form
      class="audit-overview__filters"
      role="search"
      @submit.prevent="emit('search', queryInput)"
    >
      <label class="audit-overview__query" for="audit-query">
        <span>Pesquisar intenção</span>
        <div>
          <UIcon
            class="audit-overview__search-icon"
            name="i-lucide-search"
            aria-hidden="true"
          />
          <input
            id="audit-query"
            v-model="queryInput"
            name="q"
            type="search"
            autocomplete="off"
            maxlength="100"
            placeholder="Prompt, serviço, cidade ou mensagem…"
          />
        </div>
      </label>

      <label for="audit-outcome">
        <span>Resultado</span>
        <select
          id="audit-outcome"
          name="outcome"
          :value="outcome ?? ''"
          @change="changeOutcome"
        >
          <option value="">Todos</option>
          <option value="zero_results">Sem resultados</option>
          <option value="not_understood">Não compreendida</option>
          <option value="thin_results">Poucos resultados</option>
          <option value="operational_issue">Falha operacional</option>
          <option value="healthy">Saudável</option>
        </select>
      </label>

      <label for="audit-sort">
        <span>Ordenar por</span>
        <select id="audit-sort" name="sort" :value="sort" @change="changeSort">
          <option value="results_asc">Menos resultados</option>
          <option value="gaps">Oportunidades primeiro</option>
          <option value="newest">Mais recentes</option>
          <option value="results_desc">Mais resultados</option>
        </select>
      </label>

      <UButton type="submit" color="primary" label="Pesquisar" />
      <UButton
        v-if="q || outcome"
        type="button"
        color="neutral"
        variant="ghost"
        label="Limpar filtros"
        @click="emit('clear')"
      />
    </form>
  </section>
</template>

<style scoped lang="scss">
.audit-overview {
  display: grid;
  gap: 16px;
  padding: 18px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  background: rgb(255 255 255 / 76%);

  &__heading {
    display: flex;
    align-items: start;
    justify-content: space-between;
    gap: 18px;
  }

  h2,
  p {
    margin: 0;
  }

  h2 {
    color: var(--color-brand-strong);
    font-size: 1rem;
    font-weight: 850;
  }

  p {
    margin-top: 3px;
    color: var(--color-text-muted);
    font-size: 0.78rem;
  }

  &__loading {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    color: var(--color-text-muted);
    font-size: 0.76rem;
    font-weight: 750;
  }

  &__cards {
    display: grid;
    grid-template-columns: repeat(6, minmax(0, 1fr));
    gap: 8px;
  }

  &__card {
    display: grid;
    gap: 7px;
    min-width: 0;
    padding: 11px 12px;
    border: 1px solid var(--color-border);
    border-radius: var(--radius-md);
    background: var(--color-surface);
    color: var(--color-text-muted);
    text-align: left;
    cursor: pointer;
    transition:
      border-color var(--motion-fast) ease,
      background var(--motion-fast) ease;

    &:hover {
      border-color: var(--color-border-strong);
      background: var(--color-brand-tint-subtle);
    }

    &--active {
      border-color: var(--color-brand);
      background: var(--color-brand-tint);
      color: var(--color-brand-strong);
      box-shadow: inset 0 0 0 1px var(--color-brand);
    }

    span {
      min-height: 2em;
      font-size: 0.72rem;
      font-weight: 750;
      line-height: 1.1;
    }

    strong {
      color: var(--color-brand-strong);
      font-size: 1.25rem;
      font-variant-numeric: tabular-nums;
      line-height: 1;
    }
  }

  &__filters {
    display: grid;
    grid-template-columns:
      minmax(230px, 1fr) minmax(150px, 0.45fr) minmax(190px, 0.5fr)
      auto auto;
    align-items: end;
    gap: 10px;

    label {
      display: grid;
      gap: 5px;
      min-width: 0;
      color: var(--color-text-muted);
      font-size: 0.7rem;
      font-weight: 800;
    }

    input,
    select {
      width: 100%;
      min-height: 38px;
      border: 1px solid var(--color-border);
      border-radius: var(--radius-md);
      background: var(--color-surface-control);
      color: var(--color-text);
      font-size: 0.8rem;
    }

    input {
      padding: 8px 10px 8px 34px;
    }

    select {
      padding: 8px 30px 8px 10px;
    }
  }

  &__query div {
    position: relative;
  }

  &__search-icon {
    position: absolute;
    top: 50%;
    left: 11px;
    z-index: 1;
    color: var(--color-text-subtle);
    transform: translateY(-50%);
    pointer-events: none;
  }
}

@media (width <= 1000px) {
  .audit-overview {
    &__cards {
      grid-template-columns: repeat(3, minmax(0, 1fr));
    }

    &__filters {
      grid-template-columns: 1fr 1fr;
    }

    &__query {
      grid-column: 1 / -1;
    }
  }
}

@media (width <= 600px) {
  .audit-overview {
    padding: 14px;

    &__heading {
      display: grid;
    }

    &__cards,
    &__filters {
      grid-template-columns: 1fr 1fr;
    }

    &__filters > :deep(button) {
      width: 100%;
    }
  }
}
</style>
