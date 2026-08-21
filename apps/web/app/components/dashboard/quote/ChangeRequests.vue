<script setup lang="ts">
import type { QuoteChangeRequest } from "~/types";
import { formatDateTime } from "~/utils/formatters";

defineProps<{ requests: QuoteChangeRequest[] }>();
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="quote-change-requests">
    <header>
      <span class="quote-change-requests__icon" aria-hidden="true">
        <UIcon name="i-lucide-message-square-warning" />
      </span>
      <div>
        <h2>Pedidos de alterações</h2>
        <p>Histórico dos comentários enviados pelo cliente.</p>
      </div>
    </header>
    <ol>
      <li v-for="request in requests" :key="request.id">
        <time :datetime="request.requestedAt">
          {{ formatDateTime(request.requestedAt) }}
        </time>
        <p>{{ request.message }}</p>
      </li>
    </ol>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.quote-change-requests {
  padding: 22px;
  border-color: color-mix(in srgb, var(--color-warning) 34%, var(--line));

  header {
    display: flex;
    align-items: center;
    gap: 11px;
    padding-bottom: 17px;
    margin-bottom: 4px;
    border-bottom: 1px solid var(--line);
  }

  &__icon {
    display: grid;
    flex: 0 0 auto;
    place-items: center;
    width: 32px;
    height: 32px;
    border-radius: 9px;
    background: color-mix(in srgb, var(--color-warning) 14%, white);
    color: var(--color-warning);
  }

  h2,
  header p,
  li p {
    margin: 0;
  }

  h2 {
    font-family: var(--font-display);
    font-size: 1.25rem;
    text-wrap: balance;
  }

  header p {
    margin-top: 3px;
    color: var(--ink-soft);
    font-size: 0.84rem;
  }

  ol {
    padding: 0;
    margin: 0;
    list-style: none;
  }

  li {
    padding: 14px 0;
    border-bottom: 1px solid var(--line);
  }

  li:last-child {
    padding-bottom: 0;
    border-bottom: 0;
  }

  time {
    display: block;
    margin-bottom: 5px;
    color: var(--ink-soft);
    font-size: 0.76rem;
    font-weight: 800;
  }

  li p {
    overflow-wrap: anywhere;
    color: var(--ink);
    font-size: 0.9rem;
    line-height: 1.55;
  }
}
</style>
