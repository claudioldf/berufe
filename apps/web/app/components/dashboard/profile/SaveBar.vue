<script setup lang="ts">
const props = withDefaults(
  defineProps<{ saved: boolean; saving?: boolean }>(),
  { saving: false },
);
</script>

<template>
  <div class="editor-savebar">
    <span>
      <UIcon :name="saved ? 'i-lucide-cloud-check' : 'i-lucide-circle-dot'" />
      {{
        props.saving
          ? "Salvando alterações…"
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
        :disabled="saved || props.saving"
      >
        Salvar alterações
      </UButton>
    </div>
  </div>
</template>
