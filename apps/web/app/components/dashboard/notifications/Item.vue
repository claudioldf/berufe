<script setup lang="ts">
import { computed } from "vue";
import type { ProfessionalNotification } from "~/types";
import { formatDateTime } from "~/utils/formatters";

const props = defineProps<{
  notification: ProfessionalNotification;
  reading?: boolean;
}>();
const emit = defineEmits<{
  read: [notification: ProfessionalNotification];
  select: [notification: ProfessionalNotification];
}>();

const icon = computed(() => {
  const type = props.notification.notificationType;
  if (type.startsWith("relationship_")) return "i-lucide-handshake";
  if (type.startsWith("quote_")) return "i-lucide-file-text";
  if (type.startsWith("service_completion_")) {
    return "i-lucide-briefcase-business";
  }
  if (type === "customer_recommendation_published") {
    return "i-lucide-message-square-heart";
  }
  if (type.endsWith("_rejected") || type.endsWith("_hidden")) {
    return "i-lucide-circle-alert";
  }
  return "i-lucide-circle-check";
});
</script>

<template>
  <article class="notification-item">
    <NuxtLink
      class="notification-item__link"
      :to="notification.route"
      @click="emit('select', notification)"
    >
      <span class="notification-item__icon">
        <UIcon :name="icon" aria-hidden="true" />
      </span>
      <span class="notification-item__copy">
        <strong>{{ notification.title }}</strong>
        <span>{{ notification.description }}</span>
        <time :datetime="notification.occurredAt">
          {{ formatDateTime(notification.occurredAt) }}
        </time>
      </span>
    </NuxtLink>
    <button
      type="button"
      class="notification-item__read"
      :disabled="reading"
      :aria-label="`Marcar como lida: ${notification.title}`"
      @click="emit('read', notification)"
    >
      <UIcon
        :name="reading ? 'i-lucide-loader-circle' : 'i-lucide-check'"
        :class="{ 'notification-item__spinner': reading }"
        aria-hidden="true"
      />
    </button>
  </article>
</template>

<style scoped lang="scss">
.notification-item {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: start;
  gap: 8px;
  padding: 14px 16px;
  border-bottom: 1px solid rgb(23 53 47 / 10%);
  background: white;
  color: var(--color-brand-strong);

  &__link {
    display: grid;
    grid-template-columns: auto minmax(0, 1fr);
    gap: 11px;
    color: inherit;
    text-decoration: none;
  }

  &__link:hover strong {
    text-decoration: underline;
    text-decoration-color: var(--coral);
    text-underline-offset: 3px;
  }

  &__link:focus-visible,
  &__read:focus-visible {
    outline: 3px solid rgb(248 117 93 / 32%);
    outline-offset: 2px;
  }

  &__icon {
    display: grid;
    place-items: center;
    width: 34px;
    height: 34px;
    border-radius: 10px;
    background: var(--color-brand-tint);
    color: var(--color-success);
    font-size: 1rem;
  }

  &__copy,
  &__copy > span,
  &__copy strong,
  &__copy time {
    display: block;
  }

  &__copy strong {
    font-size: 0.88rem;
    line-height: 1.3;
  }

  &__copy > span {
    margin-top: 3px;
    color: var(--color-text-muted);
    font-size: 0.8rem;
    line-height: 1.4;
  }

  &__copy time {
    margin-top: 6px;
    color: #687a76;
    font-size: 0.7rem;
    font-weight: 650;
  }

  &__read {
    display: grid;
    place-items: center;
    width: 32px;
    height: 32px;
    padding: 0;
    border: 1px solid rgb(23 53 47 / 14%);
    border-radius: 9px;
    background: transparent;
    color: #5b706b;
    cursor: pointer;
  }

  &__read:hover:not(:disabled) {
    border-color: var(--color-success);
    color: var(--color-success);
  }

  &__read:disabled {
    cursor: wait;
    opacity: 0.7;
  }

  &__spinner {
    animation: notification-spin 0.8s linear infinite;
  }
}

@keyframes notification-spin {
  to {
    transform: rotate(1turn);
  }
}
</style>
