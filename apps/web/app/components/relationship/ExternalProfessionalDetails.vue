<script setup lang="ts">
import type { LocationCoverageDraft } from "~/types";
import LocationCoverageFields from "~/components/location/LocationCoverageFields.vue";

export type ExternalCoverageMode = "not_informed" | "informed";

const phone = defineModel<string>("phone", { required: true });
const coverageMode = defineModel<ExternalCoverageMode>("coverageMode", {
  required: true,
});
const coverage = defineModel<LocationCoverageDraft>("coverage", {
  required: true,
});

const props = withDefaults(
  defineProps<{
    phoneError?: string;
    coverageError?: string;
  }>(),
  { phoneError: "", coverageError: "" },
);
</script>

<template>
  <div class="external-professional-details">
    <DesignSystemFormField
      id="external-professional-phone"
      v-slot="field"
      label="Celular com DDD"
      hint="O número não será exibido publicamente"
      :error="props.phoneError"
      required
    >
      <input
        :id="field.controlId"
        v-model="phone"
        name="external-phone"
        type="tel"
        inputmode="tel"
        autocomplete="tel-national"
        placeholder="(47) 99999-9999"
        required
        :aria-describedby="field.describedBy"
        :aria-invalid="field.invalid"
      />
    </DesignSystemFormField>

    <fieldset class="external-professional-details__fieldset">
      <legend>
        Qual região esse profissional atende? <small>Opcional</small>
      </legend>
      <div class="external-professional-details__radios">
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
        :validation-error="props.coverageError"
      />
    </fieldset>
  </div>
</template>

<style scoped lang="scss">
.external-professional-details {
  display: grid;
  gap: 18px;

  &__fieldset {
    display: grid;
    gap: 10px;
    margin: 0;
    padding: 0;
    border: 0;
  }

  &__fieldset legend {
    margin-bottom: 8px;
    font-size: 0.84rem;
    font-weight: 800;
  }

  &__fieldset legend small {
    color: var(--ink-soft);
    font-weight: 500;
  }

  &__radios label {
    display: flex;
    align-items: flex-start;
    gap: 8px;
    font-size: 0.82rem;
    line-height: 1.4;
    cursor: pointer;

    input[type="checkbox"],
    input[type="radio"] {
      margin-top: 3px;
    }
  }

  &__radios {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
  }
}
</style>
