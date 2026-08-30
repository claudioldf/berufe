<script setup lang="ts">
import { computed } from "vue";
import type { ServiceJobStatus } from "~/types";

const props = defineProps<{
  status: ServiceJobStatus;
  canRequestCompletion: boolean;
  canComplete: boolean;
  canCancel: boolean;
  acting: boolean;
  copyFallbackUrl: string;
}>();

const emit = defineEmits<{
  requestCompletion: [];
  copyFallback: [];
  openCancel: [];
  openComplete: [];
}>();

const actionCopy = computed(() => {
  if (props.status === "completion_requested") {
    return {
      label: "Aguardando retorno",
      title: "O cliente recebeu o pedido",
      description:
        "Você será avisado quando ele confirmar. Se preferir, também pode concluir por aqui.",
      icon: "i-lucide-send",
    };
  }
  if (props.status === "completion_issue") {
    return {
      label: "Próximo passo",
      title: "Resolva a pendência",
      description:
        "Alinhe o ponto indicado pelo cliente e envie uma nova solicitação quando estiver tudo certo.",
      icon: "i-lucide-circle-alert",
    };
  }
  if (props.status === "completed") {
    return {
      label: "Tudo certo",
      title: "Serviço finalizado",
      description:
        "A conclusão está registrada e este serviço já saiu da sua lista de trabalhos em andamento.",
      icon: "i-lucide-check-circle-2",
    };
  }
  if (props.status === "cancelled") {
    return {
      label: "Fluxo encerrado",
      title: "Serviço cancelado",
      description: "Não há novas ações disponíveis para este atendimento.",
      icon: "i-lucide-x",
    };
  }
  return {
    label: "Próximo passo",
    title: "Finalize com confiança",
    description:
      "Quando o trabalho terminar, envie um pedido rápido para o cliente confirmar a conclusão.",
    icon: "i-lucide-message-circle",
  };
});

const hasPrimaryActions = computed(
  () =>
    props.canRequestCompletion ||
    props.canComplete ||
    Boolean(props.copyFallbackUrl),
);
</script>

<template>
  <DesignSystemSurfaceCard
    as="aside"
    class="actions-card"
    aria-labelledby="service-actions-title"
  >
    <span class="actions-card__icon" aria-hidden="true">
      <UIcon :name="actionCopy.icon" />
    </span>
    <span class="actions-card__kicker">{{ actionCopy.label }}</span>
    <h2 id="service-actions-title">{{ actionCopy.title }}</h2>
    <p>{{ actionCopy.description }}</p>

    <div v-if="hasPrimaryActions" class="actions-card__buttons">
      <UButton
        v-if="canRequestCompletion"
        block
        size="lg"
        color="primary"
        icon="i-lucide-message-circle"
        :loading="acting"
        @click="emit('requestCompletion')"
      >
        Pedir confirmação de conclusão
      </UButton>
      <UButton
        v-if="canComplete"
        block
        size="lg"
        color="neutral"
        variant="outline"
        icon="i-lucide-circle-check-big"
        :disabled="acting"
        @click="emit('openComplete')"
      >
        Marcar como concluído
      </UButton>
      <UButton
        v-if="copyFallbackUrl"
        block
        color="neutral"
        variant="soft"
        icon="i-lucide-link"
        :disabled="acting"
        @click="emit('copyFallback')"
      >
        Copiar link como alternativa
      </UButton>
    </div>

    <div
      v-else
      class="actions-card__resolved"
      :class="{ 'actions-card__resolved--cancelled': status === 'cancelled' }"
    >
      <UIcon
        :name="
          status === 'cancelled' ? 'i-lucide-info' : 'i-lucide-shield-check'
        "
        aria-hidden="true"
      />
      <span>
        {{
          status === "cancelled"
            ? "Nenhuma ação necessária"
            : "Conclusão registrada com sucesso"
        }}
      </span>
    </div>

    <div v-if="canCancel" class="actions-card__cancel">
      <span>Precisa encerrar este atendimento?</span>
      <UButton
        color="neutral"
        variant="link"
        :disabled="acting"
        @click="emit('openCancel')"
      >
        Cancelar serviço
      </UButton>
    </div>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.actions-card {
  padding: 27px 26px 22px;
  background: #fbf8f1;

  &__icon {
    display: grid;
    place-items: center;
    width: 46px;
    height: 46px;
    margin-bottom: 22px;
    border-radius: 14px;
    background: var(--color-brand-strong);
    color: white;
    font-size: 1.15rem;
    box-shadow: 0 9px 20px rgb(23 53 47 / 18%);
  }

  &__kicker {
    color: var(--color-brand);
    font-size: 0.7rem;
    font-weight: 850;
    letter-spacing: 0.12em;
    text-transform: uppercase;
  }

  & h2 {
    margin: 5px 0 8px;
    font-family: var(--font-display);
    font-size: 1.75rem;
    font-weight: 600;
    letter-spacing: -0.035em;
    line-height: 1.05;
  }

  & > p {
    margin: 0;
    color: var(--ink-soft);
    font-size: 0.87rem;
    line-height: 1.55;
  }

  &__buttons {
    display: grid;
    gap: 9px;
    margin-top: 23px;
  }

  &__buttons :deep(button),
  &__buttons :deep(a) {
    justify-content: center;
    min-height: 43px;
  }

  &__resolved {
    display: flex;
    align-items: center;
    gap: 9px;
    margin-top: 23px;
    padding: 12px 13px;
    border-radius: 12px;
    background: var(--color-success-tint);
    color: var(--color-success);
    font-size: 0.78rem;
    font-weight: 800;
  }

  &__resolved--cancelled {
    background: var(--color-surface-muted);
    color: var(--color-text-muted);
  }

  &__cancel {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 12px;
    margin-top: 20px;
    padding-top: 17px;
    border-top: 1px solid var(--line);
  }

  &__cancel > span {
    color: var(--color-text-subtle);
    font-size: 0.7rem;
  }

  &__cancel :deep(button) {
    padding-right: 0;
    padding-left: 0;
    font-size: 0.76rem;
  }
}

@media (width <= 520px) {
  .actions-card {
    padding: 24px 20px 20px;
    border-radius: 18px;
  }
}
</style>
