<script setup lang="ts">
import type { Quote } from "~/types";

const quote = defineModel<Quote>({ required: true });
const emit = defineEmits<{ dirty: [] }>();
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="builder-card">
    <header>
      <div>
        <span>04</span>
        <div>
          <h2>Observações</h2>
          <p>Inclua prazos, materiais ou condições importantes.</p>
        </div>
      </div>
    </header>
    <DesignSystemFormField
      v-slot="field"
      class="builder-notes"
      label="Observações (opcional)"
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
