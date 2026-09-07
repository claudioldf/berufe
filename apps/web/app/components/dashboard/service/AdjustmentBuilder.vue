<script setup lang="ts">
import { computed, shallowRef, useTemplateRef } from "vue";
import type {
  ProfessionalServiceJob,
  QuoteProfessional,
  ServiceAdjustment,
  ServiceAdjustmentEditorForm,
  ServiceAdjustmentEditorSaveIntent,
} from "~/types";

const props = defineProps<{
  service: ProfessionalServiceJob;
  professional: QuoteProfessional;
  adjustment?: ServiceAdjustment;
  total: number;
  projectedTotal: number;
  errors: Record<string, string>;
  savingIntent: ServiceAdjustmentEditorSaveIntent | null;
  saveError: string;
}>();

const form = defineModel<ServiceAdjustmentEditorForm>({ required: true });
const shareOpen = defineModel<boolean>("shareOpen", { default: false });
const emit = defineEmits<{
  add: [];
  remove: [index: number];
  changeKind: [index: number];
  selectReceipt: [index: number, event: Event];
  clearReceipt: [index: number];
  save: [intent: ServiceAdjustmentEditorSaveIntent];
  requestShare: [];
}>();

const previewOpen = shallowRef(false);
const formRoot = useTemplateRef<HTMLFormElement>("formRoot");
const valid = computed(
  () =>
    Boolean(form.value.title.trim()) &&
    form.value.items.length > 0 &&
    props.projectedTotal >= 0 &&
    form.value.items.every(
      (item) =>
        Boolean(item.description.trim()) &&
        item.quantity > 0 &&
        item.unitPrice >= 0,
    ),
);
const displayedError = computed(() => {
  if (props.saveError) return props.saveError;
  return Object.keys(props.errors).length
    ? "Revise os campos destacados para continuar."
    : "";
});

function focusFirstError() {
  formRoot.value?.querySelector<HTMLElement>('[aria-invalid="true"]')?.focus();
}

defineExpose({ focusFirstError });
</script>

<template>
  <div class="adjustment-builder">
    <form
      ref="formRoot"
      class="adjustment-builder__form"
      novalidate
      @submit.prevent="emit('save', 'draft')"
    >
      <DashboardServiceAdjustmentDetailsFields
        v-model="form"
        :errors="errors"
      />
      <DashboardServiceAdjustmentItemsEditor
        v-model="form.items"
        :total="total"
        :errors="errors"
        @add="emit('add')"
        @remove="emit('remove', $event)"
        @change-kind="emit('changeKind', $event)"
        @select-receipt="(index, event) => emit('selectReceipt', index, event)"
        @clear-receipt="emit('clearReceipt', $event)"
      />
      <DashboardServiceAdjustmentSaveBar
        :valid="valid"
        :saving-intent="savingIntent"
        :error="displayedError"
        @preview="previewOpen = true"
        @save="emit('save', 'draft')"
        @share="emit('requestShare')"
      />
    </form>

    <aside class="adjustment-builder__preview">
      <div class="adjustment-builder__preview-label">
        <span>Prévia do cliente</span>
        <em>Atualização instantânea</em>
      </div>
      <DashboardServiceAdjustmentPreview
        :form="form"
        :service="service"
        :professional="professional"
        :adjustment-number="adjustment?.number"
        :total="total"
        :projected-total="projectedTotal"
      />
    </aside>

    <UModal
      v-model:open="previewOpen"
      title="Prévia do ajuste"
      description="Esta é a apresentação que o cliente verá."
    >
      <template #body>
        <DashboardServiceAdjustmentPreview
          :form="form"
          :service="service"
          :professional="professional"
          :adjustment-number="adjustment?.number"
          :total="total"
          :projected-total="projectedTotal"
        />
      </template>
    </UModal>

    <UModal
      v-model:open="shareOpen"
      title="Compartilhar ajuste"
      description="Escolha como compartilhar o link seguro com seu cliente."
    >
      <template #body>
        <div class="adjustment-share">
          <span>
            <UIcon name="i-lucide-message-circle" aria-hidden="true" />
          </span>
          <div>
            <strong>Enviar pelo WhatsApp</strong>
            <p>
              A Berufe abre o WhatsApp com uma mensagem pronta e o link. Não
              enviamos a mensagem nem acessamos a conversa.
            </p>
          </div>
        </div>
        <div class="adjustment-share__link">
          <UIcon name="i-lucide-link" aria-hidden="true" />
          <span>
            berufe.com.br/orcamento/••••••••#ajuste-{{
              adjustment?.number ?? "novo"
            }}
          </span>
        </div>
        <p v-if="saveError" class="adjustment-share__error" role="alert">
          {{ saveError }}
        </p>
      </template>
      <template #footer>
        <UButton color="neutral" variant="ghost" @click="shareOpen = false">
          Cancelar
        </UButton>
        <UButton
          color="neutral"
          variant="outline"
          icon="i-lucide-link"
          :loading="savingIntent === 'copy'"
          :disabled="Boolean(savingIntent)"
          @click="emit('save', 'copy')"
        >
          Copiar link
        </UButton>
        <UButton
          color="primary"
          icon="i-lucide-message-circle"
          :loading="savingIntent === 'whatsapp'"
          :disabled="Boolean(savingIntent)"
          @click="emit('save', 'whatsapp')"
        >
          Abrir WhatsApp
        </UButton>
      </template>
    </UModal>
  </div>
</template>

<style scoped lang="scss">
.adjustment-builder {
  display: grid;
  grid-template-columns: minmax(0, 1.25fr) minmax(330px, 0.75fr);
  gap: 24px;
  align-items: start;

  &__form {
    display: grid;
    grid-template-columns: minmax(0, 1fr);
    gap: 14px;
    min-width: 0;
  }

  &__form :where(input, select, textarea):focus {
    outline: none;
  }

  &__form :where(input, select, textarea):focus-visible {
    border-color: var(--color-brand);
    box-shadow: none;
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

:deep(.adjustment-builder-card) {
  padding: 22px;
}

:deep(.adjustment-builder-card > header) {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-bottom: 17px;
  margin-bottom: 18px;
  border-bottom: 1px solid var(--line);
}

:deep(.adjustment-builder-card > header > div) {
  display: flex;
  align-items: center;
  gap: 11px;
}

:deep(.adjustment-builder-card > header > div > span) {
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

:deep(.adjustment-builder-card h2),
:deep(.adjustment-builder-card p) {
  margin: 0;
}

:deep(.adjustment-builder-card h2) {
  font-family: var(--font-display);
  font-size: 1.25rem;
  text-wrap: balance;
}

:deep(.adjustment-builder-card header p) {
  margin-top: 3px;
  color: var(--ink-soft);
  font-size: 0.84rem;
}

.adjustment-share {
  display: flex;
  align-items: center;
  gap: 13px;
  padding: 16px;
  border-radius: 13px;
  background: #e9f5f1;

  & > span {
    display: grid;
    flex: 0 0 auto;
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
    overflow-wrap: anywhere;
  }

  &__error {
    color: var(--color-danger);
  }
}

@media (width <= 1000px) {
  .adjustment-builder {
    grid-template-columns: 1fr;

    &__preview {
      display: none;
    }
  }
}
</style>
