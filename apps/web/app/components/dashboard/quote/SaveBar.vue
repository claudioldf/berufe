<script setup lang="ts">
import type { QuoteSaveIntent } from "~/types";

const props = defineProps<{
  saved: boolean;
  shared: boolean;
  readyToShare: boolean;
  valid: boolean;
  editing: boolean;
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
const saveBlockedReason = computed(() => {
  if (props.savingIntent === "draft") {
    return "O rascunho está sendo salvo.";
  }

  if (props.savingIntent === "share") {
    return "Aguarde o salvamento necessário para compartilhar.";
  }

  if (props.saved) {
    return "O rascunho já está salvo. Faça uma alteração para salvar novamente.";
  }

  return null;
});
const previewBlockedReason = computed(() => {
  if (props.savingIntent === "draft") {
    return "Aguarde o salvamento do rascunho terminar.";
  }
  if (props.savingIntent === "share") {
    return "Aguarde o salvamento necessário para compartilhar.";
  }
  return null;
});
const shareActionBlockedReason = computed(() => {
  if (props.savingIntent === "draft") {
    return "Aguarde o salvamento do rascunho terminar.";
  }
  if (props.savingIntent === "share") {
    return "Aguarde o salvamento necessário para compartilhar.";
  }
  if (props.readyToShare && !props.shareEnabled) {
    return (
      props.shareBlockedReason?.trim() ||
      "Seu perfil precisa estar disponível para compartilhar o orçamento."
    );
  }
  return null;
});
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
  if (props.readyToShare) return "Enviar ao cliente";
  return props.editing ? "Atualizar" : "Criar";
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
      <DesignSystemDisabledTooltip :reason="previewBlockedReason">
        <UButton
          color="neutral"
          variant="outline"
          icon="i-lucide-eye"
          :disabled="pending"
          @click="$emit('preview')"
        >
          Pré-visualizar
        </UButton>
      </DesignSystemDisabledTooltip>
      <DesignSystemDisabledTooltip
        :reason="saveBlockedReason"
        :loading="savingIntent === 'draft'"
      >
        <UButton
          color="neutral"
          variant="outline"
          :loading="savingIntent === 'draft'"
          :disabled="saved || pending"
          @click="$emit('save')"
        >
          Salvar rascunho
        </UButton>
      </DesignSystemDisabledTooltip>
      <DesignSystemDisabledTooltip
        :reason="shareActionBlockedReason"
        :loading="savingIntent === 'share'"
      >
        <UButton
          color="primary"
          :icon="readyToShare ? 'i-lucide-share' : 'i-lucide-check'"
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
