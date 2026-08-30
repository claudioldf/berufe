<script setup lang="ts">
import type { Service } from "~/types";

const serviceIds = defineModel<string[]>({ required: true });
defineProps<{ services: Service[] }>();
</script>

<template>
  <fieldset class="external-professional-services">
    <legend>
      Qual o serviço esse profissional oferece? <small>Opcional</small>
    </legend>
    <div class="external-professional-services__options">
      <label v-for="service in services" :key="service.id">
        <input v-model="serviceIds" type="checkbox" :value="service.id" />
        <span>{{ service.name }}</span>
      </label>
    </div>
  </fieldset>
</template>

<style scoped lang="scss">
.external-professional-services {
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

  & legend small {
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
    display: flex;
    align-items: flex-start;
    gap: 8px;
    padding: 2px 0;
    font-size: 0.82rem;
    line-height: 1.4;
    cursor: pointer;
  }

  &__options input {
    margin-top: 3px;
  }
}

@media (width <= 620px) {
  .external-professional-services__options {
    grid-template-columns: 1fr;
  }
}
</style>
