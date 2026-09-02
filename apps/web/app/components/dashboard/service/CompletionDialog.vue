<script setup lang="ts">
import { computed } from "vue";
import type { RecommendationDeliveryChannel } from "~/types";

const props = defineProps<{
  customerName: string;
  deliveryChannel: RecommendationDeliveryChannel;
  busy: boolean;
  pendingChoice: boolean | null;
  error?: string;
}>();

const emit = defineEmits<{
  confirm: [requestRecommendation: boolean];
}>();

const open = defineModel<boolean>("open", { required: true });

const deliveryCopy = computed(() =>
  props.deliveryChannel === "email"
    ? `Se você solicitar uma avaliação, enviaremos o convite por e-mail para ${props.customerName} assim que a conclusão for registrada.`
    : `Se você solicitar uma avaliação, abriremos o WhatsApp com uma mensagem pronta para ${props.customerName}.`,
);

const busyReason = computed(() =>
  props.busy ? "Aguarde a conclusão do serviço terminar." : null,
);

function close() {
  if (props.busy) return;
  open.value = false;
}
</script>

<template>
  <UModal
    v-model:open="open"
    title="Concluir serviço"
    description="Esta ação não pode ser desfeita."
    :dismissible="!busy"
    :close="!busy"
  >
    <template #body>
      <div class="completion-dialog__body">
        <p>Confirme apenas se o trabalho já terminou.</p>
        <p>{{ deliveryCopy }}</p>
        <p v-if="error" class="completion-dialog__error" role="alert">
          {{ error }}
        </p>
      </div>
    </template>

    <template #footer>
      <div class="completion-dialog__actions">
        <DesignSystemDisabledTooltip :reason="busyReason">
          <UButton
            color="neutral"
            variant="ghost"
            :disabled="busy"
            @click="close"
          >
            Cancelar
          </UButton>
        </DesignSystemDisabledTooltip>
        <DesignSystemDisabledTooltip
          :reason="busyReason"
          :loading="busy && pendingChoice === false"
        >
          <UButton
            color="neutral"
            variant="outline"
            :loading="busy && pendingChoice === false"
            :disabled="busy"
            @click="emit('confirm', false)"
          >
            Concluir sem solicitar avaliação
          </UButton>
        </DesignSystemDisabledTooltip>
        <DesignSystemDisabledTooltip
          :reason="busyReason"
          :loading="busy && pendingChoice === true"
        >
          <UButton
            color="primary"
            icon="i-lucide-check"
            :loading="busy && pendingChoice === true"
            :disabled="busy"
            @click="emit('confirm', true)"
          >
            Concluir e solicitar avaliação
          </UButton>
        </DesignSystemDisabledTooltip>
      </div>
    </template>
  </UModal>
</template>

<style scoped lang="scss">
.completion-dialog {
  &__body {
    display: grid;
    gap: 10px;
  }

  &__body p {
    margin: 0;
    color: var(--color-text-muted);
    line-height: 1.55;
  }

  &__error {
    padding: 10px 12px;
    border-radius: 10px;
    background: var(--color-error-tint);
    color: var(--color-error) !important;
  }

  &__actions {
    display: flex;
    flex-wrap: wrap;
    justify-content: flex-end;
    gap: 8px;
    width: 100%;
  }
}

@media (width <= 680px) {
  .completion-dialog__actions {
    display: grid;
    grid-template-columns: 1fr;
  }

  .completion-dialog__actions :deep(button) {
    justify-content: center;
    width: 100%;
  }
}
</style>
