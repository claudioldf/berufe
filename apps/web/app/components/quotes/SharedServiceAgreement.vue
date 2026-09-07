<script setup lang="ts">
import { reactive } from "vue";
import type { QuoteServiceJob, ServiceAdjustment } from "~/types";

defineProps<{
  serviceJob: QuoteServiceJob;
  actingAdjustmentId: string | null;
  actionError?: string;
}>();

const emit = defineEmits<{
  decide: [
    adjustment: ServiceAdjustment,
    kind: "approve" | "request_change" | "decline",
    message: string,
    termsAccepted: boolean,
  ];
  viewReceipt: [receiptId: string];
}>();

const responses = reactive<
  Record<
    string,
    {
      message: string;
      termsAccepted: boolean;
      messageError: string;
      termsError: string;
    }
  >
>({});
const money = new Intl.NumberFormat("pt-BR", {
  style: "currency",
  currency: "BRL",
});
const kindLabels: Record<ServiceAdjustment["items"][number]["kind"], string> = {
  additional_service: "Serviço adicional",
  material_charge: "Material fornecido pelo profissional",
  material_reimbursement: "Compra e reembolso de material",
  credit: "Crédito para você",
};
const statusLabels: Record<ServiceAdjustment["status"], string> = {
  draft: "Rascunho",
  awaiting_response: "Aguardando sua resposta",
  change_requested: "Alteração solicitada",
  approved: "Aprovado",
  declined: "Recusado",
  cancelled: "Cancelado",
};

function formatScheduleImpact(value: string) {
  const trimmed = value.trim();
  if (!/^\d+(?:[.,]\d+)?$/.test(trimmed)) return trimmed;

  const amount = Number(trimmed.replace(",", "."));
  return `${trimmed} ${amount === 1 ? "dia a mais" : "dias a mais"}`;
}

function responseFor(id: string) {
  return (responses[id] ??= {
    message: "",
    termsAccepted: false,
    messageError: "",
    termsError: "",
  });
}

function decide(
  adjustment: ServiceAdjustment,
  kind: "approve" | "request_change" | "decline",
) {
  const response = responseFor(adjustment.id);
  response.messageError = "";
  response.termsError = "";
  if (kind === "request_change" && !response.message.trim()) {
    response.messageError = "Explique o que precisa ser alterado.";
  }
  if (kind === "approve" && !response.termsAccepted) {
    response.termsError = "Confirme que revisou este ajuste.";
  }
  if (response.messageError || response.termsError) return;
  emit(
    "decide",
    adjustment,
    kind,
    response.message,
    kind === "approve" && response.termsAccepted,
  );
}
</script>

<template>
  <section
    class="shared-agreement"
    aria-labelledby="shared-service-agreement-title"
  >
    <header class="shared-agreement__header">
      <div>
        <DesignSystemEyebrow>Acordo atual do serviço</DesignSystemEyebrow>
        <h2 id="shared-service-agreement-title">O que está combinado agora</h2>
        <p>
          O orçamento original não muda. Somente ajustes aprovados entram no
          total combinado abaixo.
        </p>
      </div>
    </header>

    <div v-if="serviceJob.adjustments?.length" class="shared-agreement__list">
      <article
        v-for="adjustment in serviceJob.adjustments"
        :id="`ajuste-${adjustment.id}`"
        :key="adjustment.id"
        class="shared-agreement__adjustment"
        :class="{
          'shared-agreement__adjustment--pending':
            adjustment.status === 'awaiting_response',
        }"
      >
        <div class="shared-agreement__adjustment-heading">
          <div>
            <span
              >Ajuste #{{ adjustment.number }} ·
              {{ statusLabels[adjustment.status] }}</span
            >
            <h3>{{ adjustment.title }}</h3>
          </div>
        </div>
        <p v-if="adjustment.description">{{ adjustment.description }}</p>
        <p v-if="adjustment.scheduleImpact" class="shared-agreement__impact">
          <UIcon
            class="shared-agreement__message-icon"
            name="i-lucide-calendar-clock"
            aria-hidden="true"
          />
          <span>
            Impacto no prazo:
            {{ formatScheduleImpact(adjustment.scheduleImpact) }}
          </span>
        </p>
        <p v-if="adjustment.incurredOn" class="shared-agreement__incurred">
          <UIcon
            class="shared-agreement__message-icon"
            name="i-lucide-triangle-alert"
            aria-hidden="true"
          />
          <span>
            Este gasto ou trabalho foi informado como já realizado em
            {{
              new Date(`${adjustment.incurredOn}T12:00:00`).toLocaleDateString(
                "pt-BR",
              )
            }}. Mesmo assim, o valor só entra no total combinado se você
            aprovar.
          </span>
        </p>

        <ul v-if="adjustment.items.length" class="shared-agreement__items">
          <li v-for="item in adjustment.items" :key="item.id">
            <div>
              <span>{{ kindLabels[item.kind] }}</span>
              <strong>{{ item.description }}</strong>
              <small
                >{{ item.quantity }} {{ item.unit }} ×
                {{ money.format(item.unitPrice) }}</small
              >
            </div>
            <div class="shared-agreement__item-value">
              <strong>{{ money.format(item.lineTotal) }}</strong>
              <template v-if="item.kind === 'material_reimbursement'">
                <UButton
                  v-if="item.receipt"
                  color="neutral"
                  variant="link"
                  size="xs"
                  icon="i-lucide-receipt-text"
                  @click="emit('viewReceipt', item.receipt.id)"
                >
                  Ver comprovante
                </UButton>
                <small v-else>Comprovante não anexado</small>
              </template>
            </div>
          </li>
        </ul>
        <p v-else class="shared-agreement__zero">
          Este ajuste documenta escopo ou prazo e não possui itens financeiros.
        </p>

        <div class="shared-agreement__adjustment-total">
          <span>Total do ajuste</span>
          <strong>{{ money.format(adjustment.total) }}</strong>
        </div>

        <div
          v-if="adjustment.status === 'awaiting_response'"
          class="shared-agreement__decision"
        >
          <label>
            Mensagem para o profissional (obrigatória para solicitar alterações)
            <textarea
              v-model="responseFor(adjustment.id).message"
              rows="3"
              maxlength="700"
              placeholder="Explique o que gostaria de alterar"
            />
            <small v-if="responseFor(adjustment.id).messageError" role="alert">
              {{ responseFor(adjustment.id).messageError }}
            </small>
          </label>
          <label class="shared-agreement__check">
            <input
              v-model="responseFor(adjustment.id).termsAccepted"
              type="checkbox"
            />
            <span>
              Revisei o escopo, os itens, o valor e eventual impacto no prazo
              deste ajuste.
            </span>
          </label>
          <small v-if="responseFor(adjustment.id).termsError" role="alert">
            {{ responseFor(adjustment.id).termsError }}
          </small>
          <p
            v-if="actionError && actingAdjustmentId === adjustment.id"
            role="alert"
          >
            {{ actionError }}
          </p>
          <div class="shared-agreement__actions">
            <UButton
              color="error"
              variant="ghost"
              :disabled="Boolean(actingAdjustmentId)"
              @click="decide(adjustment, 'decline')"
            >
              Recusar
            </UButton>
            <UButton
              color="neutral"
              variant="outline"
              :disabled="Boolean(actingAdjustmentId)"
              @click="decide(adjustment, 'request_change')"
            >
              Solicitar alteração
            </UButton>
            <UButton
              color="primary"
              icon="i-lucide-circle-check"
              :loading="actingAdjustmentId === adjustment.id"
              :disabled="Boolean(actingAdjustmentId)"
              @click="decide(adjustment, 'approve')"
            >
              Aprovar ajuste
            </UButton>
          </div>
        </div>

        <p
          v-else-if="adjustment.status === 'change_requested'"
          class="shared-agreement__resolved"
        >
          Você solicitou uma alteração. O profissional pode editar e reenviar
          uma nova revisão neste mesmo link.
        </p>
        <p
          v-else-if="adjustment.status === 'approved'"
          class="shared-agreement__resolved shared-agreement__resolved--approved"
        >
          Aprovado e incluído no total combinado.
        </p>
        <p v-else class="shared-agreement__resolved">
          Este ajuste foi
          {{ adjustment.status === "declined" ? "recusado" : "cancelado" }}
          e não entra no total combinado.
        </p>
      </article>
    </div>

    <footer class="shared-agreement__summary">
      <dl class="shared-agreement__totals">
        <div>
          <dt>Orçamento original</dt>
          <dd>{{ money.format(serviceJob.originalTotal ?? 0) }}</dd>
        </div>
        <div v-if="(serviceJob.approvedAdjustmentTotal ?? 0) > 0">
          <dt>Ajustes aprovados</dt>
          <dd>{{ money.format(serviceJob.approvedAdjustmentTotal ?? 0) }}</dd>
        </div>
        <div v-if="serviceJob.awaitingDecisionTotal">
          <dt>Aguardando sua resposta</dt>
          <dd>{{ money.format(serviceJob.awaitingDecisionTotal) }}</dd>
        </div>
      </dl>
      <div class="shared-agreement__agreed-total">
        <span>Total combinado</span>
        <strong>{{ money.format(serviceJob.agreedTotal ?? 0) }}</strong>
      </div>
    </footer>
  </section>
</template>

<style scoped lang="scss">
.shared-agreement {
  margin-top: 20px;
  padding: 22px;
  border: 1px solid var(--line);
  border-radius: 18px;
  background: white;
  box-shadow: var(--shadow-sm);

  &__header,
  &__adjustment-heading,
  &__actions,
  &__items li {
    display: flex;
    justify-content: space-between;
    gap: 16px;
  }

  h2,
  h3,
  p,
  dl {
    margin: 0;
  }

  h2 {
    margin-top: 4px;
    font-family: var(--font-display);
    font-size: 1.55rem;
    font-weight: 600;
    line-height: 1.2;
    text-wrap: balance;
  }

  &__header p {
    margin-top: 6px;
    color: var(--ink-soft);
    font-size: 0.85rem;
  }

  &__totals {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 8px;
  }

  &__totals div {
    padding: 11px;
    border-radius: 10px;
    background: var(--color-surface-subtle);
  }

  dt,
  &__items span {
    color: var(--ink-soft);
    font-size: 0.75rem;
  }

  &__adjustment-heading span {
    color: var(--ink-soft);
    font-size: 0.78rem;
    font-weight: 700;
  }

  dd {
    margin: 3px 0 0;
    font-weight: 750;
    font-variant-numeric: tabular-nums;
  }

  &__list {
    display: grid;
    gap: 14px;
    margin-top: 20px;
  }

  &__adjustment {
    scroll-margin-top: 20px;
    padding: 17px;
    border: 1px solid var(--line);
    border-radius: 14px;
  }

  &__adjustment--pending {
    border-color: rgb(18 98 93 / 35%);
    box-shadow:
      0 18px 44px rgb(23 53 47 / 18%),
      0 0 0 4px rgb(18 98 93 / 10%);
  }

  &__adjustment h3 {
    margin-top: 3px;
    font-size: 1.08rem;
    font-weight: 600;
    line-height: 1.35;
    text-wrap: balance;
  }

  &__adjustment > p {
    margin-top: 9px;
    color: var(--ink-soft);
    font-size: 0.875rem;
    line-height: 1.5;
  }

  &__impact,
  &__incurred {
    display: flex;
    align-items: flex-start;
    gap: 8px;
    padding: 9px 10px;
    border-radius: 9px;
    background: var(--color-surface-subtle);
  }

  &__incurred {
    background: var(--color-warning-tint, #fff5dd) !important;
    color: #7a4307 !important;
  }

  &__message-icon {
    flex: 0 0 auto;
    margin-top: 0.15em;
  }

  &__items {
    display: grid;
    gap: 8px;
    margin: 14px 0 0;
    padding: 0;
    list-style: none;
  }

  &__items li {
    align-items: center;
    padding: 10px 0;
    border-top: 1px solid var(--line);
  }

  &__items li > div:first-child,
  &__item-value {
    display: grid;
    gap: 2px;
  }

  &__item-value {
    justify-items: end;
  }

  &__items li > div:first-child > strong {
    font-size: 0.9375rem;
    font-weight: 650;
    line-height: 1.4;
  }

  &__item-value > strong {
    font-size: 0.9375rem;
    font-weight: 700;
    font-variant-numeric: tabular-nums;
  }

  &__adjustment-total {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    width: min(280px, 100%);
    margin: 12px 0 0 auto;
    padding-top: 10px;
    border-top: 2px solid var(--ink);
    font-size: 0.875rem;
    font-weight: 600;
  }

  &__adjustment-total strong {
    font-size: 1rem;
    font-weight: 750;
    font-variant-numeric: tabular-nums;
    white-space: nowrap;
  }

  &__item-value small,
  &__zero {
    color: var(--ink-soft);
    font-size: 0.75rem;
  }

  &__decision {
    display: grid;
    gap: 12px;
    margin-top: 16px;
    padding-top: 16px;
    border-top: 1px solid var(--line);
  }

  &__decision label:not(.shared-agreement__check) {
    display: grid;
    gap: 6px;
    color: var(--ink-soft);
    font-size: var(--font-size-min);
    font-weight: 700;
  }

  textarea {
    width: 100%;
    padding: 10px;
    border: 1px solid var(--line);
    border-radius: 9px;
    color: var(--ink);
    font: inherit;
    resize: vertical;
  }

  &__check {
    display: grid;
    grid-template-columns: 18px minmax(0, 1fr);
    align-items: start;
    column-gap: 10px;
    font-size: 0.875rem;
    line-height: 1.4;
  }

  &__check input {
    width: 18px;
    height: 18px;
    margin: 0.05em 0 0;
  }

  small[role="alert"],
  &__decision p {
    color: var(--color-danger);
    font-size: var(--font-size-min);
    font-weight: 700;
  }

  &__actions {
    justify-content: flex-end;
    flex-wrap: wrap;
  }

  &__resolved {
    font-weight: 750;
  }

  &__resolved--approved {
    color: var(--color-brand) !important;
  }

  &__summary {
    margin-top: 20px;
    padding-top: 16px;
    border-top: 1px solid var(--line);
  }

  &__agreed-total {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    margin-top: 12px;
    padding-top: 14px;
    border-top: 2px solid var(--ink);
  }

  &__agreed-total span {
    font-weight: 750;
  }

  &__agreed-total strong {
    color: var(--color-brand-strong);
    font-size: 1.45rem;
    font-variant-numeric: tabular-nums;
    white-space: nowrap;
  }
}

@media (width <= 600px) {
  .shared-agreement {
    &__header,
    &__adjustment-heading {
      align-items: flex-start;
      flex-direction: column;
    }

    &__totals {
      grid-template-columns: 1fr;
    }

    &__actions {
      display: grid;
    }

    &__actions :deep(button) {
      justify-content: center;
      width: 100%;
    }
  }
}
</style>
