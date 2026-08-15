<script setup lang="ts">
const filter = defineModel<string>("filter", { required: true });
const search = defineModel<string>("search", { required: true });
defineProps<{ types: string[] }>();
</script>

<template>
  <div class="moderation__toolbar">
    <div class="moderation__filters" aria-label="Filtrar fila">
      <button
        v-for="type in types"
        :key="type"
        type="button"
        :class="{ active: filter === type }"
        :aria-pressed="filter === type"
        @click="filter = type"
      >
        {{ type }}
      </button>
    </div>
    <label for="moderation-search">
      <UIcon name="i-lucide-search" />
      <span class="sr-only">Buscar na fila</span>
      <input
        id="moderation-search"
        v-model="search"
        name="moderation-search"
        type="search"
        autocomplete="off"
        placeholder="Buscar na fila…"
      />
    </label>
  </div>
</template>
