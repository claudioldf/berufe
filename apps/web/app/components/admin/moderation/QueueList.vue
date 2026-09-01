<script setup lang="ts">
import type { ModerationQueueItem } from "~/types";

defineProps<{
  items: readonly ModerationQueueItem[];
  selectedId?: string;
  page: number;
  totalPages: number;
  loading?: boolean;
}>();
defineEmits<{ select: [id: string]; page: [page: number] }>();
</script>

<template>
  <section class="moderation__list" aria-label="Fila de moderação">
    <button
      v-for="item in items"
      :key="item.id"
      type="button"
      :class="{ active: selectedId === item.id }"
      :aria-current="selectedId === item.id ? 'true' : undefined"
      @click="$emit('select', item.id)"
    >
      <span class="moderation__type-icon">
        <UIcon name="i-lucide-shield-check" />
      </span>
      <span>
        <em>{{ item.type }}</em>
        <strong>{{ item.title }}</strong>
        <small>{{ item.subtitle }}</small>
      </span>
      <span class="moderation__age">{{ item.age }}</span>
    </button>
    <div v-if="loading && !items.length" class="moderation__filtered-empty">
      Carregando fila…
    </div>
    <div v-else-if="!items.length" class="moderation__filtered-empty">
      Nenhum item corresponde aos filtros.
    </div>
    <nav
      v-if="totalPages > 1"
      class="moderation__pagination"
      aria-label="Paginação da fila"
    >
      <DesignSystemDisabledTooltip
        :reason="page <= 1 ? null : loading ? 'Carregando a fila…' : null"
      >
        <button
          type="button"
          :disabled="page <= 1 || loading"
          aria-label="Página anterior"
          @click="$emit('page', page - 1)"
        >
          <UIcon name="i-lucide-chevron-left" />
        </button>
      </DesignSystemDisabledTooltip>
      <span>Página {{ page }} de {{ totalPages }}</span>
      <DesignSystemDisabledTooltip
        :reason="
          page >= totalPages ? null : loading ? 'Carregando a fila…' : null
        "
      >
        <button
          type="button"
          :disabled="page >= totalPages || loading"
          aria-label="Próxima página"
          @click="$emit('page', page + 1)"
        >
          <UIcon name="i-lucide-chevron-right" />
        </button>
      </DesignSystemDisabledTooltip>
    </nav>
  </section>
</template>
