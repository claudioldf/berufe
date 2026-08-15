<script setup lang="ts">
import type { Quote } from "~/types";

const quote = defineModel<Quote>({ required: true });
const emit = defineEmits<{ dirty: [] }>();
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="builder-card">
    <header>
      <div>
        <span>03</span>
        <div>
          <h2>Observações</h2>
          <p>Detalhes de prazo, materiais ou condições.</p>
        </div>
      </div>
    </header>
    <DesignSystemFormField
      v-slot="field"
      class="builder-notes"
      label="Observações opcionais"
    >
      <textarea
        :id="field.controlId"
        v-model="quote.notes"
        name="notes"
        autocomplete="off"
        :aria-describedby="field.describedBy"
        maxlength="700"
        @input="emit('dirty')"
      />
    </DesignSystemFormField>
  </DesignSystemSurfaceCard>
</template>
