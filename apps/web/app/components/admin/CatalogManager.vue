<script setup lang="ts">
import { computed, onMounted, shallowRef } from "vue";
import { useAdminCatalog } from "~/composables/useAdminCatalog";
import { useToast } from "~/composables/useToast";
import { ApiRequestError } from "~/services/api/errors";
import type {
  CatalogEntry,
  CatalogEntryDraft,
  CatalogTab,
} from "~/types/catalog";
import { normalizeSearchText } from "~/utils/text";

const { showToast } = useToast();
const {
  catalog,
  isLoading,
  isMutating,
  loadError,
  load,
  createService,
  updateService,
  reorderServices,
  createNeighborhood,
  updateNeighborhood,
  reorderNeighborhoods,
} = useAdminCatalog();
const activeTab = shallowRef<CatalogTab>("services");
const isFormOpen = shallowRef(false);
const editingEntry = shallowRef<CatalogEntry | null>(null);
const stateCodeFilter = shallowRef("");
const cityFilter = shallowRef("");
const neighborhoodFilter = shallowRef("");

const categories = computed(() => catalog.value.categories);
const services = computed(() => catalog.value.services);
const neighborhoods = computed(() => catalog.value.neighborhoods);
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

async function initialize(showFailureToast = true) {
  try {
    await load();
  } catch (error) {
    if (showFailureToast) showOperationError(error);
  }
}

function showOperationError(error: unknown) {
  const apiError = error instanceof ApiRequestError ? error : undefined;
  const fieldMessage = apiError
    ? Object.values(apiError.fieldErrors).flat()[0]
    : undefined;
  showToast({
    title:
      apiError?.code === "catalog_conflict"
        ? "Catálogo desatualizado"
        : "Não foi possível atualizar",
    description:
      fieldMessage ??
      apiError?.message ??
      "Tente novamente em alguns instantes.",
  });
}

function validJoinvilleLocation(draft: CatalogEntryDraft) {
  if (draft.stateCode === "SC" && draft.city === "Joinville") return true;

  showToast({
    title: "Localidade inválida",
    description: "O catálogo desta etapa está limitado a Joinville, SC.",
  });
  return false;
}

async function saveEntry(draft: CatalogEntryDraft) {
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

  try {
    if (activeTab.value === "services") {
      if (!draft.category || !draft.description) {
        showToast({
          title: "Revise os campos informados",
          description: "Categoria e descrição são obrigatórias.",
        });
        return;
      }

      if (editingEntry.value) {
        await updateService(editingEntry.value.id, {
          name: draft.name,
          category_slug: draft.category,
          description: draft.description,
        });
      } else {
        await createService({
          name: draft.name,
          slug: draft.identifier,
          category_slug: draft.category,
          description: draft.description,
        });
      }
    } else {
      if (!validJoinvilleLocation(draft)) return;

      if (editingEntry.value) {
        await updateNeighborhood(editingEntry.value.id, {
          name: draft.name,
          state_code: "SC",
          city: "Joinville",
        });
      } else {
        await createNeighborhood({
          name: draft.name,
          code: draft.identifier,
          state_code: "SC",
          city: "Joinville",
        });
      }
    }

    showToast({
      title: "Catálogo atualizado",
      description: "As alterações já estão disponíveis para novas seleções.",
    });
    closeForm();
  } catch (error) {
    showOperationError(error);
    if (error instanceof ApiRequestError && error.code === "catalog_conflict") {
      await initialize(false);
    }
  }
}

async function toggleEntry(id: string) {
  const entry = entries.value.find((item) => item.id === id);
  if (!entry) return;

  try {
    if (activeTab.value === "services") {
      await updateService(id, { is_active: !entry.active });
    } else {
      await updateNeighborhood(id, { is_active: !entry.active });
    }
    showToast({
      title: "Status atualizado",
      description: "Referências históricas foram preservadas.",
    });
  } catch (error) {
    showOperationError(error);
  }
}

async function moveEntry(id: string, direction: -1 | 1) {
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
  try {
    if (activeTab.value === "services") {
      await reorderServices(reordered.map((entry) => entry.id));
    } else {
      await reorderNeighborhoods(reordered.map((entry) => entry.id));
    }
    showToast({
      title: "Ordem atualizada",
      description: "A listagem usa agora a nova ordem do catálogo.",
    });
  } catch (error) {
    showOperationError(error);
    if (error instanceof ApiRequestError && error.code === "catalog_conflict") {
      await initialize(false);
    }
  }
}

onMounted(() => void initialize());
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
        :disabled="isLoading || isMutating"
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

    <p v-if="isLoading" class="catalog__state" role="status">
      Carregando catálogo…
    </p>
    <div v-else-if="loadError" class="catalog__state" role="alert">
      <span>{{ loadError }}</span>
      <UButton
        color="neutral"
        variant="outline"
        label="Tentar novamente"
        @click="initialize()"
      />
    </div>
    <AdminCatalogEntryList
      v-else
      :entries="visibleEntries"
      :tab="activeTab"
      :disabled="isMutating"
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
        :disabled="isMutating"
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
  &__state {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 12px;
    min-height: 180px;
    margin: 0;
    padding: 24px;
    color: var(--ink-soft);
    font-size: 0.86rem;
  }
}
@media (width <= 700px) {
  .catalog__header {
    display: grid;
  }
}
</style>
