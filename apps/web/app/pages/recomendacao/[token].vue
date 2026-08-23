<script setup lang="ts">
import LegalInlineNotice from "~/components/legal/LegalInlineNotice.vue";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import {
  createCustomerRecommendation,
  resolveCustomerRecommendation,
} from "~/services/api/customer-recommendations";

definePageMeta({ layout: false });
useSeoMeta({ title: "Recomendar profissional", robots: "noindex, nofollow" });

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
const displayName = shallowRef(context.value?.customerName ?? "");
const recommendationText = shallowRef("");
const serviceConfirmed = shallowRef(false);
const publicationConsent = shallowRef(false);
const submitting = shallowRef(false);
const submitted = shallowRef(false);
const submitError = shallowRef("");
const canSubmit = computed(
  () =>
    displayName.value.trim().length > 0 &&
    recommendationText.value.trim().length > 0 &&
    serviceConfirmed.value &&
    publicationConsent.value,
);

async function submit() {
  if (!canSubmit.value || submitting.value) return;
  submitting.value = true;
  submitError.value = "";
  try {
    await createCustomerRecommendation(client, token.value, {
      displayName: displayName.value,
      text: recommendationText.value,
      serviceConfirmed: serviceConfirmed.value,
      publicationConsent: publicationConsent.value,
    });
    submitted.value = true;
  } catch (error) {
    submitError.value =
      error instanceof ApiRequestError
        ? error.message
        : "Não foi possível publicar sua recomendação. Tente novamente.";
  } finally {
    submitting.value = false;
  }
}
</script>

<template>
  <div class="recommendation-page">
    <DesignSystemContainer as="header" class="recommendation-page__header">
      <DesignSystemBrand size="sm" />
      <span><UIcon name="i-lucide-mail-check" /> Link enviado por e-mail</span>
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
        v-else-if="submitted"
        class="recommendation-page__card"
      >
        <UIcon name="i-lucide-badge-check" />
        <h1>Recomendação publicada</h1>
        <p>
          Obrigado por compartilhar sua experiência. Ela já pode aparecer no
          perfil público de {{ context.professional.name }}.
        </p>
        <UButton :to="`/profissionais/${context.professional.slug}`">
          Ver perfil profissional
        </UButton>
      </DesignSystemSurfaceCard>
      <form v-else class="recommendation-page__form" @submit.prevent="submit">
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
          Seu nome e seu texto ficarão públicos no perfil. O e-mail é usado para
          validar este convite. Você pode retirar a autorização pelo suporte.
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
        <UButton
          type="submit"
          color="primary"
          block
          :loading="submitting"
          :disabled="!canSubmit"
          >Publicar recomendação</UButton
        >
        <small>
          Este convite pessoal foi enviado por e-mail após a sua confirmação de
          conclusão, é válido por 14 dias e só pode ser usado uma vez. Não há
          nota por estrelas nem revisão prévia da Berufe.
        </small>
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
