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
  <DesignSystemSurfaceCard
    as="section"
    class="adjustment-builder-card adjustment-items-editor"
  >
    <header>
      <div>
        <span>02</span>
        <div>
          <h2>Itens do ajuste</h2>
          <p>
            Detalhe os serviços ou compras que serão submetidos à aprovação.
          </p>
        </div>
      </div>
    </header>

    <div v-if="items.length" class="adjustment-items">
      <div class="adjustment-item adjustment-item--head" aria-hidden="true">
        <span>Tipo</span>
        <span>Descrição</span>
        <span>Qtd.</span>
        <span>Valor unit.</span>
        <span>Total</span>
        <span />
      </div>
      <fieldset
        v-for="(item, index) in items"
        :key="item.key"
        class="adjustment-item"
      >
        <legend class="adjustment-item__mobile-index">
          Item {{ index + 1 }}
        </legend>
        <button
          v-if="items.length > 1"
          class="adjustment-item__remove"
          type="button"
          :aria-label="`Remover item ${index + 1}`"
          @click="emit('remove', index)"
        >
          <UIcon name="i-lucide-trash-2" aria-hidden="true" />
        </button>

        <label class="adjustment-item__kind">
          <span class="adjustment-item__label"
            >Tipo do item {{ index + 1 }}</span
          >
          <select
            v-model="item.kind"
            :name="`adjustment-item-${index}-kind`"
            autocomplete="off"
            required
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
        <label
          class="adjustment-item__description"
          :class="{
            'adjustment-item__field--invalid':
              errors[`item-${index}-description`],
          }"
        >
          <span class="adjustment-item__label">
            Descrição do item {{ index + 1 }}
          </span>
          <input
            v-model="item.description"
            :name="`adjustment-item-${index}-description`"
            maxlength="160"
            autocomplete="off"
            placeholder="Ex.: Pintura adicional…"
            required
            :aria-describedby="
              errors[`item-${index}-description`]
                ? `adjustment-item-${index}-description-error`
                : undefined
            "
            :aria-invalid="Boolean(errors[`item-${index}-description`])"
          />
          <small
            v-if="errors[`item-${index}-description`]"
            :id="`adjustment-item-${index}-description-error`"
            class="adjustment-item__error"
          >
            {{ errors[`item-${index}-description`] }}
          </small>
        </label>
        <label
          :class="{
            'adjustment-item__field--invalid': errors[`item-${index}-quantity`],
          }"
        >
          <span class="adjustment-item__label">
            Quantidade do item {{ index + 1 }}
          </span>
          <input
            v-model.number="item.quantity"
            :name="`adjustment-item-${index}-quantity`"
            type="number"
            inputmode="decimal"
            autocomplete="off"
            min="0.001"
            step="0.001"
            required
            :aria-describedby="
              errors[`item-${index}-quantity`]
                ? `adjustment-item-${index}-quantity-error`
                : undefined
            "
            :aria-invalid="Boolean(errors[`item-${index}-quantity`])"
          />
          <small
            v-if="errors[`item-${index}-quantity`]"
            :id="`adjustment-item-${index}-quantity-error`"
            class="adjustment-item__error"
          >
            {{ errors[`item-${index}-quantity`] }}
          </small>
        </label>
        <label
          :class="{
            'adjustment-item__field--invalid':
              errors[`item-${index}-unit-price`],
          }"
        >
          <span class="adjustment-item__label">
            Valor unitário do item {{ index + 1 }}
          </span>
          <CurrencyInput
            v-model="item.unitPrice"
            class="adjustment-item__currency-input"
            :name="`adjustment-item-${index}-unit-price`"
            required
            :aria-describedby="
              errors[`item-${index}-unit-price`]
                ? `adjustment-item-${index}-unit-price-error`
                : undefined
            "
            :aria-invalid="Boolean(errors[`item-${index}-unit-price`])"
          />
          <small
            v-if="errors[`item-${index}-unit-price`]"
            :id="`adjustment-item-${index}-unit-price-error`"
            class="adjustment-item__error"
          >
            {{ errors[`item-${index}-unit-price`] }}
          </small>
        </label>
        <span class="adjustment-item__total">
          <span class="adjustment-item__label">
            Total do item {{ index + 1 }}
          </span>
          <strong>{{ money.format(lineTotal(item)) }}</strong>
        </span>

        <div
          v-if="item.kind === 'material_reimbursement'"
          class="adjustment-item__receipt"
        >
          <label>
            <span>Comprovante (opcional, JPEG ou PNG)</span>
            <input
              :name="`adjustment-item-${index}-receipt`"
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
    margin-top: 12px;
  }

  &__actions :deep(button) {
    font-size: var(--font-size-min);
    font-weight: 600;
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
    margin: 18px 0 0 auto;
    padding-top: 12px;
    border-top: 2px solid var(--ink);
    color: var(--ink);
    font-size: 0.86rem;
  }

  &__summary > span {
    font-weight: 600;
  }

  &__summary strong {
    font-size: 1rem;
    font-weight: 750;
    font-variant-numeric: tabular-nums;
  }
}

.adjustment-items {
  overflow-x: auto;
}

.adjustment-item {
  display: grid;
  grid-template-columns:
    minmax(138px, 0.85fr) minmax(150px, 1.25fr) 62px 100px 86px
    30px;
  gap: 7px;
  align-items: start;
  min-width: 685px;
  margin: 0;
  padding: 8px 0;
  border: 0;
  border-top: 1px solid var(--line);

  &--head {
    align-items: center;
    border: 0;
    color: var(--ink-soft);
    font-size: 0.82rem;
    font-weight: 700;
    text-transform: uppercase;
  }

  &--head > span:nth-child(n + 3) {
    text-align: right;
  }

  & > label {
    display: grid;
    gap: 4px;
  }

  input,
  select {
    width: 100%;
    min-height: 38px;
    padding: 8px;
    border: 1px solid var(--line);
    border-radius: 8px;
    background-color: var(--color-surface-control);
    color: var(--ink);
    font-size: 0.84rem;
    transition: border-color var(--motion-fast) ease;
  }

  &__remove {
    grid-column: 6;
    grid-row: 1;
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
    margin-top: 5px;
  }

  &__remove:focus-visible {
    outline: none;
    box-shadow: var(--focus-ring);
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
    font-size: var(--font-size-min);
    font-weight: 650;
    line-height: 1.25;
  }

  &__total {
    display: grid;
    text-align: right;
  }

  &__total strong {
    margin-top: 9px;
    font-size: 0.84rem;
    font-variant-numeric: tabular-nums;
    text-align: right;
    white-space: nowrap;
  }

  &__currency-input {
    text-align: right;
  }

  &__receipt {
    grid-column: 1 / -1;
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
}

@media (width <= 720px) {
  .adjustment-items {
    display: grid;
    gap: 12px;
    overflow-x: visible;
  }

  .adjustment-item {
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
      font-weight: 750;
    }

    &__label {
      color: var(--ink-soft);
      font-size: var(--font-size-min);
      font-weight: 700;
    }

    &__kind,
    &__description,
    &__receipt {
      grid-column: 1 / -1;
    }

    &__remove {
      grid-column: 2;
      grid-row: 1;
      justify-self: end;
      margin-top: 0;
    }

    input,
    select {
      min-height: 42px;
      font-size: 1rem;
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
      background: var(--color-surface-control);
      font-size: 1rem;
    }

    &__receipt {
      align-items: flex-start;
    }
  }
}
</style>
