<script setup lang="ts">
import {
  computed,
  nextTick,
  reactive,
  shallowRef,
  useTemplateRef,
  watch,
} from "vue";
import AdjustmentBuilder from "~/components/dashboard/service/AdjustmentBuilder.vue";
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
import { fetchProfessionalWorkspace } from "~/services/api/professional-workspace";
import type {
  QuoteProfessional,
  ServiceAdjustmentDraft,
  ServiceAdjustmentEditorForm,
  ServiceAdjustmentEditorItem,
  ServiceAdjustmentEditorSaveIntent,
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
  async () => {
    const [service, workspace] = await Promise.all([
      fetchProfessionalServiceJob(client, serviceJobId.value),
      fetchProfessionalWorkspace(client),
    ]);
    return { service, workspace };
  },
);
if (loaded.error.value || !loaded.data.value) {
  throw createError({
    statusCode: 404,
    statusMessage: "Serviço não encontrado",
  });
}

const service = shallowRef(loaded.data.value.service);
const professional = computed<QuoteProfessional>(() => {
  const workspace = loaded.data.value!.workspace;
  const primaryService =
    workspace.profile.services.find((item) => item.isPrimary) ??
    workspace.profile.services[0];
  return {
    name: workspace.profile.identity.name,
    avatar: workspace.profile.photo.imageUrl,
    primaryService: primaryService?.name ?? "",
    identityVerified: workspace.dashboard.readiness.steps.approvedIdentity,
  };
});
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

const form = reactive<ServiceAdjustmentEditorForm>({
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
const formModel = computed({
  get: () => form,
  set: (value: ServiceAdjustmentEditorForm) => Object.assign(form, value),
});
const savingIntent = shallowRef<ServiceAdjustmentEditorSaveIntent | null>(null);
const saving = computed(() => savingIntent.value !== null);
const saveError = shallowRef("");
const shareOpen = shallowRef(false);
const fieldErrors = reactive<Record<string, string>>({});
const builder =
  useTemplateRef<InstanceType<typeof AdjustmentBuilder>>("builder");

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
  if (form.items.length <= 1) return;
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
  if (!form.items.length)
    fieldErrors.itemsMessage = "Adicione pelo menos 1 item ao ajuste.";
  form.items.forEach((item, index) => {
    if (!item.description.trim())
      fieldErrors[`item-${index}-description`] = "Descreva este item.";
    if (!(item.quantity > 0))
      fieldErrors[`item-${index}-quantity`] =
        "A quantidade deve ser maior que zero.";
    if (!(item.unitPrice >= 0))
      fieldErrors[`item-${index}-unit-price`] =
        "O valor não pode ser negativo.";
  });
  return Object.keys(fieldErrors).length === 0;
}

watch(
  form,
  () => {
    if (!saveError.value && !Object.keys(fieldErrors).length) return;
    saveError.value = "";
    validate();
  },
  { deep: true },
);

function canSubmit() {
  if (validate()) return true;
  void nextTick(() => builder.value?.focusFirstError());
  return false;
}

function requestShare() {
  if (saving.value || !canSubmit()) return;
  shareOpen.value = true;
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

async function save(intent: ServiceAdjustmentEditorSaveIntent) {
  if (saving.value || !canSubmit()) return;
  const handoff =
    intent === "whatsapp" && import.meta.client
      ? window.open("about:blank", "_blank")
      : null;
  if (handoff) handoff.opener = null;
  savingIntent.value = intent;
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
    savingIntent.value = null;
  }
}

if (!form.items.length) addItem();
</script>

<template>
  <div class="adjustment-workspace">
    <section class="adjustment-workspace__heading">
      <DesignSystemContainer class="adjustment-workspace__heading-inner">
        <NuxtLink :to="`/app/professional/services/${service.id}`">
          <UIcon name="i-lucide-arrow-left" aria-hidden="true" />
          Voltar ao serviço
        </NuxtLink>
        <div>
          <DesignSystemEyebrow tone="inverse">
            Berufe Ferramentas
          </DesignSystemEyebrow>
          <h1>
            {{ isEditing ? "Ajuste" : "Novo ajuste" }}
            <em v-if="existing?.number">#{{ existing.number }}</em>
          </h1>
          <p>
            Registre a mudança, revise como o cliente verá e compartilhe para
            aprovação.
          </p>
        </div>
      </DesignSystemContainer>
    </section>

    <DesignSystemContainer class="adjustment-workspace__content">
      <DashboardServiceAdjustmentStatusCard
        class="adjustment-workspace__status"
        :adjustment="existing"
      />
      <AdjustmentBuilder
        ref="builder"
        v-model="formModel"
        v-model:share-open="shareOpen"
        class="adjustment-workspace__builder"
        :service="service"
        :professional="professional"
        :adjustment="existing"
        :total="total"
        :projected-total="projectedTotal"
        :errors="fieldErrors"
        :saving-intent="savingIntent"
        :save-error="saveError"
        @add="addItem()"
        @remove="removeItem"
        @change-kind="changeItemKind"
        @select-receipt="selectReceipt"
        @clear-receipt="clearReceipt"
        @save="save"
        @request-share="requestShare"
      />
    </DesignSystemContainer>
  </div>
</template>

<style scoped lang="scss">
.adjustment-workspace {
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

  &__heading .eyebrow {
    margin-bottom: 7px;
  }

  &__heading h1 {
    margin: 0;
    font-family: var(--font-display);
    font-size: 2.5rem;
    font-weight: 500;
    letter-spacing: -0.04em;
    text-wrap: balance;
  }

  &__heading h1 em {
    color: var(--color-brand-muted);
    font-size: 0.55em;
    font-style: normal;
  }

  &__heading p {
    margin: 7px 0 0;
    color: rgb(255 255 255 / 58%);
    font-size: 0.82rem;
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
  .adjustment-workspace {
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
