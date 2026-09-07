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
  ServiceAdjustmentEditorItem,
  ServiceAdjustmentItemKind,
} from "~/types";

definePageMeta({ layout: "workspace" });
useSeoMeta({ title: "Ajuste do serviço", robots: "noindex, nofollow" });

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
  items: (existing.value?.items ?? []).map<ServiceAdjustmentEditorItem>(
    (item) => ({
      key: itemKey(),
      kind: item.kind,
      description: item.description,
      quantity: item.quantity,
      unit: item.unit,
      unitPrice: item.unitPrice,
      mediaUploadId: item.receipt?.mediaUploadId ?? null,
      receiptFile: null,
    }),
  ),
});
const saving = shallowRef(false);
const saveError = shallowRef("");
const fieldErrors = reactive<Record<string, string>>({});

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
  const item = form.items[index];
  if (!item) return;
  item.unit = item.kind === "material_reimbursement" ? "unidade" : "serviço";
  if (item.kind !== "material_reimbursement") {
    clearReceipt(index);
  }
}

function validate() {
  Object.keys(fieldErrors).forEach((key) =>
    Reflect.deleteProperty(fieldErrors, key),
  );
  if (!form.title.trim())
    fieldErrors.title = "Informe um resumo para o ajuste.";
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

async function receiptUploadId(item: ServiceAdjustmentEditorItem) {
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

      <form
        class="adjustment-editor__form"
        novalidate
        @submit.prevent="save('draft')"
      >
        <DesignSystemSurfaceCard as="section" class="adjustment-editor__card">
          <h2>O que mudou?</h2>
          <DesignSystemFormField
            label="Resumo do ajuste"
            :error="fieldErrors.title"
            required
          >
            <template #default="{ controlId, describedBy, invalid, required }">
              <input
                :id="controlId"
                v-model="form.title"
                maxlength="120"
                placeholder="Ex.: Pintura da parede adicional"
                :aria-describedby="describedBy"
                :aria-invalid="invalid"
                :required="required"
              />
            </template>
          </DesignSystemFormField>
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
            <UIcon name="i-lucide-triangle-alert" aria-hidden="true" />
            <span>
              O cliente verá que esta despesa ocorreu antes da aprovação. Ela
              continuará fora do total combinado até ser aprovada.
            </span>
          </p>
        </DesignSystemSurfaceCard>

        <DashboardServiceAdjustmentItemsEditor
          v-model="form.items"
          :total="total"
          :errors="fieldErrors"
          @add="addItem()"
          @remove="removeItem"
          @change-kind="changeItemKind"
          @select-receipt="selectReceipt"
          @clear-receipt="clearReceipt"
        />

        <footer class="adjustment-editor__savebar">
          <span
            :role="
              saveError || Object.keys(fieldErrors).length ? 'alert' : 'status'
            "
          >
            <UIcon
              :name="
                saveError ? 'i-lucide-circle-alert' : 'i-lucide-circle-dot'
              "
              aria-hidden="true"
            />
            {{
              saveError ||
              (Object.keys(fieldErrors).length
                ? "Revise os campos destacados para continuar"
                : saving
                  ? "Salvando ajuste…"
                  : "Alterações ainda não foram salvas")
            }}
          </span>
          <div class="adjustment-editor__savebar-actions">
            <UButton
              type="submit"
              color="neutral"
              variant="outline"
              icon="i-lucide-file-text"
              :loading="saving"
              :disabled="saving"
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
              :disabled="saving"
              @click="save('whatsapp')"
            >
              Salvar e enviar no WhatsApp
            </UButton>
          </div>
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

  &__heading p {
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

  &__form {
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

  &__two-columns {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 13px;
  }

  &__warning {
    display: flex;
    align-items: flex-start;
    gap: 8px;
    padding: 12px;
    border-radius: 10px;
    background: var(--color-warning-tint, #fff5dd);
    color: #7a4307;
    font-size: 0.84rem;
  }

  &__warning :deep(svg) {
    flex: 0 0 auto;
    margin-top: 0.15em;
  }

  &__savebar {
    position: sticky;
    z-index: 10;
    bottom: 12px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 16px;
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

  &__savebar-actions {
    display: flex;
    gap: 6px;
  }
}

@media (width <= 700px) {
  .adjustment-editor {
    padding-top: 24px;

    &__heading {
      align-items: stretch;
      flex-direction: column;
    }

    &__total {
      min-width: 0;
    }

    &__two-columns {
      grid-template-columns: 1fr;
    }

    &__savebar {
      display: grid;
      grid-template-columns: minmax(0, 1fr);
      row-gap: 8px;
      padding-inline: 8px;
    }

    &__savebar-actions {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 4px;
      width: 100%;
      min-width: 0;
    }

    &__savebar-actions :deep(button) {
      justify-content: center;
      width: 100%;
      min-width: 0;
      min-height: 48px;
      padding-inline: 4px;
      gap: 4px;
      font-size: clamp(0.625rem, 3vw, 0.75rem);
    }
  }
}
</style>
