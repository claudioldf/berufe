<script setup lang="ts">
import type { CatalogEntry, CatalogTab } from "~/types/catalog";

const props = defineProps<{
  entries: CatalogEntry[];
  tab: CatalogTab;
}>();

const emit = defineEmits<{
  edit: [entry: CatalogEntry];
  toggle: [id: string];
  move: [id: string, direction: -1 | 1];
}>();
</script>

<template>
  <div class="catalog-table">
    <div
      class="catalog-table__head"
      :class="{
        'catalog-table__head--neighborhoods': props.tab === 'neighborhoods',
      }"
    >
      <template v-if="props.tab === 'services'">
        <span>Ordem</span><span>Nome</span><span>Identificador</span
        ><span>Status</span><span>Ações</span>
      </template>
      <template v-else>
        <span>Ordem</span><span>UF</span><span>Cidade</span><span>Bairro</span
        ><span>Código</span><span>Status</span><span>Ações</span>
      </template>
    </div>
    <div
      v-for="(entry, index) in props.entries"
      :key="entry.id"
      class="catalog-table__row"
      :class="{
        'catalog-table__row--neighborhood': props.tab === 'neighborhoods',
      }"
    >
      <span class="catalog-table__order">
        <button
          type="button"
          :aria-label="`Mover ${entry.name} para cima`"
          :disabled="index === 0"
          @click="emit('move', entry.id, -1)"
        >
          <UIcon name="i-lucide-chevron-up" />
        </button>
        <button
          type="button"
          :aria-label="`Mover ${entry.name} para baixo`"
          :disabled="index === props.entries.length - 1"
          @click="emit('move', entry.id, 1)"
        >
          <UIcon name="i-lucide-chevron-down" />
        </button>
        <small>{{ index + 1 }}</small>
      </span>
      <template v-if="props.tab === 'neighborhoods'">
        <span class="catalog-table__state">{{ entry.stateCode }}</span>
        <span class="catalog-table__city">{{ entry.city }}</span>
      </template>
      <span class="catalog-table__name">
        <strong>{{ entry.name }}</strong>
        <small v-if="entry.description">{{ entry.description }}</small>
      </span>
      <code class="catalog-table__identifier">{{ entry.identifier }}</code>
      <button
        type="button"
        class="catalog-table__status"
        :class="{ 'catalog-table__status--inactive': !entry.active }"
        @click="emit('toggle', entry.id)"
      >
        <i />{{ entry.active ? "Ativo" : "Inativo" }}
      </button>
      <button
        type="button"
        class="catalog-table__edit"
        @click="emit('edit', entry)"
      >
        <UIcon name="i-lucide-pencil" /> Editar
      </button>
    </div>
    <div v-if="props.entries.length === 0" class="catalog-table__empty">
      <UIcon name="i-lucide-search-x" />
      <strong>Nenhum bairro encontrado</strong>
      <small>Revise ou limpe os filtros para ver outras localidades.</small>
    </div>
  </div>
</template>

<style scoped lang="scss">
.catalog-table {
  &__head,
  &__row {
    display: grid;
    grid-template-columns: 90px 1.5fr 1fr 90px 75px;
    gap: 12px;
    align-items: center;
    padding: 11px 20px;
  }
  &__head--neighborhoods,
  &__row--neighborhood {
    grid-template-columns:
      80px 45px minmax(110px, 0.8fr) minmax(140px, 1fr) minmax(100px, 0.8fr)
      80px 70px;
  }
  &__head {
    background: var(--color-surface-muted);
    color: var(--ink-soft);
    font-size: var(--font-size-min);
    font-weight: 900;
    text-transform: uppercase;
  }
  &__row {
    min-height: 66px;
    border-top: 1px solid var(--line);
  }
  &__order {
    display: flex;
    align-items: center;
    color: var(--ink-soft);
  }
  &__order button {
    display: grid;
    place-items: center;
    width: 24px;
    height: 28px;
    padding: 0;
    border: 0;
    background: transparent;
    color: inherit;
    cursor: pointer;
  }
  &__order button:disabled {
    opacity: 0.25;
    cursor: default;
  }
  &__order small {
    margin-left: 3px;
    font-size: var(--font-size-min);
  }
  &__name strong,
  &__name small {
    display: block;
  }
  &__name strong {
    font-size: 0.86rem;
  }
  &__name small {
    overflow: hidden;
    max-width: 400px;
    margin-top: 3px;
    color: var(--ink-soft);
    font-size: var(--font-size-min);
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  &__identifier {
    color: var(--ink-soft);
    font-size: var(--font-size-min);
  }
  &__state,
  &__city {
    color: var(--ink-soft);
    font-size: var(--font-size-min);
  }
  &__state {
    font-weight: 850;
  }
  &__status,
  &__edit {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    border: 0;
    background: transparent;
    color: #31715f;
    font-size: var(--font-size-min);
    font-weight: 850;
    cursor: pointer;
  }
  &__status i {
    width: 7px;
    height: 7px;
    border-radius: 99px;
    background: #4caf8e;
  }
  &__status--inactive {
    color: #8a7772;
  }
  &__status--inactive i {
    background: #a79792;
  }
  &__edit {
    color: var(--ink-soft);
  }
  &__empty {
    display: grid;
    justify-items: center;
    gap: 4px;
    padding: 36px 20px;
    color: var(--ink-soft);
    text-align: center;
  }
  &__empty > svg {
    margin-bottom: 4px;
    font-size: 1.4rem;
  }
  &__empty strong {
    color: var(--ink);
    font-size: 0.9rem;
  }
  &__empty small {
    font-size: var(--font-size-min);
  }
}
@media (width <= 700px) {
  .catalog-table {
    &__head {
      display: none;
    }
    &__row {
      grid-template-columns: 70px 1fr auto;
      padding-inline: 14px;
    }
    &__row--neighborhood {
      grid-template-columns: 70px 1fr auto;
    }
    &__row--neighborhood &__state {
      grid-column: 2;
      align-self: end;
    }
    &__row--neighborhood &__city {
      grid-column: 2;
    }
    &__row--neighborhood &__name {
      grid-column: 2;
    }
    &__row--neighborhood &__status {
      grid-column: 3;
      grid-row: 2;
    }
    &__identifier {
      display: none;
    }
    &__edit {
      grid-column: 3;
    }
  }
}
</style>
