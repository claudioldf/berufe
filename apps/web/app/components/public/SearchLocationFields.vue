<script setup lang="ts">
import { computed, shallowRef, watch } from "vue";
import type { SearchLocation, SearchLocationSource } from "~/types";

const props = defineProps<{
  location: SearchLocation;
  cities: SearchLocation[];
  source: SearchLocationSource;
}>();

const emit = defineEmits<{
  change: [location: SearchLocation];
}>();

// Matches the empty-results card: soft mint accents, rounded corners, and
// bold ink text, so the dropdowns read as part of the same visual system.
const dropdownUi = {
  base: "h-10 w-full rounded-[11px] border border-[var(--line)] bg-white px-3 text-[0.86rem] font-extrabold text-[var(--ink)] shadow-none ring-0 transition hover:border-[#97c6b7] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-brand)]",
  value: "font-extrabold text-[var(--ink)]",
  placeholder: "font-bold text-[var(--ink-soft)]",
  content:
    "rounded-[14px] border border-[var(--line)] bg-white p-1.5 shadow-[0_18px_40px_rgb(23_53_47/14%)] ring-0",
  item: "rounded-[10px] px-2.5 py-2 text-[0.86rem] font-bold text-[var(--ink)] data-highlighted:bg-[var(--mint)] data-highlighted:text-[var(--ink)]",
  itemLabel: "font-bold",
};

// The state drives which cities are listed. A city is always required, so
// picking a state applies its first city straight away.
const stateCode = shallowRef(props.location.stateCode);
watch(
  () => props.location.stateCode,
  (next) => {
    stateCode.value = next;
  },
);

function selectState(next: string) {
  stateCode.value = next;
  const first = cityItems.value[0];
  if (first) emit("change", first);
}

const states = computed(() =>
  [...new Set(props.cities.map((city) => city.stateCode))].sort(),
);
const cityItems = computed(() =>
  props.cities.filter((city) => city.stateCode === stateCode.value),
);

const citySlug = computed<string | undefined>({
  get: () =>
    stateCode.value === props.location.stateCode
      ? props.location.citySlug
      : undefined,
  set: (slug) => {
    const next = cityItems.value.find((city) => city.citySlug === slug);
    if (next) emit("change", next);
  },
});
</script>

<template>
  <div class="search-location-fields">
    <div class="search-location-fields__grid">
      <label class="search-location-fields__field">
        <span>Estado</span>
        <USelect
          :model-value="stateCode"
          class="search-location-fields__control"
          @update:model-value="selectState"
          :items="states"
          size="sm"
          :ui="dropdownUi"
        />
      </label>

      <label class="search-location-fields__field">
        <span>Cidade</span>
        <USelectMenu
          v-model="citySlug"
          class="search-location-fields__control"
          :items="cityItems"
          value-key="citySlug"
          label-key="city"
          size="sm"
          :search-input="{ placeholder: 'Buscar cidade' }"
          :disabled="!cityItems.length"
          :ui="dropdownUi"
        />
      </label>

      <slot name="action" :complete="citySlug !== undefined" />
    </div>
  </div>
</template>

<style scoped lang="scss">
.search-location-fields {
  display: grid;
  gap: 8px;
  margin-top: 9px;
  padding-top: 10px;
  border-top: 1px solid rgb(23 53 47 / 10%);
  color: var(--ink-soft);
  font-size: 0.78rem;
}

// State, city and the submit button share one row; the button lines up with
// the bottom edge of the dropdowns rather than the labels above them.
.search-location-fields__grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1.6fr) auto;
  align-items: end;
  gap: 8px;
}

.search-location-fields__field {
  display: grid;
  gap: 4px;
  min-width: 0;

  > span {
    padding-inline: 3px;
    font-size: 0.7rem;
    line-height: 1rem;
    font-weight: 800;
    letter-spacing: 0.06em;
    text-transform: uppercase;
  }
}

.search-location-fields__control {
  width: 100%;
  min-width: 0;
}
</style>
