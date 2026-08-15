<script setup lang="ts">
import { computed, ref, shallowRef } from "vue";
import catalogsData from "@data/catalogs.json";
import { useToast } from "~/composables/useToast";
import type {
  CatalogEntry,
  CatalogEntryDraft,
  CatalogTab,
} from "~/types/catalog";
import { normalizeSearchText } from "~/utils/text";

const { showToast } = useToast();
const activeTab = shallowRef<CatalogTab>("services");
const isFormOpen = shallowRef(false);
const editingEntry = shallowRef<CatalogEntry | null>(null);
const stateCodeFilter = shallowRef("");
const cityFilter = shallowRef("");
const neighborhoodFilter = shallowRef("");

const categories = catalogsData.categories.map(({ id, name }) => ({
  id,
  name,
}));
const services = ref<CatalogEntry[]>(
  catalogsData.services.map((item, index) => ({
    id: item.id,
    name: item.name,
    identifier: item.slug,
    description: item.description,
    category: item.category,
    active: index !== 7,
  })),
);
const neighborhoods = ref<CatalogEntry[]>(
  catalogsData.neighborhoods.map((item) => ({
    id: item.code,
    name: item.name,
    identifier: item.code,
    description: "",
    stateCode: item.stateCode,
    city: item.city,
    active: true,
  })),
);

const entries = computed(() =>
  activeTab.value === "services" ? services.value : neighborhoods.value,
);
const visibleEntries = computed(() => {
  if (activeTab.value === "services") return services.value;

  const stateCode = normalizeSearchText(stateCodeFilter.value);
  const city = normalizeSearchText(cityFilter.value);
  const neighborhood = normalizeSearchText(neighborhoodFilter.value);

  return neighborhoods.value.filter(
    (entry) =>
      normalizeSearchText(entry.stateCode).includes(stateCode) &&
      normalizeSearchText(entry.city).includes(city) &&
      normalizeSearchText(entry.name).includes(neighborhood),
  );
});
const formKey = computed(
  () => `${activeTab.value}-${editingEntry.value?.id ?? "new"}`,
);
const modalTitle = computed(() => {
  const action = editingEntry.value ? "Editar" : "Adicionar";
  return `${action} ${activeTab.value === "services" ? "serviço" : "bairro"}`;
});
const modalDescription = computed(() =>
  activeTab.value === "services"
    ? "Atualize os dados usados nos perfis profissionais e na busca."
    : "Atualize UF, cidade e bairro sem alterar o código histórico.",
);

function selectTab(tab: CatalogTab) {
  activeTab.value = tab;
  closeForm();
}

function openCreate() {
  editingEntry.value = null;
  isFormOpen.value = true;
}

function openEdit(entry: CatalogEntry) {
  editingEntry.value = entry;
  isFormOpen.value = true;
}

function closeForm() {
  isFormOpen.value = false;
  editingEntry.value = null;
}

function updateFormOpen(open: boolean) {
  if (open) {
    isFormOpen.value = true;
  } else {
    closeForm();
  }
}

function replaceEntries(nextEntries: CatalogEntry[]) {
  if (activeTab.value === "services") {
    services.value = nextEntries;
  } else {
    neighborhoods.value = nextEntries;
  }
}

function saveEntry(draft: CatalogEntryDraft) {
  const duplicate = entries.value.some(
    (entry) =>
      entry.identifier === draft.identifier &&
      entry.id !== editingEntry.value?.id,
  );

  if (duplicate) {
    showToast({
      title: "Identificador já utilizado",
      description: "Use um slug ou código único para esta entrada.",
    });
    return;
  }

  if (editingEntry.value) {
    replaceEntries(
      entries.value.map((entry) =>
        entry.id === editingEntry.value?.id
          ? {
              ...entry,
              name: draft.name,
              description: draft.description,
              category: draft.category,
              stateCode: draft.stateCode,
              city: draft.city,
            }
          : entry,
      ),
    );
  } else {
    replaceEntries([
      ...entries.value,
      {
        id: `${activeTab.value === "services" ? "svc" : "bairro"}-${draft.identifier}`,
        ...draft,
        active: true,
      },
    ]);
  }

  showToast({
    title: "Catálogo atualizado",
    description: "A lista local foi atualizada para esta demonstração.",
  });
  closeForm();
}

function toggleEntry(id: string) {
  replaceEntries(
    entries.value.map((entry) =>
      entry.id === id ? { ...entry, active: !entry.active } : entry,
    ),
  );
  showToast({
    title: "Status atualizado",
    description: "Referências históricas foram preservadas.",
  });
}

function moveEntry(id: string, direction: -1 | 1) {
  const currentVisibleIndex = visibleEntries.value.findIndex(
    (entry) => entry.id === id,
  );
  const targetVisibleIndex = currentVisibleIndex + direction;
  if (
    currentVisibleIndex < 0 ||
    targetVisibleIndex < 0 ||
    targetVisibleIndex >= visibleEntries.value.length
  ) {
    return;
  }

  const targetId = visibleEntries.value[targetVisibleIndex]?.id;
  const currentIndex = entries.value.findIndex((entry) => entry.id === id);
  const targetIndex = entries.value.findIndex((entry) => entry.id === targetId);
  if (currentIndex < 0 || targetIndex < 0) return;

  const reordered = [...entries.value];
  const currentEntry = reordered[currentIndex];
  const targetEntry = reordered[targetIndex];
  if (!currentEntry || !targetEntry) return;

  reordered[currentIndex] = targetEntry;
  reordered[targetIndex] = currentEntry;
  replaceEntries(reordered);
  showToast({
    title: "Ordem atualizada",
    description: "A listagem usa agora a nova ordem do catálogo.",
  });
}
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="catalog">
    <header class="catalog__header">
      <div>
        <h2 class="catalog__title">Catálogo controlado</h2>
        <p class="catalog__description">
          A mesma lista alimenta a busca e os perfis profissionais.
        </p>
      </div>
      <UButton
        color="primary"
        icon="i-lucide-plus"
        label="Adicionar entrada"
        @click="openCreate"
      />
    </header>

    <nav class="catalog__tabs" aria-label="Tipos de catálogo">
      <button
        type="button"
        :class="{ 'catalog__tab--active': activeTab === 'services' }"
        @click="selectTab('services')"
      >
        Serviços <span>{{ services.length }}</span>
      </button>
      <button
        type="button"
        :class="{ 'catalog__tab--active': activeTab === 'neighborhoods' }"
        @click="selectTab('neighborhoods')"
      >
        Bairros <span>{{ neighborhoods.length }}</span>
      </button>
    </nav>

    <AdminCatalogNeighborhoodFilters
      v-if="activeTab === 'neighborhoods'"
      v-model:state-code="stateCodeFilter"
      v-model:city="cityFilter"
      v-model:neighborhood="neighborhoodFilter"
    />

    <AdminCatalogEntryList
      :entries="visibleEntries"
      :tab="activeTab"
      @edit="openEdit"
      @toggle="toggleEntry"
      @move="moveEntry"
    />
  </DesignSystemSurfaceCard>

  <UModal
    :open="isFormOpen"
    :title="modalTitle"
    :description="modalDescription"
    :ui="{ content: 'sm:max-w-2xl' }"
    @update:open="updateFormOpen"
  >
    <template #body>
      <AdminCatalogEntryForm
        :key="formKey"
        :tab="activeTab"
        :entry="editingEntry"
        :categories="categories"
        @save="saveEntry"
        @cancel="closeForm"
      />
    </template>
  </UModal>
</template>

<style scoped lang="scss">
.catalog {
  overflow: hidden;
  &__header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 20px;
    padding: 22px;
  }
  &__title,
  &__description {
    margin: 0;
  }
  &__title {
    font-family: var(--font-display);
    font-size: 1.5rem;
  }
  &__description {
    margin-top: 4px;
    color: var(--ink-soft);
    font-size: 0.86rem;
  }
  &__tabs {
    display: flex;
    gap: 4px;
    padding: 0 22px;
    border-bottom: 1px solid var(--line);
  }
  &__tabs button {
    padding: 10px 12px;
    border: 0;
    border-bottom: 2px solid transparent;
    background: transparent;
    color: var(--ink-soft);
    font-size: 0.86rem;
    font-weight: 850;
    cursor: pointer;
  }
  &__tabs button.catalog__tab--active {
    border-bottom-color: var(--color-brand);
    color: var(--color-brand);
  }
  &__tabs span {
    margin-left: 4px;
    padding: 2px 5px;
    border-radius: 5px;
    background: #eeece6;
    font-size: var(--font-size-min);
  }
}
@media (width <= 700px) {
  .catalog__header {
    display: grid;
  }
}
</style>
