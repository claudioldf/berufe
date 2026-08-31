<script setup lang="ts">
import { computed, shallowRef, watch } from "vue";
import type {
  ProfessionalPortfolioItem,
  PortfolioItemDraft,
  PortfolioItemUpdateDraft,
} from "~/types";

const props = withDefaults(
  defineProps<{
    items: ProfessionalPortfolioItem[];
    serviceOptions?: string[];
    submitting?: boolean;
    initialEditItemId?: string | null;
  }>(),
  {
    serviceOptions: () => ["Eletricista", "Marido de aluguel"],
    submitting: false,
    initialEditItemId: null,
  },
);
const emit = defineEmits<{
  added: [draft: PortfolioItemDraft];
  updated: [id: string, draft: PortfolioItemUpdateDraft];
  removed: [id: string];
  editClosed: [];
}>();
const uploadOpen = shallowRef(false);
const editOpen = shallowRef(false);
const editingItemId = shallowRef<string | null>(null);
const editingItem = computed(() =>
  props.items.find((item) => item.id === editingItemId.value),
);
const expandedRejectionReasonIds = shallowRef(new Set<string>());
const rejectionReasonPreviewLength = 120;
const emptyStateBenefits = [
  "Até 12 trabalhos com serviço e descrição",
  "Imagens em destaque no seu perfil público",
  "Publicação imediata enquanto a equipe revisa",
];
const emptyStateVisual = {
  icon: "i-lucide-images",
  title: "Meus trabalhos",
  caption: "Resultados que falam por você",
  metaLabel: "Capacidade",
  metaValue: "Até 12 trabalhos",
  badge: "Mais confiança",
  badgeIcon: "i-lucide-badge-check",
};

watch(
  [() => props.initialEditItemId, () => props.items],
  ([itemId, items]) => {
    if (!itemId || editOpen.value) return;
    const item = items.find(
      (candidate) =>
        candidate.id === itemId && isEditableStatus(candidate.status),
    );
    if (item) openEdit(item);
  },
  { immediate: true },
);

watch(editingItem, (item) => {
  if (editOpen.value && (!item || !isEditableStatus(item.status))) closeEdit();
});

function isEditableStatus(status: ProfessionalPortfolioItem["status"]) {
  return status === "rejected" || status === "hidden";
}

function submitUpload(draft: PortfolioItemUpdateDraft) {
  if (!draft.file) return;
  emit("added", { ...draft, file: draft.file });
  uploadOpen.value = false;
}

function openEdit(item: ProfessionalPortfolioItem) {
  if (!isEditableStatus(item.status)) return;
  editingItemId.value = item.id;
  editOpen.value = true;
}

function closeEdit() {
  editOpen.value = false;
  editingItemId.value = null;
  emit("editClosed");
}

function handleEditOpen(open: boolean) {
  if (open) {
    editOpen.value = true;
  } else if (editOpen.value) {
    closeEdit();
  }
}

function submitEdit(draft: PortfolioItemUpdateDraft) {
  const item = editingItem.value;
  if (!item) return;
  emit("updated", item.id, draft);
}

function isRejectionReasonLong(reason: string) {
  return reason.length > rejectionReasonPreviewLength;
}

function isRejectionReasonExpanded(itemId: string) {
  return expandedRejectionReasonIds.value.has(itemId);
}

function rejectionReasonText(item: ProfessionalPortfolioItem) {
  const reason = item.rejectionReason;

  if (
    !reason ||
    !isRejectionReasonLong(reason) ||
    isRejectionReasonExpanded(item.id)
  ) {
    return reason;
  }

  const preview = reason.slice(0, rejectionReasonPreviewLength);
  const lastWordBoundary = preview.lastIndexOf(" ");
  const cutoff = lastWordBoundary >= 80 ? lastWordBoundary : preview.length;

  return `${preview.slice(0, cutoff).trimEnd()}…`;
}

function toggleRejectionReason(itemId: string) {
  const nextIds = new Set(expandedRejectionReasonIds.value);

  if (nextIds.has(itemId)) {
    nextIds.delete(itemId);
  } else {
    nextIds.add(itemId);
  }

  expandedRejectionReasonIds.value = nextIds;
}
</script>

<template>
  <div class="portfolio-manager">
    <DesignSystemSurfaceCard
      v-if="items.length"
      as="section"
      class="portfolio-manager__intro"
    >
      <div>
        <DesignSystemEyebrow>Seu trabalho na prática</DesignSystemEyebrow>
        <h2>Meus trabalhos</h2>
        <p>
          Adicione até 12 trabalhos. Em um perfil publicado, novos itens
          aparecem imediatamente e continuam na fila de revisão.
        </p>
      </div>
      <UButton
        color="primary"
        icon="i-lucide-image-plus"
        :disabled="items.length >= 12"
        @click="uploadOpen = true"
        >Adicionar trabalho</UButton
      >
    </DesignSystemSurfaceCard>
    <DesignSystemFeatureEmptyState
      v-if="items.length === 0"
      eyebrow="Seu trabalho vende por você"
      title="Mostre resultados antes mesmo da conversa."
      description="Fotos de trabalhos reais ajudam clientes a entender sua qualidade, seu cuidado e o tipo de resultado que podem esperar."
      :items="emptyStateBenefits"
      cta-label="Adicionar meu primeiro trabalho"
      cta-icon="i-lucide-image-plus"
      :visual="emptyStateVisual"
      @action="uploadOpen = true"
    />
    <div v-else class="portfolio-manager__grid">
      <article v-for="item in items" :key="item.id">
        <img
          v-if="item.image"
          :src="item.image"
          :alt="item.title"
          width="640"
          height="380"
          loading="lazy"
        />
        <div v-else class="portfolio-manager__placeholder" aria-hidden="true">
          <UIcon name="i-lucide-image" />
        </div>
        <div class="portfolio-manager__details">
          <span
            ><strong>{{ item.title }}</strong
            ><small>{{ item.service }}</small></span
          ><em
            v-if="item.status === 'rejected'"
            class="portfolio-manager__status"
            >Recusado</em
          >
        </div>
        <p v-if="item.rejectionReason" class="portfolio-manager__reason">
          <strong>Motivo:</strong>
          <span :id="`portfolio-rejection-reason-${item.id}`">{{
            rejectionReasonText(item)
          }}</span>
          <button
            v-if="isRejectionReasonLong(item.rejectionReason)"
            type="button"
            class="portfolio-manager__reason-toggle"
            :aria-expanded="isRejectionReasonExpanded(item.id)"
            :aria-controls="`portfolio-rejection-reason-${item.id}`"
            @click="toggleRejectionReason(item.id)"
          >
            {{ isRejectionReasonExpanded(item.id) ? "ver menos" : "ver mais" }}
          </button>
        </p>
        <div
          v-if="isEditableStatus(item.status)"
          class="portfolio-manager__card-actions"
        >
          <UButton
            type="button"
            size="sm"
            color="primary"
            variant="soft"
            icon="i-lucide-pencil"
            @click="openEdit(item)"
          >
            Editar e reenviar
          </UButton>
        </div>
        <button
          type="button"
          :aria-label="`Excluir ${item.title}`"
          @click="emit('removed', item.id)"
        >
          <UIcon name="i-lucide-trash-2" />
        </button>
      </article>
      <button
        v-if="items.length < 12"
        class="portfolio-manager__add"
        type="button"
        @click="uploadOpen = true"
      >
        <UIcon name="i-lucide-plus" /><strong>Adicionar trabalho</strong
        ><small>{{ items.length }} de 12 trabalhos</small>
      </button>
    </div>
    <UModal
      v-model:open="uploadOpen"
      title="Adicionar trabalho"
      description="A imagem será publicada imediatamente e revisada pela equipe."
    >
      <template #body>
        <DashboardPortfolioUploadForm
          :service-options="serviceOptions"
          show-cancel
          :submitting="submitting"
          @cancel="uploadOpen = false"
          @submitted="submitUpload"
        />
      </template>
    </UModal>
    <UModal
      :open="editOpen"
      title="Corrigir trabalho"
      description="Atualize as informações indicadas e envie o mesmo trabalho para uma nova análise."
      @update:open="handleEditOpen"
    >
      <template v-if="editingItem" #body>
        <DashboardPortfolioUploadForm
          :key="editingItem.id"
          :service-options="serviceOptions"
          :initial-values="editingItem"
          :image-required="false"
          :reset-on-submit="false"
          submit-label="Salvar e reenviar"
          show-cancel
          :submitting="submitting"
          @cancel="closeEdit"
          @submitted="submitEdit"
        />
      </template>
    </UModal>
  </div>
</template>

<style scoped lang="scss">
.portfolio-manager {
  display: grid;
  gap: 18px;
  &__intro {
    display: flex;
    justify-content: space-between;
    align-items: end;
    gap: 30px;
    padding: 26px;
  }
  &__intro h2 {
    margin: 0;
    font-family: var(--font-display);
    font-size: 2rem;
  }
  &__intro p:last-child {
    max-width: 580px;
    margin: 7px 0 0;
    color: var(--ink-soft);
    font-size: 0.82rem;
    line-height: 1.5;
  }
  &__grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 12px;
  }
  &__grid article {
    position: relative;
    overflow: hidden;
    border: 1px solid var(--line);
    border-radius: 16px;
    background: white;
  }
  &__grid article > img {
    width: 100%;
    height: 190px;
    object-fit: cover;
  }
  &__placeholder {
    display: grid !important;
    place-items: center;
    width: 100%;
    height: 190px;
    padding: 0 !important;
    background: var(--paper-soft);
    color: var(--ink-soft);
    font-size: 2rem;
  }
  &__details {
    display: flex;
    justify-content: space-between;
    gap: 8px;
    padding: 13px;
  }
  &__grid strong,
  &__grid small {
    display: block;
  }
  &__grid strong {
    font-size: 0.82rem;
  }
  &__grid small {
    margin-top: 3px;
    color: var(--ink-soft);
    font-size: 0.82rem;
  }
  &__status {
    align-self: start;
    padding: 4px 6px;
    border-radius: 6px;
    background: var(--color-danger-tint);
    color: var(--color-danger);
    font-size: 0.82rem;
    font-style: normal;
    font-weight: 900;
  }
  &__reason {
    margin: -4px 13px 13px;
    color: var(--color-danger);
    font-size: 0.76rem;
    line-height: 1.45;
  }
  &__reason strong {
    display: inline;
    font-size: inherit;
  }
  &__reason-toggle {
    margin-left: 4px;
    padding: 0;
    border: 0;
    background: none;
    color: inherit;
    font: inherit;
    font-weight: 800;
    text-decoration: underline;
    cursor: pointer;
  }
  &__card-actions {
    display: flex;
    justify-content: flex-end;
    padding: 0 13px 13px;
  }
  &__grid article > button {
    position: absolute;
    top: 9px;
    right: 9px;
    display: grid;
    place-items: center;
    width: 31px;
    height: 31px;
    border: 0;
    border-radius: 9px;
    background: rgb(255 255 255 / 92%);
    cursor: pointer;
  }
  &__add {
    min-height: 260px;
    display: grid;
    place-items: center;
    align-content: center;
    gap: 5px;
    border: 1px dashed #9ab9af;
    border-radius: 16px;
    background: transparent;
    color: var(--color-brand);
    cursor: pointer;
  }
  &__add > svg {
    margin-bottom: 5px;
    font-size: 1.5rem;
  }
  &__add small {
    color: var(--ink-soft);
  }
}
@media (width <= 780px) {
  .portfolio-manager {
    &__grid {
      grid-template-columns: repeat(2, 1fr);
    }
    &__intro {
      display: grid;
    }
  }
}
@media (width <= 500px) {
  .portfolio-manager {
    &__grid {
      grid-template-columns: 1fr;
    }
  }
}
</style>
