<script setup lang="ts">
import type { ModerationStatusFilter, ModerationTypeFilter } from "~/types";

defineProps<{
  typeFilter: ModerationTypeFilter;
  statusFilter: ModerationStatusFilter;
  search: string;
}>();
defineEmits<{
  type: [value: ModerationTypeFilter];
  status: [value: ModerationStatusFilter];
  search: [value: string];
}>();

const types: { value: ModerationTypeFilter; label: string }[] = [
  { value: "all", label: "Todos" },
  { value: "profile_revision", label: "Perfil" },
  { value: "profile_photo", label: "Foto" },
  { value: "portfolio_item", label: "Portfólio" },
  { value: "verification_request", label: "Verificação" },
];
</script>

<template>
  <div class="moderation__toolbar">
    <div class="moderation__filters" aria-label="Filtrar fila">
      <button
        v-for="type in types"
        :key="type.value"
        type="button"
        :class="{ active: typeFilter === type.value }"
        :aria-pressed="typeFilter === type.value"
        @click="$emit('type', type.value)"
      >
        {{ type.label }}
      </button>
    </div>
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
        <option value="hidden">Ocultos</option>
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
