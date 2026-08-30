<script setup lang="ts">
import { computed } from "vue";
import type { LocationCoverageDraft, ProfessionalProfileDraft } from "~/types";
import LocationCoverageFields from "~/components/location/LocationCoverageFields.vue";

const form = defineModel<ProfessionalProfileDraft>({ required: true });
withDefaults(defineProps<{ error?: string }>(), { error: "" });
const emit = defineEmits<{ dirty: [] }>();
const coverage = computed<LocationCoverageDraft>({
  get: () => ({
    cityCode: form.value.coverageCityCode,
    wholeCity: form.value.coversWholeCity,
    neighborhoodCodes: [...form.value.selectedNeighborhoodCodes],
  }),
  set: (value) => {
    form.value.coverageCityCode = value.cityCode;
    form.value.coversWholeCity = value.wholeCity;
    form.value.selectedNeighborhoodCodes = [...value.neighborhoodCodes];
  },
});
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
    </header>
    <LocationCoverageFields
      v-model="coverage"
      :validation-error="error"
      @dirty="emit('dirty')"
    />
  </section>
</template>
