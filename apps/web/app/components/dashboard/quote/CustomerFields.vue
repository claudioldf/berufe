<script setup lang="ts">
import type { Quote } from "~/types";

const quote = defineModel<Quote>({ required: true });
const emit = defineEmits<{ dirty: [] }>();
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="builder-card">
    <header>
      <div>
        <span>01</span>
        <div>
          <h2>Cliente e serviço</h2>
          <p>Informações visíveis no link compartilhado.</p>
        </div>
      </div>
    </header>
    <div class="builder-fields" @input="emit('dirty')">
      <DesignSystemFormField v-slot="field" label="Nome do cliente" required>
        <input
          :id="field.controlId"
          v-model="quote.customerName"
          name="customerName"
          autocomplete="name"
          :aria-describedby="field.describedBy"
          required
          maxlength="80"
        />
      </DesignSystemFormField>
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
    </div>
  </DesignSystemSurfaceCard>
</template>
