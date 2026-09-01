<script setup lang="ts">
import { computed } from "vue";
import type { ServiceJobStatus } from "~/types";

const props = defineProps<{
  status: ServiceJobStatus;
  canComplete: boolean;
  canCancel: boolean;
  canRequestRecommendation: boolean;
  recommendationSentAt: string | null;
  acting: boolean;
}>();

const emit = defineEmits<{
  openComplete: [];
  requestRecommendation: [];
  openCancel: [];
}>();

const actionCopy = computed(() => {
  if (props.status === "completed") {
    return {
      label: "Tudo certo",
      title: "Serviço concluído",
      description:
        "Registrado como concluído por você. Este serviço já saiu da sua lista de trabalhos em andamento.",
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
      "Quando o trabalho terminar, confirme a conclusão e escolha se deseja solicitar uma avaliação ao cliente.",
    icon: "i-lucide-clipboard-check",
  };
});

const recommendationLabel = computed(() =>
  props.recommendationSentAt
    ? "Pedir a recomendação de novo pelo WhatsApp"
    : "Pedir a recomendação pelo WhatsApp",
);

const hasPrimaryActions = computed(
  () => props.canComplete || props.canRequestRecommendation,
);

const actingReason = computed(() =>
  props.acting ? "Aguarde a atualização do serviço terminar." : null,
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
      <DesignSystemDisabledTooltip v-if="canComplete" :reason="actingReason">
        <UButton
          block
          size="lg"
          color="primary"
          icon="i-lucide-circle-check-big"
          :disabled="acting"
          @click="emit('openComplete')"
        >
          Concluído
        </UButton>
      </DesignSystemDisabledTooltip>
      <UButton
        v-if="canRequestRecommendation"
        block
        size="lg"
        :color="recommendationSentAt ? 'neutral' : 'primary'"
        :variant="recommendationSentAt ? 'outline' : 'solid'"
        icon="i-lucide-message-circle"
        :loading="acting"
        @click="emit('requestRecommendation')"
      >
        {{ recommendationLabel }}
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
      <DesignSystemDisabledTooltip :reason="actingReason">
        <UButton
          color="neutral"
          variant="link"
          :disabled="acting"
          @click="emit('openCancel')"
        >
          Cancelar serviço
        </UButton>
      </DesignSystemDisabledTooltip>
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
