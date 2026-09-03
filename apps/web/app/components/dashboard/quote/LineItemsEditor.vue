<script setup lang="ts">
import type { Quote, QuotePricingMode, QuoteValidationErrors } from "~/types";
import { formatCurrency } from "~/utils/formatters";
import { quoteItemTotal } from "~/utils/quotes";

const props = defineProps<{
  subtotal: number;
  total: number;
  errors?: QuoteValidationErrors;
}>();
const quote = defineModel<Quote>({ required: true });
const emit = defineEmits<{
  add: [];
  remove: [id: string];
  dirty: [];
  changeMode: [mode: QuotePricingMode];
}>();
const fixedPrice = computed(() => quote.value.pricingMode === "fixed_price");
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="builder-card pricing-editor">
    <header>
      <div>
        <span>03</span>
        <div>
          <h2>Forma de cobrança e valores</h2>
          <p>Escolha como o preço será apresentado ao cliente.</p>
        </div>
      </div>
      <UButton
        size="sm"
        color="neutral"
        variant="outline"
        icon="i-lucide-plus"
        :disabled="quote.items.length >= 20"
        @click="emit('add')"
      >
        Adicionar item
      </UButton>
    </header>

    <fieldset class="pricing-mode">
      <legend>Forma de cobrança</legend>
      <label
        class="pricing-mode__option"
        :class="{
          'pricing-mode__option--selected': quote.pricingMode === 'fixed_price',
        }"
      >
        <input
          type="radio"
          name="pricing-mode"
          value="fixed_price"
          :checked="quote.pricingMode === 'fixed_price'"
          @change="emit('changeMode', 'fixed_price')"
        />
        <span class="pricing-mode__icon"
          ><UIcon name="i-lucide-lock-keyhole" aria-hidden="true"
        /></span>
        <span>
          <strong>Preço fechado</strong>
          <small
            >O cliente vê somente o valor final. Os cálculos abaixo ficam
            privados.</small
          >
        </span>
      </label>
      <label
        class="pricing-mode__option"
        :class="{
          'pricing-mode__option--selected': quote.pricingMode === 'itemized',
        }"
      >
        <input
          type="radio"
          name="pricing-mode"
          value="itemized"
          :checked="quote.pricingMode === 'itemized'"
          @change="emit('changeMode', 'itemized')"
        />
        <span class="pricing-mode__icon"
          ><UIcon name="i-lucide-list" aria-hidden="true"
        /></span>
        <span>
          <strong>Detalhado</strong>
          <small
            >O cliente vê cada item, quantidade, valor unitário e total.</small
          >
        </span>
      </label>
    </fieldset>

    <div v-if="fixedPrice" class="pricing-editor__private-note">
      <UIcon name="i-lucide-eye-off" aria-hidden="true" />
      <span>
        <strong>Cálculo particular</strong> Os itens abaixo servem apenas para
        ajudar você a calcular o custo total do serviço. Eles não definem o
        preço do orçamento e não aparecem para o cliente. O cliente verá somente
        o “Preço final ao cliente” e a descrição informada na seção Serviço.
      </span>
    </div>

    <div class="quote-items">
      <div class="quote-item quote-item--head" aria-hidden="true">
        <span>Descrição</span><span>Qtd.</span><span>Unidade</span
        ><span>{{ fixedPrice ? "Custo unit." : "Valor unit." }}</span
        ><span>{{ fixedPrice ? "Custo" : "Total" }}</span
        ><span />
      </div>
      <div
        v-for="(item, index) in quote.items"
        :key="item.id"
        class="quote-item"
        @input="emit('dirty')"
      >
        <span class="quote-item__mobile-index">Item {{ index + 1 }}</span>
        <button
          v-if="quote.items.length > 1"
          class="quote-item__remove"
          type="button"
          :aria-label="`Remover item ${index + 1}`"
          @click="emit('remove', item.id)"
        >
          <UIcon name="i-lucide-trash-2" aria-hidden="true" />
        </button>
        <label
          class="quote-item__description"
          :class="{
            'quote-item__field--invalid':
              props.errors?.items[item.id]?.description,
          }"
        >
          <span class="quote-item__label"
            >Descrição do item {{ index + 1 }}</span
          >
          <input
            v-model="item.description"
            :name="`item-${item.id}-description`"
            autocomplete="off"
            :placeholder="
              fixedPrice ? 'Ex.: mão de obra…' : `Item ${index + 1}…`
            "
            :aria-describedby="
              props.errors?.items[item.id]?.description
                ? `item-${item.id}-description-error`
                : undefined
            "
            :aria-invalid="Boolean(props.errors?.items[item.id]?.description)"
            maxlength="160"
          />
          <small
            v-if="props.errors?.items[item.id]?.description"
            :id="`item-${item.id}-description-error`"
            class="quote-item__error"
          >
            {{ props.errors.items[item.id]?.description }}
          </small>
        </label>
        <label
          :class="{
            'quote-item__field--invalid':
              props.errors?.items[item.id]?.quantity,
          }"
        >
          <span class="quote-item__label"
            >Quantidade do item {{ index + 1 }}</span
          >
          <input
            v-model.number="item.quantity"
            :name="`item-${item.id}-quantity`"
            type="number"
            inputmode="decimal"
            autocomplete="off"
            :aria-describedby="
              props.errors?.items[item.id]?.quantity
                ? `item-${item.id}-quantity-error`
                : undefined
            "
            :aria-invalid="Boolean(props.errors?.items[item.id]?.quantity)"
            min="0.001"
            step="0.001"
          />
          <small
            v-if="props.errors?.items[item.id]?.quantity"
            :id="`item-${item.id}-quantity-error`"
            class="quote-item__error"
          >
            {{ props.errors.items[item.id]?.quantity }}
          </small>
        </label>
        <label
          :class="{
            'quote-item__field--invalid': props.errors?.items[item.id]?.unit,
          }"
        >
          <span class="quote-item__label">Unidade do item {{ index + 1 }}</span>
          <select
            v-model="item.unit"
            :name="`item-${item.id}-unit`"
            autocomplete="off"
            :aria-describedby="
              props.errors?.items[item.id]?.unit
                ? `item-${item.id}-unit-error`
                : undefined
            "
            :aria-invalid="Boolean(props.errors?.items[item.id]?.unit)"
          >
            <option>serviço</option>
            <option>hora</option>
            <option>ponto</option>
            <option>m²</option>
            <option>unidade</option>
          </select>
          <small
            v-if="props.errors?.items[item.id]?.unit"
            :id="`item-${item.id}-unit-error`"
            class="quote-item__error"
          >
            {{ props.errors.items[item.id]?.unit }}
          </small>
        </label>
        <label
          :class="{
            'quote-item__field--invalid':
              props.errors?.items[item.id]?.unitPrice,
          }"
        >
          <span class="quote-item__label"
            >{{ fixedPrice ? "Custo" : "Valor" }} unitário do item
            {{ index + 1 }}</span
          >
          <input
            v-model.number="item.unitPrice"
            :name="`item-${item.id}-unit-price`"
            type="number"
            inputmode="decimal"
            autocomplete="off"
            :aria-describedby="
              props.errors?.items[item.id]?.unitPrice
                ? `item-${item.id}-unit-price-error`
                : undefined
            "
            :aria-invalid="Boolean(props.errors?.items[item.id]?.unitPrice)"
            min="0"
            step="0.01"
          />
          <small
            v-if="props.errors?.items[item.id]?.unitPrice"
            :id="`item-${item.id}-unit-price-error`"
            class="quote-item__error"
          >
            {{ props.errors.items[item.id]?.unitPrice }}
          </small>
        </label>
        <span class="quote-item__total">
          <span class="quote-item__label"
            >{{ fixedPrice ? "Custo" : "Total" }} do item {{ index + 1 }}</span
          >
          <strong>{{ formatCurrency(quoteItemTotal(item)) }}</strong>
        </span>
      </div>
    </div>
    <p
      v-if="props.errors?.itemsMessage"
      class="quote-items__error"
      role="alert"
    >
      {{ props.errors.itemsMessage }}
    </p>
    <UButton
      class="quote-items__mobile-add"
      color="neutral"
      variant="outline"
      block
      icon="i-lucide-plus"
      :disabled="quote.items.length >= 20"
      @click="emit('add')"
    >
      Adicionar item
    </UButton>
    <div class="builder-total">
      <div>
        <span>{{ fixedPrice ? "Custo total (particular)" : "Subtotal" }}</span
        ><strong>{{ formatCurrency(subtotal) }}</strong>
      </div>
      <label v-if="fixedPrice">
        <span>Preço final ao cliente</span>
        <span class="builder-total__field">
          <span
            class="builder-total__control"
            :class="{
              'builder-total__control--invalid': props.errors?.fixedPrice,
            }"
          >
            <em>R$</em>
            <input
              v-model.number="quote.fixedPrice"
              name="fixed-price"
              type="number"
              inputmode="decimal"
              autocomplete="off"
              :aria-describedby="
                props.errors?.fixedPrice ? 'quote-fixed-price-error' : undefined
              "
              :aria-invalid="Boolean(props.errors?.fixedPrice)"
              min="0"
              step="0.01"
              @input="emit('dirty')"
            />
          </span>
          <small
            v-if="props.errors?.fixedPrice"
            id="quote-fixed-price-error"
            class="builder-total__error"
          >
            {{ props.errors.fixedPrice }}
          </small>
        </span>
      </label>
      <label v-else>
        <span>Desconto</span>
        <span class="builder-total__field">
          <span
            class="builder-total__control"
            :class="{
              'builder-total__control--invalid': props.errors?.discount,
            }"
          >
            <em>R$</em>
            <input
              v-model.number="quote.discount"
              name="discount"
              type="number"
              inputmode="decimal"
              autocomplete="off"
              :aria-describedby="
                props.errors?.discount ? 'quote-discount-error' : undefined
              "
              :aria-invalid="Boolean(props.errors?.discount)"
              min="0"
              :max="subtotal"
              step="0.01"
              @input="emit('dirty')"
            />
          </span>
          <small
            v-if="props.errors?.discount"
            id="quote-discount-error"
            class="builder-total__error"
          >
            {{ props.errors.discount }}
          </small>
        </span>
      </label>
      <div v-if="!fixedPrice">
        <span>Total</span><strong>{{ formatCurrency(total) }}</strong>
      </div>
    </div>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.pricing-mode {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
  padding: 0;
  margin: 0 0 18px;
  border: 0;

  legend {
    position: absolute;
    width: 1px;
    height: 1px;
    overflow: hidden;
    clip-path: inset(50%);
  }

  &__option {
    display: grid;
    grid-template-columns: auto auto 1fr;
    gap: 10px;
    align-items: start;
    padding: 14px;
    border: 1px solid var(--line);
    border-radius: 12px;
    background: var(--color-surface-control);
    cursor: pointer;
    transition:
      border-color var(--motion-fast) ease,
      background var(--motion-fast) ease;
  }

  &__option--selected {
    border-color: var(--color-brand);
    background: var(--color-brand-tint-muted);
  }

  &__option input {
    margin-top: 4px;
    accent-color: var(--color-brand);
  }

  &__icon {
    display: grid;
    place-items: center;
    width: 32px;
    height: 32px;
    border-radius: 9px;
    background: white;
    color: var(--color-brand);
  }

  &__option strong,
  &__option small {
    display: block;
  }

  &__option strong {
    font-size: 0.88rem;
  }

  &__option small {
    margin-top: 3px;
    color: var(--ink-soft);
    font-size: 0.78rem;
    line-height: 1.4;
  }
}

.pricing-editor__private-note {
  display: flex;
  gap: 9px;
  align-items: flex-start;
  padding: 13px 14px;
  margin-bottom: 10px;
  border: 1px solid color-mix(in srgb, var(--color-warning) 35%, var(--line));
  border-radius: 10px;
  background: var(--color-warning-tint);
  box-shadow: inset 3px 0 0 var(--color-warning);
  color: var(--ink);
  font-size: 0.8rem;
  line-height: 1.5;

  svg {
    flex: 0 0 auto;
    margin-top: 2px;
    color: var(--color-warning);
    font-size: 1.1rem;
  }

  strong {
    display: block;
    margin-bottom: 2px;
    color: var(--ink);
  }
}

@media (width <= 720px) {
  .pricing-mode {
    grid-template-columns: 1fr;
  }
}
</style>
