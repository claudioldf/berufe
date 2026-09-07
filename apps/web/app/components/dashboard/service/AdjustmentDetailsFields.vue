<script setup lang="ts">
import type { ServiceAdjustmentEditorForm } from "~/types";

defineProps<{
  errors: Record<string, string>;
}>();

const form = defineModel<ServiceAdjustmentEditorForm>({ required: true });
</script>

<template>
  <DesignSystemSurfaceCard
    as="section"
    class="adjustment-builder-card adjustment-details"
  >
    <header>
      <div>
        <span>01</span>
        <div>
          <h2>O que mudou?</h2>
          <p>Resuma o novo escopo e informe qualquer impacto no prazo.</p>
        </div>
      </div>
    </header>

    <div class="adjustment-details__fields">
      <DesignSystemFormField
        class="adjustment-details__full"
        label="Resumo do ajuste"
        :error="errors.title"
        required
      >
        <template #default="{ controlId, describedBy, invalid, required }">
          <input
            :id="controlId"
            v-model="form.title"
            name="adjustment-summary"
            maxlength="120"
            autocomplete="off"
            placeholder="Ex.: Pintura da parede adicional…"
            :aria-describedby="describedBy"
            :aria-invalid="invalid"
            :required="required"
          />
        </template>
      </DesignSystemFormField>

      <DesignSystemFormField
        class="adjustment-details__full"
        label="Detalhes (opcional)"
      >
        <template #default="{ controlId, describedBy, invalid }">
          <textarea
            :id="controlId"
            v-model="form.description"
            name="adjustment-details"
            rows="4"
            maxlength="700"
            autocomplete="off"
            placeholder="Explique o novo escopo ou a razão do ajuste…"
            :aria-describedby="describedBy"
            :aria-invalid="invalid"
          />
        </template>
      </DesignSystemFormField>

      <DesignSystemFormField label="Impacto no prazo (opcional)">
        <template #default="{ controlId, describedBy, invalid }">
          <input
            :id="controlId"
            v-model="form.scheduleImpact"
            name="adjustment-schedule-impact"
            maxlength="300"
            autocomplete="off"
            placeholder="Ex.: 1 dia a mais…"
            :aria-describedby="describedBy"
            :aria-invalid="invalid"
          />
        </template>
      </DesignSystemFormField>

      <DesignSystemFormField label="Já realizado ou comprado em (opcional)">
        <template #default="{ controlId, describedBy, invalid }">
          <input
            :id="controlId"
            v-model="form.incurredOn"
            name="adjustment-incurred-on"
            type="date"
            autocomplete="off"
            :aria-describedby="describedBy"
            :aria-invalid="invalid"
          />
        </template>
      </DesignSystemFormField>
    </div>

    <p v-if="form.incurredOn" class="adjustment-details__warning">
      <UIcon name="i-lucide-triangle-alert" aria-hidden="true" />
      <span>
        O cliente verá que esta despesa ocorreu antes da aprovação. Ela
        continuará fora do total combinado até ser aprovada.
      </span>
    </p>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.adjustment-details {
  &__fields {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 14px;
  }

  &__full {
    grid-column: 1 / -1;
  }

  &__warning {
    display: flex;
    align-items: flex-start;
    gap: 8px;
    padding: 12px;
    margin: 16px 0 0;
    border-radius: 10px;
    background: var(--color-warning-tint);
    color: #7a4307;
    font-size: 0.84rem;
    line-height: 1.5;
  }

  &__warning :deep(svg) {
    flex: 0 0 auto;
    margin-top: 0.15em;
  }
}

@media (width <= 720px) {
  .adjustment-details {
    &__fields {
      grid-template-columns: 1fr;
    }

    &__full {
      grid-column: auto;
    }
  }
}
</style>
