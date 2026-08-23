<script setup lang="ts">
import type { QuoteSaveIntent } from "~/types";

const props = defineProps<{
  saved: boolean;
  shared: boolean;
  valid: boolean;
  savingIntent: QuoteSaveIntent | null;
  error: string;
  shareEnabled: boolean;
}>();

defineEmits<{
  preview: [];
  save: [];
  share: [];
}>();

const pending = computed(() => props.savingIntent !== null);
const statusText = computed(() => {
  if (props.error) return props.error;
  if (props.savingIntent === "share") {
    return "Salvando antes de compartilhar…";
  }
  if (props.savingIntent === "draft") return "Salvando rascunho…";
  if (!props.saved) return "Alterações não salvas";
  return props.shared ? "Compartilhado" : "Rascunho salvo";
});
const shareLabel = computed(() => {
  if (props.savingIntent === "share") return "Salvando…";
  return props.saved ? "Compartilhar" : "Salvar e compartilhar";
});
</script>

<template>
  <div class="quote-builder__savebar">
    <span :role="error ? 'alert' : 'status'">
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
      {{ statusText }}
    </span>
    <div>
      <UButton
        color="neutral"
        variant="outline"
        icon="i-lucide-eye"
        :disabled="pending"
        @click="$emit('preview')"
      >
        Pré-visualizar
      </UButton>
      <UButton
        color="neutral"
        variant="outline"
        :loading="savingIntent === 'draft'"
        :disabled="!valid || saved || pending"
        @click="$emit('save')"
      >
        Salvar rascunho
      </UButton>
      <UButton
        color="primary"
        icon="i-lucide-send"
        :loading="savingIntent === 'share'"
        :disabled="!valid || !shareEnabled || pending"
        @click="$emit('share')"
      >
        {{ shareLabel }}
      </UButton>
    </div>
  </div>
</template>
