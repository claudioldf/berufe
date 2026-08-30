<script setup lang="ts">
import { computed, onMounted, shallowRef } from "vue";
import type { LocationCoverageDraft } from "~/types";
import { useLocations } from "~/composables/useLocations";

const model = defineModel<LocationCoverageDraft>({ required: true });
const props = withDefaults(
  defineProps<{
    validationError?: string;
    citySelectionCoversWholeCity?: boolean;
  }>(),
  {
    validationError: "",
    citySelectionCoversWholeCity: false,
  },
);
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
const locationValidationError = computed(() =>
  model.value.cityCode ? "" : props.validationError,
);
const stateValidationError = computed(() =>
  selectedStateCode.value ? "" : locationValidationError.value,
);
const cityValidationError = computed(() =>
  selectedStateCode.value ? locationValidationError.value : "",
);
const stateInvalid = computed(() =>
  Boolean(locationValidationError.value && !selectedStateCode.value),
);
const cityInvalid = computed(() => Boolean(locationValidationError.value));
const areaValidationError = computed(() =>
  model.value.cityCode ? props.validationError : "",
);

onMounted(async () => {
  const selected = await initialize(model.value.cityCode);
  selectedStateCode.value = selected?.state.code ?? "";
  if (
    selected &&
    (props.citySelectionCoversWholeCity || neighborhoods.value.length === 0)
  ) {
    setWholeCity(true);
  }
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
  model.value = {
    cityCode,
    wholeCity: Boolean(cityCode && props.citySelectionCoversWholeCity),
    neighborhoodCodes: [],
  };
  if (cityCode && !props.citySelectionCoversWholeCity) {
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
      <DesignSystemFormField
        id="coverage-state"
        v-slot="field"
        label="Estado"
        :error="stateValidationError"
        required
      >
        <select
          :id="field.controlId"
          :class="{
            'location-coverage-fields__select--invalid': stateInvalid,
          }"
          :value="selectedStateCode"
          name="coverage-state"
          required
          :disabled="loading"
          :aria-describedby="field.describedBy"
          :aria-invalid="stateInvalid"
          @change="changeState"
        >
          <option value="">Selecione</option>
          <option v-for="state in states" :key="state.code" :value="state.code">
            {{ state.name }} ({{ state.abbreviation }})
          </option>
        </select>
      </DesignSystemFormField>
      <DesignSystemFormField
        id="coverage-city"
        v-slot="field"
        label="Cidade"
        :error="cityValidationError"
        required
      >
        <select
          :id="field.controlId"
          :class="{
            'location-coverage-fields__select--invalid': cityInvalid,
          }"
          :value="model.cityCode"
          name="coverage-city"
          required
          :disabled="loading || !selectedStateCode"
          :aria-describedby="
            field.describedBy ||
            (cityInvalid ? 'coverage-state-error' : undefined)
          "
          :aria-invalid="cityInvalid"
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

    <div
      v-if="selectedCity && !props.citySelectionCoversWholeCity"
      class="location-coverage-fields__area"
      :class="{
        'location-coverage-fields__area--invalid': areaValidationError,
      }"
      :aria-describedby="
        areaValidationError ? 'coverage-area-error' : undefined
      "
      :aria-invalid="Boolean(areaValidationError)"
      tabindex="-1"
    >
      <label class="location-coverage-fields__whole-city">
        <input
          :checked="model.wholeCity"
          name="whole-city"
          type="checkbox"
          @change="changeWholeCity"
        />
        <span>
          <strong>Atendo em toda {{ selectedCity.name }}</strong>
          <small
            >Seu perfil poderá aparecer em buscas de qualquer bairro.</small
          >
        </span>
        <UIcon name="i-lucide-map" />
      </label>

      <p
        v-if="neighborhoods.length === 0"
        class="location-coverage-fields__empty"
      >
        O IBGE não publicou bairros oficiais para esta cidade. A cobertura será
        cadastrada para a cidade inteira.
      </p>

      <div
        v-else-if="!model.wholeCity"
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
      <p
        v-if="areaValidationError"
        id="coverage-area-error"
        class="location-coverage-fields__error"
        role="alert"
      >
        {{ areaValidationError }}
      </p>
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
    padding: 0 2.75rem 0 12px;
    border: 1px solid var(--line);
    border-radius: 10px;
    background-color: white;
    color: var(--ink);
  }

  &__selectors select.location-coverage-fields__select--invalid {
    border-color: var(--color-danger);
    background-color: var(--color-danger-tint);
  }

  &__selectors select.location-coverage-fields__select--invalid:focus-visible {
    border-color: var(--color-danger);
    box-shadow: 0 0 0 3px rgb(180 35 24 / 16%);
  }

  &__whole-city {
    display: grid;
    grid-template-columns: auto 1fr auto;
    align-items: center;
    gap: 11px;
    padding: 15px;
    border: 1px solid var(--color-border-strong);
    border-radius: 13px;
    background: #edf7f3;
    cursor: pointer;
  }

  &__area {
    display: grid;
    gap: 14px;
    border-radius: 13px;
    outline: none;
  }

  &__area--invalid .location-coverage-fields__whole-city {
    border-color: var(--color-danger);
    background: var(--color-danger-tint);
  }

  &__area--invalid:focus-visible {
    box-shadow: 0 0 0 3px rgb(180 35 24 / 16%);
  }

  &__whole-city input {
    width: 17px;
    height: 17px;
    accent-color: var(--color-brand);
  }

  &__whole-city strong,
  &__whole-city small {
    display: block;
  }

  &__whole-city strong {
    font-size: 0.82rem;
  }

  &__whole-city small {
    margin-top: 3px;
    font-size: 0.84rem;
  }

  &__whole-city > svg {
    color: var(--color-brand);
    font-size: 1.3rem;
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
