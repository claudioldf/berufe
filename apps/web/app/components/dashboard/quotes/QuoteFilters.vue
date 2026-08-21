<script setup lang="ts">
import type { Quote } from "~/types";

const props = defineProps<{
  query: string;
  status: Quote["status"] | "all";
  scheduledOn: string;
}>();
const emit = defineEmits<{
  "update:query": [value: string];
  "update:status": [value: Quote["status"] | "all"];
  "update:scheduledOn": [value: string];
}>();

function inputValue(event: Event) {
  return (event.target as HTMLInputElement).value;
}
</script>

<template>
  <DesignSystemSurfaceCard
    as="section"
    class="quote-filters"
    aria-label="Filtros de orçamentos"
  >
    <label class="quote-filters__search">
      <span>Buscar orçamento</span>
      <span class="quote-filters__control">
        <UIcon
          class="quote-filters__search-icon"
          name="i-lucide-search"
          aria-hidden="true"
        />
        <input
          :value="props.query"
          class="quote-filters__input"
          name="quoteSearch"
          type="search"
          autocomplete="off"
          maxlength="100"
          placeholder="Cliente, serviço ou número…"
          @input="emit('update:query', inputValue($event))"
        />
      </span>
    </label>

    <label class="quote-filters__status">
      <span>Status</span>
      <select
        :value="props.status"
        class="quote-filters__select"
        name="quoteStatus"
        autocomplete="off"
        @change="
          emit('update:status', inputValue($event) as Quote['status'] | 'all')
        "
      >
        <option value="all">Todos os status</option>
        <option value="draft">Rascunho</option>
        <option value="shared">Aguardando cliente</option>
        <option value="change_requested">Alteração solicitada</option>
        <option value="approved">Aprovado</option>
        <option value="declined">Recusado</option>
      </select>
    </label>

    <label class="quote-filters__date">
      <span>Data combinada</span>
      <input
        :value="props.scheduledOn"
        class="quote-filters__date-input"
        name="quoteScheduledOn"
        type="date"
        autocomplete="off"
        @input="emit('update:scheduledOn', inputValue($event))"
      />
    </label>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.quote-filters {
  display: grid;
  grid-template-columns:
    minmax(220px, 1fr) minmax(190px, 0.38fr)
    minmax(170px, 0.32fr);
  gap: 14px;
  align-items: end;
  padding: 18px;

  &__search,
  &__status,
  &__date {
    display: grid;
    gap: 7px;
    color: var(--ink);
    font-size: 0.84rem;
    font-weight: 800;
  }

  &__control {
    position: relative;
    display: flex;
    align-items: center;
  }

  &__search-icon {
    position: absolute;
    z-index: 1;
    top: 50%;
    left: 13px;
    color: var(--ink-soft);
    font-size: 1rem;
    pointer-events: none;
    transform: translateY(-50%);
  }

  &__input,
  &__select,
  &__date-input {
    width: 100%;
    min-height: 44px;
    border: 1px solid var(--line);
    border-radius: 11px;
    background: var(--color-surface-control);
    color: var(--ink);
  }

  &__input {
    padding: 10px 13px 10px 40px;
  }

  &__select {
    padding: 10px 36px 10px 13px;
  }

  &__date-input {
    padding: 10px 13px;
  }

  &__input:focus-visible,
  &__select:focus-visible,
  &__date-input:focus-visible {
    border-color: var(--color-focus);
    outline: 0;
    box-shadow: var(--focus-ring);
  }
}

@media (width <= 900px) {
  .quote-filters {
    grid-template-columns: 1fr 1fr;

    &__search {
      grid-column: 1 / -1;
    }
  }
}

@media (width <= 560px) {
  .quote-filters {
    grid-template-columns: 1fr;

    &__search {
      grid-column: auto;
    }
  }
}
</style>
