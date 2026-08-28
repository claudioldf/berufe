<script setup lang="ts">
import { reactive } from "vue";
import type {
  CatalogCategoryOption,
  CatalogEntry,
  CatalogEntryDraft,
} from "~/types/catalog";

const props = defineProps<{
  entry: CatalogEntry | null;
  categories: readonly CatalogCategoryOption[];
  disabled?: boolean;
}>();
const emit = defineEmits<{
  save: [draft: CatalogEntryDraft];
  cancel: [];
}>();
const form = reactive<CatalogEntryDraft>({
  name: props.entry?.name ?? "",
  identifier: props.entry?.identifier ?? "",
  description: props.entry?.description ?? "",
  category: props.entry?.category ?? props.categories[0]?.id,
});

function submit() {
  emit("save", {
    name: form.name.trim(),
    identifier: form.identifier.trim().toLocaleLowerCase("pt-BR"),
    description: form.description.trim(),
    category: form.category,
  });
}
</script>

<template>
  <form class="catalog-form" @submit.prevent="submit">
    <label class="catalog-form__field">
      <span>Nome</span>
      <input v-model="form.name" maxlength="80" required :disabled="disabled" />
    </label>
    <label class="catalog-form__field">
      <span>Categoria</span>
      <select v-model="form.category" required :disabled="disabled">
        <option
          v-for="category in categories"
          :key="category.id"
          :value="category.id"
        >
          {{ category.name }}
        </option>
      </select>
    </label>
    <label class="catalog-form__field">
      <span>Slug</span>
      <input
        v-model="form.identifier"
        maxlength="80"
        pattern="[a-z0-9-]+"
        required
        :disabled="Boolean(entry) || disabled"
      />
      <small v-if="entry"
        >O slug permanece estável para preservar referências históricas.</small
      >
    </label>
    <label class="catalog-form__field">
      <span>Descrição</span>
      <textarea
        v-model="form.description"
        rows="3"
        maxlength="240"
        required
        :disabled="disabled"
      />
    </label>
    <div class="catalog-form__actions">
      <button
        type="button"
        class="catalog-form__cancel"
        :disabled="disabled"
        @click="emit('cancel')"
      >
        Cancelar
      </button>
      <button type="submit" class="catalog-form__save" :disabled="disabled">
        {{ entry ? "Salvar alterações" : "Adicionar serviço" }}
      </button>
    </div>
  </form>
</template>

<style scoped lang="scss">
.catalog-form {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
  &__field {
    display: grid;
    align-content: start;
    gap: 6px;
  }
  &__field > span {
    font-size: var(--font-size-min);
    font-weight: 850;
  }
  &__field input,
  &__field select,
  &__field textarea {
    width: 100%;
    padding: 10px 11px;
    border: 1px solid var(--line-strong);
    border-radius: 9px;
    background-color: white;
    color: var(--ink);
    font: inherit;
    font-size: 0.86rem;
  }
  &__field select {
    padding-right: 2.5rem;
  }
  &__field small {
    color: var(--ink-soft);
    font-size: var(--font-size-min);
  }
  &__field textarea {
    resize: vertical;
  }
  &__actions {
    grid-column: 1 / -1;
    display: flex;
    justify-content: end;
    gap: 8px;
  }
  &__cancel,
  &__save {
    padding: 9px 13px;
    border-radius: 9px;
    font-size: 0.82rem;
    font-weight: 850;
    cursor: pointer;
  }
  &__cancel {
    border: 1px solid var(--line-strong);
    background: white;
    color: var(--ink-soft);
  }
  &__save {
    border: 1px solid var(--color-brand);
    background: var(--color-brand);
    color: white;
  }
  button:disabled {
    opacity: 0.55;
    cursor: not-allowed;
  }
}
@media (width <= 640px) {
  .catalog-form {
    grid-template-columns: 1fr;
  }
}
</style>
