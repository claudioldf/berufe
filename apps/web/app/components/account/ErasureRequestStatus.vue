<script setup lang="ts">
import { computed } from "vue";
import type { DataErasureRequestStatus } from "~/services/api/professional-data-erasure";

const props = defineProps<{
  request: DataErasureRequestStatus;
  refreshing: boolean;
}>();

const emit = defineEmits<{ refresh: [] }>();

const statusContent = computed(() => {
  switch (props.request.status) {
    case "completed":
      return {
        label: "Exclusão concluída",
        description:
          "Os dados elegíveis da conta foram excluídos. Os registros mínimos pseudonimizados seguem a retenção legal informada.",
        icon: "i-lucide-circle-check",
        tone: "completed",
      };
    case "retrying":
      return {
        label: "Exclusão em nova tentativa",
        description:
          "Houve uma interrupção técnica, mas a conta continua despublicada e o processamento será tentado novamente.",
        icon: "i-lucide-shield-alert",
        tone: "retrying",
      };
    case "processing":
      return {
        label: "Exclusão em processamento",
        description:
          "A conta já está despublicada e os dados elegíveis estão sendo removidos.",
        icon: "i-lucide-clock-3",
        tone: "processing",
      };
    default:
      return {
        label: "Solicitação recebida",
        description:
          "O perfil e os links foram desativados. A exclusão dos dados elegíveis está na fila de processamento.",
        icon: "i-lucide-clock-3",
        tone: "requested",
      };
  }
});

function formatDateTime(value: string | null) {
  if (!value) return "—";
  return new Intl.DateTimeFormat("pt-BR", {
    dateStyle: "long",
    timeStyle: "short",
  }).format(new Date(value));
}
</script>

<template>
  <DesignSystemSurfaceCard
    as="section"
    class="erasure-status"
    :class="'erasure-status--' + statusContent.tone"
    aria-live="polite"
  >
    <div class="erasure-status__summary">
      <span><UIcon :name="statusContent.icon" aria-hidden="true" /></span>
      <div>
        <DesignSystemEyebrow>Protocolo de privacidade</DesignSystemEyebrow>
        <h1>{{ statusContent.label }}</h1>
        <p>{{ statusContent.description }}</p>
      </div>
    </div>

    <dl class="erasure-status__details">
      <div>
        <dt>Referência</dt>
        <dd>
          <code>{{ request.reference }}</code>
        </dd>
      </div>
      <div>
        <dt>Solicitada em</dt>
        <dd>{{ formatDateTime(request.requestedAt) }}</dd>
      </div>
      <div>
        <dt>Perfil despublicado em</dt>
        <dd>{{ formatDateTime(request.unpublishedAt) }}</dd>
      </div>
      <div>
        <dt>Prazo máximo informado</dt>
        <dd>{{ formatDateTime(request.completionDeadlineAt) }}</dd>
      </div>
      <div v-if="request.completedAt">
        <dt>Concluída em</dt>
        <dd>{{ formatDateTime(request.completedAt) }}</dd>
      </div>
    </dl>

    <div class="erasure-status__retention">
      <UIcon name="i-lucide-file-lock-2" aria-hidden="true" />
      <p>
        Nenhum identificador pessoal é exibido aqui. Registros mínimos
        pseudonimizados de aceite, consentimento, auditoria, fraude e defesa
        permanecem por cinco anos.
      </p>
    </div>

    <div class="erasure-status__actions">
      <UButton
        type="button"
        color="neutral"
        variant="outline"
        icon="i-lucide-refresh-cw"
        :loading="refreshing"
        @click="emit('refresh')"
      >
        Atualizar estado
      </UButton>
      <UButton to="/" color="primary" variant="soft">Ir para o início</UButton>
    </div>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.erasure-status {
  display: grid;
  gap: 28px;
  padding: clamp(24px, 5vw, 44px);

  &__summary {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 18px;
    align-items: start;
  }

  &__summary > span {
    display: grid;
    place-items: center;
    width: 54px;
    height: 54px;
    border-radius: 16px;
    background: var(--mint);
    color: var(--color-brand);
    font-size: 1.5rem;
  }

  &--retrying &__summary > span {
    background: color-mix(in srgb, var(--ui-warning) 14%, white);
    color: var(--ui-warning);
  }

  &__summary h1 {
    margin: 7px 0 10px;
    font-family: var(--font-display);
    font-size: clamp(2rem, 5vw, 3.5rem);
    font-weight: 550;
    letter-spacing: -0.045em;
    line-height: 1;
  }

  &__summary p,
  &__retention p {
    margin: 0;
    color: var(--ink-soft);
    line-height: 1.65;
  }

  &__details {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 1px;
    overflow: hidden;
    margin: 0;
    border: 1px solid var(--line);
    border-radius: var(--radius-md);
    background: var(--line);
  }

  &__details > div {
    min-width: 0;
    padding: 16px;
    background: white;
  }

  &__details dt {
    margin-bottom: 5px;
    color: var(--ink-soft);
    font-size: 0.78rem;
    font-weight: 800;
    text-transform: uppercase;
  }

  &__details dd {
    margin: 0;
    font-weight: 750;
  }

  &__details code {
    overflow-wrap: anywhere;
    font-size: 0.82rem;
  }

  &__retention {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 12px;
    padding: 17px;
    border-radius: var(--radius-md);
    background: var(--color-surface-warm);
  }

  &__retention svg {
    margin-top: 3px;
    color: var(--color-brand);
  }

  &__actions {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
  }
}

@media (width <= 620px) {
  .erasure-status {
    &__summary,
    &__details {
      grid-template-columns: 1fr;
    }

    &__actions {
      display: grid;
    }

    &__actions :deep(.u-button) {
      justify-content: center;
    }
  }
}
</style>
