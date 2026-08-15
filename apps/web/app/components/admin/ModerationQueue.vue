<script setup lang="ts">
import moderationData from "@data/moderation.json";
import type { ModerationDecision, ModerationQueueItem } from "~/types";
import { useModerationQueue } from "~/composables/useModerationQueue";
import { useToast } from "~/composables/useToast";

const { showToast } = useToast();
const {
  queue,
  selectedId,
  typeFilter,
  searchQuery,
  rejectionOpen,
  rejectionReason,
  types,
  filteredQueue,
  selected,
  select,
  decide: recordDecision,
} = useModerationQueue(moderationData.queue as ModerationQueueItem[]);

function decide(action: ModerationDecision) {
  const item = recordDecision();
  if (!item) return;
  showToast({
    title: action === "approved" ? "Item aprovado" : "Item rejeitado",
    description: `A decisão sobre “${item.title}” foi registrada na auditoria.`,
  });
}
</script>

<template>
  <div class="moderation">
    <AdminModerationToolbar
      v-model:filter="typeFilter"
      v-model:search="searchQuery"
      :types="types"
    />

    <div v-if="queue.length" class="moderation__workspace">
      <AdminModerationQueueList
        :items="filteredQueue"
        :selected-id="selectedId"
        @select="select"
      />
      <AdminModerationReviewPanel
        v-if="selected"
        :item="selected"
        @approve="decide('approved')"
        @reject="rejectionOpen = true"
      />
    </div>

    <DesignSystemSurfaceCard v-else class="moderation__empty"
      ><span><UIcon name="i-lucide-party-popper" /></span>
      <h2>Fila em dia.</h2>
      <p>
        Todos os itens pendentes foram analisados nesta sessão do protótipo.
      </p></DesignSystemSurfaceCard
    >

    <AdminModerationRejectionDialog
      v-model:open="rejectionOpen"
      v-model:reason="rejectionReason"
      @confirm="decide('rejected')"
    />
  </div>
</template>

<style scoped lang="scss">
.moderation {
  display: grid;
  gap: 14px;
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
</style>
