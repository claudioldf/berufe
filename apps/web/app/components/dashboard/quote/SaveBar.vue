<script setup lang="ts">
defineProps<{
  saved: boolean;
  shared: boolean;
  valid: boolean;
  saving: boolean;
  error: string;
  shareEnabled: boolean;
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
        :name="
          error
            ? 'i-lucide-circle-alert'
            : saved
              ? 'i-lucide-cloud-check'
              : 'i-lucide-circle-dot'
        "
        aria-hidden="true"
      />
      {{
        error
          ? error
          : saving
            ? "Salvando rascunho…"
            : saved
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
      <UButton
        color="primary"
        :loading="saving"
        :disabled="!valid || saving"
        @click="$emit('save')"
      >
        Salvar rascunho
      </UButton>
      <UButton
        color="secondary"
        icon="i-lucide-send"
        :disabled="!valid || !saved || !shareEnabled || saving"
        @click="$emit('share')"
      >
        Compartilhar
      </UButton>
    </div>
  </div>
</template>
