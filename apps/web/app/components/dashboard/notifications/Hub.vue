<script setup lang="ts">
import { computed, shallowRef } from "vue";
import { useProfessionalNotifications } from "~/composables/useProfessionalNotifications";
import type { ProfessionalNotification } from "~/types";

const open = shallowRef(false);
const {
  notifications,
  unreadCount,
  loadError,
  mutationError,
  isInitialLoading,
  isRefreshing,
  isLoadingMore,
  readingIds,
  isReadingAll,
  hasMore,
  refresh,
  loadMore,
  markRead,
  markAllRead,
} = useProfessionalNotifications();
const readingAllReason = computed(() =>
  isReadingAll.value
    ? "Aguarde todas as notificações serem marcadas como lidas."
    : null,
);
const loadingMoreReason = computed(() =>
  isLoadingMore.value
    ? "Aguarde o carregamento das próximas notificações."
    : null,
);

function handleOpen(value: boolean) {
  open.value = value;
  if (value) void refresh();
}

function handleSelect(notification: ProfessionalNotification) {
  open.value = false;
  void markRead(notification.id);
}
</script>

<template>
  <UPopover
    :open="open"
    :modal="true"
    :content="{
      side: 'bottom',
      align: 'end',
      sideOffset: 10,
      collisionPadding: 12,
    }"
    @update:open="handleOpen"
  >
    <button
      type="button"
      class="notification-hub__trigger"
      :aria-label="
        unreadCount === 1
          ? 'Notificações: 1 não lida'
          : `Notificações: ${unreadCount} não lidas`
      "
    >
      <UIcon name="i-lucide-bell" aria-hidden="true" />
      <span
        v-if="unreadCount > 0"
        class="notification-hub__badge"
        aria-hidden="true"
      >
        {{ unreadCount > 99 ? "99+" : unreadCount }}
      </span>
    </button>

    <template #content>
      <section
        class="notification-hub__panel"
        role="dialog"
        aria-modal="true"
        aria-labelledby="notification-hub-title"
      >
        <header class="notification-hub__header">
          <div>
            <span>Central</span>
            <h2 id="notification-hub-title">Notificações</h2>
          </div>
          <button
            type="button"
            class="notification-hub__close"
            aria-label="Fechar notificações"
            @click="open = false"
          >
            <UIcon name="i-lucide-x" aria-hidden="true" />
          </button>
        </header>

        <div class="notification-hub__toolbar">
          <span>
            {{ unreadCount }} {{ unreadCount === 1 ? "não lida" : "não lidas" }}
          </span>
          <DesignSystemDisabledTooltip
            v-if="unreadCount > 0"
            :reason="readingAllReason"
          >
            <button type="button" :disabled="isReadingAll" @click="markAllRead">
              {{ isReadingAll ? "Marcando…" : "Marcar todas como lidas" }}
            </button>
          </DesignSystemDisabledTooltip>
        </div>

        <p
          v-if="loadError || mutationError"
          class="notification-hub__error"
          role="status"
        >
          {{ mutationError || loadError }}
        </p>

        <div v-if="isInitialLoading" class="notification-hub__state">
          <UIcon
            class="notification-hub__spinner"
            name="i-lucide-loader-circle"
            aria-hidden="true"
          />
          <span>Atualizando notificações…</span>
        </div>
        <div
          v-else-if="notifications.length === 0"
          class="notification-hub__state"
        >
          <UIcon name="i-lucide-bell-ring" aria-hidden="true" />
          <strong>Você está em dia</strong>
          <span>Novas atividades aparecerão aqui.</span>
        </div>
        <div v-else class="notification-hub__list" aria-live="polite">
          <DashboardNotificationsItem
            v-for="notification in notifications"
            :key="notification.id"
            :notification="notification"
            :reading="readingIds.includes(notification.id)"
            @read="markRead(notification.id)"
            @select="handleSelect"
          />
        </div>

        <footer v-if="hasMore" class="notification-hub__footer">
          <DesignSystemDisabledTooltip :reason="loadingMoreReason">
            <button type="button" :disabled="isLoadingMore" @click="loadMore">
              {{ isLoadingMore ? "Carregando…" : "Carregar mais" }}
            </button>
          </DesignSystemDisabledTooltip>
        </footer>
        <span v-else-if="isRefreshing && !isInitialLoading" class="sr-only">
          Atualizando notificações
        </span>
      </section>
    </template>
  </UPopover>
</template>

<style scoped lang="scss">
.notification-hub {
  &__trigger {
    position: relative;
    display: grid;
    place-items: center;
    width: 42px;
    height: 42px;
    padding: 0;
    border: 1px solid rgb(255 255 255 / 28%);
    border-radius: 12px;
    background: rgb(255 255 255 / 8%);
    color: white;
    cursor: pointer;
    font-size: 1.1rem;
  }

  &__trigger:hover {
    background: rgb(255 255 255 / 16%);
  }

  &__trigger:focus-visible,
  &__close:focus-visible,
  &__toolbar button:focus-visible,
  &__footer button:focus-visible {
    outline: 3px solid rgb(248 117 93 / 42%);
    outline-offset: 2px;
  }

  &__badge {
    position: absolute;
    top: -5px;
    right: -6px;
    min-width: 20px;
    height: 20px;
    padding: 0 5px;
    border: 2px solid var(--color-brand-strong);
    border-radius: 99px;
    background: var(--coral);
    color: white;
    font-size: 0.62rem;
    font-weight: 850;
    line-height: 16px;
    text-align: center;
  }

  &__panel {
    display: flex;
    flex-direction: column;
    width: min(420px, calc(100vw - 24px));
    max-height: min(620px, calc(100dvh - 96px));
    overflow: hidden;
    color: var(--color-brand-strong);
  }

  &__header {
    display: flex;
    flex: 0 0 auto;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    padding: 16px;
    border-bottom: 1px solid rgb(23 53 47 / 12%);
  }

  &__header span {
    display: block;
    color: var(--color-success);
    font-size: 0.68rem;
    font-weight: 800;
    letter-spacing: 0.08em;
    text-transform: uppercase;
  }

  &__header h2 {
    margin: 1px 0 0;
    font-size: 1.1rem;
    line-height: 1.2;
  }

  &__close {
    display: grid;
    place-items: center;
    width: 36px;
    height: 36px;
    padding: 0;
    border: 0;
    border-radius: 10px;
    background: var(--color-brand-tint);
    color: inherit;
    cursor: pointer;
  }

  &__toolbar {
    display: flex;
    flex: 0 0 auto;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    min-height: 44px;
    padding: 8px 16px;
    background: #f7f8f5;
    color: var(--color-text-muted);
    font-size: 0.75rem;
    font-weight: 650;
  }

  &__toolbar button,
  &__footer button {
    padding: 0;
    border: 0;
    background: transparent;
    color: var(--color-success);
    cursor: pointer;
    font: inherit;
    font-weight: 800;
  }

  &__toolbar button:disabled,
  &__footer button:disabled {
    cursor: wait;
    opacity: 0.6;
  }

  &__error {
    flex: 0 0 auto;
    margin: 0;
    padding: 9px 16px;
    border-bottom: 1px solid rgb(183 62 52 / 18%);
    background: #fff2ef;
    color: #9c352e;
    font-size: 0.76rem;
  }

  &__list {
    min-height: 0;
    overflow-y: auto;
    overscroll-behavior: contain;
  }

  &__state {
    display: grid;
    flex: 1 1 auto;
    place-items: center;
    align-content: center;
    gap: 7px;
    min-height: 220px;
    padding: 32px 20px;
    color: var(--color-text-muted);
    text-align: center;
  }

  &__state > .iconify {
    color: var(--color-success);
    font-size: 1.6rem;
  }

  &__state strong {
    color: var(--color-brand-strong);
  }

  &__state span {
    font-size: 0.82rem;
  }

  &__footer {
    flex: 0 0 auto;
    padding: 13px 16px;
    border-top: 1px solid rgb(23 53 47 / 12%);
    text-align: center;
  }

  &__spinner {
    animation: notification-hub-spin 0.8s linear infinite;
  }
}

@keyframes notification-hub-spin {
  to {
    transform: rotate(1turn);
  }
}

@media (width <= 520px) {
  .notification-hub {
    &__panel {
      width: calc(100vw - 16px);
      max-height: calc(100dvh - 82px);
    }
  }
}
</style>
