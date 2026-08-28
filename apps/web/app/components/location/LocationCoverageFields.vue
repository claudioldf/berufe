<script setup lang="ts">
import { computed, onMounted, shallowRef } from "vue";
import type { LocationCoverageDraft } from "~/types";
import { useLocations } from "~/composables/useLocations";

const model = defineModel<LocationCoverageDraft>({ required: true });
const emit = defineEmits<{ dirty: [] }>();
const selectedStateCode = shallowRef("");
const {
  states,
  cities,
  neighborhoods,
  loading,
  error,
  loadCities,
  loadNeighborhoods,
  initialize,
} = useLocations();

const selectedCity = computed(() =>
  cities.value.find((city) => city.code === model.value.cityCode),
);

onMounted(async () => {
  const selected = await initialize(model.value.cityCode);
  selectedStateCode.value = selected?.state.code ?? "";
  if (selected && neighborhoods.value.length === 0) setWholeCity(true);
});

async function changeState(event: Event) {
  const stateCode = (event.target as HTMLSelectElement).value;
  selectedStateCode.value = stateCode;
  model.value = { cityCode: "", wholeCity: false, neighborhoodCodes: [] };
  const state = states.value.find((candidate) => candidate.code === stateCode);
  if (state) await loadCities(state.abbreviation);
  emit("dirty");
}

async function changeCity(event: Event) {
  const cityCode = (event.target as HTMLSelectElement).value;
  model.value = { cityCode, wholeCity: false, neighborhoodCodes: [] };
  if (cityCode) {
    const loaded = await loadNeighborhoods(cityCode);
    if (loaded.length === 0) setWholeCity(true);
  }
  emit("dirty");
}

function setWholeCity(wholeCity: boolean) {
  model.value = {
    ...model.value,
    wholeCity,
    neighborhoodCodes: wholeCity ? [] : model.value.neighborhoodCodes,
  };
  emit("dirty");
}

function changeWholeCity(event: Event) {
  setWholeCity((event.target as HTMLInputElement).checked);
}

function toggleNeighborhood(code: string) {
  const selected = model.value.neighborhoodCodes.includes(code);
  model.value = {
    ...model.value,
    neighborhoodCodes: selected
      ? model.value.neighborhoodCodes.filter((item) => item !== code)
      : [...model.value.neighborhoodCodes, code],
  };
  emit("dirty");
}
</script>

<template>
  <div class="location-coverage-fields">
    <div class="location-coverage-fields__selectors">
      <DesignSystemFormField id="coverage-state" label="Estado" required>
        <select
          id="coverage-state"
          :value="selectedStateCode"
          name="coverage-state"
          required
          :disabled="loading"
          @change="changeState"
        >
          <option value="">Selecione</option>
          <option v-for="state in states" :key="state.code" :value="state.code">
            {{ state.name }} ({{ state.abbreviation }})
          </option>
        </select>
      </DesignSystemFormField>
      <DesignSystemFormField id="coverage-city" label="Cidade" required>
        <select
          id="coverage-city"
          :value="model.cityCode"
          name="coverage-city"
          required
          :disabled="loading || !selectedStateCode"
          @change="changeCity"
        >
          <option value="">Selecione</option>
          <option v-for="city in cities" :key="city.code" :value="city.code">
            {{ city.name }}
          </option>
        </select>
      </DesignSystemFormField>
    </div>

    <p v-if="error" class="location-coverage-fields__error" role="alert">
      {{ error }}
    </p>

    <label v-if="selectedCity" class="location-coverage-fields__whole-city">
      <input
        :checked="model.wholeCity"
        name="whole-city"
        type="checkbox"
        @change="changeWholeCity"
      />
      <span>
        <strong>Atendo em toda {{ selectedCity.name }}</strong>
        <small>Seu perfil poderá aparecer em buscas de qualquer bairro.</small>
      </span>
      <UIcon name="i-lucide-map" />
    </label>

    <p
      v-if="selectedCity && neighborhoods.length === 0"
      class="location-coverage-fields__empty"
    >
      O IBGE não publicou bairros oficiais para esta cidade. A cobertura será
      cadastrada para a cidade inteira.
    </p>

    <div
      v-else-if="selectedCity && !model.wholeCity"
      class="location-coverage-fields__neighborhoods"
    >
      <button
        v-for="neighborhood in neighborhoods"
        :key="neighborhood.code"
        type="button"
        :class="{
          selected: model.neighborhoodCodes.includes(neighborhood.code),
        }"
        :aria-pressed="model.neighborhoodCodes.includes(neighborhood.code)"
        @click="toggleNeighborhood(neighborhood.code)"
      >
        <UIcon
          :name="
            model.neighborhoodCodes.includes(neighborhood.code)
              ? 'i-lucide-check'
              : 'i-lucide-plus'
          "
        />
        {{ neighborhood.name }}
      </button>
    </div>
  </div>
</template>

<style scoped lang="scss">
.location-coverage-fields {
  display: grid;
  gap: 14px;

  &__selectors {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 12px;
  }

  &__selectors select {
    width: 100%;
    min-height: 44px;
    padding: 0 12px;
    border: 1px solid var(--line);
    border-radius: 10px;
    background: white;
    color: var(--ink);
  }

  &__whole-city {
    display: grid;
    grid-template-columns: auto 1fr auto;
    align-items: center;
    gap: 12px;
    padding: 14px;
    border: 1px solid var(--line);
    border-radius: 12px;
    cursor: pointer;
  }

  &__whole-city strong,
  &__whole-city small {
    display: block;
  }

  &__whole-city small,
  &__empty {
    color: var(--ink-soft);
  }

  &__neighborhoods {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
  }

  &__neighborhoods button {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    padding: 8px 10px;
    border: 1px solid var(--line);
    border-radius: 999px;
    background: white;
    color: var(--ink);
    cursor: pointer;
  }

  &__neighborhoods button.selected {
    border-color: var(--color-brand);
    background: var(--mint);
    color: var(--color-brand-strong);
  }

  &__error {
    color: var(--color-error);
  }
}

@media (width <= 620px) {
  .location-coverage-fields__selectors {
    grid-template-columns: 1fr;
  }
}
</style>
