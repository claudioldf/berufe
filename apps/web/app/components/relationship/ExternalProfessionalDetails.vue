<script setup lang="ts">
import type { LocationCoverageDraft, Service } from "~/types";
import LocationCoverageFields from "~/components/location/LocationCoverageFields.vue";

export type ExternalCoverageMode = "not_informed" | "informed";

const phone = defineModel<string>("phone", { required: true });
const serviceIds = defineModel<string[]>("serviceIds", { required: true });
const coverageMode = defineModel<ExternalCoverageMode>("coverageMode", {
  required: true,
});
const coverage = defineModel<LocationCoverageDraft>("coverage", {
  required: true,
});

defineProps<{
  name: string;
  services: Service[];
}>();
</script>

<template>
  <div class="external-professional-details">
    <!-- <p class="external-professional-details__intro">
      Informe o telefone de <strong>{{ name }}</strong
      >. Se ainda não houver uma conta com esse número, criaremos um perfil
      básico para que o profissional possa confirmar a relação e completar os
      dados depois.
    </p> -->

    <DesignSystemFormField
      id="external-professional-phone"
      label="Celular com DDD"
      hint="O número não será exibido publicamente"
      required
    >
      <input
        id="external-professional-phone"
        v-model="phone"
        name="external-phone"
        type="tel"
        inputmode="tel"
        autocomplete="tel-national"
        placeholder="(47) 99999-9999"
        required
      />
    </DesignSystemFormField>

    <fieldset class="external-professional-details__fieldset">
      <legend>
        Qual o serviço esse profissional oferece? <small>Opcional</small>
      </legend>
      <div class="external-professional-details__options">
        <label v-for="service in services" :key="service.id">
          <input v-model="serviceIds" type="checkbox" :value="service.id" />
          <span>{{ service.name }}</span>
        </label>
      </div>
    </fieldset>

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
      />
    </fieldset>
  </div>
</template>

<style scoped lang="scss">
.external-professional-details {
  display: grid;
  gap: 18px;

  &__intro {
    margin: 0;
    padding: 12px 14px;
    border-radius: 10px;
    background: var(--mint);
    color: var(--color-brand-strong);
    font-size: 0.82rem;
    line-height: 1.5;
  }

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

  &__options {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 8px;
    max-height: 180px;
    overflow: auto;
  }

  &__options label {
    padding: 2px 0;
  }

  &__options label,
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

@media (width <= 620px) {
  .external-professional-details__options {
    grid-template-columns: 1fr;
  }
}
</style>
