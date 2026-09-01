<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    saved: boolean;
    saving?: boolean;
    valid?: boolean;
    validationAttempted?: boolean;
  }>(),
  { saving: false, valid: true, validationAttempted: false },
);
const savingReason = computed(() =>
  props.saving ? "Aguarde o salvamento do perfil terminar." : null,
);
</script>

<template>
  <div class="editor-savebar">
    <span class="editor-savebar__status">
      <UIcon :name="saved ? 'i-lucide-cloud-check' : 'i-lucide-circle-dot'" />
      {{
        props.saving
          ? "Salvando alterações…"
          : props.validationAttempted && !props.valid
            ? "Revise os campos destacados"
            : saved
              ? "Alterações salvas"
              : "Há alterações não salvas"
      }}
    </span>
    <div class="editor-savebar__actions">
      <DesignSystemDisabledTooltip :reason="savingReason">
        <UButton
          type="submit"
          color="primary"
          :loading="props.saving"
          :disabled="props.saving"
        >
          Salvar
        </UButton>
      </DesignSystemDisabledTooltip>
    </div>
  </div>
</template>

<style scoped lang="scss">
.editor-savebar {
  position: sticky;
  z-index: 20;
  bottom: 14px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 15px;
  padding: 12px 14px;
  border: 1px solid var(--line);
  border-radius: 15px;
  background: rgb(255 255 255 / 95%);
  box-shadow: var(--shadow-lg);
  backdrop-filter: blur(14px);

  &__status {
    display: flex;
    min-width: 0;
    align-items: center;
    gap: 6px;
    color: var(--ink-soft);
    font-size: 0.86rem;
    font-weight: 700;
  }

  &__actions {
    display: flex;
    flex: 0 0 auto;
    align-items: center;
    justify-content: flex-end;
  }
}
</style>
