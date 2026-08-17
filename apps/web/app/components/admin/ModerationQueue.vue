<script setup lang="ts">
import { onMounted, shallowRef } from "vue";
import type { ModerationDecision } from "~/types";
import { useModerationQueue } from "~/composables/useModerationQueue";
import { useToast } from "~/composables/useToast";

const { showToast } = useToast();
const {
  queue,
  selectedId,
  typeFilter,
  statusFilter,
  searchQuery,
  note,
  isLoading,
  isMutating,
  loadError,
  mediaUrl,
  mediaLoading,
  mediaError,
  selected,
  load,
  select,
  setTypeFilter,
  setStatusFilter,
  setSearchQuery,
  setPage,
  setNote,
  decide: recordDecision,
} = useModerationQueue();
const reasonOpen = shallowRef(false);
const reason = shallowRef("");
const reasonAction = shallowRef<"rejected" | "hidden">("rejected");

onMounted(() => void load().catch(() => undefined));

function requestReason(action: "rejected" | "hidden") {
  reasonAction.value = action;
  reason.value = "";
  reasonOpen.value = true;
}

async function decide(action: ModerationDecision, privateReason?: string) {
  try {
    const item = await recordDecision(action, { reason: privateReason });
    if (!item) return;
    const titles: Record<ModerationDecision, string> = {
      approved: "Item aprovado",
      rejected: "Item rejeitado",
      hidden: "Item ocultado",
      restored: "Item restaurado",
    };
    showToast({
      title: titles[action],
      description: `A decisão sobre “${item.title}” foi registrada na auditoria.`,
    });
    reasonOpen.value = false;
    reason.value = "";
  } catch (error) {
    showToast({
      title: "Não foi possível registrar a decisão",
      description:
        error instanceof Error
          ? error.message
          : "Atualize a fila e tente novamente.",
    });
  }
}
</script>

<template>
  <div class="moderation">
    <div class="admin-summary">
      <article class="admin-summary--warning">
        <span><UIcon name="i-lucide-inbox" /></span>
        <div>
          <strong>{{ queue.summary.pendingCount }}</strong>
          <small>Aguardando análise</small>
        </div>
      </article>
      <article class="admin-summary--success">
        <span><UIcon name="i-lucide-check-circle-2" /></span>
        <div>
          <strong>{{ queue.summary.reviewedTodayCount }}</strong>
          <small>Analisados hoje</small>
        </div>
      </article>
      <article class="admin-summary--warning">
        <span><UIcon name="i-lucide-clock-3" /></span>
        <div>
          <strong>{{ queue.summary.oldestPendingAge }}</strong>
          <small>Item mais antigo</small>
        </div>
      </article>
    </div>

    <AdminModerationToolbar
      :type-filter="typeFilter"
      :status-filter="statusFilter"
      :search="searchQuery"
      @type="setTypeFilter"
      @status="setStatusFilter"
      @search="setSearchQuery"
    />

    <p v-if="loadError" class="moderation__error" role="alert">
      {{ loadError }}
      <button type="button" @click="load">Tentar novamente</button>
    </p>

    <div
      v-if="queue.items.length || isLoading"
      class="moderation__workspace"
      :aria-busy="isLoading"
    >
      <AdminModerationQueueList
        :items="queue.items"
        :selected-id="selectedId"
        :page="queue.meta.page"
        :total-pages="queue.meta.totalPages"
        :loading="isLoading"
        @select="select"
        @page="setPage"
      />
      <AdminModerationReviewPanel
        v-if="selected"
        :item="selected"
        :note="note"
        :media-url="mediaUrl"
        :media-loading="mediaLoading"
        :media-error="mediaError"
        :mutating="isMutating"
        @note="setNote"
        @approve="decide('approved')"
        @reject="requestReason('rejected')"
        @hide="requestReason('hidden')"
        @restore="decide('restored')"
      />
    </div>

    <DesignSystemSurfaceCard v-else-if="!loadError" class="moderation__empty"
      ><span><UIcon name="i-lucide-party-popper" /></span>
      <h2>Fila em dia.</h2>
      <p>
        Todos os itens deste filtro foram analisados.
      </p></DesignSystemSurfaceCard
    >

    <AdminModerationRejectionDialog
      v-model:open="reasonOpen"
      v-model:reason="reason"
      :action="reasonAction"
      @confirm="decide(reasonAction, reason)"
    />
  </div>
</template>

<style scoped lang="scss">
.moderation {
  display: grid;
  gap: 14px;
}

.admin-summary {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 9px;
  margin-bottom: 4px;

  & article {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 15px;
    border: 1px solid var(--line);
    border-radius: 14px;
    background: white;
  }

  & article > span {
    display: grid;
    place-items: center;
    width: 36px;
    height: 36px;
    border-radius: 10px;
    background: var(--color-surface-muted);
  }

  & strong,
  & small {
    display: block;
  }

  & strong {
    font-family: var(--font-display);
    font-size: 1.3rem;
  }

  & small {
    color: var(--ink-soft);
    font-size: 0.82rem;
  }

  &--warning > span {
    background: #fff2cf !important;
    color: #947019;
  }

  &--success > span {
    background: var(--mint) !important;
    color: var(--color-brand);
  }
}

:deep() {
  .moderation {
    display: grid;
    gap: 14px;
    &__toolbar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 20px;
    }
    &__status {
      width: auto !important;
      padding: 0 !important;
    }
    &__status select {
      min-height: 36px;
      padding: 7px 30px 7px 10px;
      border: 0;
      border-radius: 9px;
      background: white;
      color: var(--ink-soft);
      font-size: 0.82rem;
      font-weight: 800;
    }
    &__filters {
      display: flex;
      overflow-x: auto;
      gap: 5px;
    }
    &__filters button {
      padding: 7px 10px;
      border: 1px solid var(--line);
      border-radius: 8px;
      background: white;
      color: var(--ink-soft);
      font-size: 0.82rem;
      font-weight: 800;
      white-space: nowrap;
      cursor: pointer;
    }
    &__filters button.active {
      border-color: var(--color-brand);
      background: var(--color-brand);
      color: white;
    }
    &__toolbar label {
      display: flex;
      align-items: center;
      gap: 7px;
      width: 220px;
      padding: 8px 10px;
      border: 1px solid var(--line);
      border-radius: 9px;
      background: white;
      color: var(--ink-soft);
    }
    &__toolbar input {
      min-width: 0;
      width: 100%;
      border: 0;
      font-size: 0.84rem;
    }
    &__workspace {
      display: grid;
      grid-template-columns: minmax(280px, 0.65fr) minmax(430px, 1.35fr);
      overflow: hidden;
      min-height: 610px;
      border: 1px solid var(--line);
      border-radius: 18px;
      background: white;
    }
    &__list {
      overflow-y: auto;
      border-right: 1px solid var(--line);
      background: var(--color-surface-hover);
    }
    &__list > button {
      display: grid;
      grid-template-columns: auto 1fr auto;
      gap: 10px;
      width: 100%;
      padding: 15px 13px;
      border: 0;
      border-bottom: 1px solid var(--line);
      border-left: 3px solid transparent;
      background: transparent;
      color: var(--ink);
      text-align: left;
      cursor: pointer;
    }
    &__list > button:hover {
      background: white;
    }
    &__list > button.active {
      border-left-color: var(--color-brand);
      background: white;
    }
    &__type-icon {
      display: grid;
      place-items: center;
      width: 34px;
      height: 34px;
      border-radius: 10px;
      background: var(--mint);
      color: var(--color-brand);
    }
    &__list em,
    &__list strong,
    &__list small {
      display: block;
    }
    &__list em {
      color: var(--color-brand);
      font-size: 0.82rem;
      font-style: normal;
      font-weight: 900;
      text-transform: uppercase;
    }
    &__list strong {
      overflow: hidden;
      margin-top: 3px;
      font-size: 0.86rem;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    &__list small {
      margin-top: 3px;
      color: var(--ink-soft);
      font-size: 0.82rem;
    }
    &__age {
      color: var(--ink-soft);
      font-size: 0.82rem;
    }
    &__filtered-empty {
      padding: 30px;
      color: var(--ink-soft);
      font-size: 0.86rem;
      text-align: center;
    }
    &__pagination {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      padding: 12px;
      border-top: 1px solid var(--line);
      color: var(--ink-soft);
      font-size: 0.8rem;
    }
    &__pagination button,
    &__overflow-action {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
      min-width: 32px;
      min-height: 32px;
      border: 1px solid var(--line);
      border-radius: 9px;
      background: white;
      color: var(--ink);
      cursor: pointer;
    }
    &__pagination button:disabled,
    &__overflow-action:disabled {
      cursor: not-allowed;
      opacity: 0.5;
    }
    &__overflow-action {
      margin: 8px;
      padding: 7px 10px;
      color: var(--color-error);
      font-size: 0.82rem;
      font-weight: 800;
    }
    &__review {
      display: flex;
      flex-direction: column;
      min-width: 0;
      padding: 24px;
    }
    &__review > header {
      display: flex;
      justify-content: space-between;
      gap: 20px;
    }
    &__review > header span {
      color: var(--color-brand);
      font-size: 0.82rem;
      font-weight: 900;
      text-transform: uppercase;
    }
    &__review > header h2 {
      margin: 4px 0 0;
      font-family: var(--font-display);
      font-size: 1.65rem;
    }
    &__review > header p {
      margin: 4px 0 0;
      color: var(--ink-soft);
      font-size: 0.84rem;
    }
    &__review > header button {
      display: grid;
      place-items: center;
      width: 32px;
      height: 32px;
      border: 1px solid var(--line);
      border-radius: 9px;
      background: white;
      cursor: pointer;
    }
    &__meta {
      display: flex;
      gap: 16px;
      padding: 14px 0;
      margin: 17px 0;
      border-block: 1px solid var(--line);
      color: var(--ink-soft);
      font-size: 0.82rem;
    }
    &__meta span {
      display: flex;
      align-items: center;
      gap: 4px;
    }
    &__review-block > span {
      color: var(--ink-soft);
      font-size: 0.82rem;
      font-weight: 900;
      text-transform: uppercase;
    }
    &__review-block p {
      margin: 5px 0 0;
      font-size: 0.86rem;
      line-height: 1.55;
    }
    &__preview {
      display: grid;
      grid-template-columns: auto 1fr;
      gap: 12px;
      align-items: center;
      padding: 17px;
      margin-top: 16px;
      border: 1px solid var(--line);
      border-radius: 13px;
      background: var(--color-surface-hover);
    }
    &__preview > div {
      display: grid;
      place-items: center;
      width: 48px;
      height: 48px;
      border-radius: 12px;
      background: white;
      color: var(--color-brand);
      font-size: 1.25rem;
    }
    &__preview > img {
      width: 112px;
      height: 112px;
      border-radius: 11px;
      object-fit: cover;
    }
    &__preview.has-image {
      grid-template-columns: auto 1fr;
    }
    &__preview small {
      color: var(--ink-soft);
      font-size: 0.82rem;
      font-weight: 850;
      text-transform: uppercase;
    }
    &__preview p {
      margin: 5px 0 0;
      font-family: var(--font-display);
      font-size: 0.83rem;
      line-height: 1.4;
    }
    &__private-warning {
      display: grid;
      grid-template-columns: auto 1fr auto;
      align-items: center;
      gap: 10px;
      padding: 13px;
      margin-top: 13px;
      border: 1px solid #eccf8c;
      border-radius: 11px;
      background: #fff9e8;
      color: #8c671b;
    }
    &__private-warning strong,
    &__private-warning small {
      display: block;
    }
    &__private-warning strong {
      font-size: 0.84rem;
    }
    &__private-warning small {
      margin-top: 2px;
      color: #8d7a50;
      font-size: 0.82rem;
    }
    &__note {
      margin-top: 17px;
    }
    &__review > footer {
      display: flex;
      justify-content: flex-end;
      gap: 7px;
      padding-top: 18px;
      margin-top: auto;
      border-top: 1px solid var(--line);
    }
    &__empty {
      padding: 70px 30px;
      text-align: center;
    }
    &__empty > span {
      display: grid;
      place-items: center;
      width: 60px;
      height: 60px;
      margin: auto;
      border-radius: 18px;
      background: var(--mint);
      color: var(--color-brand);
      font-size: 1.5rem;
    }
    &__empty h2 {
      margin: 15px 0 4px;
      font-family: var(--font-display);
      font-size: 2rem;
    }
    &__empty p {
      margin: 0;
      color: var(--ink-soft);
      font-size: 0.82rem;
    }
    &__error {
      padding: 12px 14px;
      margin: 0;
      border: 1px solid #efb8b8;
      border-radius: 10px;
      background: #fff3f3;
      color: #8f2525;
      font-size: 0.84rem;
    }
    &__error button {
      padding: 0;
      border: 0;
      background: transparent;
      color: inherit;
      font: inherit;
      font-weight: 900;
      text-decoration: underline;
      cursor: pointer;
    }
  }
  @media (width <= 850px) {
    .moderation {
      &__workspace {
        grid-template-columns: 1fr;
      }
      &__list {
        max-height: 320px;
        border-right: 0;
        border-bottom: 1px solid var(--line);
      }
      &__toolbar {
        display: grid;
      }
      &__toolbar label {
        width: 100%;
      }
    }
  }
  @media (width <= 550px) {
    .moderation {
      &__review {
        padding: 17px;
      }
      &__review > footer {
        flex-wrap: wrap;
      }
      &__private-warning {
        grid-template-columns: auto 1fr;
      }
      &__private-warning > :last-child {
        grid-column: 2;
      }
    }
  }
}

@media (width <= 800px) {
  .admin-summary {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (width <= 500px) {
  .admin-summary {
    grid-template-columns: 1fr;
  }
}
</style>
