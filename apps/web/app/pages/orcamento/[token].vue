<script setup lang="ts">
import { useAnalyticsEvent } from "~/composables/useAnalyticsEvent";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import {
  decideSharedQuote,
  resolveSharedQuote,
} from "~/services/api/shared-quotes";

definePageMeta({ layout: false });

const route = useRoute();
const client = useApiClient();
const { trackEvent } = useAnalyticsEvent();
const token = computed(() =>
  Array.isArray(route.params.token)
    ? (route.params.token[0] ?? "")
    : String(route.params.token ?? ""),
);
const resolved = await useAsyncData(
  "shared-quote-resolve",
  async () => {
    try {
      return {
        kind: "success" as const,
        value: await resolveSharedQuote(client, token.value),
      };
    } catch (error) {
      return {
        kind: "error" as const,
        notFound:
          error instanceof ApiRequestError && error.code === "not_found",
      };
    }
  },
  { watch: [token] },
);
const outcome = resolved.data.value;
if (!outcome || outcome.kind === "error") {
  throw createError({
    statusCode: outcome?.notFound ? 404 : 503,
    statusMessage: outcome?.notFound
      ? "Orçamento não encontrado"
      : "Orçamento temporariamente indisponível",
  });
}
const current = shallowRef(outcome.value);
const quote = computed(() => current.value.quote);
const professional = computed(() => current.value.professional);
const decisionMessage = shallowRef("");
const termsAccepted = shallowRef(false);
const submitting = shallowRef(false);
const submittingDecision = shallowRef<
  "approve" | "request_change" | "decline" | null
>(null);
const actionError = shallowRef("");
const decisionMessageError = shallowRef("");
const termsAcceptedError = shallowRef("");

useSeoMeta({
  title: `Orçamento #${quote.value.number}`,
  robots: "noindex, nofollow",
});

const DECISION_EVENT_NAMES = {
  approve: "quote_approved",
  decline: "quote_declined",
  request_change: "quote_change_requested",
} as const;

onMounted(() => {
  // Only the professional's own public service category travels here —
  // never the customer's name, phone, quote amount, or the page's token
  // (already redacted from all page-view URL fields by app/utils/analytics.ts).
  trackEvent("quote_viewed", {
    service: professional.value.primaryService,
  });
});

function printQuote() {
  if (import.meta.client) window.print();
}

function validateDecision(kind: "approve" | "request_change" | "decline") {
  decisionMessageError.value = "";
  termsAcceptedError.value = "";

  if (kind === "request_change" && !decisionMessage.value.trim()) {
    decisionMessageError.value = "Explique o que precisa ser alterado.";
  }
  if (kind === "approve" && !termsAccepted.value) {
    termsAcceptedError.value =
      "Confirme que você revisou o escopo, o valor e a validade.";
  }

  return !decisionMessageError.value && !termsAcceptedError.value;
}

watch(decisionMessage, (message) => {
  if (message.trim()) decisionMessageError.value = "";
});

watch(termsAccepted, (accepted) => {
  if (accepted) termsAcceptedError.value = "";
});

async function submitDecision(kind: "approve" | "request_change" | "decline") {
  if (submitting.value) return;
  actionError.value = "";
  if (!validateDecision(kind)) return;

  submitting.value = true;
  submittingDecision.value = kind;
  try {
    current.value = await decideSharedQuote(client, token.value, {
      kind,
      revision: quote.value.revision,
      termsAccepted: kind === "approve" && termsAccepted.value,
      message: decisionMessage.value,
    });
    trackEvent(DECISION_EVENT_NAMES[kind], {
      service: professional.value.primaryService,
    });
  } catch (error) {
    if (error instanceof ApiRequestError) {
      decisionMessageError.value = error.fieldErrors.message?.[0] ?? "";
      termsAcceptedError.value = error.fieldErrors.terms_accepted?.[0] ?? "";
      if (!decisionMessageError.value && !termsAcceptedError.value) {
        actionError.value = error.message;
      }
    } else {
      actionError.value =
        "Não foi possível registrar sua resposta. Tente novamente.";
    }
  } finally {
    submitting.value = false;
    submittingDecision.value = null;
  }
}
</script>

<template>
  <div class="shared-quote-page">
    <DesignSystemContainer as="header" class="shared-quote-page__header"
      ><DesignSystemBrand size="sm" />
      <div>
        <UIcon name="i-lucide-lock-keyhole" /> Link privado do orçamento
      </div></DesignSystemContainer
    >
    <DesignSystemContainer
      id="main-content"
      as="main"
      tabindex="-1"
      class="shared-quote-page__content"
    >
      <div class="shared-quote-page__heading">
        <div>
          <p>Olá, {{ quote.customerName }}.</p>
          <h1>Aqui está seu orçamento.</h1>
          <span>
            Revise o escopo, o valor e os materiais por sua conta. Converse
            diretamente com {{ professional.name.split(" ")[0] }} se tiver
            alguma dúvida.
          </span>
        </div>
        <UButton
          color="neutral"
          variant="outline"
          icon="i-lucide-printer"
          @click="printQuote"
          >Imprimir</UButton
        >
      </div>
      <QuotesQuotePreview
        :quote="quote"
        :professional="professional"
        customer-facing
        authoritative-totals
      />
      <section
        v-if="quote.status === 'shared'"
        class="shared-quote-page__action-card"
        aria-labelledby="quote-decision-title"
      >
        <div>
          <DesignSystemEyebrow>Próximo passo</DesignSystemEyebrow>
          <h2 id="quote-decision-title">Responda ao orçamento</h2>
          <p>
            Ao aprovar, você confirma que está de acordo com o escopo, o valor e
            os materiais por sua conta apresentados. Isso não substitui um
            contrato nem confirma pagamento.
          </p>
        </div>
        <label
          :class="{
            'shared-quote-page__field--invalid': decisionMessageError,
          }"
        >
          Mensagem para o profissional (obrigatória para solicitar alterações)
          <textarea
            v-model="decisionMessage"
            maxlength="700"
            rows="3"
            placeholder="Descreva o que você gostaria de alterar"
            :aria-invalid="Boolean(decisionMessageError)"
            :aria-describedby="
              decisionMessageError ? 'quote-decision-message-error' : undefined
            "
          />
          <small
            v-if="decisionMessageError"
            id="quote-decision-message-error"
            class="shared-quote-page__field-error"
            role="alert"
          >
            {{ decisionMessageError }}
          </small>
        </label>
        <div
          class="shared-quote-page__check-field"
          :class="{
            'shared-quote-page__check-field--invalid': termsAcceptedError,
          }"
        >
          <label class="shared-quote-page__check">
            <input
              v-model="termsAccepted"
              type="checkbox"
              :aria-invalid="Boolean(termsAcceptedError)"
              :aria-describedby="
                termsAcceptedError ? 'quote-terms-accepted-error' : undefined
              "
            />
            Revisei o escopo, o valor e a validade deste orçamento.
          </label>
          <small
            v-if="termsAcceptedError"
            id="quote-terms-accepted-error"
            class="shared-quote-page__field-error"
            role="alert"
          >
            {{ termsAcceptedError }}
          </small>
        </div>
        <p v-if="actionError" role="alert" class="shared-quote-page__error">
          {{ actionError }}
        </p>
        <div class="shared-quote-page__actions">
          <UButton
            class="shared-quote-page__decline"
            color="error"
            variant="ghost"
            :loading="submittingDecision === 'decline'"
            :disabled="submitting"
            @click="submitDecision('decline')"
            >Recusar</UButton
          >
          <UButton
            color="neutral"
            variant="outline"
            :loading="submittingDecision === 'request_change'"
            :disabled="submitting"
            @click="submitDecision('request_change')"
            >Solicitar alterações</UButton
          >
          <UButton
            color="primary"
            icon="i-lucide-circle-check"
            :loading="submittingDecision === 'approve'"
            :disabled="submitting"
            @click="submitDecision('approve')"
            >Aprovar orçamento</UButton
          >
        </div>
      </section>

      <section
        v-else-if="quote.status === 'change_requested'"
        class="shared-quote-page__state-card"
      >
        <UIcon name="i-lucide-message-square-text" />
        <div>
          <h2>Solicitação enviada</h2>
          <p>
            O profissional recebeu sua mensagem. Quando uma nova versão for
            compartilhada, ela aparecerá neste mesmo link.
          </p>
        </div>
      </section>

      <section
        v-else-if="quote.status === 'declined'"
        class="shared-quote-page__state-card"
      >
        <UIcon name="i-lucide-circle-x" />
        <div>
          <h2>Orçamento recusado</h2>
          <p>Sua resposta foi registrada. O serviço não foi confirmado.</p>
        </div>
      </section>

      <section v-else class="shared-quote-page__state-card">
        <UIcon
          :name="
            quote.serviceJob?.status === 'completed'
              ? 'i-lucide-badge-check'
              : quote.serviceJob?.status === 'cancelled'
                ? 'i-lucide-ban'
                : 'i-lucide-clock-3'
          "
        />
        <div>
          <h2 v-if="quote.serviceJob?.status === 'completed'">
            Serviço concluído
          </h2>
          <h2 v-else-if="quote.serviceJob?.status === 'cancelled'">
            Serviço cancelado
          </h2>
          <h2 v-else>Orçamento aprovado</h2>
          <p v-if="quote.serviceJob?.status === 'completed'">
            Obrigado! Em breve você recebe um convite para contar como foi o
            serviço e, se quiser, recomendar o profissional.
          </p>
          <p v-else-if="quote.serviceJob?.status === 'cancelled'">
            Este serviço foi encerrado.
          </p>
          <p v-else>O profissional dará andamento ao serviço combinado.</p>
        </div>
      </section>
      <p class="shared-quote-page__notice">
        <UIcon name="i-lucide-info" /> Este link é privado. A aprovação registra
        sua decisão, mas não substitui um contrato nem confirma pagamento.
      </p>
    </DesignSystemContainer>
  </div>
</template>

<style scoped lang="scss">
.shared-quote-page {
  min-height: 100vh;
  padding-bottom: 70px;
  background: #eeeae1;
  &__header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    min-height: 70px;
  }
  &__header > div {
    display: flex;
    align-items: center;
    gap: 5px;
    color: var(--ink-soft);
    font-size: 0.84rem;
    font-weight: 750;
  }
  &__content {
    max-width: 760px;
  }
  &__heading {
    display: flex;
    justify-content: space-between;
    align-items: end;
    gap: 20px;
    margin: 42px 0 24px;
  }
  &__heading p {
    margin: 0 0 6px;
    color: var(--color-brand);
    font-size: 0.86rem;
    font-weight: 850;
  }
  &__heading h1 {
    margin: 0;
    font-family: var(--font-display);
    font-size: 2.5rem;
    font-weight: 500;
    letter-spacing: -0.04em;
  }
  &__heading span {
    display: block;
    max-width: 500px;
    margin-top: 7px;
    color: var(--ink-soft);
    font-size: 0.86rem;
    line-height: 1.5;
  }
  &__notice {
    display: flex;
    align-items: flex-start;
    justify-content: center;
    gap: 5px;
    margin: 16px 0 0;
    color: var(--ink-soft);
    font-size: 0.84rem;
    text-align: center;
  }
  &__action-card,
  &__state-card {
    margin-top: 20px;
    padding: 22px;
    border: 1px solid var(--line);
    border-radius: 18px;
    background: white;
    box-shadow: var(--shadow-sm);
  }
  &__action-card {
    display: grid;
    gap: 16px;
  }
  &__action-card h2,
  &__state-card h2 {
    margin: 4px 0 0;
    font-family: var(--font-display);
    font-size: 1.45rem;
  }
  &__action-card p,
  &__state-card p {
    margin: 6px 0 0;
    color: var(--ink-soft);
    font-size: 0.86rem;
    line-height: 1.5;
  }
  &__action-card label:not(&__check) {
    display: grid;
    gap: 7px;
    color: var(--ink-soft);
    font-size: 0.82rem;
    font-weight: 800;
  }
  &__action-card textarea {
    width: 100%;
    padding: 11px;
    border: 1px solid var(--line);
    border-radius: 10px;
    resize: vertical;
    color: var(--ink);
    font: inherit;
  }
  &__field--invalid textarea {
    border-color: var(--color-danger);
    background: var(--color-danger-tint);
  }
  &__field-error {
    color: var(--color-danger);
    font-size: 0.78rem;
    font-weight: 750;
    line-height: 1.4;
  }
  &__check-field {
    display: grid;
    gap: 6px;
    width: fit-content;
    padding: 9px 10px;
    border: 1px solid transparent;
    border-radius: 10px;
  }
  &__check-field--invalid {
    border-color: var(--color-danger);
    background: var(--color-danger-tint);
  }
  &__check {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 0.84rem;
  }
  &__check input {
    flex: 0 0 auto;
    margin: 0;
  }
  &__actions {
    display: flex;
    justify-content: flex-end;
    gap: 8px;
    flex-wrap: wrap;
  }
  &__decline {
    margin-right: auto;
  }
  &__error {
    color: var(--color-danger) !important;
    font-weight: 800;
  }
  &__state-card {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 12px;
  }
  &__state-card > svg {
    color: var(--color-brand);
    font-size: 1.5rem;
  }
}
@media (width <= 600px) {
  .shared-quote-page {
    &__heading {
      display: grid;
    }
    &__heading h1 {
      font-size: 2rem;
    }
  }
}
@media print {
  .shared-quote-page {
    &__header,
    &__heading,
    &__notice {
      display: none;
    }
    padding: 0;
    background: white;
    &__content {
      width: 100%;
      max-width: none;
    }
  }
}
</style>
