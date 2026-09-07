<script setup lang="ts">
import { computed } from "vue";
import type { ProfessionalServiceJob, ServiceAdjustment } from "~/types";

const props = defineProps<{
  service: ProfessionalServiceJob;
  actingAdjustmentId?: string | null;
}>();

const emit = defineEmits<{
  share: [adjustment: ServiceAdjustment, method: "copy" | "whatsapp"];
  cancel: [adjustment: ServiceAdjustment];
}>();

const money = new Intl.NumberFormat("pt-BR", {
  style: "currency",
  currency: "BRL",
});
const canCreate = computed(() => props.service.status === "approved");
const adjustments = computed(() => props.service.adjustments ?? []);

const statusCopy: Record<
  ServiceAdjustment["status"],
  { label: string; tone: "neutral" | "warning" | "success" | "error" }
> = {
  draft: { label: "Rascunho", tone: "neutral" },
  awaiting_response: { label: "Aguardando cliente", tone: "warning" },
  change_requested: { label: "Alteração solicitada", tone: "warning" },
  approved: { label: "Aprovado", tone: "success" },
  declined: { label: "Recusado", tone: "error" },
  cancelled: { label: "Cancelado", tone: "neutral" },
};

function editable(adjustment: ServiceAdjustment) {
  return ["draft", "awaiting_response", "change_requested"].includes(
    adjustment.status,
  );
}
</script>

<template>
  <DesignSystemSurfaceCard
    as="section"
    class="adjustment-ledger"
    aria-labelledby="service-adjustments-title"
  >
    <header class="adjustment-ledger__header">
      <div>
        <DesignSystemEyebrow>Acordo do serviço</DesignSystemEyebrow>
        <h2 id="service-adjustments-title">Ajustes de escopo e valor</h2>
        <p>
          Registre extras, materiais, reembolsos ou créditos sem alterar o
          orçamento que já foi aprovado.
        </p>
      </div>
      <UButton
        v-if="canCreate"
        :to="`/app/professional/services/${service.id}/adjustments/new`"
        icon="i-lucide-plus"
      >
        Novo ajuste
      </UButton>
    </header>

    <dl class="adjustment-ledger__totals">
      <div>
        <dt>Orçamento original</dt>
        <dd>
          {{ money.format(service.originalTotal ?? service.quote.total) }}
        </dd>
      </div>
      <div>
        <dt>Ajustes aprovados</dt>
        <dd>{{ money.format(service.approvedAdjustmentTotal ?? 0) }}</dd>
      </div>
      <div class="adjustment-ledger__agreed">
        <dt>Total combinado</dt>
        <dd>{{ money.format(service.agreedTotal ?? service.quote.total) }}</dd>
      </div>
    </dl>

    <p
      v-if="(service.awaitingDecisionTotal ?? 0) !== 0"
      class="adjustment-ledger__pending-total"
    >
      {{ money.format(service.awaitingDecisionTotal ?? 0) }} aguardando resposta
      — ainda fora do total combinado.
    </p>

    <div v-if="adjustments.length" class="adjustment-ledger__list">
      <article
        v-for="adjustment in adjustments"
        :key="adjustment.id"
        class="adjustment-ledger__item"
      >
        <div class="adjustment-ledger__item-heading">
          <div>
            <span>Ajuste #{{ adjustment.number }}</span>
            <h3>{{ adjustment.title }}</h3>
          </div>
          <div class="adjustment-ledger__item-meta">
            <UBadge
              :color="statusCopy[adjustment.status].tone"
              variant="subtle"
            >
              {{ statusCopy[adjustment.status].label }}
            </UBadge>
            <strong>{{ money.format(adjustment.total) }}</strong>
          </div>
        </div>
        <p v-if="adjustment.description">{{ adjustment.description }}</p>
        <p v-if="adjustment.incurredOn" class="adjustment-ledger__warning">
          <UIcon name="i-lucide-triangle-alert" /> Despesa já realizada em
          {{
            new Date(`${adjustment.incurredOn}T12:00:00`).toLocaleDateString(
              "pt-BR",
            )
          }}.
        </p>
        <p
          v-if="adjustment.status === 'change_requested'"
          class="adjustment-ledger__request"
        >
          “{{ adjustment.changeRequests[0]?.message }}”
        </p>
        <div v-if="editable(adjustment)" class="adjustment-ledger__actions">
          <UButton
            :to="`/app/professional/services/${service.id}/adjustments/new?adjustment=${adjustment.id}`"
            color="neutral"
            variant="outline"
            size="sm"
          >
            Editar
          </UButton>
          <UButton
            color="neutral"
            variant="outline"
            size="sm"
            icon="i-lucide-copy"
            :loading="actingAdjustmentId === adjustment.id"
            @click="emit('share', adjustment, 'copy')"
          >
            {{
              adjustment.status === "awaiting_response"
                ? "Reenviar"
                : "Salvar e copiar link"
            }}
          </UButton>
          <UButton
            color="primary"
            variant="soft"
            size="sm"
            icon="i-lucide-message-circle"
            :loading="actingAdjustmentId === adjustment.id"
            @click="emit('share', adjustment, 'whatsapp')"
          >
            WhatsApp
          </UButton>
          <UButton
            color="error"
            variant="ghost"
            size="sm"
            @click="emit('cancel', adjustment)"
          >
            Cancelar ajuste
          </UButton>
        </div>
      </article>
    </div>
    <div v-else class="adjustment-ledger__empty">
      <UIcon name="i-lucide-file-plus-2" />
      <p>
        Nenhum ajuste registrado. O total combinado ainda é o orçamento
        original.
      </p>
    </div>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.adjustment-ledger {
  padding: 26px;

  &__header,
  &__item-heading,
  &__actions {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 16px;
  }

  h2,
  h3,
  p {
    margin: 0;
  }

  h2 {
    margin-top: 4px;
    font-family: var(--font-display);
    font-size: 1.6rem;
  }

  &__header p {
    max-width: 610px;
    margin-top: 7px;
    color: var(--ink-soft);
    line-height: 1.5;
  }

  &__totals {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 10px;
    margin: 22px 0 0;
  }

  &__totals div {
    padding: 14px;
    border-radius: 12px;
    background: var(--color-surface-subtle);
  }

  dt {
    color: var(--ink-soft);
    font-size: 0.76rem;
  }

  dd {
    margin: 5px 0 0;
    font-size: 1.05rem;
    font-weight: 850;
  }

  &__agreed {
    background: var(--color-brand-tint) !important;
    color: var(--color-brand-strong);
  }

  &__pending-total,
  &__warning,
  &__request {
    margin-top: 10px !important;
    color: var(--color-warning-strong, #8a4b08);
    font-size: 0.82rem;
  }

  &__list {
    display: grid;
    gap: 12px;
    margin-top: 20px;
  }

  &__item {
    padding: 17px;
    border: 1px solid var(--line);
    border-radius: 14px;
  }

  &__item-heading span {
    color: var(--color-brand);
    font-size: 0.72rem;
    font-weight: 850;
    text-transform: uppercase;
  }

  &__item h3 {
    margin-top: 3px;
    font-size: 1rem;
  }

  &__item > p:not(.adjustment-ledger__warning, .adjustment-ledger__request) {
    margin-top: 8px;
    color: var(--ink-soft);
    font-size: 0.86rem;
  }

  &__item-meta {
    display: flex;
    align-items: center;
    gap: 10px;
    white-space: nowrap;
  }

  &__actions {
    justify-content: flex-start;
    flex-wrap: wrap;
    margin-top: 14px;
  }

  &__empty {
    display: flex;
    gap: 8px;
    margin-top: 20px;
    padding: 15px;
    border: 1px dashed var(--line);
    border-radius: 12px;
    color: var(--ink-soft);
  }
}

@media (width <= 640px) {
  .adjustment-ledger {
    padding: 20px;

    &__header,
    &__item-heading {
      align-items: stretch;
      flex-direction: column;
    }

    &__totals {
      grid-template-columns: 1fr;
    }

    &__item-meta {
      justify-content: space-between;
    }
  }
}
</style>
