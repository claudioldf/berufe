<script setup lang="ts">
import type {
  Quote,
  QuoteDraft,
  QuoteProfessional,
  QuoteSaveIntent,
  QuoteShareMethod,
} from "~/types";
import { useQuoteDraft } from "~/composables/useQuoteDraft";
import { cloneQuote } from "~/utils/quotes";

const props = defineProps<{
  initialQuote: Quote;
  professional: QuoteProfessional;
  savingIntent: QuoteSaveIntent | null;
  saveError: string;
  sharingMethod: QuoteShareMethod | null;
  shareError: string;
  shareEnabled?: boolean;
  revoking?: boolean;
}>();
const emit = defineEmits<{
  save: [draft: QuoteDraft];
  prepareShare: [draft: QuoteDraft];
  share: [method: QuoteShareMethod];
  revoke: [];
}>();
const shareOpen = defineModel<boolean>("shareOpen", { default: false });
const revokeOpen = shallowRef(false);
const locked = computed(() => props.initialQuote.status === "approved");

function confirmRevoke() {
  revokeOpen.value = false;
  emit("revoke");
}
const {
  quote,
  previewOpen,
  isSaved,
  isShared,
  subtotal,
  isValid,
  markDirty,
  addItem,
  removeItem,
} = useQuoteDraft(() => props.initialQuote);

function save() {
  emit("save", cloneQuote(quote.value));
}

function requestShare() {
  if (isSaved.value) {
    shareOpen.value = true;
    return;
  }

  emit("prepareShare", cloneQuote(quote.value));
}
</script>

<template>
  <div class="quote-builder">
    <div class="quote-builder__form">
      <DesignSystemSurfaceCard v-if="locked" class="quote-builder__locked">
        <UIcon name="i-lucide-lock-keyhole" />
        <div>
          <strong>Orçamento aprovado</strong>
          <p>
            Este orçamento foi aprovado e não pode mais ser alterado. Acompanhe
            o andamento na área de serviços.
          </p>
        </div>
        <UButton
          v-if="initialQuote.serviceJob?.id"
          :to="`/app/professional/services/${initialQuote.serviceJob.id}`"
          >Ver serviço</UButton
        >
      </DesignSystemSurfaceCard>
      <DashboardQuoteChangeRequests
        v-if="initialQuote.changeRequests.length"
        :requests="initialQuote.changeRequests"
      />
      <template v-if="!locked">
        <DashboardQuoteCustomerFields v-model="quote" @dirty="markDirty" />
        <DashboardQuoteServiceFields v-model="quote" @dirty="markDirty" />
        <DashboardQuoteLineItemsEditor
          v-model="quote"
          :subtotal="subtotal"
          @add="addItem"
          @remove="removeItem"
          @dirty="markDirty"
        />
        <DashboardQuoteNotesField v-model="quote" @dirty="markDirty" />
        <DashboardQuoteSaveBar
          :saved="isSaved"
          :shared="isShared"
          :valid="isValid"
          :saving-intent="savingIntent"
          :error="saveError"
          :share-enabled="shareEnabled ?? false"
          @preview="previewOpen = true"
          @save="save"
          @share="requestShare"
        />
      </template>
      <div v-if="isShared && !locked" class="quote-builder__revoke">
        <p>
          Qualquer pessoa com o link ainda pode abrir este orçamento. Revogue-o
          para desativar o acesso imediatamente.
        </p>
        <UButton
          color="neutral"
          variant="outline"
          icon="i-lucide-link-2-off"
          :loading="revoking"
          @click="revokeOpen = true"
          >Revogar link</UButton
        >
      </div>
    </div>

    <aside class="quote-builder__preview">
      <div class="quote-builder__preview-label">
        <span>Prévia do cliente</span><em>Atualização instantânea</em>
      </div>
      <QuotesQuotePreview :quote="quote" :professional="professional" />
    </aside>

    <UModal
      v-model:open="previewOpen"
      title="Prévia do orçamento"
      description="Esta é a página que o cliente verá."
    >
      <template #body
        ><QuotesQuotePreview
          :quote="quote"
          :professional="professional"
          customer-facing
      /></template>
    </UModal>

    <UModal
      v-model:open="shareOpen"
      title="Compartilhar orçamento"
      description="Escolha como compartilhar o link seguro com seu cliente."
    >
      <template #body>
        <div class="share-quote">
          <span><UIcon name="i-lucide-message-circle" /></span>
          <div>
            <strong>Enviar pelo WhatsApp</strong>
            <p>
              A Berufe abre o WhatsApp com uma mensagem pronta e o link. Não
              enviamos a mensagem nem acessamos a conversa.
            </p>
          </div>
        </div>
        <div class="share-quote__link">
          <UIcon name="i-lucide-link" /><span
            >berufe.com.br/orcamento/••••••••{{ quote.number }}</span
          >
        </div>
        <p v-if="shareError" class="share-quote__error" role="alert">
          {{ shareError }}
        </p>
      </template>
      <template #footer
        ><UButton color="neutral" variant="ghost" @click="shareOpen = false"
          >Cancelar</UButton
        ><UButton
          color="neutral"
          variant="outline"
          icon="i-lucide-link"
          :loading="sharingMethod === 'copy'"
          :disabled="Boolean(sharingMethod)"
          @click="emit('share', 'copy')"
          >Copiar link</UButton
        ><UButton
          color="primary"
          icon="i-lucide-message-circle"
          :loading="sharingMethod === 'whatsapp'"
          :disabled="Boolean(sharingMethod)"
          @click="emit('share', 'whatsapp')"
          >Abrir WhatsApp</UButton
        ></template
      >
    </UModal>

    <UModal
      v-model:open="revokeOpen"
      title="Revogar o link do orçamento"
      description="O link atual deixará de funcionar e não poderá ser reativado."
    >
      <template #body>
        <p class="revoke-quote">
          O orçamento volta a ser um rascunho. Você pode compartilhá-lo de novo
          depois, e um link diferente será gerado.
        </p>
      </template>
      <template #footer
        ><UButton color="neutral" variant="ghost" @click="revokeOpen = false"
          >Cancelar</UButton
        ><UButton
          color="error"
          icon="i-lucide-link-2-off"
          :loading="revoking"
          @click="confirmRevoke"
          >Revogar link</UButton
        ></template
      >
    </UModal>
  </div>
</template>

<style scoped lang="scss">
.quote-builder {
  display: grid;
  grid-template-columns: minmax(0, 1.25fr) minmax(330px, 0.75fr);
  gap: 24px;
  align-items: start;
}

.quote-builder__locked {
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 12px;
  padding: 18px;
}

.quote-builder__locked > svg {
  color: var(--color-brand);
  font-size: 1.4rem;
}

.quote-builder__locked p {
  margin: 3px 0 0;
  color: var(--ink-soft);
  font-size: 0.84rem;
}

@media (width <= 1000px) {
  .quote-builder {
    grid-template-columns: 1fr;
  }
}

:deep() {
  .quote-builder {
    display: grid;
    grid-template-columns: minmax(0, 1.25fr) minmax(330px, 0.75fr);
    gap: 24px;
    align-items: start;
    &__form {
      min-width: 0;
      display: grid;
      grid-template-columns: minmax(0, 1fr);
      gap: 14px;
    }
  }
  .builder-card {
    padding: 22px;
  }
  .builder-card > header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding-bottom: 17px;
    margin-bottom: 18px;
    border-bottom: 1px solid var(--line);
  }
  .builder-card > header > div {
    display: flex;
    align-items: center;
    gap: 11px;
  }
  .builder-card > header > div > span {
    display: grid;
    place-items: center;
    width: 32px;
    height: 32px;
    border-radius: 9px;
    background: var(--mint);
    color: var(--color-brand);
    font-family: var(--font-display);
    font-size: 0.82rem;
  }
  .builder-card h2,
  .builder-card p {
    margin: 0;
  }
  .builder-card h2 {
    font-family: var(--font-display);
    font-size: 1.25rem;
  }
  .builder-card p {
    margin-top: 3px;
    color: var(--ink-soft);
    font-size: 0.84rem;
  }
  .builder-fields {
    display: grid;
    grid-template-columns: 1fr 0.55fr;
    gap: 14px;
    &__full {
      grid-column: 1 / -1;
    }
  }
  .quote-items {
    overflow-x: auto;
  }
  .quote-item {
    display: grid;
    grid-template-columns: minmax(150px, 1.4fr) 64px 84px 95px 90px 30px;
    gap: 7px;
    align-items: center;
    min-width: 660px;
    padding: 8px 0;
    border-top: 1px solid var(--line);
    &--head {
      border: 0;
      color: var(--ink-soft);
      font-size: 0.82rem;
      font-weight: 850;
      text-transform: uppercase;
    }
    &--head span:nth-child(n + 2) {
      text-align: right;
    }
    & input,
    & select {
      width: 100%;
      padding: 8px;
      border: 1px solid var(--line);
      border-radius: 8px;
      background: var(--color-surface-control);
      font-size: 0.84rem;
    }
    & strong {
      text-align: right;
      font-size: 0.84rem;
    }
    & button {
      display: grid;
      place-items: center;
      width: 27px;
      height: 27px;
      border: 0;
      border-radius: 7px;
      background: transparent;
      color: #a45245;
      cursor: pointer;
    }
    & button:disabled {
      opacity: 0.25;
    }
  }
  .quote-items {
    &__mobile-add {
      display: none;
    }
  }
  .builder-total {
    width: min(280px, 100%);
    margin: 18px 0 0 auto;
  }
  .builder-total > div,
  .builder-total > label {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 6px 0;
    color: var(--ink-soft);
    font-size: 0.84rem;
  }
  .builder-total > div:last-child {
    margin-top: 6px;
    padding-top: 12px;
    border-top: 2px solid var(--ink);
    color: var(--ink);
    font-size: 0.86rem;
  }
  .builder-total label > div {
    display: grid;
    grid-template-columns: auto 80px;
    align-items: center;
    border: 1px solid var(--line);
    border-radius: 8px;
  }
  .builder-total label em {
    padding-left: 8px;
    font-size: 0.82rem;
    font-style: normal;
  }
  .builder-total input {
    width: 80px;
    padding: 7px;
    border: 0;
    background: transparent;
    text-align: right;
    font-size: 0.84rem;
  }
  .quote-builder {
    &__savebar {
      position: sticky;
      z-index: 10;
      bottom: 12px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      padding: 11px 13px;
      border: 1px solid var(--line);
      border-radius: 14px;
      background: rgb(255 255 255 / 96%);
      box-shadow: var(--shadow-lg);
    }
    &__savebar > span {
      display: flex;
      align-items: center;
      gap: 5px;
      color: var(--ink-soft);
      font-size: 0.82rem;
    }
    &__savebar > div {
      display: flex;
      gap: 6px;
    }
    &__preview {
      position: sticky;
      top: 20px;
      min-width: 0;
    }
    &__preview-label {
      display: flex;
      justify-content: space-between;
      margin-bottom: 8px;
      color: var(--ink-soft);
      font-size: 0.82rem;
      font-weight: 800;
      text-transform: uppercase;
    }
    &__preview-label em {
      color: var(--color-brand);
      font-style: normal;
      text-transform: none;
    }
  }
  .share-quote {
    display: flex;
    align-items: center;
    gap: 13px;
    padding: 16px;
    border-radius: 13px;
    background: #e9f5f1;
    & > span {
      display: grid;
      place-items: center;
      width: 42px;
      height: 42px;
      border-radius: 12px;
      background: var(--color-brand);
      color: white;
      font-size: 1.25rem;
    }
    & strong {
      font-size: 0.84rem;
    }
    & p {
      margin: 4px 0 0;
      color: var(--ink-soft);
      font-size: 0.84rem;
      line-height: 1.5;
    }
    &__link {
      display: flex;
      align-items: center;
      gap: 7px;
      margin-top: 12px;
      padding: 11px;
      border: 1px solid var(--line);
      border-radius: 10px;
      color: var(--ink-soft);
      font-size: 0.86rem;
    }
    &__error {
      color: #a45245;
    }
  }
  .revoke-quote {
    margin: 0;
    color: var(--ink-soft);
    font-size: 0.86rem;
    line-height: 1.5;
  }
  .quote-builder__revoke {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    padding: 16px;
    border: 1px solid var(--line);
    border-radius: 13px;
    & p {
      flex: 1 1 260px;
      margin: 0;
      color: var(--ink-soft);
      font-size: 0.84rem;
      line-height: 1.5;
    }
  }
  @media (width <= 1000px) {
    .quote-builder {
      grid-template-columns: 1fr;
      &__preview {
        display: none;
      }
    }
  }
  @media (width <= 720px) {
    .quote-item input,
    .quote-item select,
    .builder-total input {
      font-size: 1rem;
    }
    .builder-fields {
      grid-template-columns: 1fr;
      &__full {
        grid-column: auto;
      }
    }
    .quote-builder {
      &__savebar {
        display: grid;
      }
      &__savebar > div {
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }
      &__savebar > div > * {
        justify-content: center;
      }
      &__savebar > div > :last-child {
        grid-column: 1 / -1;
      }
    }
    .builder-card {
      padding: 17px;
    }
  }
}
</style>
