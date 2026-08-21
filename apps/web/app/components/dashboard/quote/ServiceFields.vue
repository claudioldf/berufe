<script setup lang="ts">
import type { Quote } from "~/types";

const quote = defineModel<Quote>({ required: true });
const emit = defineEmits<{ dirty: [] }>();
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="builder-card">
    <header>
      <div>
        <span>02</span>
        <div>
          <h2>Serviço</h2>
          <p>Prazo, escopo e local combinados com o cliente.</p>
        </div>
      </div>
    </header>
    <div class="builder-fields" @input="emit('dirty')">
      <DesignSystemFormField v-slot="field" label="Válido até">
        <input
          :id="field.controlId"
          v-model="quote.validUntil"
          name="validUntil"
          type="date"
          autocomplete="off"
          :aria-describedby="field.describedBy"
        />
      </DesignSystemFormField>
      <DesignSystemFormField v-slot="field" label="Data combinada">
        <input
          :id="field.controlId"
          v-model="quote.scheduledOn"
          name="scheduledOn"
          type="date"
          autocomplete="off"
          :aria-describedby="field.describedBy"
        />
      </DesignSystemFormField>
      <DesignSystemFormField
        v-slot="field"
        class="builder-fields__full"
        label="Descrição do serviço"
        required
      >
        <input
          :id="field.controlId"
          v-model="quote.serviceDescription"
          name="serviceDescription"
          autocomplete="off"
          :aria-describedby="field.describedBy"
          required
          maxlength="160"
        />
      </DesignSystemFormField>
      <DesignSystemFormField
        v-slot="field"
        class="builder-fields__full"
        label="Endereço do serviço (opcional)"
      >
        <input
          :id="field.controlId"
          v-model="quote.serviceAddress"
          name="serviceAddress"
          autocomplete="street-address"
          :aria-describedby="field.describedBy"
          maxlength="240"
        />
      </DesignSystemFormField>
    </div>
  </DesignSystemSurfaceCard>
</template>
