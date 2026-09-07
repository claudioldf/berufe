<script setup lang="ts">
import { computed, reactive, shallowRef } from "vue";
import { useToast } from "~/composables/useToast";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import { uploadMedia, waitForMediaUpload } from "~/services/api/media-upload";
import {
  createProfessionalServiceAdjustment,
  fetchProfessionalServiceJob,
  shareProfessionalServiceAdjustment,
  updateProfessionalServiceAdjustment,
} from "~/services/api/professional-service-jobs";
import type {
  ServiceAdjustmentDraft,
  ServiceAdjustmentItemKind,
} from "~/types";

definePageMeta({ layout: "workspace" });
useSeoMeta({ title: "Ajuste do serviço", robots: "noindex, nofollow" });

interface EditorItem {
  key: string;
  kind: ServiceAdjustmentItemKind;
  description: string;
  quantity: number;
  unit: string;
  unitPrice: number;
  mediaUploadId: string | null;
  receiptFile: File | null;
}

const route = useRoute();
const client = useApiClient();
const { showToast } = useToast();
const serviceJobId = computed(() =>
  Array.isArray(route.params.id)
    ? (route.params.id[0] ?? "")
    : String(route.params.id ?? ""),
);
const adjustmentId = computed(() =>
  Array.isArray(route.query.adjustment)
    ? (route.query.adjustment[0] ?? "")
    : String(route.query.adjustment ?? ""),
);
const loaded = await useAsyncData(
  `service-adjustment-editor-${serviceJobId.value}`,
  () => fetchProfessionalServiceJob(client, serviceJobId.value),
);
if (loaded.error.value || !loaded.data.value) {
  throw createError({
    statusCode: 404,
    statusMessage: "Serviço não encontrado",
  });
}

const service = shallowRef(loaded.data.value);
const existing = computed(() =>
  service.value.adjustments.find(
    (adjustment) => adjustment.id === adjustmentId.value,
  ),
);
if (adjustmentId.value && !existing.value) {
  throw createError({
    statusCode: 404,
    statusMessage: "Ajuste não encontrado",
  });
}
if (
  existing.value &&
  !["draft", "awaiting_response", "change_requested"].includes(
    existing.value.status,
  )
) {
  throw createError({
    statusCode: 409,
    statusMessage: "Este ajuste não pode mais ser alterado",
  });
}

function itemKey() {
  return globalThis.crypto.randomUUID();
}

const form = reactive({
  title: existing.value?.title ?? "",
  description: existing.value?.description ?? "",
  scheduleImpact: existing.value?.scheduleImpact ?? "",
  incurredOn: existing.value?.incurredOn ?? "",
  items: (existing.value?.items ?? []).map<EditorItem>((item) => ({
    key: itemKey(),
    kind: item.kind,
    description: item.description,
    quantity: item.quantity,
    unit: item.unit,
    unitPrice: item.unitPrice,
    mediaUploadId: item.receipt?.mediaUploadId ?? null,
    receiptFile: null,
  })),
});
const saving = shallowRef(false);
const saveError = shallowRef("");
const fieldErrors = reactive<Record<string, string>>({});

const kindOptions: Array<{ value: ServiceAdjustmentItemKind; label: string }> =
  [
    { value: "additional_service", label: "Serviço adicional" },
    { value: "material_charge", label: "Material fornecido" },
    { value: "material_reimbursement", label: "Reembolso de material" },
    { value: "credit", label: "Crédito para o cliente" },
  ];
const money = new Intl.NumberFormat("pt-BR", {
  style: "currency",
  currency: "BRL",
});
const total = computed(() =>
  form.items.reduce((sum, item) => {
    const value = Number(item.quantity || 0) * Number(item.unitPrice || 0);
    return sum + (item.kind === "credit" ? -value : value);
  }, 0),
);
const projectedTotal = computed(() => service.value.agreedTotal + total.value);
const isEditing = computed(() => Boolean(existing.value));

function addItem(kind: ServiceAdjustmentItemKind = "additional_service") {
  form.items.push({
    key: itemKey(),
    kind,
    description: "",
    quantity: 1,
    unit: kind === "material_reimbursement" ? "unidade" : "serviço",
    unitPrice: 0,
    mediaUploadId: null,
    receiptFile: null,
  });
}

function removeItem(index: number) {
  form.items.splice(index, 1);
}

function selectReceipt(index: number, event: Event) {
  const input = event.target as HTMLInputElement;
  const file = input.files?.[0] ?? null;
  form.items[index]!.receiptFile = file;
  if (file) form.items[index]!.mediaUploadId = null;
}

function clearReceipt(index: number) {
  form.items[index]!.receiptFile = null;
  form.items[index]!.mediaUploadId = null;
}

function changeItemKind(index: number) {
  if (form.items[index]?.kind !== "material_reimbursement") {
    clearReceipt(index);
  }
}

function validate() {
  Object.keys(fieldErrors).forEach((key) =>
    Reflect.deleteProperty(fieldErrors, key),
  );
  if (!form.title.trim())
    fieldErrors.title = "Informe um título para o ajuste.";
  if (projectedTotal.value < 0)
    fieldErrors.total =
      "Os créditos não podem deixar o total combinado negativo.";
  form.items.forEach((item, index) => {
    if (!item.description.trim())
      fieldErrors[`item-${index}`] = "Descreva este item.";
    else if (!(item.quantity > 0))
      fieldErrors[`item-${index}`] = "A quantidade deve ser maior que zero.";
    else if (!(item.unitPrice >= 0))
      fieldErrors[`item-${index}`] = "O valor não pode ser negativo.";
  });
  return Object.keys(fieldErrors).length === 0;
}

async function receiptUploadId(item: EditorItem) {
  if (!item.receiptFile) return item.mediaUploadId;
  const upload = await uploadMedia(
    client,
    item.receiptFile,
    "service_adjustment_receipt",
  );
  const processed = await waitForMediaUpload(client, upload);
  if (processed.state !== "processed") {
    throw new Error("receipt_processing_failed");
  }
  return processed.id;
}

async function save(intent: "draft" | "copy" | "whatsapp") {
  if (saving.value || !validate()) return;
  const handoff =
    intent === "whatsapp" && import.meta.client
      ? window.open("about:blank", "_blank")
      : null;
  if (handoff) handoff.opener = null;
  saving.value = true;
  saveError.value = "";
  try {
    const items = [];
    for (const item of form.items) {
      items.push({
        kind: item.kind,
        description: item.description,
        quantity: Number(item.quantity),
        unit: item.unit,
        unitPrice: Number(item.unitPrice),
        mediaUploadId: await receiptUploadId(item),
      });
    }
    const payload: ServiceAdjustmentDraft = {
      revision: existing.value?.revision,
      title: form.title,
      description: form.description,
      scheduleImpact: form.scheduleImpact,
      incurredOn: form.incurredOn,
      items,
    };
    const updated = existing.value
      ? await updateProfessionalServiceAdjustment(
          client,
          service.value.id,
          existing.value.id,
          payload,
        )
      : await createProfessionalServiceAdjustment(
          client,
          service.value.id,
          payload,
        );
    const savedAdjustment = existing.value
      ? updated.adjustments.find((item) => item.id === existing.value?.id)
      : updated.adjustments.at(-1);
    if (!savedAdjustment) throw new Error("adjustment_missing");

    if (intent !== "draft") {
      const shared = await shareProfessionalServiceAdjustment(
        client,
        service.value.id,
        savedAdjustment.id,
        intent,
      );
      if (intent === "copy" && import.meta.client) {
        await navigator.clipboard.writeText(shared.shareUrl);
      } else if (intent === "whatsapp") {
        if (handoff) handoff.location.replace(shared.whatsappUrl);
        else if (import.meta.client) window.location.assign(shared.whatsappUrl);
      }
    } else {
      handoff?.close();
    }

    clearNuxtData("professional-service-jobs");
    clearNuxtData("professional-workspace");
    clearNuxtData(`professional-service-job-${service.value.id}`);
    showToast({
      title: intent === "draft" ? "Ajuste salvo" : "Ajuste compartilhado",
      description:
        intent === "draft"
          ? "O cliente ainda não pode responder a este rascunho."
          : "O valor só entra no total combinado após a aprovação.",
    });
    await navigateTo(`/app/professional/services/${service.value.id}`);
  } catch (error) {
    handoff?.close();
    if (error instanceof ApiRequestError) {
      saveError.value = error.message;
      for (const [key, messages] of Object.entries(error.fieldErrors)) {
        fieldErrors[key] = messages[0] ?? "Revise este campo.";
      }
    } else {
      saveError.value = "Não foi possível salvar o ajuste. Tente novamente.";
    }
  } finally {
    saving.value = false;
  }
}
</script>

<template>
  <div class="adjustment-editor">
    <DesignSystemContainer class="adjustment-editor__container">
      <NuxtLink
        :to="`/app/professional/services/${service.id}`"
        class="adjustment-editor__back"
      >
        <UIcon name="i-lucide-arrow-left" /> Voltar ao serviço
      </NuxtLink>

      <header class="adjustment-editor__heading">
        <div>
          <DesignSystemEyebrow>Acordo adicional</DesignSystemEyebrow>
          <h1>
            {{
              isEditing ? `Editar ajuste #${existing?.number}` : "Novo ajuste"
            }}
          </h1>
          <p>
            O orçamento #{{ service.quote.number }} continua intacto. Este
            ajuste só altera o total combinado quando o cliente aprovar.
          </p>
        </div>
        <div class="adjustment-editor__total">
          <span>Valor deste ajuste</span>
          <strong>{{ money.format(total) }}</strong>
          <small>Após aprovação: {{ money.format(projectedTotal) }}</small>
        </div>
      </header>

      <form class="adjustment-editor__form" @submit.prevent="save('draft')">
        <DesignSystemSurfaceCard as="section" class="adjustment-editor__card">
          <h2>O que mudou?</h2>
          <label>
            Título
            <input
              v-model="form.title"
              maxlength="120"
              placeholder="Ex.: Pintura da parede adicional"
              :aria-invalid="Boolean(fieldErrors.title)"
            />
            <small v-if="fieldErrors.title" role="alert">{{
              fieldErrors.title
            }}</small>
          </label>
          <label>
            Detalhes (opcional)
            <textarea
              v-model="form.description"
              rows="4"
              maxlength="700"
              placeholder="Explique o novo escopo ou a razão do ajuste"
            />
          </label>
          <div class="adjustment-editor__two-columns">
            <label>
              Impacto no prazo (opcional)
              <input
                v-model="form.scheduleImpact"
                maxlength="300"
                placeholder="Ex.: acrescenta 1 dia"
              />
            </label>
            <label>
              Já realizado ou comprado em
              <input v-model="form.incurredOn" type="date" />
            </label>
          </div>
          <p v-if="form.incurredOn" class="adjustment-editor__warning">
            <UIcon name="i-lucide-triangle-alert" /> O cliente verá que esta
            despesa ocorreu antes da aprovação. Ela continuará fora do total
            combinado até ser aprovada.
          </p>
        </DesignSystemSurfaceCard>

        <DesignSystemSurfaceCard as="section" class="adjustment-editor__card">
          <div class="adjustment-editor__section-heading">
            <div>
              <h2>Itens do ajuste</h2>
              <p>
                Você também pode salvar um ajuste de valor zero só para
                documentar escopo ou prazo.
              </p>
            </div>
            <UButton
              type="button"
              color="neutral"
              variant="outline"
              icon="i-lucide-plus"
              :disabled="form.items.length >= 20"
              @click="addItem()"
            >
              Adicionar item
            </UButton>
          </div>

          <div v-if="form.items.length" class="adjustment-editor__items">
            <fieldset
              v-for="(item, index) in form.items"
              :key="item.key"
              class="adjustment-editor__item"
            >
              <legend>Item {{ index + 1 }}</legend>
              <div class="adjustment-editor__item-grid">
                <label>
                  Tipo
                  <select v-model="item.kind" @change="changeItemKind(index)">
                    <option
                      v-for="option in kindOptions"
                      :key="option.value"
                      :value="option.value"
                    >
                      {{ option.label }}
                    </option>
                  </select>
                </label>
                <label class="adjustment-editor__description">
                  Descrição
                  <input v-model="item.description" maxlength="160" />
                </label>
                <label>
                  Quantidade
                  <input
                    v-model.number="item.quantity"
                    type="number"
                    min="0.001"
                    step="0.001"
                  />
                </label>
                <label>
                  Unidade
                  <input v-model="item.unit" maxlength="20" />
                </label>
                <label>
                  Valor unitário
                  <input
                    v-model.number="item.unitPrice"
                    type="number"
                    min="0"
                    step="0.01"
                  />
                </label>
                <strong class="adjustment-editor__line-total">
                  {{
                    money.format(
                      (item.kind === "credit" ? -1 : 1) *
                        item.quantity *
                        item.unitPrice,
                    )
                  }}
                </strong>
              </div>
              <div
                v-if="item.kind === 'material_reimbursement'"
                class="adjustment-editor__receipt"
              >
                <label>
                  Comprovante (opcional, JPEG ou PNG)
                  <input
                    type="file"
                    accept="image/jpeg,image/png"
                    @change="selectReceipt(index, $event)"
                  />
                </label>
                <span v-if="item.receiptFile">{{ item.receiptFile.name }}</span>
                <span v-else-if="item.mediaUploadId">Comprovante anexado</span>
                <span v-else
                  >Sem comprovante — isso ficará claro para o cliente.</span
                >
                <UButton
                  v-if="item.receiptFile || item.mediaUploadId"
                  type="button"
                  color="neutral"
                  variant="link"
                  @click="clearReceipt(index)"
                >
                  Remover comprovante
                </UButton>
              </div>
              <small v-if="fieldErrors[`item-${index}`]" role="alert">
                {{ fieldErrors[`item-${index}`] }}
              </small>
              <UButton
                type="button"
                color="error"
                variant="ghost"
                size="sm"
                @click="removeItem(index)"
              >
                Remover item
              </UButton>
            </fieldset>
          </div>
          <p v-else class="adjustment-editor__empty">
            Nenhum item financeiro. O ajuste documentará apenas o texto acima.
          </p>
          <p
            v-if="fieldErrors.total"
            class="adjustment-editor__error"
            role="alert"
          >
            {{ fieldErrors.total }}
          </p>
        </DesignSystemSurfaceCard>

        <p v-if="saveError" class="adjustment-editor__error" role="alert">
          {{ saveError }}
        </p>
        <footer class="adjustment-editor__actions">
          <UButton
            type="submit"
            color="neutral"
            variant="outline"
            :loading="saving"
          >
            Salvar rascunho
          </UButton>
          <UButton
            type="button"
            color="neutral"
            variant="outline"
            icon="i-lucide-copy"
            :disabled="saving"
            @click="save('copy')"
          >
            Salvar e copiar link
          </UButton>
          <UButton
            type="button"
            color="primary"
            icon="i-lucide-message-circle"
            :loading="saving"
            @click="save('whatsapp')"
          >
            Salvar e enviar no WhatsApp
          </UButton>
        </footer>
      </form>
    </DesignSystemContainer>
  </div>
</template>

<style scoped lang="scss">
.adjustment-editor {
  min-height: 100vh;
  padding: 34px 0 90px;
  background: var(--color-surface-canvas);

  &__container {
    max-width: 980px;
  }

  &__back {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    color: var(--color-brand);
    font-weight: 750;
    text-decoration: none;
  }

  &__heading {
    display: flex;
    align-items: flex-end;
    justify-content: space-between;
    gap: 24px;
    margin: 34px 0 24px;
  }

  h1,
  h2,
  p {
    margin: 0;
  }

  h1 {
    margin-top: 5px;
    font-family: var(--font-display);
    font-size: clamp(2rem, 5vw, 3rem);
    letter-spacing: -0.04em;
  }

  &__heading p,
  &__section-heading p {
    max-width: 610px;
    margin-top: 7px;
    color: var(--ink-soft);
    line-height: 1.5;
  }

  &__total {
    display: grid;
    min-width: 220px;
    padding: 16px;
    border-radius: 14px;
    background: var(--color-brand-strong);
    color: white;
  }

  &__total span,
  &__total small {
    color: rgb(255 255 255 / 70%);
    font-size: 0.75rem;
  }

  &__total strong {
    margin: 3px 0;
    font-size: 1.45rem;
  }

  &__form,
  &__items {
    display: grid;
    gap: 18px;
  }

  &__card {
    display: grid;
    gap: 16px;
    padding: 24px;
  }

  &__card h2 {
    font-family: var(--font-display);
    font-size: 1.45rem;
  }

  label {
    display: grid;
    gap: 6px;
    color: var(--ink);
    font-size: 0.83rem;
    font-weight: 750;
  }

  input,
  textarea,
  select {
    width: 100%;
    padding: 11px 12px;
    border: 1px solid var(--line);
    border-radius: 10px;
    background: var(--color-surface-control);
    color: var(--ink);
    font: inherit;
  }

  textarea {
    resize: vertical;
  }

  small[role="alert"],
  &__error {
    color: var(--color-danger);
    font-size: 0.8rem;
  }

  &__two-columns,
  &__item-grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 13px;
  }

  &__warning {
    padding: 12px;
    border-radius: 10px;
    background: var(--color-warning-tint, #fff5dd);
    color: #7a4307;
    font-size: 0.84rem;
  }

  &__section-heading,
  &__actions {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 16px;
  }

  &__item {
    display: grid;
    gap: 13px;
    margin: 0;
    padding: 16px;
    border: 1px solid var(--line);
    border-radius: 13px;
  }

  &__item legend {
    padding: 0 4px;
    color: var(--color-brand);
    font-size: 0.76rem;
    font-weight: 850;
  }

  &__description {
    grid-column: span 1;
  }

  &__line-total {
    align-self: end;
    padding: 11px 0;
    text-align: right;
  }

  &__receipt {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 10px;
    padding: 12px;
    border-radius: 10px;
    background: var(--color-surface-subtle);
    color: var(--ink-soft);
    font-size: 0.8rem;
  }

  &__receipt label {
    flex: 1 1 280px;
  }

  &__empty {
    padding: 14px;
    border: 1px dashed var(--line);
    border-radius: 10px;
    color: var(--ink-soft);
    font-size: 0.84rem;
  }

  &__actions {
    justify-content: flex-end;
    flex-wrap: wrap;
  }
}

@media (width <= 700px) {
  .adjustment-editor {
    padding-top: 24px;

    &__heading,
    &__section-heading,
    &__actions {
      align-items: stretch;
      flex-direction: column;
    }

    &__total {
      min-width: 0;
    }

    &__two-columns,
    &__item-grid {
      grid-template-columns: 1fr;
    }

    &__actions :deep(button) {
      justify-content: center;
      width: 100%;
    }
  }
}
</style>
