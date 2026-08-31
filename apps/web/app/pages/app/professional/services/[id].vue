<script setup lang="ts">
import ServiceActionsCard from "~/components/dashboard/service/ServiceActionsCard.vue";
import ServiceCompletionDialog from "~/components/dashboard/service/CompletionDialog.vue";
import ServiceDetailsCard from "~/components/dashboard/service/ServiceDetailsCard.vue";
import ServiceHero from "~/components/dashboard/service/ServiceHero.vue";
import ServiceStatusCard from "~/components/dashboard/service/ServiceStatusCard.vue";
import { useToast } from "~/composables/useToast";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import {
  cancelProfessionalServiceJob,
  completeProfessionalServiceJob,
  fetchProfessionalServiceJob,
  requestProfessionalServiceRecommendation,
} from "~/services/api/professional-service-jobs";

definePageMeta({ layout: "workspace" });
useSeoMeta({ title: "Detalhes do serviço", robots: "noindex, nofollow" });

const route = useRoute();
const client = useApiClient();
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
const cancelOpen = shallowRef(false);
const completeOpen = shallowRef(false);
const completionIntent = shallowRef<boolean | null>(null);
const cancellationReason = shallowRef("");

function invalidateServiceData() {
  clearNuxtData("professional-service-jobs");
  clearNuxtData("professional-workspace");
}

const statusPresentation = computed(() => {
  const status = service.value?.status;
  if (status === "completed") {
    const recommendation = service.value?.recommendation;
    return {
      title: "Serviço concluído",
      description: !recommendation
        ? "Registrado por você sem solicitar uma avaliação ao cliente."
        : recommendation.deliveryChannel === "email"
          ? "Registrado por você. O pedido de avaliação foi encaminhado por e-mail."
          : "Registrado por você. O pedido de avaliação foi aberto no WhatsApp.",
      icon: "i-lucide-check-circle-2",
      tone: "success" as const,
    };
  }
  if (status === "cancelled")
    return {
      title: "Serviço cancelado",
      description: "Este fluxo foi encerrado.",
      icon: "i-lucide-x",
      tone: "neutral" as const,
    };
  return {
    title: "Serviço aprovado",
    description: "Quando terminar, marque como concluído.",
    icon: "i-lucide-clipboard-check",
    tone: "brand" as const,
  };
});
const canCancel = computed(
  () =>
    Boolean(service.value) &&
    !["completed", "cancelled"].includes(service.value?.status ?? "cancelled"),
);
const canComplete = computed(() => service.value?.status === "approved");
const canRequestRecommendation = computed(
  () =>
    service.value?.status === "completed" &&
    service.value.recommendation?.deliveryChannel === "whatsapp",
);
const recommendationSentAt = computed(
  () => service.value?.recommendation?.sentAt ?? null,
);
const completionDeliveryChannel = computed(() =>
  service.value?.quote.customerEmail ? "email" : "whatsapp",
);

function openCompleteDialog() {
  actionError.value = "";
  completeOpen.value = true;
}

async function requestRecommendation() {
  if (!service.value || acting.value) return;
  const handoff = import.meta.client
    ? window.open("about:blank", "_blank")
    : null;
  if (handoff) handoff.opener = null;
  acting.value = true;
  actionError.value = "";
  try {
    const result = await requestProfessionalServiceRecommendation(
      client,
      service.value.id,
    );
    service.value = result.serviceJob;
    invalidateServiceData();
    if (handoff) handoff.location.replace(result.whatsappUrl);
    else if (import.meta.client) window.location.assign(result.whatsappUrl);
    showToast({
      title: "Abrindo o WhatsApp",
      description: "Peça a recomendação por lá.",
    });
  } catch (error) {
    handoff?.close();
    actionError.value =
      error instanceof ApiRequestError
        ? error.message
        : "Não foi possível pedir a recomendação.";
  } finally {
    acting.value = false;
  }
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
    invalidateServiceData();
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

async function completeService(requestRecommendation: boolean) {
  if (!service.value || acting.value) return;
  const deliveryChannel = completionDeliveryChannel.value;
  const handoff =
    requestRecommendation &&
    deliveryChannel === "whatsapp" &&
    import.meta.client
      ? window.open("about:blank", "_blank")
      : null;
  if (handoff) handoff.opener = null;
  completionIntent.value = requestRecommendation;
  acting.value = true;
  actionError.value = "";
  try {
    const result = await completeProfessionalServiceJob(
      client,
      service.value.id,
      requestRecommendation,
    );
    service.value = result.serviceJob;
    completeOpen.value = false;
    invalidateServiceData();

    if (result.whatsappUrl) {
      if (handoff) handoff.location.replace(result.whatsappUrl);
      else if (import.meta.client) window.location.assign(result.whatsappUrl);
    } else {
      handoff?.close();
    }

    showToast({
      title: "Serviço concluído",
      description: !requestRecommendation
        ? "Nenhum pedido de avaliação foi enviado."
        : deliveryChannel === "email"
          ? "O pedido de avaliação foi enfileirado para envio por e-mail."
          : "O pedido de avaliação está pronto no WhatsApp.",
    });
  } catch (error) {
    handoff?.close();
    actionError.value =
      error instanceof ApiRequestError
        ? error.message
        : "Não foi possível concluir o serviço.";
  } finally {
    acting.value = false;
    completionIntent.value = null;
  }
}
</script>

<template>
  <div class="service-page">
    <section class="service-page__masthead">
      <DesignSystemContainer class="service-page__masthead-content">
        <NuxtLink to="/app/professional/services" class="service-page__back">
          <UIcon name="i-lucide-arrow-left" /> Todos os serviços
        </NuxtLink>

        <p
          v-if="loaded.status.value === 'pending'"
          class="service-page__loading"
          aria-live="polite"
        >
          Carregando serviço…
        </p>
        <p
          v-else-if="loaded.error.value || !service"
          class="service-page__loading"
          role="alert"
        >
          Não foi possível carregar este serviço.
        </p>
        <ServiceHero
          v-else
          :service="service"
          :status-label="statusPresentation.title"
          :status-tone="statusPresentation.tone"
        />
      </DesignSystemContainer>
    </section>

    <DesignSystemContainer v-if="service" class="service-page__content">
      <ServiceStatusCard
        :service="service"
        :title="statusPresentation.title"
        :description="statusPresentation.description"
        :icon="statusPresentation.icon"
        :tone="statusPresentation.tone"
      />

      <div v-if="actionError" class="service-page__error" role="alert">
        <UIcon name="i-lucide-circle-alert" aria-hidden="true" />
        <span>{{ actionError }}</span>
      </div>

      <div class="service-page__grid">
        <ServiceDetailsCard :quote="service.quote" />
        <ServiceActionsCard
          class="service-page__actions"
          :status="service.status"
          :can-complete="canComplete"
          :can-cancel="canCancel"
          :can-request-recommendation="canRequestRecommendation"
          :recommendation-sent-at="recommendationSentAt"
          :acting="acting"
          @request-recommendation="requestRecommendation"
          @open-cancel="cancelOpen = true"
          @open-complete="openCompleteDialog"
        />
      </div>
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

    <ServiceCompletionDialog
      v-model:open="completeOpen"
      :customer-name="service?.quote.customerName ?? 'o cliente'"
      :delivery-channel="completionDeliveryChannel"
      :busy="acting"
      :pending-choice="completionIntent"
      :error="actionError"
      @confirm="completeService"
    />
  </div>
</template>

<style scoped lang="scss">
.service-page {
  min-height: 100vh;
  background: var(--color-surface-canvas);
  background-image: radial-gradient(
    circle at 88% 72%,
    rgb(18 98 93 / 5%) 0,
    transparent 25rem
  );

  &__masthead {
    padding: 30px 0 116px;
    background: var(--color-brand-strong);
  }

  &__masthead-content,
  &__content {
    position: relative;
    z-index: 1;
    max-width: 1080px;
  }

  &__back {
    display: inline-flex;
    align-items: center;
    gap: 7px;
    margin-bottom: 42px;
    color: rgb(255 255 255 / 64%);
    font-size: 0.82rem;
    font-weight: 750;
    text-decoration: none;
    transition: color var(--motion-fast) ease;
  }

  &__back:hover {
    color: white;
  }

  &__loading {
    min-height: 150px;
    margin: 0;
    color: rgb(255 255 255 / 72%);
  }

  &__content {
    margin-top: -72px;
    padding-bottom: 90px;
  }

  &__grid {
    display: grid;
    grid-template-columns: minmax(0, 1.45fr) minmax(280px, 0.72fr);
    gap: 20px;
    align-items: start;
    margin-top: 20px;
  }

  &__actions {
    position: sticky;
    top: 92px;
  }

  &__error {
    display: flex;
    align-items: center;
    gap: 9px;
    margin-top: 18px;
    padding: 13px 15px;
    border: 1px solid rgb(180 35 24 / 16%);
    border-radius: 12px;
    background: var(--color-danger-tint);
    color: var(--color-danger);
    font-size: 0.85rem;
    font-weight: 750;
  }

  &__cancel-field {
    display: grid;
    gap: 7px;
    color: var(--ink);
    font-size: 0.86rem;
    font-weight: 750;
  }

  &__cancel-field textarea {
    min-height: 96px;
    padding: 12px;
    border: 1px solid var(--line);
    border-radius: 12px;
    background: var(--color-surface-control);
    font: inherit;
    resize: vertical;
  }
}

@media (width <= 820px) {
  .service-page {
    &__grid {
      grid-template-columns: 1fr;
    }

    &__actions {
      position: static;
    }
  }
}

@media (width <= 560px) {
  .service-page {
    &__masthead {
      padding-top: 23px;
      padding-bottom: 78px;
    }

    &__back {
      margin-bottom: 32px;
    }

    &__content {
      margin-top: -42px;
      padding-bottom: 60px;
    }

    &__grid {
      gap: 14px;
      margin-top: 14px;
    }
  }
}
</style>
