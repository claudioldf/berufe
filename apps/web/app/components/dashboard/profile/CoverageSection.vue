<script setup lang="ts">
import type { Neighborhood, ProfessionalProfileDraft } from "~/types";

const form = defineModel<ProfessionalProfileDraft>({ required: true });
defineProps<{ neighborhoods: Neighborhood[] }>();
defineEmits<{ dirty: []; toggle: [name: string] }>();
</script>

<template>
  <section class="editor-section">
    <header>
      <div>
        <span>04</span>
        <div>
          <h2>Área de atendimento</h2>
          <p>O Finder usa essas escolhas para mostrar seu perfil.</p>
        </div>
      </div>
      <em>Joinville</em>
    </header>
    <label class="all-city">
      <input
        v-model="form.allJoinville"
        name="all-joinville"
        type="checkbox"
        @change="$emit('dirty')"
      />
      <span>
        <strong>Atendo em toda Joinville</strong>
        <small>Seu perfil poderá aparecer em buscas de qualquer bairro.</small>
      </span>
      <UIcon name="i-lucide-map" />
    </label>
    <div v-if="!form.allJoinville" class="neighborhood-picker">
      <button
        v-for="item in neighborhoods"
        :key="item.code"
        type="button"
        :class="{ selected: form.selectedNeighborhoods.includes(item.name) }"
        :aria-pressed="form.selectedNeighborhoods.includes(item.name)"
        @click="$emit('toggle', item.name)"
      >
        <UIcon
          :name="
            form.selectedNeighborhoods.includes(item.name)
              ? 'i-lucide-check'
              : 'i-lucide-plus'
          "
        />
        {{ item.name }}
      </button>
    </div>
  </section>
</template>
