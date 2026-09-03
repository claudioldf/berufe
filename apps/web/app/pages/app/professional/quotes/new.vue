<script setup lang="ts">
import type {
  Quote,
  QuoteDraft,
  QuoteProfessional,
  QuoteSaveIntent,
  QuoteShareMethod,
} from "~/types";
import { useShare } from "~/composables/useShare";
import { useToast } from "~/composables/useToast";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import { fetchProfessionalCustomer } from "~/services/api/professional-customers";
import {
  createProfessionalQuote,
  fetchProfessionalQuote,
  revokeProfessionalQuoteShare,
  shareProfessionalQuote,
  updateProfessionalQuote,
} from "~/services/api/professional-quotes";
import { fetchProfessionalWorkspace } from "~/services/api/professional-workspace";
import { quoteDateAfterDays, withDefaultQuoteValidity } from "~/utils/quotes";

definePageMeta({ layout: "workspace" });

useSeoMeta({
  title: "Novo orçamento",
  robots: "noindex, nofollow",
});

const route = useRoute();
const router = useRouter();
const client = useApiClient();
const { showToast } = useToast();
const { copyText } = useShare();
const requestedQuoteId = Array.isArray(route.query.quote)
  ? route.query.quote[0]
  : route.query.quote;
const requestedCustomerId = requestedQuoteId
  ? undefined
  : Array.isArray(route.query.customer)
    ? route.query.customer[0]
    : route.query.customer;
const editor = await useAsyncData(
  `professional-quote-editor-${requestedQuoteId ?? `new-${requestedCustomerId ?? "blank"}`}`,
  async () => {
    const workspaceRequest = fetchProfessionalWorkspace(client);
    if (requestedQuoteId) {
      const [workspace, initialQuote] = await Promise.all([
        workspaceRequest,
        fetchProfessionalQuote(client, requestedQuoteId),
      ]);
      return { workspace, quote: withDefaultQuoteValidity(initialQuote) };
    }

    const [workspace, customer] = await Promise.all([
      workspaceRequest,
      requestedCustomerId
        ? fetchProfessionalCustomer(client, requestedCustomerId)
        : Promise.resolve(undefined),
    ]);
    const initialQuote = createEmptyQuote(
      workspace.quoteDefaults.pricingMode,
      customer,
    );
    return { workspace, quote: withDefaultQuoteValidity(initialQuote) };
  },
);
const savingIntent = shallowRef<QuoteSaveIntent | null>(null);
const saveError = shallowRef("");
const sharingMethod = shallowRef<QuoteShareMethod | null>(null);
const shareError = shallowRef("");
const shareOpen = shallowRef(false);
const revoking = shallowRef(false);
const quote = computed(() => editor.data.value?.quote ?? null);
const professional = computed<QuoteProfessional | null>(() => {
  const workspace = editor.data.value?.workspace;
  if (!workspace) return null;
  const primaryService =
    workspace.profile.services.find((service) => service.isPrimary) ??
    workspace.profile.services[0];
  return {
    name: workspace.profile.identity.name,
    avatar: workspace.profile.photo.imageUrl,
    primaryService: primaryService?.name ?? "",
    identityVerified: workspace.dashboard.readiness.steps.approvedIdentity,
  };
});
const shareEnabled = computed(() => {
  const workspace = editor.data.value?.workspace;
  return Boolean(
    quote.value &&
    !["approved", "completed", "cancelled"].includes(quote.value.status) &&
    workspace?.profile.isPublic,
  );
});
// The quote editor hides the share bar entirely for a locked
// quote, so in practice the only reachable cause here is a non-public
// profile — surface why, reusing the same reason the dashboard shows.
const shareBlockedReason = computed(() => {
  if (shareEnabled.value) return null;
  const profile = editor.data.value?.workspace.profile;
  if (!profile) return null;
  return (
    profile.suspensionReason ??
    "Seu perfil não está público, então o link do orçamento não pode ser aberto pelo cliente."
  );
});
const editorTitle = computed(() =>
  quote.value?.number ? "Orçamento" : "Novo orçamento",
);

watch(shareOpen, (open) => {
  const quoteId = quote.value?.id;
  const routeQuoteId = Array.isArray(route.query.quote)
    ? route.query.quote[0]
    : route.query.quote;
  if (open || !quoteId || routeQuoteId === quoteId) return;

  void router.replace({
    path: "/app/professional/quotes/new",
    query: { quote: quoteId },
  });
});

function createEmptyQuote(
  pricingMode: Quote["pricingMode"],
  customer?: Awaited<ReturnType<typeof fetchProfessionalCustomer>>,
): Quote {
  return {
    id: null,
    number: null,
    revision: 0,
    customerId: customer?.id ?? null,
    customerName: customer?.name ?? "",
    customerPhone: customer?.phone ?? "",
    customerEmail: customer?.email ?? "",
    pricingMode,
    serviceDescription: "",
    serviceAddress: "",
    scheduledOn: "",
    validUntil: quoteDateAfterDays(30),
    discount: 0,
    markup: 0,
    notes: "",
    status: "draft",
    subtotal: 0,
    total: 0,
    sharedAt: null,
    createdAt: null,
    updatedAt: null,
    customerDecisionMessage: "",
    changeRequests: [],
    serviceJob: null,
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
    customerSuppliedMaterials: [],
  };
}

async function persistQuote(
  draft: QuoteDraft,
  intent: QuoteSaveIntent,
): Promise<Quote | null> {
  if (savingIntent.value || !editor.data.value) return null;
  savingIntent.value = intent;
  saveError.value = "";
  try {
    const saved = draft.id
      ? await updateProfessionalQuote(client, draft.id, draft)
      : await createProfessionalQuote(client, draft);
    editor.data.value = { ...editor.data.value, quote: saved };
    if (!draft.id) {
      const location = {
        path: "/app/professional/quotes/new",
        query: { quote: saved.id },
      };
      if (intent === "share" && import.meta.client) {
        // Keep the assigned quote URL without remounting this page before the
        // share dialog opens. The watcher above syncs Vue Router on close.
        window.history.replaceState(
          window.history.state,
          "",
          router.resolve(location).href,
        );
      } else {
        await router.replace(location);
      }
    }
    return saved;
  } catch (error) {
    saveError.value =
      error instanceof ApiRequestError
        ? error.message
        : "Não foi possível salvar o orçamento. Tente novamente.";
    return null;
  } finally {
    savingIntent.value = null;
  }
}

async function saveQuote(draft: QuoteDraft) {
  const saved = await persistQuote(draft, "draft");
  if (!saved) return;

  showToast({
    title: "Orçamento salvo",
    description: `As alterações do orçamento #${saved.number} foram salvas.`,
  });
}

async function prepareShare(draft: QuoteDraft) {
  shareError.value = "";
  const saved = await persistQuote(draft, "share");
  if (saved && shareEnabled.value) shareOpen.value = true;
}

async function shareQuote(method: QuoteShareMethod) {
  const quoteId = quote.value?.id;
  if (!quoteId || sharingMethod.value) return;
  const handoffWindow =
    method === "whatsapp" && import.meta.client
      ? window.open("about:blank", "_blank")
      : null;
  if (handoffWindow) handoffWindow.opener = null;
  sharingMethod.value = method;
  shareError.value = "";
  try {
    const result = await shareProfessionalQuote(client, quoteId, method);
    if (editor.data.value) {
      editor.data.value = { ...editor.data.value, quote: result.quote };
    }
    shareOpen.value = false;
    if (method === "copy") {
      await copyText(result.shareUrl, "Link do orçamento copiado");
    } else if (handoffWindow) {
      handoffWindow.location.replace(result.whatsappUrl);
      showToast({
        title: "Abrindo o WhatsApp",
        description: "A Berufe não envia nem confirma a entrega da mensagem.",
      });
    } else if (import.meta.client) {
      window.location.assign(result.whatsappUrl);
    }
  } catch (error) {
    handoffWindow?.close();
    shareError.value =
      error instanceof ApiRequestError
        ? error.message
        : "Não foi possível compartilhar o orçamento. Tente novamente.";
  } finally {
    sharingMethod.value = null;
  }
}

async function revokeShare() {
  const quoteId = quote.value?.id;
  if (!quoteId || revoking.value) return;
  revoking.value = true;
  shareError.value = "";
  try {
    const revoked = await revokeProfessionalQuoteShare(client, quoteId);
    if (editor.data.value) {
      editor.data.value = { ...editor.data.value, quote: revoked };
    }
    showToast({
      title: "Link revogado",
      description: "O link anterior deixou de abrir este orçamento.",
    });
  } catch (error) {
    shareError.value =
      error instanceof ApiRequestError
        ? error.message
        : "Não foi possível revogar o link. Tente novamente.";
  } finally {
    revoking.value = false;
  }
}
</script>

<template>
  <div class="quote-workspace">
    <section class="quote-workspace__heading">
      <DesignSystemContainer class="quote-workspace__heading-inner">
        <NuxtLink to="/app/professional/quotes"
          ><UIcon name="i-lucide-arrow-left" /> Voltar aos orçamentos</NuxtLink
        >
        <div>
          <div>
            <DesignSystemEyebrow tone="inverse"
              >Berufe Ferramentas</DesignSystemEyebrow
            >
            <h1>
              {{ editorTitle }}
              <em v-if="quote?.number">#{{ quote.number }}</em>
            </h1>
            <p>
              Preencha os dados, revise e compartilhe o orçamento com seu
              cliente.
            </p>
          </div>
        </div>
      </DesignSystemContainer>
    </section>
    <DesignSystemContainer class="quote-workspace__content">
      <p v-if="editor.status.value === 'pending'" aria-live="polite">
        Carregando orçamento…
      </p>
      <p v-else-if="editor.error.value || !quote || !professional" role="alert">
        Não foi possível carregar o orçamento. Volte à lista de orçamentos e
        tente novamente.
      </p>
      <template v-else>
        <DashboardQuoteStatusCard
          class="quote-workspace__status"
          :quote="quote"
        />
        <DashboardQuoteBuilder
          v-model:share-open="shareOpen"
          class="quote-workspace__builder"
          :initial-quote="quote"
          :professional="professional"
          :saving-intent="savingIntent"
          :save-error="saveError"
          :sharing-method="sharingMethod"
          :share-error="shareError"
          :share-enabled="shareEnabled"
          :share-blocked-reason="shareBlockedReason"
          :revoking="revoking"
          @save="saveQuote"
          @prepare-share="prepareShare"
          @share="shareQuote"
          @revoke="revokeShare"
        />
      </template>
    </DesignSystemContainer>
  </div>
</template>

<style scoped lang="scss">
.quote-workspace {
  min-height: 100vh;
  padding-bottom: 80px;
  background: var(--color-surface-canvas);
  &__heading {
    padding: 28px 0 100px;
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
  &__status {
    margin-top: -84px;
  }
  &__builder {
    margin-top: 24px;
  }
}

@media (width <= 560px) {
  .quote-workspace {
    &__heading {
      padding-bottom: 76px;
    }

    &__status {
      margin-top: -58px;
    }

    &__builder {
      margin-top: 16px;
    }
  }
}
</style>
