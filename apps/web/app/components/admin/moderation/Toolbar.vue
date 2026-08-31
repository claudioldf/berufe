<script setup lang="ts">
import type { ModerationStatusFilter } from "~/types";

defineProps<{
  statusFilter: ModerationStatusFilter;
  search: string;
}>();
defineEmits<{
  status: [value: ModerationStatusFilter];
  search: [value: string];
}>();
</script>

<template>
  <div class="moderation__toolbar">
    <label class="moderation__status" for="moderation-status">
      <span class="sr-only">Filtrar por status</span>
      <select
        id="moderation-status"
        :value="statusFilter"
        name="moderation-status"
        @change="
          $emit(
            'status',
            ($event.target as HTMLSelectElement)
              .value as ModerationStatusFilter,
          )
        "
      >
        <option value="pending_review">Aguardando análise</option>
        <option value="approved">Aprovados</option>
        <option value="rejected">Rejeitados</option>
        <option value="all">Todos os status</option>
      </select>
    </label>
    <label for="moderation-search">
      <UIcon name="i-lucide-search" />
      <span class="sr-only">Buscar na fila</span>
      <input
        id="moderation-search"
        :value="search"
        name="moderation-search"
        type="search"
        autocomplete="off"
        maxlength="100"
        placeholder="Buscar na fila…"
        @input="$emit('search', ($event.target as HTMLInputElement).value)"
      />
    </label>
  </div>
</template>
