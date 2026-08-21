<script setup lang="ts">
import { useShare } from "~/composables/useShare";
import { useToast } from "~/composables/useToast";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import {
  cancelProfessionalServiceJob,
  fetchProfessionalServiceJob,
  requestProfessionalServiceCompletion,
} from "~/services/api/professional-service-jobs";
import { formatCurrency, formatDate } from "~/utils/formatters";

definePageMeta({ layout: "workspace" });
useSeoMeta({ title: "Detalhes do serviço", robots: "noindex, nofollow" });

const route = useRoute();
const client = useApiClient();
const { copyText } = useShare();
const { showToast } = useToast();
const id = computed(() =>
  Array.isArray(route.params.id)
    ? (route.params.id[0] ?? "")
    : String(route.params.id ?? ""),
);
const loaded = await useAsyncData(`professional-service-job-${id.value}`, () =>
  fetchProfessionalServiceJob(client, id.value),
);
const service = shallowRef(loaded.data.value ?? null);
const acting = shallowRef(false);
const actionError = shallowRef("");
const copyFallbackUrl = shallowRef("");
const cancelOpen = shallowRef(false);
const cancellationReason = shallowRef("");

const statusCopy = computed(() => {
  const status = service.value?.status;
  if (status === "completion_requested")
    return ["Aguardando confirmação", "O cliente recebeu o link de conclusão."];
  if (status === "completion_issue")
    return [
      "Pendência informada",
      "Resolva o ponto indicado e solicite novamente.",
    ];
  if (status === "completed")
    return ["Serviço concluído", "A conclusão foi confirmada pelo cliente."];
  if (status === "cancelled")
    return ["Serviço cancelado", "Este fluxo foi encerrado."];
  return [
    "Serviço aprovado",
    "Quando terminar, peça a confirmação do cliente.",
  ];
});
const canRequestCompletion = computed(
  () =>
    service.value?.status === "approved" ||
    service.value?.status === "completion_issue",
);
const canCancel = computed(
  () =>
    service.value && !["completed", "cancelled"].includes(service.value.status),
);

async function requestCompletion() {
  if (!service.value || acting.value) return;
  const handoff = import.meta.client
    ? window.open("about:blank", "_blank")
    : null;
  if (handoff) handoff.opener = null;
  acting.value = true;
  actionError.value = "";
  copyFallbackUrl.value = "";
  try {
    const result = await requestProfessionalServiceCompletion(
      client,
      service.value.id,
    );
    service.value = result.serviceJob;
    copyFallbackUrl.value = result.shareUrl;
    if (handoff) handoff.location.replace(result.whatsappUrl);
    else if (import.meta.client) window.location.assign(result.whatsappUrl);
    showToast({
      title: "Abrindo o WhatsApp",
      description: "A mensagem já aponta para o telefone deste cliente.",
    });
  } catch (error) {
    handoff?.close();
    actionError.value =
      error instanceof ApiRequestError
        ? error.message
        : "Não foi possível solicitar a confirmação.";
  } finally {
    acting.value = false;
  }
}

async function copyFallback() {
  if (!copyFallbackUrl.value) return;
  await copyText(copyFallbackUrl.value, "Link de conclusão copiado");
}

async function cancelService() {
  if (!service.value || acting.value) return;
  acting.value = true;
  actionError.value = "";
  try {
    service.value = await cancelProfessionalServiceJob(
      client,
      service.value.id,
      cancellationReason.value,
    );
    cancelOpen.value = false;
    showToast({
      title: "Serviço cancelado",
      description: "O fluxo de conclusão foi encerrado.",
    });
  } catch (error) {
    actionError.value =
      error instanceof ApiRequestError
        ? error.message
        : "Não foi possível cancelar o serviço.";
  } finally {
    acting.value = false;
  }
}
</script>

<template>
  <div class="service-page">
    <DesignSystemContainer as="main" class="service-page__content">
      <NuxtLink to="/app/professional/services" class="service-page__back">
        <UIcon name="i-lucide-arrow-left" /> Todos os serviços
      </NuxtLink>
      <p v-if="loaded.status.value === 'pending'" aria-live="polite">
        Carregando serviço…
      </p>
      <p v-else-if="loaded.error.value || !service" role="alert">
        Não foi possível carregar este serviço.
      </p>
      <template v-else>
        <header class="service-page__heading">
          <div>
            <DesignSystemEyebrow
              >Orçamento #{{ service.quote.number }}</DesignSystemEyebrow
            >
            <h1>{{ service.quote.serviceDescription }}</h1>
            <p>
              {{ service.quote.customerName }} ·
              {{ service.quote.customerPhone }}
            </p>
          </div>
          <strong>{{ formatCurrency(service.quote.total) }}</strong>
        </header>

        <div class="service-page__grid">
          <DesignSystemSurfaceCard class="service-page__status">
            <span><UIcon name="i-lucide-clipboard-check" /></span>
            <div>
              <h2>{{ statusCopy[0] }}</h2>
              <p>{{ statusCopy[1] }}</p>
              <blockquote v-if="service.completionIssueMessage">
                “{{ service.completionIssueMessage }}”
              </blockquote>
            </div>
          </DesignSystemSurfaceCard>

          <DesignSystemSurfaceCard class="service-page__details">
            <h2>Dados combinados</h2>
            <dl>
              <div>
                <dt>Data</dt>
                <dd>
                  {{
                    service.quote.scheduledOn
                      ? formatDate(service.quote.scheduledOn)
                      : "Não informada"
                  }}
                </dd>
              </div>
              <div>
                <dt>Endereço</dt>
                <dd>{{ service.quote.serviceAddress || "Não informado" }}</dd>
              </div>
              <div>
                <dt>E-mail</dt>
                <dd>{{ service.quote.customerEmail || "Não informado" }}</dd>
              </div>
            </dl>
          </DesignSystemSurfaceCard>
        </div>

        <p v-if="actionError" class="service-page__error" role="alert">
          {{ actionError }}
        </p>
        <div class="service-page__actions">
          <UButton
            v-if="copyFallbackUrl"
            color="neutral"
            variant="outline"
            icon="i-lucide-link"
            @click="copyFallback"
            >Copiar link como alternativa</UButton
          >
          <UButton
            v-if="canCancel"
            color="neutral"
            variant="ghost"
            @click="cancelOpen = true"
            >Cancelar serviço</UButton
          >
          <UButton
            v-if="canRequestCompletion"
            color="primary"
            icon="i-lucide-message-circle"
            :loading="acting"
            @click="requestCompletion"
            >Pedir confirmação de conclusão</UButton
          >
        </div>
      </template>
    </DesignSystemContainer>

    <UModal
      v-model:open="cancelOpen"
      title="Cancelar serviço"
      description="A conclusão e a recomendação deixam de ficar disponíveis."
    >
      <template #body>
        <label class="service-page__cancel-field">
          Motivo (opcional)
          <textarea v-model="cancellationReason" rows="3" maxlength="700" />
        </label>
      </template>
      <template #footer>
        <UButton color="neutral" variant="ghost" @click="cancelOpen = false"
          >Voltar</UButton
        >
        <UButton color="error" :loading="acting" @click="cancelService"
          >Cancelar serviço</UButton
        >
      </template>
    </UModal>
  </div>
</template>

<style scoped lang="scss">
.service-page {
  min-height: 100vh;
  background: var(--color-surface-canvas);

  &__content {
    max-width: 940px;
    padding-top: 34px;
    padding-bottom: 80px;
  }

  &__back {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    margin-bottom: 28px;
    color: var(--color-brand);
    font-weight: 800;
    text-decoration: none;
  }

  &__heading {
    display: flex;
    justify-content: space-between;
    gap: 20px;
    align-items: end;
    margin-bottom: 24px;
  }

  &__heading h1 {
    margin: 5px 0;
    font-family: var(--font-display);
    font-size: 2.4rem;
    font-weight: 500;
  }

  &__heading p {
    margin: 0;
    color: var(--ink-soft);
  }

  &__heading > strong {
    font-size: 1.2rem;
  }

  &__grid {
    display: grid;
    grid-template-columns: 1.2fr 0.8fr;
    gap: 16px;
  }

  &__status,
  &__details {
    padding: 22px;
  }

  &__status {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 12px;
  }

  &__status > span {
    display: grid;
    place-items: center;
    width: 42px;
    height: 42px;
    border-radius: 12px;
    background: var(--color-brand-tint-muted);
    color: var(--color-brand);
  }

  & h2 {
    margin: 0;
    font-family: var(--font-display);
  }

  &__status p,
  &__details dt {
    color: var(--ink-soft);
  }

  &__status blockquote {
    margin: 14px 0 0;
    padding: 12px;
    border-left: 3px solid var(--coral);
    background: #fff7f4;
  }

  &__details dl {
    display: grid;
    gap: 12px;
    margin-bottom: 0;
  }

  &__details dt,
  &__details dd {
    font-size: 0.84rem;
  }

  &__details dd {
    margin: 2px 0 0;
  }

  &__actions {
    display: flex;
    justify-content: flex-end;
    flex-wrap: wrap;
    gap: 8px;
    margin-top: 18px;
  }

  &__error {
    color: var(--color-danger);
    font-weight: 800;
  }

  &__cancel-field {
    display: grid;
    gap: 7px;
  }

  &__cancel-field textarea {
    padding: 10px;
    border: 1px solid var(--line);
    border-radius: 10px;
    font: inherit;
  }
}

@media (width <= 700px) {
  .service-page__grid {
    grid-template-columns: 1fr;
  }
}
</style>
