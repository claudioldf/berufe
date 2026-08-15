<script setup lang="ts">
defineProps<{
  saved: boolean;
  shared: boolean;
  valid: boolean;
}>();

defineEmits<{
  preview: [];
  save: [];
  share: [];
}>();
</script>

<template>
  <div class="quote-builder__savebar" aria-live="polite">
    <span>
      <UIcon
        :name="saved ? 'i-lucide-cloud-check' : 'i-lucide-circle-dot'"
        aria-hidden="true"
      />
      {{
        saved
          ? shared
            ? "Compartilhado"
            : "Rascunho salvo"
          : "Alterações não salvas"
      }}
    </span>
    <div>
      <UButton
        color="neutral"
        variant="outline"
        icon="i-lucide-eye"
        @click="$emit('preview')"
      >
        Pré-visualizar
      </UButton>
      <UButton color="primary" :disabled="!valid" @click="$emit('save')">
        Salvar rascunho
      </UButton>
      <UButton
        color="secondary"
        icon="i-lucide-send"
        :disabled="!valid"
        @click="$emit('share')"
      >
        Compartilhar
      </UButton>
    </div>
  </div>
</template>
