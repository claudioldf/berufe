<script setup lang="ts">
import type { Quote, QuoteDraft, QuoteProfessional } from "~/types";
import { useToast } from "~/composables/useToast";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import {
  createProfessionalQuote,
  fetchProfessionalQuote,
  updateProfessionalQuote,
} from "~/services/api/professional-quotes";
import { fetchProfessionalWorkspace } from "~/services/api/professional-workspace";

definePageMeta({ layout: "workspace" });

useSeoMeta({
  title: "Novo orçamento",
  robots: "noindex, nofollow",
});

const route = useRoute();
const router = useRouter();
const client = useApiClient();
const { showToast } = useToast();
const requestedQuoteId = Array.isArray(route.query.quote)
  ? route.query.quote[0]
  : route.query.quote;
const editor = await useAsyncData(
  `professional-quote-editor-${requestedQuoteId ?? "new"}`,
  async () => {
    const [workspace, quote] = await Promise.all([
      fetchProfessionalWorkspace(client),
      requestedQuoteId
        ? fetchProfessionalQuote(client, requestedQuoteId)
        : Promise.resolve(createEmptyQuote()),
    ]);
    return { workspace, quote };
  },
);
const saving = shallowRef(false);
const saveError = shallowRef("");
const quote = computed(() => editor.data.value?.quote ?? null);
const professional = computed<QuoteProfessional | null>(() => {
  const workspace = editor.data.value?.workspace;
  if (!workspace) return null;
  const primaryService =
    workspace.profile.services.find((service) => service.isPrimary) ??
    workspace.profile.services[0];
  return {
    name: workspace.profile.identity.name,
    avatar: workspace.profile.photo.publishedImageUrl,
    primaryService: primaryService?.name ?? "",
    identityVerified: workspace.dashboard.readiness.steps.approvedIdentity,
  };
});

function createEmptyQuote(): Quote {
  return {
    id: null,
    number: null,
    customerName: "",
    serviceDescription: "",
    validUntil: "",
    discount: 0,
    notes: "",
    status: "draft",
    subtotal: 0,
    total: 0,
    sharedAt: null,
    createdAt: null,
    updatedAt: null,
    items: [
      {
        id: globalThis.crypto.randomUUID(),
        description: "",
        quantity: 1,
        unit: "serviço",
        unitPrice: 0,
        lineTotal: 0,
        sortOrder: 0,
      },
    ],
  };
}

async function saveQuote(draft: QuoteDraft) {
  if (saving.value || !editor.data.value) return;
  saving.value = true;
  saveError.value = "";
  try {
    const saved = draft.id
      ? await updateProfessionalQuote(client, draft.id, draft)
      : await createProfessionalQuote(client, draft);
    editor.data.value.quote = saved;
    if (!draft.id) {
      await router.replace({
        path: "/app/professional/quotes/new",
        query: { quote: saved.id },
      });
    }
    showToast({
      title: "Rascunho salvo",
      description: `Orçamento #${saved.number} atualizado.`,
    });
  } catch (error) {
    saveError.value =
      error instanceof ApiRequestError
        ? error.message
        : "Não foi possível salvar o orçamento. Tente novamente.";
  } finally {
    saving.value = false;
  }
}
</script>

<template>
  <div class="quote-workspace">
    <section class="quote-workspace__heading">
      <DesignSystemContainer class="quote-workspace__heading-inner">
        <NuxtLink to="/app/professional"
          ><UIcon name="i-lucide-arrow-left" /> Voltar ao painel</NuxtLink
        >
        <div>
          <div>
            <DesignSystemEyebrow tone="inverse"
              >Berufe Ferramentas</DesignSystemEyebrow
            >
            <h1>
              Novo orçamento <em v-if="quote?.number">#{{ quote.number }}</em>
            </h1>
            <p>Crie, revise e compartilhe um link seguro com seu cliente.</p>
          </div>
          <span
            ><DesignSystemStatusDot />
            {{
              quote?.status === "shared" ? "Compartilhado" : "Rascunho"
            }}</span
          >
        </div>
      </DesignSystemContainer>
    </section>
    <DesignSystemContainer class="quote-workspace__content">
      <p v-if="editor.status.value === 'pending'" aria-live="polite">
        Carregando orçamento…
      </p>
      <p v-else-if="editor.error.value || !quote || !professional" role="alert">
        Não foi possível carregar o orçamento. Volte ao painel e tente
        novamente.
      </p>
      <DashboardQuoteBuilder
        v-else
        :initial-quote="quote"
        :professional="professional"
        :saving="saving"
        :save-error="saveError"
        @save="saveQuote"
      />
    </DesignSystemContainer>
  </div>
</template>

<style scoped lang="scss">
.quote-workspace {
  min-height: 100vh;
  padding-bottom: 80px;
  background: var(--color-surface-canvas);
  &__heading {
    padding: 28px 0 34px;
    background: var(--color-brand-strong);
    color: white;
  }
  &__heading a {
    display: flex;
    align-items: center;
    gap: 5px;
    margin-bottom: 20px;
    color: rgb(255 255 255 / 58%);
    font-size: 0.84rem;
    font-weight: 700;
    text-decoration: none;
  }
  &__heading-inner > div {
    display: flex;
    justify-content: space-between;
    align-items: end;
    gap: 20px;
  }
  &__heading .eyebrow {
    margin-bottom: 7px;
  }
  &__heading h1 {
    margin: 0;
    font-family: var(--font-display);
    font-size: 2.5rem;
    font-weight: 500;
    letter-spacing: -0.04em;
  }
  &__heading h1 em {
    color: var(--color-brand-muted);
    font-size: 0.55em;
    font-style: normal;
  }
  &__heading p:last-child {
    margin: 7px 0 0;
    color: rgb(255 255 255 / 58%);
    font-size: 0.82rem;
  }
  &__heading-inner > div > span {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 7px 10px;
    border: 1px solid rgb(255 255 255 / 15%);
    border-radius: 8px;
    color: #d5ddd9;
    font-size: 0.84rem;
    font-weight: 850;
  }
  &__content {
    padding-top: 24px;
  }
}
</style>
