<script setup lang="ts">
import ServiceActionsCard from "~/components/dashboard/service/ServiceActionsCard.vue";
import ServiceDetailsCard from "~/components/dashboard/service/ServiceDetailsCard.vue";
import ServiceHero from "~/components/dashboard/service/ServiceHero.vue";
import ServiceStatusCard from "~/components/dashboard/service/ServiceStatusCard.vue";
import { useShare } from "~/composables/useShare";
import { useToast } from "~/composables/useToast";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import {
  cancelProfessionalServiceJob,
  completeProfessionalServiceJob,
  fetchProfessionalServiceJob,
  requestProfessionalServiceCompletion,
} from "~/services/api/professional-service-jobs";

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
const completeOpen = shallowRef(false);
const cancellationReason = shallowRef("");

function invalidateServiceData() {
  clearNuxtData("professional-service-jobs");
  clearNuxtData("professional-workspace");
}

const statusPresentation = computed(() => {
  const status = service.value?.status;
  if (status === "completion_requested")
    return {
      title: "Aguardando confirmação",
      description: "O cliente recebeu o link de conclusão.",
      icon: "i-lucide-send",
      tone: "brand" as const,
    };
  if (status === "completion_issue")
    return {
      title: "Pendência informada",
      description: "Resolva o ponto indicado e solicite novamente.",
      icon: "i-lucide-circle-alert",
      tone: "warning" as const,
    };
  if (status === "completed") {
    const confirmer = service.value?.completionConfirmedBy;
    return {
      title: "Serviço concluído",
      description:
        confirmer === "professional"
          ? "A conclusão foi confirmada pelo profissional."
          : "A conclusão foi confirmada pelo cliente.",
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
    description: "Quando terminar, peça a confirmação do cliente.",
    icon: "i-lucide-clipboard-check",
    tone: "brand" as const,
  };
});
const canRequestCompletion = computed(
  () =>
    service.value?.status === "approved" ||
    service.value?.status === "completion_issue",
);
const canCancel = computed(
  () =>
    Boolean(service.value) &&
    !["completed", "cancelled"].includes(service.value?.status ?? "cancelled"),
);
const canComplete = computed(
  () =>
    Boolean(service.value) &&
    ["approved", "completion_requested", "completion_issue"].includes(
      service.value?.status ?? "cancelled",
    ),
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
    invalidateServiceData();
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

async function completeService() {
  if (!service.value || acting.value) return;
  acting.value = true;
  actionError.value = "";
  try {
    service.value = await completeProfessionalServiceJob(
      client,
      service.value.id,
    );
    completeOpen.value = false;
    invalidateServiceData();
    showToast({
      title: "Serviço concluído",
      description: "A conclusão foi confirmada por você.",
    });
  } catch (error) {
    actionError.value =
      error instanceof ApiRequestError
        ? error.message
        : "Não foi possível concluir o serviço.";
  } finally {
    acting.value = false;
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
          :can-request-completion="canRequestCompletion"
          :can-complete="canComplete"
          :can-cancel="canCancel"
          :acting="acting"
          :copy-fallback-url="copyFallbackUrl"
          @request-completion="requestCompletion"
          @copy-fallback="copyFallback"
          @open-cancel="cancelOpen = true"
          @open-complete="completeOpen = true"
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

    <UModal
      v-model:open="completeOpen"
      title="Concluir serviço"
      description="A conclusão será registrada como confirmada por você."
    >
      <template #body>
        <p>
          Confirme apenas se o trabalho já terminou. O serviço sairá da seção
          “Serviços em andamento”.
        </p>
        <p v-if="actionError" class="service-page__error" role="alert">
          {{ actionError }}
        </p>
      </template>
      <template #footer>
        <UButton color="neutral" variant="ghost" @click="completeOpen = false"
          >Voltar</UButton
        >
        <UButton
          color="primary"
          icon="i-lucide-check"
          :loading="acting"
          @click="completeService"
          >Confirmar conclusão</UButton
        >
      </template>
    </UModal>
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
