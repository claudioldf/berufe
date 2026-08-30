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
</script>

<template>
  <div class="editor-savebar">
    <span>
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
    <div>
      <small
        >Os campos acima representam as informações públicas do perfil.</small
      >
      <UButton
        type="submit"
        color="primary"
        :loading="props.saving"
        :disabled="props.saving || (saved && props.valid)"
      >
        Salvar alterações
      </UButton>
    </div>
  </div>
</template>
