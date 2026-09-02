<script setup lang="ts">
import LegalInlineNotice from "~/components/legal/LegalInlineNotice.vue";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import {
  createCustomerFeedbackIssue,
  createCustomerRecommendation,
  resolveCustomerRecommendation,
} from "~/services/api/customer-recommendations";

definePageMeta({ layout: false });
useSeoMeta({ title: "Como foi o serviço?", robots: "noindex, nofollow" });

const route = useRoute();
const client = useApiClient();
const token = computed(() =>
  Array.isArray(route.params.token)
    ? (route.params.token[0] ?? "")
    : String(route.params.token ?? ""),
);
const resolved = await useAsyncData(`recommendation-${token.value}`, () =>
  resolveCustomerRecommendation(client, token.value),
);
const context = computed(() => resolved.data.value);

// The landing question is neutral on purpose: asking directly for a public
// recommendation leaves an unhappy customer no outlet but a bad public one.
type Step = "choice" | "recommend" | "issue";
const step = shallowRef<Step>("choice");
const displayName = shallowRef(context.value?.customerName ?? "");
const recommendationText = shallowRef("");
const serviceConfirmed = shallowRef(false);
const publicationConsent = shallowRef(false);
const issueMessage = shallowRef("");
const submitting = shallowRef(false);
const recommendationSubmitted = shallowRef(false);
const issueSubmitted = shallowRef(false);
const submitError = shallowRef("");
const canSubmitRecommendation = computed(
  () =>
    displayName.value.trim().length > 0 &&
    recommendationText.value.trim().length > 0 &&
    serviceConfirmed.value &&
    publicationConsent.value,
);
const canSubmitIssue = computed(() => issueMessage.value.trim().length > 0);
const recommendationBlockedReason = computed(() =>
  canSubmitRecommendation.value
    ? null
    : "Preencha os campos e marque as duas confirmações",
);

async function submitRecommendation() {
  if (!canSubmitRecommendation.value || submitting.value) return;
  submitting.value = true;
  submitError.value = "";
  try {
    await createCustomerRecommendation(client, token.value, {
      displayName: displayName.value,
      text: recommendationText.value,
      serviceConfirmed: serviceConfirmed.value,
      publicationConsent: publicationConsent.value,
    });
    recommendationSubmitted.value = true;
  } catch (error) {
    submitError.value =
      error instanceof ApiRequestError
        ? error.message
        : "Não foi possível publicar sua recomendação. Tente novamente.";
  } finally {
    submitting.value = false;
  }
}

async function submitIssue() {
  if (!canSubmitIssue.value || submitting.value) return;
  submitting.value = true;
  submitError.value = "";
  try {
    await createCustomerFeedbackIssue(client, token.value, issueMessage.value);
    issueSubmitted.value = true;
  } catch (error) {
    submitError.value =
      error instanceof ApiRequestError
        ? error.message
        : "Não foi possível enviar sua mensagem. Tente novamente.";
  } finally {
    submitting.value = false;
  }
}
</script>

<template>
  <div class="recommendation-page">
    <DesignSystemContainer as="header" class="recommendation-page__header">
      <DesignSystemBrand size="sm" />
      <span><UIcon name="i-lucide-lock-keyhole" /> Link pessoal e privado</span>
    </DesignSystemContainer>
    <DesignSystemContainer as="main" class="recommendation-page__content">
      <p v-if="resolved.status.value === 'pending'" aria-live="polite">
        Carregando convite…
      </p>
      <DesignSystemSurfaceCard
        v-else-if="resolved.error.value || !context"
        class="recommendation-page__card"
      >
        <UIcon name="i-lucide-link-2-off" />
        <h1>Este convite não está disponível</h1>
        <p>O link pode ter expirado ou já ter sido usado.</p>
      </DesignSystemSurfaceCard>
      <DesignSystemSurfaceCard
        v-else-if="recommendationSubmitted"
        class="recommendation-page__card"
      >
        <UIcon name="i-lucide-badge-check" />
        <h1>Recomendação publicada</h1>
        <p>
          Obrigado por compartilhar sua experiência. Ela já pode aparecer no
          perfil público de {{ context.professional.name }}.
        </p>
        <UButton :to="buildPublicProfilePath(context.professional.slug)">
          Ver perfil profissional
        </UButton>
      </DesignSystemSurfaceCard>
      <DesignSystemSurfaceCard
        v-else-if="issueSubmitted"
        class="recommendation-page__card"
      >
        <UIcon name="i-lucide-message-circle-warning" />
        <h1>Mensagem enviada</h1>
        <p>
          Avisamos {{ context.professional.name }} sobre o que você descreveu.
          Isto não fica público.
        </p>
      </DesignSystemSurfaceCard>

      <div v-else-if="step === 'choice'" class="recommendation-page__form">
        <DesignSystemEyebrow>Serviço confirmado</DesignSystemEyebrow>
        <h1>Como foi o serviço de {{ context.professional.name }}?</h1>
        <p>
          Sobre “{{ context.serviceDescription }}”. Escolha a opção que descreve
          melhor o que aconteceu.
        </p>
        <div class="recommendation-page__choice">
          <UButton
            size="lg"
            color="primary"
            icon="i-lucide-thumbs-up"
            @click="step = 'recommend'"
          >
            Correu bem, quero recomendar
          </UButton>
          <UButton
            size="lg"
            color="neutral"
            variant="outline"
            icon="i-lucide-circle-alert"
            @click="step = 'issue'"
          >
            Algo ainda ficou pendente
          </UButton>
        </div>
      </div>

      <form
        v-else-if="step === 'recommend'"
        class="recommendation-page__form"
        @submit.prevent="submitRecommendation"
      >
        <button
          type="button"
          class="recommendation-page__back"
          @click="step = 'choice'"
        >
          <UIcon name="i-lucide-arrow-left" aria-hidden="true" /> Voltar
        </button>
        <DesignSystemEyebrow>Serviço confirmado</DesignSystemEyebrow>
        <h1>Como foi trabalhar com {{ context.professional.name }}?</h1>
        <p>
          Sua recomendação sobre “{{ context.serviceDescription }}” ajuda outras
          pessoas a contratar com mais confiança.
        </p>

        <DesignSystemFormField
          v-slot="field"
          label="Nome que será exibido"
          required
        >
          <input
            :id="field.controlId"
            v-model="displayName"
            name="displayName"
            autocomplete="name"
            maxlength="80"
            required
          />
        </DesignSystemFormField>
        <DesignSystemFormField v-slot="field" label="Sua recomendação" required>
          <textarea
            :id="field.controlId"
            v-model="recommendationText"
            name="recommendationText"
            rows="5"
            maxlength="700"
            placeholder="Conte brevemente como foi a experiência"
            required
          />
        </DesignSystemFormField>
        <LegalInlineNotice title="Publicação com sua autorização">
          Seu nome e seu texto ficarão públicos no perfil. Este link pessoal é
          usado para validar o convite. Você pode retirar a autorização pelo
          suporte.
        </LegalInlineNotice>
        <label class="recommendation-page__check">
          <input v-model="serviceConfirmed" type="checkbox" required />
          Confirmo que este serviço foi realizado e concluído.
        </label>
        <label class="recommendation-page__check">
          <input v-model="publicationConsent" type="checkbox" required />
          Autorizo a publicação do meu nome e deste texto no perfil público do
          profissional.
        </label>
        <p v-if="submitError" class="recommendation-page__error" role="alert">
          {{ submitError }}
        </p>
        <DesignSystemDisabledTooltip
          :reason="submitting ? null : recommendationBlockedReason"
          :loading="submitting"
        >
          <UButton
            type="submit"
            color="primary"
            block
            :loading="submitting"
            :disabled="!canSubmitRecommendation"
            >Publicar recomendação</UButton
          >
        </DesignSystemDisabledTooltip>
        <small>
          Este convite pessoal é válido por 14 dias e só pode ser usado uma vez.
          Não há nota por estrelas nem revisão prévia da Berufe.
        </small>
      </form>

      <form
        v-else
        class="recommendation-page__form"
        @submit.prevent="submitIssue"
      >
        <button
          type="button"
          class="recommendation-page__back"
          @click="step = 'choice'"
        >
          <UIcon name="i-lucide-arrow-left" aria-hidden="true" /> Voltar
        </button>
        <DesignSystemEyebrow>Mensagem privada</DesignSystemEyebrow>
        <h1>O que ainda precisa ser resolvido?</h1>
        <p>
          Isto vai direto para {{ context.professional.name }} e não aparece em
          nenhum lugar público.
        </p>
        <DesignSystemFormField v-slot="field" label="Sua mensagem" required>
          <textarea
            :id="field.controlId"
            v-model="issueMessage"
            name="issueMessage"
            rows="5"
            maxlength="700"
            placeholder="Descreva o que ficou pendente"
            required
          />
        </DesignSystemFormField>
        <p v-if="submitError" class="recommendation-page__error" role="alert">
          {{ submitError }}
        </p>
        <UButton
          type="submit"
          color="primary"
          block
          :loading="submitting"
          :disabled="!canSubmitIssue"
          >Enviar mensagem</UButton
        >
      </form>
    </DesignSystemContainer>
  </div>
</template>

<style scoped lang="scss">
.recommendation-page {
  min-height: 100vh;
  padding-bottom: 70px;
  background: #eeeae1;

  &__header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    min-height: 70px;
  }

  &__header span {
    display: flex;
    align-items: center;
    gap: 5px;
    color: var(--ink-soft);
    font-size: 0.82rem;
    font-weight: 800;
  }

  &__content {
    max-width: 650px;
    padding-top: 38px;
  }

  &__form,
  &__card {
    display: grid;
    gap: 16px;
    padding: 28px;
    border: 1px solid var(--line);
    border-radius: 20px;
    background: white;
    box-shadow: var(--shadow-sm);
  }

  & h1 {
    margin: 0;
    font-family: var(--font-display);
    font-size: 2rem;
    font-weight: 500;
    letter-spacing: -0.03em;
  }

  &__form > p,
  &__card p,
  &__form > small {
    margin: 0;
    color: var(--ink-soft);
    line-height: 1.55;
  }

  & textarea,
  & input[type="text"] {
    width: 100%;
  }

  & textarea {
    padding: 11px;
    border: 1px solid var(--line);
    border-radius: 10px;
    resize: vertical;
    font: inherit;
  }

  &__choice {
    display: grid;
    gap: 10px;
    margin-top: 6px;
  }

  &__back {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    justify-self: start;
    padding: 0;
    border: 0;
    background: none;
    color: var(--ink-soft);
    font-size: 0.82rem;
    font-weight: 750;
    cursor: pointer;
  }

  &__check {
    display: flex;
    align-items: flex-start;
    gap: 8px;
    font-size: 0.84rem;
    line-height: 1.45;
  }

  &__error {
    color: var(--color-danger) !important;
    font-weight: 800;
  }

  &__card {
    justify-items: start;
  }

  &__card > svg {
    color: var(--color-brand);
    font-size: 2rem;
  }
}
</style>
