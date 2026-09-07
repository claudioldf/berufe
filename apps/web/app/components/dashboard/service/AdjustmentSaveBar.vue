<script setup lang="ts">
import { computed } from "vue";
import type { ServiceAdjustmentEditorSaveIntent } from "~/types";

const props = defineProps<{
  valid: boolean;
  savingIntent: ServiceAdjustmentEditorSaveIntent | null;
  error: string;
}>();

defineEmits<{
  preview: [];
  save: [];
  share: [];
}>();

const pending = computed(() => props.savingIntent !== null);
const statusText = computed(() => {
  if (props.error) return props.error;
  if (props.savingIntent) return "Salvando ajuste…";
  if (!props.valid) return "Preencha os campos obrigatórios";
  return "Alterações não salvas";
});
</script>

<template>
  <div class="adjustment-savebar">
    <span :role="error ? 'alert' : 'status'" aria-live="polite">
      <UIcon
        :name="error ? 'i-lucide-circle-alert' : 'i-lucide-circle-dot'"
        aria-hidden="true"
      />
      {{ statusText }}
    </span>
    <div class="adjustment-savebar__actions">
      <UButton
        class="adjustment-savebar__action"
        type="button"
        color="neutral"
        variant="outline"
        icon="i-lucide-eye"
        :disabled="pending"
        @click="$emit('preview')"
      >
        Pré-visualizar
      </UButton>
      <UButton
        class="adjustment-savebar__action"
        type="button"
        color="neutral"
        variant="outline"
        icon="i-lucide-file-text"
        :loading="savingIntent === 'draft'"
        :disabled="pending"
        @click="$emit('save')"
      >
        Salvar rascunho
      </UButton>
      <UButton
        class="adjustment-savebar__action"
        type="button"
        color="primary"
        icon="i-lucide-share"
        :disabled="pending"
        @click="$emit('share')"
      >
        Enviar ao cliente
      </UButton>
    </div>
  </div>
</template>

<style scoped lang="scss">
.adjustment-savebar {
  position: sticky;
  z-index: 10;
  bottom: 12px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 11px 13px;
  border: 1px solid var(--line);
  border-radius: 14px;
  background: rgb(255 255 255 / 96%);
  box-shadow: var(--shadow-lg);

  & > span {
    display: flex;
    align-items: center;
    gap: 5px;
    min-width: 0;
    color: var(--ink-soft);
    font-size: 0.82rem;
  }

  &__actions {
    display: flex;
    gap: 6px;
  }
}

@media (width <= 720px) {
  .adjustment-savebar {
    display: grid;
    grid-template-columns: minmax(0, 1fr);
    row-gap: 8px;
    padding-inline: 8px;

    &__actions {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 6px;
      width: 100%;
      min-width: 0;
    }

    &__action {
      justify-content: center;
      width: 100%;
      min-width: 0;
      min-height: 48px;
      padding-inline: 8px;
      gap: 5px;
      font-size: 0.8125rem;
      font-weight: 600;
      white-space: nowrap;
    }

    &__action:last-child {
      grid-column: 1 / -1;
      grid-row: 1;
      font-size: 0.875rem;
    }
  }
}
</style>
