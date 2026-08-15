<script setup lang="ts">
import type { ModerationQueueItem } from "~/types";

defineProps<{
  items: ModerationQueueItem[];
  selectedId?: string;
}>();
defineEmits<{ select: [id: string] }>();

function itemIcon(item: ModerationQueueItem) {
  if (item.type === "Perfil") return "i-lucide-user-round";
  if (item.type === "Verificação") return "i-lucide-shield-check";
  if (item.type === "Portfólio") return "i-lucide-image";
  return "i-lucide-handshake";
}
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
        <UIcon :name="itemIcon(item)" />
      </span>
      <span>
        <em>{{ item.type }}</em>
        <strong>{{ item.title }}</strong>
        <small>{{ item.subtitle }}</small>
      </span>
      <span class="moderation__age">{{ item.age }}</span>
    </button>
    <div v-if="!items.length" class="moderation__filtered-empty">
      Nenhum item corresponde aos filtros.
    </div>
  </section>
</template>
