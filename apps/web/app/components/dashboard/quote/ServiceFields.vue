<script setup lang="ts">
import type { Quote, QuoteValidationErrors } from "~/types";

const props = defineProps<{ errors?: QuoteValidationErrors }>();
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
          <p>Defina a validade, a data prevista e os detalhes do serviço.</p>
        </div>
      </div>
    </header>
    <div class="builder-fields" @input="emit('dirty')">
      <DesignSystemFormField
        v-slot="field"
        label="Válido até"
        :error="props.errors?.validUntil"
        required
      >
        <input
          :id="field.controlId"
          v-model="quote.validUntil"
          name="validUntil"
          type="date"
          lang="pt-BR"
          autocomplete="off"
          :aria-describedby="field.describedBy"
          :aria-invalid="field.invalid"
          required
        />
      </DesignSystemFormField>
      <DesignSystemFormField
        v-slot="field"
        label="Data prevista do serviço"
        :error="props.errors?.scheduledOn"
      >
        <input
          :id="field.controlId"
          v-model="quote.scheduledOn"
          name="scheduledOn"
          type="date"
          lang="pt-BR"
          autocomplete="off"
          :aria-describedby="field.describedBy"
          :aria-invalid="field.invalid"
        />
      </DesignSystemFormField>
      <DesignSystemFormField
        v-slot="field"
        class="builder-fields__full"
        label="Descrição do serviço"
        :error="props.errors?.serviceDescription"
        required
      >
        <input
          :id="field.controlId"
          v-model="quote.serviceDescription"
          name="serviceDescription"
          autocomplete="off"
          :aria-describedby="field.describedBy"
          :aria-invalid="field.invalid"
          required
          maxlength="160"
        />
      </DesignSystemFormField>
      <DesignSystemFormField
        v-slot="field"
        class="builder-fields__full"
        label="Endereço do serviço (opcional)"
        :error="props.errors?.serviceAddress"
      >
        <input
          :id="field.controlId"
          v-model="quote.serviceAddress"
          name="serviceAddress"
          autocomplete="street-address"
          :aria-describedby="field.describedBy"
          :aria-invalid="field.invalid"
          maxlength="240"
        />
      </DesignSystemFormField>
    </div>
  </DesignSystemSurfaceCard>
</template>
