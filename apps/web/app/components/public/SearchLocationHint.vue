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

const open = shallowRef(false);
const prefix = computed(() =>
  props.source === "ip" ? "Localização aproximada" : "Buscando em",
);

function isCurrentLocation(candidate: SearchLocation) {
  return (
    candidate.stateSlug === props.location.stateSlug &&
    candidate.citySlug === props.location.citySlug
  );
}

function selectLocation(location: SearchLocation) {
  emit("change", location);
  open.value = false;
}
</script>

<template>
  <div class="search-location" aria-live="polite">
    <span class="search-location__current">
      <UIcon name="i-lucide-map-pin" aria-hidden="true" />
      {{ prefix }}
      <strong>{{ location.city }}, {{ location.stateCode }}</strong>
    </span>
    <UButton
      type="button"
      class="search-location__change"
      color="primary"
      variant="link"
      aria-haspopup="dialog"
      :aria-expanded="open"
      @click="open = true"
    >
      alterar cidade
    </UButton>

    <UModal
      v-model:open="open"
      title="Escolha sua cidade"
      description="Mostramos apenas cidades com profissionais disponíveis."
      :ui="{ content: 'sm:max-w-sm' }"
    >
      <template #body>
        <ul v-if="cities.length" class="search-location__options">
          <li
            v-for="city in cities"
            :key="`${city.stateSlug}/${city.citySlug}`"
          >
            <UButton
              type="button"
              class="search-location__option"
              :class="{
                'search-location__option--current': isCurrentLocation(city),
              }"
              color="neutral"
              variant="ghost"
              :aria-current="isCurrentLocation(city) ? 'location' : undefined"
              @click="selectLocation(city)"
            >
              <span class="search-location__option-icon" aria-hidden="true">
                <UIcon name="i-lucide-map-pin" />
              </span>
              <span class="search-location__option-label">
                <strong>{{ city.city }}</strong>
                <small>{{ city.stateCode }}</small>
              </span>
              <UIcon
                v-if="isCurrentLocation(city)"
                class="search-location__option-check"
                name="i-lucide-check"
                aria-hidden="true"
              />
            </UButton>
          </li>
        </ul>

        <div v-else class="search-location__empty" role="status">
          <span aria-hidden="true">
            <UIcon name="i-lucide-map-pin-off" />
          </span>
          <strong>Nenhuma cidade disponível</strong>
          <p>Nenhuma cidade com profissionais disponíveis no momento.</p>
        </div>
      </template>
    </UModal>
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
  min-height: auto;
  font: inherit;
  font-weight: 850;
  text-decoration: underline;
  text-underline-offset: 2px;
}

.search-location__change:focus-visible {
  outline: 2px solid var(--color-brand);
  outline-offset: 3px;
}

.search-location__options {
  display: grid;
  gap: 8px;
  max-height: min(55vh, 22rem);
  padding: 0 3px 0 0;
  margin: 0;
  overflow-y: auto;
  overscroll-behavior: contain;
  list-style: none;
}

.search-location__option {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr) auto;
  align-items: center;
  gap: 11px;
  width: 100%;
  min-height: 58px;
  padding: 9px 11px;
  border: 1px solid var(--line);
  border-radius: 13px;
  background: white;
  color: var(--ink);
  text-align: left;

  &:hover {
    border-color: #97c6b7;
    background: var(--mint);
  }

  &--current {
    border-color: #97c6b7;
    background: var(--mint);
    box-shadow: inset 0 0 0 1px rgb(30 105 83 / 8%);
  }
}

.search-location__option-icon,
.search-location__empty > span {
  display: grid;
  place-items: center;
  width: 36px;
  height: 36px;
  border-radius: 11px;
  background: rgb(30 105 83 / 10%);
  color: var(--color-brand);
  font-size: 1rem;
}

.search-location__option-label {
  display: flex;
  align-items: baseline;
  gap: 5px;
  min-width: 0;

  strong {
    overflow: hidden;
    font-size: 0.92rem;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  small {
    color: var(--ink-soft);
    font-size: 0.76rem;
    font-weight: 800;
  }
}

.search-location__option-check {
  color: var(--color-brand);
  font-size: 1rem;
}

.search-location__empty {
  display: grid;
  justify-items: center;
  gap: 8px;
  padding: 20px 12px 18px;
  color: var(--ink-soft);
  text-align: center;

  strong {
    color: var(--ink);
    font-size: 0.92rem;
  }

  p {
    max-width: 260px;
    margin: 0;
    font-size: 0.82rem;
    line-height: 1.5;
  }
}
</style>
