<script setup lang="ts">
import { computed, shallowRef } from "vue";
import { useToast } from "~/composables/useToast";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import {
  fetchProfessionalRecommendations,
  hideProfessionalRecommendation,
  unhideProfessionalRecommendation,
} from "~/services/api/professional-recommendations";
import { formatDateTime } from "~/utils/formatters";

definePageMeta({ layout: "workspace" });
useSeoMeta({ title: "Recomendações", robots: "noindex, nofollow" });

const client = useApiClient();
const { showToast } = useToast();
const loaded = await useAsyncData("professional-recommendations", () =>
  fetchProfessionalRecommendations(client),
);
const recommendations = shallowRef(loaded.data.value ?? []);
const acting = shallowRef(false);
const actionError = shallowRef("");
const hideOpenId = shallowRef<string | null>(null);
const hideReason = shallowRef("");
const actingReason = computed(() =>
  acting.value ? "Aguarde a atualização da recomendação terminar." : null,
);

const hideModalOpen = computed({
  get: () => Boolean(hideOpenId.value),
  set: (value: boolean) => {
    if (!value) hideOpenId.value = null;
  },
});

function openHide(id: string) {
  hideOpenId.value = id;
  hideReason.value = "";
}

async function confirmHide() {
  if (!hideOpenId.value || acting.value) return;
  acting.value = true;
  actionError.value = "";
  try {
    const updated = await hideProfessionalRecommendation(
      client,
      hideOpenId.value,
      hideReason.value,
    );
    recommendations.value = recommendations.value.map((recommendation) =>
      recommendation.id === updated.id ? updated : recommendation,
    );
    hideOpenId.value = null;
    showToast({
      title: "Recomendação ocultada",
      description:
        "Seu perfil público agora mostra quantas recomendações você ocultou.",
    });
  } catch (error) {
    actionError.value =
      error instanceof ApiRequestError
        ? error.message
        : "Não foi possível ocultar esta recomendação.";
  } finally {
    acting.value = false;
  }
}

async function unhide(id: string) {
  if (acting.value) return;
  acting.value = true;
  actionError.value = "";
  try {
    const updated = await unhideProfessionalRecommendation(client, id);
    recommendations.value = recommendations.value.map((recommendation) =>
      recommendation.id === updated.id ? updated : recommendation,
    );
    showToast({
      title: "Recomendação restaurada",
      description: "Ela voltou a aparecer no seu perfil público.",
    });
  } catch (error) {
    actionError.value =
      error instanceof ApiRequestError
        ? error.message
        : "Não foi possível restaurar esta recomendação.";
  } finally {
    acting.value = false;
  }
}
</script>

<template>
  <div class="recommendations-page">
    <section class="recommendations-page__heading">
      <DesignSystemContainer>
        <NuxtLink to="/app/professional">
          <UIcon name="i-lucide-arrow-left" aria-hidden="true" /> Voltar ao
          painel
        </NuxtLink>
        <h1>Recomendações</h1>
        <p>
          Ocultar uma recomendação é imediato e não passa por revisão — mas seu
          perfil público sempre mostra quantas foram ocultadas.
        </p>
      </DesignSystemContainer>
    </section>

    <DesignSystemContainer as="main" class="recommendations-page__content">
      <DashboardProfessionalWorkspaceTabs />
      <div class="recommendations-page__main">
        <p v-if="loaded.status.value === 'pending'" aria-live="polite">
          Carregando recomendações…
        </p>
        <p v-else-if="loaded.error.value" role="alert">
          Não foi possível carregar suas recomendações.
        </p>
        <p v-else-if="recommendations.length === 0">
          Você ainda não recebeu recomendações.
        </p>
        <template v-else>
          <p
            v-if="actionError"
            role="alert"
            class="recommendations-page__error"
          >
            {{ actionError }}
          </p>
          <DesignSystemSurfaceCard
            v-for="recommendation in recommendations"
            :key="recommendation.id"
            class="recommendation-card"
            :class="{ 'recommendation-card--hidden': recommendation.hiddenAt }"
          >
            <div class="recommendation-card__body">
              <strong>{{ recommendation.displayName }}</strong>
              <small
                >{{ recommendation.customerName }} ·
                {{ recommendation.serviceDescription }} ·
                {{ formatDateTime(recommendation.submittedAt) }}</small
              >
              <p>“{{ recommendation.recommendationText }}”</p>
              <em v-if="recommendation.hiddenAt">
                Oculta do perfil público desde
                {{ formatDateTime(recommendation.hiddenAt) }}
                <template v-if="recommendation.hiddenReason"
                  >— “{{ recommendation.hiddenReason }}”</template
                >
              </em>
            </div>
            <DesignSystemDisabledTooltip
              v-if="recommendation.hiddenAt"
              :reason="actingReason"
            >
              <UButton
                color="neutral"
                variant="outline"
                :disabled="acting"
                @click="unhide(recommendation.id)"
              >
                Restaurar
              </UButton>
            </DesignSystemDisabledTooltip>
            <DesignSystemDisabledTooltip v-else :reason="actingReason">
              <UButton
                color="neutral"
                variant="ghost"
                :disabled="acting"
                @click="openHide(recommendation.id)"
              >
                Ocultar
              </UButton>
            </DesignSystemDisabledTooltip>
          </DesignSystemSurfaceCard>
        </template>
      </div>
    </DesignSystemContainer>

    <UModal
      v-model:open="hideModalOpen"
      title="Ocultar recomendação"
      description="Isto some do seu perfil público imediatamente. Seu perfil passa a mostrar quantas recomendações você ocultou."
    >
      <template #body>
        <label class="recommendations-page__reason-field">
          Motivo (privado, opcional)
          <textarea v-model="hideReason" rows="3" maxlength="700" />
        </label>
      </template>
      <template #footer>
        <UButton color="neutral" variant="ghost" @click="hideOpenId = null"
          >Voltar</UButton
        >
        <UButton color="error" :loading="acting" @click="confirmHide"
          >Ocultar recomendação</UButton
        >
      </template>
    </UModal>
  </div>
</template>

<style scoped lang="scss">
.recommendations-page {
  min-height: 100vh;
  background: var(--color-surface-canvas);

  &__heading {
    padding: 28px 0 34px;
    background: var(--color-brand-strong);
    color: white;
  }

  &__heading a {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    margin-bottom: 24px;
    color: rgb(255 255 255 / 65%);
    text-decoration: none;
  }

  &__heading h1 {
    margin: 6px 0;
    font-family: var(--font-display);
    font-size: 2.7rem;
    font-weight: 500;
  }

  &__heading p {
    max-width: 560px;
    margin: 0;
    color: rgb(255 255 255 / 65%);
  }

  &__content {
    display: grid;
    grid-template-columns: 190px minmax(0, 1fr);
    gap: 28px;
    padding-top: 26px;
    padding-bottom: 70px;
  }

  &__main {
    display: grid;
    gap: 12px;
    min-width: 0;
  }

  &__error {
    margin: 0;
    color: var(--color-danger);
    font-weight: 750;
  }

  &__reason-field {
    display: grid;
    gap: 7px;
    color: var(--ink);
    font-size: 0.86rem;
    font-weight: 750;
  }

  &__reason-field textarea {
    min-height: 96px;
    padding: 12px;
    border: 1px solid var(--line);
    border-radius: 12px;
    background: var(--color-surface-control);
    font: inherit;
    resize: vertical;
  }
}

.recommendation-card {
  display: flex;
  align-items: start;
  justify-content: space-between;
  gap: 16px;
  padding: 18px 20px;

  &--hidden {
    opacity: 0.7;
  }

  &__body {
    display: grid;
    gap: 4px;
    min-width: 0;
  }

  &__body small {
    color: var(--ink-soft);
  }

  &__body p {
    margin: 4px 0 0;
  }

  &__body em {
    margin-top: 4px;
    color: var(--color-danger);
    font-size: 0.82rem;
    font-style: normal;
    font-weight: 700;
  }
}

@media (width <= 760px) {
  .recommendations-page {
    &__content {
      grid-template-columns: 1fr;
    }
  }

  .recommendation-card {
    flex-direction: column;
  }
}
</style>
