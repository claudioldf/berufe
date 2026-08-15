<script setup lang="ts">
import { reactive, shallowRef, watch } from "vue";
import type {
  CatalogCategoryOption,
  CatalogEntry,
  CatalogEntryDraft,
  CatalogTab,
} from "~/types/catalog";
import { toIdentifier } from "~/utils/text";

const props = defineProps<{
  tab: CatalogTab;
  entry: CatalogEntry | null;
  categories: CatalogCategoryOption[];
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
  stateCode: props.entry?.stateCode ?? "SC",
  city: props.entry?.city ?? "Joinville",
});
const identifierManuallyEdited = shallowRef(false);

function trackIdentifierEdit(event: Event) {
  if (props.tab !== "neighborhoods" || props.entry) return;

  const value = (event.target as HTMLInputElement).value;
  identifierManuallyEdited.value = value !== toIdentifier(form.name);
}

watch(
  () => form.name,
  (name) => {
    if (
      props.tab !== "neighborhoods" ||
      props.entry ||
      identifierManuallyEdited.value
    ) {
      return;
    }
    form.identifier = toIdentifier(name);
  },
);

function submit() {
  emit("save", {
    name: form.name.trim(),
    identifier: form.identifier.trim().toLocaleLowerCase("pt-BR"),
    description: form.description.trim(),
    category: props.tab === "services" ? form.category : undefined,
    stateCode:
      props.tab === "neighborhoods"
        ? form.stateCode?.trim().toLocaleUpperCase("pt-BR")
        : undefined,
    city: props.tab === "neighborhoods" ? form.city?.trim() : undefined,
  });
}
</script>

<template>
  <form class="catalog-form" @submit.prevent="submit">
    <label class="catalog-form__field">
      <span>{{ props.tab === "services" ? "Nome" : "Bairro" }}</span>
      <input
        v-model="form.name"
        name="catalog-name"
        type="text"
        autocomplete="off"
        maxlength="80"
        required
      />
    </label>

    <label v-if="props.tab === 'services'" class="catalog-form__field">
      <span>Categoria</span>
      <select v-model="form.category" name="catalog-category" required>
        <option
          v-for="category in props.categories"
          :key="category.id"
          :value="category.id"
        >
          {{ category.name }}
        </option>
      </select>
    </label>

    <label v-if="props.tab === 'neighborhoods'" class="catalog-form__field">
      <span>UF</span>
      <input
        v-model="form.stateCode"
        name="state-code"
        type="text"
        autocomplete="address-level1"
        maxlength="2"
        pattern="[A-Za-z]{2}"
        required
      />
    </label>

    <label v-if="props.tab === 'neighborhoods'" class="catalog-form__field">
      <span>Cidade</span>
      <input
        v-model="form.city"
        name="city"
        type="text"
        autocomplete="address-level2"
        maxlength="80"
        required
      />
    </label>

    <label class="catalog-form__field">
      <span>{{ props.tab === "services" ? "Slug" : "Código" }}</span>
      <input
        v-model="form.identifier"
        name="catalog-identifier"
        type="text"
        autocomplete="off"
        maxlength="80"
        pattern="[a-z0-9-]+"
        required
        :disabled="Boolean(props.entry)"
        @input="trackIdentifierEdit"
      />
      <small v-if="props.entry">
        O identificador permanece estável para preservar referências históricas.
      </small>
      <small v-else-if="props.tab === 'neighborhoods'">
        Gerado automaticamente pelo nome do bairro; você pode ajustá-lo antes de
        salvar.
      </small>
    </label>

    <label v-if="props.tab === 'services'" class="catalog-form__field">
      <span>Descrição</span>
      <textarea
        v-model="form.description"
        name="catalog-description"
        rows="3"
        maxlength="240"
      />
    </label>

    <div class="catalog-form__actions">
      <button
        type="button"
        class="catalog-form__cancel"
        @click="emit('cancel')"
      >
        Cancelar
      </button>
      <button type="submit" class="catalog-form__save">
        {{ props.entry ? "Salvar alterações" : "Adicionar entrada" }}
      </button>
    </div>
  </form>
</template>

<style scoped lang="scss">
.catalog-form {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
  &__actions {
    grid-column: 1 / -1;
  }
  &__field small {
    margin-top: 3px;
    color: var(--ink-soft);
    font-size: var(--font-size-min);
  }
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
    background: white;
    color: var(--ink);
    font: inherit;
    font-size: 0.86rem;
  }
  &__field input:disabled {
    background: #eceae4;
    color: var(--ink-soft);
  }
  &__field textarea {
    resize: vertical;
  }
  &__actions {
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
    border: 1px solid var(--color-brand-strong);
    background: var(--color-brand-strong);
    color: white;
  }
}
@media (width <= 700px) {
  .catalog-form {
    grid-template-columns: 1fr;
  }
}
</style>
