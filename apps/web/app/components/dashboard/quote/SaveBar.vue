<script setup lang="ts">
import type { QuoteSaveIntent } from "~/types";

const props = defineProps<{
  saved: boolean;
  shared: boolean;
  readyToShare: boolean;
  valid: boolean;
  savingIntent: QuoteSaveIntent | null;
  error: string;
  shareEnabled: boolean;
  shareBlockedReason?: string | null;
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
    return "Salvando orçamento…";
  }
  if (props.savingIntent === "draft") return "Salvando rascunho…";
  if (!props.valid) return "Preencha os campos obrigatórios";
  if (!props.saved) return "Alterações não salvas";
  if (props.shared) return "Compartilhado";
  return props.readyToShare ? "Aguardando envio ao cliente" : "Rascunho salvo";
});
const shareLabel = computed(() => {
  if (props.savingIntent === "share") return "Salvando…";
  return props.readyToShare ? "Compartilhar" : "Salvar";
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
        :disabled="saved || pending"
        @click="$emit('save')"
      >
        Salvar rascunho
      </UButton>
      <DesignSystemDisabledTooltip
        :reason="readyToShare && !shareEnabled ? shareBlockedReason : null"
      >
        <UButton
          color="primary"
          :icon="readyToShare ? 'i-lucide-send' : 'i-lucide-check'"
          :loading="savingIntent === 'share'"
          :disabled="(readyToShare && !shareEnabled) || pending"
          @click="$emit('share')"
        >
          {{ shareLabel }}
        </UButton>
      </DesignSystemDisabledTooltip>
    </div>
  </div>
</template>
