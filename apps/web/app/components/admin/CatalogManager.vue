<script setup lang="ts">
import { computed, onMounted, shallowRef } from "vue";
import { useAdminCatalog } from "~/composables/useAdminCatalog";
import { useToast } from "~/composables/useToast";
import { ApiRequestError } from "~/services/api/errors";
import type { CatalogEntry, CatalogEntryDraft } from "~/types/catalog";

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
} = useAdminCatalog();
const isFormOpen = shallowRef(false);
const editingEntry = shallowRef<CatalogEntry | null>(null);
const categories = computed(() => catalog.value.categories);
const services = computed(() => catalog.value.services);
const formKey = computed(() => editingEntry.value?.id ?? "new");

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
  if (open) isFormOpen.value = true;
  else closeForm();
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

async function initialize(showFailureToast = true) {
  try {
    await load();
  } catch (error) {
    if (showFailureToast) showOperationError(error);
  }
}

async function saveEntry(draft: CatalogEntryDraft) {
  const duplicate = services.value.some(
    (entry) =>
      entry.identifier === draft.identifier &&
      entry.id !== editingEntry.value?.id,
  );
  if (duplicate) {
    showToast({
      title: "Identificador já utilizado",
      description: "Use um slug único para este serviço.",
    });
    return;
  }
  if (!draft.category || !draft.description) {
    showToast({
      title: "Revise os campos informados",
      description: "Categoria e descrição são obrigatórias.",
    });
    return;
  }

  try {
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
  const entry = services.value.find((item) => item.id === id);
  if (!entry) return;
  try {
    await updateService(id, { is_active: !entry.active });
    showToast({
      title: "Status atualizado",
      description: "Referências históricas foram preservadas.",
    });
  } catch (error) {
    showOperationError(error);
  }
}

async function moveEntry(id: string, direction: -1 | 1) {
  const currentIndex = services.value.findIndex((entry) => entry.id === id);
  const targetIndex = currentIndex + direction;
  if (
    currentIndex < 0 ||
    targetIndex < 0 ||
    targetIndex >= services.value.length
  )
    return;

  const reordered = [...services.value];
  const currentEntry = reordered[currentIndex];
  const targetEntry = reordered[targetIndex];
  if (!currentEntry || !targetEntry) return;
  reordered[currentIndex] = targetEntry;
  reordered[targetIndex] = currentEntry;

  try {
    await reorderServices(reordered.map((entry) => entry.id));
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
        <h2 class="catalog__title">Catálogo de serviços</h2>
        <p class="catalog__description">
          A mesma lista alimenta a busca e os perfis profissionais. Estados,
          cidades e bairros são mantidos pela importação do IBGE.
        </p>
      </div>
      <UButton
        color="primary"
        icon="i-lucide-plus"
        label="Adicionar serviço"
        :disabled="isLoading || isMutating"
        @click="openCreate"
      />
    </header>

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
      :entries="services"
      :disabled="isMutating"
      @edit="openEdit"
      @toggle="toggleEntry"
      @move="moveEntry"
    />
  </DesignSystemSurfaceCard>

  <UModal
    :open="isFormOpen"
    :title="editingEntry ? 'Editar serviço' : 'Adicionar serviço'"
    description="Atualize os dados usados nos perfis profissionais e na busca."
    :ui="{ content: 'sm:max-w-2xl' }"
    @update:open="updateFormOpen"
  >
    <template #body>
      <AdminCatalogEntryForm
        :key="formKey"
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
    border-bottom: 1px solid var(--line);
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
    max-width: 650px;
    margin-top: 4px;
    color: var(--ink-soft);
    font-size: 0.86rem;
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
