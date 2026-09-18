<script setup lang="ts">
import type { LocationCoverageDraft } from "~/types";
import LocationCoverageFields from "~/components/location/LocationCoverageFields.vue";

export type ExternalCoverageMode = "not_informed" | "informed";

const coverageMode = defineModel<ExternalCoverageMode>("coverageMode", {
  required: true,
});
const coverage = defineModel<LocationCoverageDraft>({ required: true });

const props = withDefaults(defineProps<{ error?: string }>(), { error: "" });
</script>

<template>
  <fieldset class="external-professional-coverage">
    <legend>Qual região esse profissional atende?</legend>
    <div class="external-professional-coverage__radios">
      <label>
        <input v-model="coverageMode" type="radio" value="not_informed" />
        Não sei
      </label>
      <label>
        <input v-model="coverageMode" type="radio" value="informed" />
        Informar localização
      </label>
    </div>
    <LocationCoverageFields
      v-if="coverageMode === 'informed'"
      v-model="coverage"
      :validation-error="props.error"
      city-selection-covers-whole-city
    />
  </fieldset>
</template>

<style scoped lang="scss">
.external-professional-coverage {
  display: grid;
  gap: 10px;
  margin: 0;
  padding: 0;
  border: 0;

  & legend {
    margin-bottom: 8px;
    font-size: 0.84rem;
    font-weight: 800;
  }

  &__radios {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
  }

  &__radios label {
    display: flex;
    align-items: flex-start;
    gap: 8px;
    font-size: 0.82rem;
    line-height: 1.4;
    cursor: pointer;
  }

  &__radios input {
    margin-top: 3px;
  }
}
</style>
