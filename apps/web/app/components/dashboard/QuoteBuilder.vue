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
  shareBlockedReason?: string | null;
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
const validationAttempted = shallowRef(false);
const formRoot = useTemplateRef<HTMLElement>("formRoot");
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
  validation,
  isValid,
  markDirty,
  addItem,
  removeItem,
} = useQuoteDraft(() => props.initialQuote);
const displayedErrors = computed(() =>
  validationAttempted.value ? validation.value : undefined,
);
const readyToShare = computed(
  () => isSaved.value && quote.value.status !== "draft",
);
const saveBarError = computed(() => {
  if (props.saveError) return props.saveError;
  return validationAttempted.value && !isValid.value
    ? "Revise os campos destacados para continuar."
    : "";
});
const sharingBlockedReason = computed(() => {
  if (props.sharingMethod === "copy") {
    return "Aguarde a cópia do link do orçamento terminar.";
  }
  if (props.sharingMethod === "whatsapp") {
    return "Aguarde a preparação do compartilhamento pelo WhatsApp.";
  }
  return null;
});

watch(
  () => [props.initialQuote.id, props.initialQuote.updatedAt],
  () => {
    validationAttempted.value = false;
  },
);

function canSubmit() {
  validationAttempted.value = true;
  if (isValid.value) return true;

  void nextTick(() => {
    formRoot.value
      ?.querySelector<HTMLElement>('[aria-invalid="true"]')
      ?.focus();
  });
  return false;
}

function save() {
  const draft = cloneQuote(quote.value);
  if (draft.status === "saved") draft.status = "draft";
  emit("save", draft);
}

function requestShare() {
  if (!canSubmit()) return;
  if (readyToShare.value) {
    shareOpen.value = true;
    return;
  }

  const draft = cloneQuote(quote.value);
  if (draft.status === "draft") draft.status = "saved";
  emit("prepareShare", draft);
}
</script>

<template>
  <div class="quote-builder">
    <div ref="formRoot" class="quote-builder__form">
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
        <DashboardQuoteCustomerFields
          v-model="quote"
          :errors="displayedErrors"
          @dirty="markDirty"
        />
        <DashboardQuoteServiceFields
          v-model="quote"
          :errors="displayedErrors"
          @dirty="markDirty"
        />
        <DashboardQuoteLineItemsEditor
          v-model="quote"
          :subtotal="subtotal"
          :errors="displayedErrors"
          @add="addItem"
          @remove="removeItem"
          @dirty="markDirty"
        />
        <DashboardQuoteNotesField
          v-model="quote"
          :errors="displayedErrors"
          @dirty="markDirty"
        />
        <DashboardQuoteSaveBar
          :saved="isSaved"
          :shared="isShared"
          :ready-to-share="readyToShare"
          :valid="isValid"
          :saving-intent="savingIntent"
          :error="saveBarError"
          :share-enabled="shareEnabled ?? false"
          :share-blocked-reason="shareBlockedReason"
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
        ><DesignSystemDisabledTooltip :reason="sharingBlockedReason">
          <UButton
            color="neutral"
            variant="outline"
            icon="i-lucide-link"
            :loading="sharingMethod === 'copy'"
            :disabled="Boolean(sharingMethod)"
            @click="emit('share', 'copy')"
            >Copiar link</UButton
          >
        </DesignSystemDisabledTooltip>
        <DesignSystemDisabledTooltip :reason="sharingBlockedReason">
          <UButton
            color="primary"
            icon="i-lucide-message-circle"
            :loading="sharingMethod === 'whatsapp'"
            :disabled="Boolean(sharingMethod)"
            @click="emit('share', 'whatsapp')"
            >Abrir WhatsApp</UButton
          >
        </DesignSystemDisabledTooltip></template
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
  .quote-builder__form :where(input, select, textarea):focus {
    outline: none;
  }
  .quote-builder__form :where(input, select, textarea):focus-visible {
    border-color: var(--color-brand);
    box-shadow: none;
  }
  .quote-builder__form
    .form-field
    :where(input, select, textarea):not([aria-invalid="true"]):focus-visible {
    box-shadow: none;
  }
  .quote-items {
    overflow-x: auto;
  }
  .quote-item {
    display: grid;
    grid-template-columns: minmax(150px, 1.4fr) 64px 84px 95px 90px 30px;
    gap: 7px;
    align-items: start;
    min-width: 660px;
    padding: 8px 0;
    border-top: 1px solid var(--line);
    &--head {
      align-items: center;
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
      background-color: var(--color-surface-control);
      font-size: 0.84rem;
      transition: border-color var(--motion-fast) ease;
    }
    & > label {
      display: grid;
      gap: 4px;
    }
    &__mobile-index,
    &__label {
      position: absolute;
      width: 1px;
      height: 1px;
      padding: 0;
      overflow: hidden;
      clip-path: inset(50%);
      white-space: nowrap;
      border: 0;
    }
    &__field--invalid input,
    &__field--invalid select {
      border-color: var(--color-danger);
      background-color: var(--color-danger-tint);
    }
    &__error {
      color: var(--color-danger);
      font-size: 0.72rem;
      font-weight: 650;
      line-height: 1.25;
    }
    & select {
      padding-right: 2.25rem;
    }
    &__total {
      display: grid;
    }
    &__total strong {
      margin-top: 9px;
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
    &__remove {
      grid-column: 6;
      grid-row: 1;
      margin-top: 5px;
    }
    & button:disabled {
      opacity: 0.25;
    }
  }
  .quote-items {
    &__mobile-add {
      display: none;
    }
    &__error {
      color: var(--color-danger) !important;
      font-weight: 700;
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
  .builder-total__field {
    display: grid;
    justify-items: end;
    gap: 4px;
  }
  .builder-total__control {
    display: grid;
    grid-template-columns: auto 80px;
    align-items: center;
    border: 1px solid var(--line);
    border-radius: 8px;
    transition: border-color var(--motion-fast) ease;
  }
  .builder-total__control:focus-within {
    border-color: var(--color-brand);
  }
  .builder-total__control--invalid,
  .builder-total__control--invalid:focus-within {
    border-color: var(--color-danger);
    background-color: var(--color-danger-tint);
  }
  .builder-total__error {
    max-width: 190px;
    color: var(--color-danger);
    font-size: 0.72rem;
    font-weight: 650;
    line-height: 1.25;
    text-align: right;
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
  .builder-total input:focus-visible {
    box-shadow: none;
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
    .quote-items {
      display: grid;
      gap: 12px;
      overflow-x: visible;
    }
    .quote-item {
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 12px;
      min-width: 0;
      padding: 14px;
      border: 1px solid var(--line);
      border-radius: 12px;
      background: var(--color-surface);
      &--head {
        display: none;
      }
      &__mobile-index,
      &__label {
        position: static;
        width: auto;
        height: auto;
        padding: 0;
        overflow: visible;
        clip-path: none;
        white-space: normal;
      }
      &__mobile-index {
        align-self: center;
        color: var(--ink);
        font-size: 0.82rem;
        font-weight: 850;
      }
      &__label {
        color: var(--ink-soft);
        font-size: 0.76rem;
        font-weight: 800;
      }
      &__description {
        grid-column: 1 / -1;
      }
      &__total {
        align-content: start;
        gap: 4px;
      }
      &__total strong {
        min-height: 42px;
        margin: 0;
        padding: 10px 8px;
        border: 1px solid var(--line);
        border-radius: 8px;
        background: var(--color-surface-neutral);
        text-align: right;
      }
      &__remove {
        grid-column: 2;
        grid-row: 1;
        justify-self: end;
        width: 44px;
        height: 44px;
        margin: 0;
      }
    }
    .builder-card {
      padding: 17px;
    }
  }
}
</style>
