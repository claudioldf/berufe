<script setup lang="ts">
import type { ProfessionalProfileDraft, Service } from "~/types";

const form = defineModel<ProfessionalProfileDraft>({ required: true });
defineProps<{ services: Service[] }>();
defineEmits<{ toggle: [name: string] }>();
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
      <em>1 principal</em>
    </header>
    <div class="service-picker">
      <button
        v-for="service in services"
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
    <DesignSystemFormField
      id="profile-primary-service"
      v-slot="field"
      class="primary-service"
      label="Serviço principal do perfil"
    >
      <select
        :id="field.controlId"
        v-model="form.primaryService"
        name="primary-service"
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
  </section>
</template>

<style scoped lang="scss">
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
