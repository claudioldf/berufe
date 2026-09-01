<script setup lang="ts">
const props = defineProps<{
  page: number;
  totalPages: number;
  loading?: boolean;
}>();
defineEmits<{
  page: [value: number];
}>();

const previousBlockedReason = computed(() => {
  if (props.loading) return "Aguarde o carregamento dos orçamentos terminar.";
  if (props.page <= 1) return "Você já está na primeira página.";
  return null;
});
const nextBlockedReason = computed(() => {
  if (props.loading) return "Aguarde o carregamento dos orçamentos terminar.";
  if (props.page >= props.totalPages) return "Você já está na última página.";
  return null;
});
</script>

<template>
  <nav
    v-if="totalPages > 1"
    class="quote-pagination"
    aria-label="Paginação dos orçamentos"
  >
    <DesignSystemDisabledTooltip :reason="previousBlockedReason">
      <button
        type="button"
        class="quote-pagination__button"
        :disabled="page <= 1 || loading"
        aria-label="Página anterior"
        @click="$emit('page', page - 1)"
      >
        <UIcon name="i-lucide-chevron-left" aria-hidden="true" />
      </button>
    </DesignSystemDisabledTooltip>
    <span class="quote-pagination__label"
      >Página {{ page }} de {{ totalPages }}</span
    >
    <DesignSystemDisabledTooltip :reason="nextBlockedReason">
      <button
        type="button"
        class="quote-pagination__button"
        :disabled="page >= totalPages || loading"
        aria-label="Próxima página"
        @click="$emit('page', page + 1)"
      >
        <UIcon name="i-lucide-chevron-right" aria-hidden="true" />
      </button>
    </DesignSystemDisabledTooltip>
  </nav>
</template>

<style scoped lang="scss">
.quote-pagination {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  color: var(--ink-soft);
  font-size: 0.82rem;

  &__label {
    min-width: 110px;
    text-align: center;
  }

  &__button {
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

  &__button:hover:not(:disabled) {
    background: var(--color-surface-hover);
  }

  &__button:focus-visible {
    outline: 0;
    box-shadow: var(--focus-ring);
  }

  &__button:disabled {
    cursor: not-allowed;
    opacity: 0.45;
  }
}
</style>
