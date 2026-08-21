<script setup lang="ts">
import type { Neighborhood, Service } from "~/types";

export type ExternalCoverageMode =
  "not_informed" | "all_joinville" | "neighborhoods";

const name = defineModel<string>("name", { required: true });
const phone = defineModel<string>("phone", { required: true });
const serviceIds = defineModel<string[]>("serviceIds", { required: true });
const coverageMode = defineModel<ExternalCoverageMode>("coverageMode", {
  required: true,
});
const neighborhoodCodes = defineModel<string[]>("neighborhoodCodes", {
  required: true,
});
const attested = defineModel<boolean>("attested", { required: true });

defineProps<{
  services: Service[];
  neighborhoods: Neighborhood[];
}>();
</script>

<template>
  <div class="external-professional-form">
    <p class="external-professional-form__intro">
      Criaremos um perfil básico para que o profissional possa confirmar a
      relação e completar os dados depois.
    </p>

    <div class="external-professional-form__identity">
      <DesignSystemFormField
        id="external-professional-name"
        label="Nome profissional"
        required
      >
        <input
          id="external-professional-name"
          v-model="name"
          name="external-name"
          type="text"
          autocomplete="name"
          minlength="3"
          maxlength="70"
          required
        />
      </DesignSystemFormField>
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
    </div>

    <fieldset class="external-professional-form__fieldset">
      <legend>Serviços <small>Opcional</small></legend>
      <div class="external-professional-form__options">
        <label v-for="service in services" :key="service.id">
          <input v-model="serviceIds" type="checkbox" :value="service.id" />
          <span>{{ service.name }}</span>
        </label>
      </div>
    </fieldset>

    <fieldset class="external-professional-form__fieldset">
      <legend>Área de atendimento <small>Opcional</small></legend>
      <div class="external-professional-form__radios">
        <label>
          <input v-model="coverageMode" type="radio" value="not_informed" />
          Não informada
        </label>
        <label>
          <input v-model="coverageMode" type="radio" value="all_joinville" />
          Toda Joinville
        </label>
        <label>
          <input v-model="coverageMode" type="radio" value="neighborhoods" />
          Bairros específicos
        </label>
      </div>
      <div
        v-if="coverageMode === 'neighborhoods'"
        class="external-professional-form__options external-professional-form__options--neighborhoods"
      >
        <label v-for="neighborhood in neighborhoods" :key="neighborhood.code">
          <input
            v-model="neighborhoodCodes"
            type="checkbox"
            :value="neighborhood.code"
          />
          <span>{{ neighborhood.name }}</span>
        </label>
      </div>
    </fieldset>

    <label class="external-professional-form__consent">
      <input
        v-model="attested"
        name="external-contact-consent"
        type="checkbox"
      />
      <span>
        Confirmo que posso compartilhar estes dados profissionais para criar o
        perfil básico e enviar a solicitação.
      </span>
    </label>
  </div>
</template>

<style scoped lang="scss">
.external-professional-form {
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

  &__identity {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 12px;
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
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 7px;
    max-height: 180px;
    overflow: auto;
  }

  &__options label,
  &__radios label,
  &__consent {
    display: flex;
    align-items: flex-start;
    gap: 8px;
    font-size: 0.82rem;
    line-height: 1.4;
    cursor: pointer;
  }

  &__radios {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
  }

  &__consent {
    padding: 12px;
    border: 1px solid var(--line);
    border-radius: 10px;
  }
}

@media (width <= 620px) {
  .external-professional-form__identity,
  .external-professional-form__options {
    grid-template-columns: 1fr;
  }
}
</style>
