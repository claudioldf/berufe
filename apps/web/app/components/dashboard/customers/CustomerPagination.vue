<script setup lang="ts">
defineProps<{
  page: number;
  totalPages: number;
  loading?: boolean;
}>();

defineEmits<{
  page: [value: number];
}>();
</script>

<template>
  <nav
    v-if="totalPages > 1"
    class="customer-pagination"
    aria-label="Paginação dos clientes"
  >
    <button
      type="button"
      :disabled="page <= 1 || loading"
      aria-label="Página anterior"
      @click="$emit('page', page - 1)"
    >
      <UIcon name="i-lucide-chevron-left" aria-hidden="true" />
    </button>
    <span>Página {{ page }} de {{ totalPages }}</span>
    <button
      type="button"
      :disabled="page >= totalPages || loading"
      aria-label="Próxima página"
      @click="$emit('page', page + 1)"
    >
      <UIcon name="i-lucide-chevron-right" aria-hidden="true" />
    </button>
  </nav>
</template>

<style scoped lang="scss">
.customer-pagination {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  color: var(--ink-soft);
  font-size: 0.82rem;

  & span {
    min-width: 110px;
    text-align: center;
  }

  & button {
    display: grid;
    place-items: center;
    width: 36px;
    height: 36px;
    border: 1px solid var(--line);
    border-radius: 10px;
    background: var(--paper);
    color: var(--color-brand);
    cursor: pointer;
  }

  & button:hover:not(:disabled) {
    background: var(--color-surface-hover);
  }

  & button:disabled {
    cursor: not-allowed;
    opacity: 0.45;
  }
}
</style>
