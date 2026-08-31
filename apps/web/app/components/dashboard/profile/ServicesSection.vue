<script setup lang="ts">
import { computed } from "vue";
import type { ProfessionalProfileDraft, Service } from "~/types";

const form = defineModel<ProfessionalProfileDraft>({ required: true });
const props = withDefaults(
  defineProps<{ services: Service[]; error?: string }>(),
  { error: "" },
);
defineEmits<{ toggle: [name: string] }>();

const sortedServices = computed(() =>
  [...props.services].sort((left, right) =>
    left.name.localeCompare(right.name, "pt-BR", { sensitivity: "base" }),
  ),
);
const serviceSelectionInvalid = computed(
  () => Boolean(props.error) && form.value.selectedServices.length === 0,
);
const hasMultipleServices = computed(
  () => form.value.selectedServices.length > 1,
);
const featuredServiceInvalid = computed(
  () =>
    hasMultipleServices.value &&
    !form.value.selectedServices.includes(form.value.primaryService),
);
const primaryServiceError = computed(() =>
  Boolean(props.error) && featuredServiceInvalid.value ? props.error : "",
);
const serviceDetailsError = computed(() =>
  Boolean(props.error) &&
  !serviceSelectionInvalid.value &&
  !featuredServiceInvalid.value
    ? props.error
    : "",
);
</script>

<template>
  <section class="editor-section">
    <header>
      <div>
        <span>03</span>
        <div>
          <h2>Serviços</h2>
          <p>Escolha no catálogo o que você realmente oferece.</p>
        </div>
      </div>
      <em>1 ou mais</em>
    </header>
    <div
      class="service-picker"
      :class="{ 'service-picker--invalid': serviceSelectionInvalid }"
      role="group"
      aria-label="Seleção de serviços"
      :aria-describedby="
        serviceSelectionInvalid ? 'profile-service-selection-error' : undefined
      "
      :aria-invalid="serviceSelectionInvalid"
      :tabindex="serviceSelectionInvalid ? -1 : undefined"
    >
      <button
        v-for="service in sortedServices"
        :key="service.id"
        type="button"
        :class="{ selected: form.selectedServices.includes(service.name) }"
        :aria-pressed="form.selectedServices.includes(service.name)"
        @click="$emit('toggle', service.name)"
      >
        <span><UIcon :name="service.icon" /></span>
        <strong>{{ service.name }}</strong>
        <UIcon
          :name="
            form.selectedServices.includes(service.name)
              ? 'i-lucide-circle-check'
              : 'i-lucide-circle-plus'
          "
        />
      </button>
    </div>
    <small
      v-if="serviceSelectionInvalid"
      id="profile-service-selection-error"
      class="service-picker__error"
      aria-live="polite"
    >
      {{ props.error }}
    </small>
    <DesignSystemFormField
      v-if="hasMultipleServices"
      id="profile-primary-service"
      v-slot="field"
      class="primary-service"
      label="Serviço em destaque"
      hint="Escolha o serviço que aparece primeiro no seu perfil. Todos continuam disponíveis nas buscas."
      :error="primaryServiceError"
      required
    >
      <select
        :id="field.controlId"
        v-model="form.primaryService"
        name="primary-service"
        required
        :aria-describedby="field.describedBy"
        :aria-invalid="field.invalid"
      >
        <option v-for="service in form.selectedServices" :key="service">
          {{ service }}
        </option>
      </select>
    </DesignSystemFormField>
    <div v-if="form.selectedServices.length" class="service-notes">
      <DesignSystemFormField
        v-for="(service, index) in form.selectedServices"
        :id="`profile-service-note-${index}`"
        :key="service"
        :label="`Especialização em ${service}`"
        hint="Opcional, até 120 caracteres."
      >
        <template #default="field">
          <input
            :id="field.controlId"
            v-model="form.serviceNotes[service]"
            :name="`service-note-${index}`"
            maxlength="120"
            autocomplete="off"
            :aria-describedby="field.describedBy"
          />
        </template>
      </DesignSystemFormField>
    </div>
    <small
      v-if="serviceDetailsError"
      class="service-details-error"
      aria-live="polite"
    >
      {{ serviceDetailsError }}
    </small>
  </section>
</template>

<style scoped lang="scss">
.service-picker {
  border-radius: 12px;
  outline: none;

  &--invalid {
    background: var(--color-danger-tint);
    box-shadow: 0 0 0 1px var(--color-danger);
  }

  &--invalid:focus-visible {
    box-shadow:
      0 0 0 1px var(--color-danger),
      0 0 0 4px rgb(180 35 24 / 16%);
  }

  &__error {
    display: block;
    margin-top: 7px;
    color: var(--color-danger);
    font-size: 0.84rem;
    font-weight: 500;
    line-height: 1.45;
  }
}

.service-details-error {
  display: block;
  margin-top: 7px;
  color: var(--color-danger);
  font-size: 0.84rem;
  font-weight: 500;
  line-height: 1.45;
}

.service-notes {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
  margin-top: 16px;
}

@media (width <= 680px) {
  .service-notes {
    grid-template-columns: 1fr;
  }
}
</style>
