<script setup lang="ts">
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import {
  decideSharedQuote,
  resolveSharedQuote,
  respondToSharedQuoteCompletion,
} from "~/services/api/shared-quotes";

definePageMeta({ layout: false });

const route = useRoute();
const client = useApiClient();
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
const completionIssueMessage = shallowRef("");
const submitting = shallowRef(false);
const actionError = shallowRef("");

useSeoMeta({
  title: `Orçamento #${quote.value.number}`,
  robots: "noindex, nofollow",
});

function printQuote() {
  if (import.meta.client) window.print();
}

async function submitDecision(kind: "approve" | "request_change" | "decline") {
  if (submitting.value) return;
  submitting.value = true;
  actionError.value = "";
  try {
    current.value = await decideSharedQuote(client, token.value, {
      kind,
      revision: quote.value.revision,
      termsAccepted: kind === "approve" && termsAccepted.value,
      message: decisionMessage.value,
    });
  } catch (error) {
    actionError.value =
      error instanceof ApiRequestError
        ? error.message
        : "Não foi possível registrar sua resposta. Tente novamente.";
  } finally {
    submitting.value = false;
  }
}

async function submitCompletion(kind: "confirm" | "report_issue") {
  if (submitting.value) return;
  submitting.value = true;
  actionError.value = "";
  try {
    current.value = await respondToSharedQuoteCompletion(client, token.value, {
      kind,
      message: completionIssueMessage.value,
    });
  } catch (error) {
    actionError.value =
      error instanceof ApiRequestError
        ? error.message
        : "Não foi possível registrar sua resposta. Tente novamente.";
  } finally {
    submitting.value = false;
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
          <span
            >Revise os itens e converse diretamente com
            {{ professional.name.split(" ")[0] }} se tiver alguma dúvida.</span
          >
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
            A aprovação confirma que você quer seguir com este escopo e valor.
            Ela não é assinatura jurídica nem pagamento.
          </p>
        </div>
        <label>
          Mensagem para o profissional (obrigatória ao pedir alteração)
          <textarea
            v-model="decisionMessage"
            maxlength="700"
            rows="3"
            placeholder="Descreva o ajuste que você precisa"
          />
        </label>
        <label class="shared-quote-page__check">
          <input v-model="termsAccepted" type="checkbox" />
          Li o escopo, o valor e a validade deste orçamento.
        </label>
        <p v-if="actionError" role="alert" class="shared-quote-page__error">
          {{ actionError }}
        </p>
        <div class="shared-quote-page__actions">
          <UButton
            color="neutral"
            variant="outline"
            :disabled="submitting || !decisionMessage.trim()"
            @click="submitDecision('request_change')"
            >Pedir alteração</UButton
          >
          <UButton
            color="neutral"
            variant="ghost"
            :disabled="submitting"
            @click="submitDecision('decline')"
            >Recusar</UButton
          >
          <UButton
            color="primary"
            icon="i-lucide-circle-check"
            :loading="submitting"
            :disabled="!termsAccepted"
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
          <h2>Alteração solicitada</h2>
          <p>
            O profissional recebeu seu pedido. Este mesmo link mostrará o
            orçamento atualizado quando ele compartilhar novamente.
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
          <p>Sua resposta foi registrada. Nenhum serviço foi criado.</p>
        </div>
      </section>

      <section
        v-else-if="quote.serviceJob?.status === 'completion_requested'"
        class="shared-quote-page__action-card"
        aria-labelledby="completion-title"
      >
        <div>
          <DesignSystemEyebrow>Conclusão do serviço</DesignSystemEyebrow>
          <h2 id="completion-title">O serviço foi concluído?</h2>
          <p>
            Confirme apenas se o trabalho combinado foi finalizado. Se ainda
            houver algo a resolver, explique abaixo.
          </p>
        </div>
        <label>
          O que ainda precisa ser resolvido?
          <textarea v-model="completionIssueMessage" maxlength="700" rows="3" />
        </label>
        <p v-if="actionError" role="alert" class="shared-quote-page__error">
          {{ actionError }}
        </p>
        <div class="shared-quote-page__actions">
          <UButton
            color="neutral"
            variant="outline"
            :disabled="submitting || !completionIssueMessage.trim()"
            @click="submitCompletion('report_issue')"
            >Ainda há um problema</UButton
          >
          <UButton
            color="primary"
            icon="i-lucide-badge-check"
            :loading="submitting"
            @click="submitCompletion('confirm')"
            >Confirmar conclusão</UButton
          >
        </div>
      </section>

      <section v-else class="shared-quote-page__state-card">
        <UIcon
          :name="
            quote.serviceJob?.status === 'completed'
              ? 'i-lucide-badge-check'
              : quote.serviceJob?.status === 'completion_issue'
                ? 'i-lucide-message-circle-warning'
                : quote.serviceJob?.status === 'cancelled'
                  ? 'i-lucide-ban'
                  : 'i-lucide-clock-3'
          "
        />
        <div>
          <h2 v-if="quote.serviceJob?.status === 'completed'">
            Conclusão confirmada
          </h2>
          <h2 v-else-if="quote.serviceJob?.status === 'completion_issue'">
            Pendência registrada
          </h2>
          <h2 v-else-if="quote.serviceJob?.status === 'cancelled'">
            Serviço cancelado
          </h2>
          <h2 v-else>Orçamento aprovado</h2>
          <p v-if="quote.serviceJob?.status === 'completed'">
            Obrigado. Se houver um e-mail neste orçamento, enviaremos por lá um
            convite pessoal para recomendar o profissional.
          </p>
          <p v-else-if="quote.serviceJob?.status === 'completion_issue'">
            O profissional poderá resolver a pendência e solicitar uma nova
            confirmação neste mesmo link.
          </p>
          <p v-else-if="quote.serviceJob?.status === 'cancelled'">
            Este serviço foi encerrado sem confirmação de conclusão.
          </p>
          <p v-else>
            O profissional dará andamento ao serviço e usará este mesmo link
            para pedir a confirmação de conclusão.
          </p>
        </div>
      </section>
      <p class="shared-quote-page__notice">
        <UIcon name="i-lucide-info" /> Este link é privado. A aprovação registra
        sua decisão, mas não representa assinatura jurídica ou pagamento.
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
