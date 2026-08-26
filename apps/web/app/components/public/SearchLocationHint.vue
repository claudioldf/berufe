<script setup lang="ts">
import { computed, shallowRef } from "vue";
import type { SearchLocation, SearchLocationSource } from "~/types";

const props = defineProps<{
  location: SearchLocation;
  cities: SearchLocation[];
  source: SearchLocationSource;
}>();

const emit = defineEmits<{
  change: [location: SearchLocation];
}>();

const editing = shallowRef(false);
const locationId = computed(
  () => `${props.location.stateSlug}/${props.location.citySlug}`,
);
const prefix = computed(() =>
  props.source === "ip" ? "Localização aproximada" : "Buscando em",
);

function selectLocation(event: Event) {
  const value = (event.target as HTMLSelectElement).value;
  const location = props.cities.find(
    (candidate) => `${candidate.stateSlug}/${candidate.citySlug}` === value,
  );
  if (!location) return;

  emit("change", location);
  editing.value = false;
}
</script>

<template>
  <div class="search-location" aria-live="polite">
    <span class="search-location__current">
      <UIcon name="i-lucide-map-pin" aria-hidden="true" />
      {{ prefix }}
      <strong>{{ location.city }}, {{ location.stateCode }}</strong>
    </span>
    <button
      type="button"
      class="search-location__change"
      :aria-expanded="editing"
      @click="editing = !editing"
    >
      alterar cidade
    </button>
    <label v-if="editing" class="search-location__picker">
      <span>Escolha uma cidade atendida</span>
      <select :value="locationId" @change="selectLocation">
        <option
          v-for="city in cities"
          :key="`${city.stateSlug}/${city.citySlug}`"
          :value="`${city.stateSlug}/${city.citySlug}`"
        >
          {{ city.city }}, {{ city.stateCode }}
        </option>
      </select>
    </label>
  </div>
</template>

<style scoped lang="scss">
.search-location {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 5px 9px;
  padding: 8px 12px 0;
  color: var(--ink-soft);
  font-size: 0.78rem;
}

.search-location__current {
  display: inline-flex;
  align-items: center;
  gap: 5px;
}

.search-location__current > svg {
  color: var(--color-brand);
}

.search-location__current strong {
  color: var(--ink);
}

.search-location__change {
  padding: 0;
  border: 0;
  background: transparent;
  color: var(--color-brand);
  font: inherit;
  font-weight: 850;
  text-decoration: underline;
  text-underline-offset: 2px;
  cursor: pointer;
}

.search-location__change:focus-visible,
.search-location__picker select:focus-visible {
  outline: 2px solid var(--color-brand);
  outline-offset: 3px;
}

.search-location__picker {
  display: flex;
  flex-basis: 100%;
  align-items: center;
  gap: 8px;
  padding-bottom: 5px;
}

.search-location__picker span {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
  border: 0;
}

.search-location__picker select {
  max-width: 260px;
  padding: 7px 30px 7px 9px;
  border: 1px solid var(--line);
  border-radius: 9px;
  background: white;
  color: var(--ink);
  font: inherit;
  font-weight: 750;
}
</style>
