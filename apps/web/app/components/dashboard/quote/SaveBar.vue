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
  return props.editing ? "Atualizar" : "Gerar";
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
    <div class="quote-builder__savebar-actions">
      <DesignSystemDisabledTooltip :reason="previewBlockedReason">
        <UButton
          class="quote-builder__savebar-action"
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
          class="quote-builder__savebar-action"
          color="neutral"
          variant="outline"
          icon="i-lucide-file-text"
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
          class="quote-builder__savebar-action"
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

<style scoped lang="scss">
@media (width <= 720px) {
  .quote-builder {
    &__savebar {
      display: grid;
      grid-template-columns: minmax(0, 1fr);
      row-gap: 8px;
      padding-inline: 8px;
    }

    &__savebar-actions {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 4px;
      width: 100%;
      min-width: 0;
    }

    &__savebar-action {
      justify-content: center;
      width: 100%;
      min-width: 0;
      min-height: 48px;
      padding-inline: 4px;
      gap: 4px;
      font-size: clamp(0.625rem, 3vw, 0.75rem);
    }

    &__savebar-actions :deep(.disabled-tooltip--boxed) {
      width: 100%;
    }
  }
}
</style>
