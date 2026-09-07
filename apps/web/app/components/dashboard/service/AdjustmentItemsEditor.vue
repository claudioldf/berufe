<script setup lang="ts">
import CurrencyInput from "~/components/design-system/CurrencyInput.vue";
import type {
  ServiceAdjustmentEditorItem,
  ServiceAdjustmentItemKind,
} from "~/types";

defineProps<{
  total: number;
  errors: Record<string, string>;
}>();

const items = defineModel<ServiceAdjustmentEditorItem[]>({ required: true });
const emit = defineEmits<{
  add: [];
  remove: [index: number];
  changeKind: [index: number];
  selectReceipt: [index: number, event: Event];
  clearReceipt: [index: number];
}>();

const kindOptions: Array<{
  value: ServiceAdjustmentItemKind;
  label: string;
}> = [
  { value: "additional_service", label: "Serviço adicional" },
  {
    value: "material_reimbursement",
    label: "Compra e reembolso de material",
  },
];
const money = new Intl.NumberFormat("pt-BR", {
  style: "currency",
  currency: "BRL",
});

function lineTotal(item: ServiceAdjustmentEditorItem) {
  const value = Number(item.quantity || 0) * Number(item.unitPrice || 0);
  return item.kind === "credit" ? -value : value;
}
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="adjustment-items-editor">
    <header class="adjustment-items-editor__heading">
      <h2>Itens do ajuste</h2>
      <p>
        Detalhe os serviços ou compras que serão submetidos à aprovação do
        cliente.
      </p>
    </header>

    <div v-if="items.length" class="adjustment-items-editor__items">
      <fieldset
        v-for="(item, index) in items"
        :key="item.key"
        class="adjustment-item"
      >
        <legend>Item {{ index + 1 }}</legend>
        <button
          class="adjustment-item__remove"
          type="button"
          :aria-label="`Remover item ${index + 1}`"
          @click="emit('remove', index)"
        >
          <UIcon name="i-lucide-trash-2" aria-hidden="true" />
        </button>

        <div class="adjustment-item__details">
          <label>
            <span>Tipo</span>
            <select
              v-model="item.kind"
              :name="`adjustment-item-${index}-kind`"
              @change="emit('changeKind', index)"
            >
              <option
                v-for="option in kindOptions"
                :key="option.value"
                :value="option.value"
              >
                {{ option.label }}
              </option>
            </select>
          </label>
          <label>
            <span>Descrição</span>
            <input
              v-model="item.description"
              :name="`adjustment-item-${index}-description`"
              maxlength="160"
              autocomplete="off"
              placeholder="Ex.: Pintura da parede adicional"
              :aria-invalid="Boolean(errors[`item-${index}`])"
            />
          </label>
        </div>

        <div class="adjustment-item__values">
          <label>
            <span>Quantidade</span>
            <input
              v-model.number="item.quantity"
              :name="`adjustment-item-${index}-quantity`"
              type="number"
              inputmode="decimal"
              autocomplete="off"
              min="0.001"
              step="0.001"
            />
          </label>
          <label>
            <span>Valor unitário</span>
            <CurrencyInput
              v-model="item.unitPrice"
              :name="`adjustment-item-${index}-unit-price`"
            />
          </label>
          <span class="adjustment-item__total">
            <span>Total do item</span>
            <strong>{{ money.format(lineTotal(item)) }}</strong>
          </span>
        </div>

        <div
          v-if="item.kind === 'material_reimbursement'"
          class="adjustment-item__receipt"
        >
          <label>
            <span>Comprovante (opcional, JPEG ou PNG)</span>
            <input
              type="file"
              accept="image/jpeg,image/png"
              @change="emit('selectReceipt', index, $event)"
            />
          </label>
          <span v-if="item.receiptFile">{{ item.receiptFile.name }}</span>
          <span v-else-if="item.mediaUploadId">Comprovante anexado</span>
          <span v-else>
            Sem comprovante — isso ficará claro para o cliente.
          </span>
          <UButton
            v-if="item.receiptFile || item.mediaUploadId"
            type="button"
            color="neutral"
            variant="link"
            @click="emit('clearReceipt', index)"
          >
            Remover comprovante
          </UButton>
        </div>

        <small v-if="errors[`item-${index}`]" role="alert">
          {{ errors[`item-${index}`] }}
        </small>
      </fieldset>
    </div>
    <p v-else class="adjustment-items-editor__empty">
      Nenhum item financeiro. O ajuste documentará apenas o texto informado.
    </p>

    <div class="adjustment-items-editor__actions">
      <UButton
        type="button"
        size="sm"
        color="neutral"
        variant="outline"
        icon="i-lucide-plus"
        :disabled="items.length >= 20"
        @click="emit('add')"
      >
        Adicionar item
      </UButton>
    </div>

    <p v-if="errors.total" class="adjustment-items-editor__error" role="alert">
      {{ errors.total }}
    </p>
    <div class="adjustment-items-editor__summary">
      <span>Total do ajuste</span>
      <strong>{{ money.format(total) }}</strong>
    </div>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.adjustment-items-editor {
  display: grid;
  gap: 16px;
  padding: 24px;

  h2,
  p {
    margin: 0;
  }

  h2 {
    font-family: var(--font-display);
    font-size: 1.45rem;
  }

  &__heading p {
    max-width: 610px;
    margin-top: 7px;
    color: var(--ink-soft);
    line-height: 1.5;
  }

  &__items {
    display: grid;
    gap: 18px;
  }

  &__empty {
    padding: 14px;
    border: 1px dashed var(--line);
    border-radius: 10px;
    color: var(--ink-soft);
    font-size: 0.84rem;
  }

  &__actions {
    display: flex;
    justify-content: flex-end;
  }

  &__error {
    color: var(--color-danger);
    font-size: 0.8rem;
  }

  &__summary {
    display: flex;
    align-items: center;
    justify-content: space-between;
    width: min(320px, 100%);
    margin-left: auto;
    padding-top: 12px;
    border-top: 2px solid var(--ink);
    color: var(--ink);
    font-size: 0.86rem;
  }
}

.adjustment-item {
  position: relative;
  display: grid;
  gap: 14px;
  margin: 0;
  padding: 16px;
  border: 1px solid var(--line);
  border-radius: 13px;

  legend {
    padding: 0 4px;
    color: var(--color-brand);
    font-size: 0.76rem;
    font-weight: 850;
  }

  label,
  &__total {
    display: grid;
    gap: 6px;
    color: var(--ink);
    font-size: 0.83rem;
    font-weight: 750;
  }

  input,
  select {
    width: 100%;
    padding: 11px 12px;
    border: 1px solid var(--line);
    border-radius: 10px;
    background: var(--color-surface-control);
    color: var(--ink);
    font: inherit;
  }

  &__remove {
    position: absolute;
    top: 9px;
    right: 10px;
    display: grid;
    place-items: center;
    width: 27px;
    height: 27px;
    padding: 0;
    border: 0;
    border-radius: 7px;
    background: transparent;
    color: #a45245;
    cursor: pointer;
  }

  &__remove:focus-visible {
    outline: none;
    box-shadow: var(--focus-ring);
  }

  &__details {
    display: grid;
    grid-template-columns: minmax(180px, 0.7fr) minmax(0, 1.3fr);
    gap: 13px;
  }

  &__values {
    display: grid;
    grid-template-columns: minmax(110px, 0.55fr) minmax(180px, 1fr) minmax(
        140px,
        0.75fr
      );
    gap: 13px;
    align-items: end;
  }

  &__values :deep(.currency-input),
  &__values :deep(input) {
    min-height: 43px;
  }

  &__total {
    min-height: 66px;
    justify-content: end;
    text-align: right;
  }

  &__total > span {
    color: var(--ink-soft);
  }

  &__total strong {
    font-size: 1rem;
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

  small[role="alert"] {
    color: var(--color-danger);
    font-size: 0.8rem;
  }
}

@media (width <= 700px) {
  .adjustment-item {
    &__details,
    &__values {
      grid-template-columns: 1fr;
    }

    &__total {
      min-height: auto;
      padding-top: 12px;
      border-top: 1px solid var(--line);
    }
  }
}
</style>
