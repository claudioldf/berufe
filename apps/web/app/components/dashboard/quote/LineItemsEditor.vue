<script setup lang="ts">
import type { Quote, QuoteValidationErrors } from "~/types";
import { formatCurrency } from "~/utils/formatters";
import { quoteItemTotal } from "~/utils/quotes";

const props = defineProps<{
  subtotal: number;
  errors?: QuoteValidationErrors;
}>();
const quote = defineModel<Quote>({ required: true });
const emit = defineEmits<{
  add: [];
  remove: [id: string];
  dirty: [];
}>();
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="builder-card">
    <header>
      <div>
        <span>03</span>
        <div>
          <h2>Itens do orçamento</h2>
          <p>Descreva os itens, as quantidades e os valores.</p>
        </div>
      </div>
      <UButton
        size="sm"
        color="neutral"
        variant="outline"
        icon="i-lucide-plus"
        @click="emit('add')"
      >
        Adicionar item
      </UButton>
    </header>
    <div class="quote-items">
      <div class="quote-item quote-item--head" aria-hidden="true">
        <span>Descrição</span><span>Qtd.</span><span>Unidade</span
        ><span>Valor unit.</span><span>Total</span><span />
      </div>
      <div
        v-for="(item, index) in quote.items"
        :key="item.id"
        class="quote-item"
        @input="emit('dirty')"
      >
        <span class="quote-item__mobile-index">Item {{ index + 1 }}</span>
        <DesignSystemDisabledTooltip
          :reason="
            quote.items.length === 1
              ? 'O orçamento precisa de pelo menos um item'
              : null
          "
        >
          <button
            class="quote-item__remove"
            type="button"
            :aria-label="`Remover item ${index + 1}`"
            :disabled="quote.items.length === 1"
            @click="emit('remove', item.id)"
          >
            <UIcon name="i-lucide-trash-2" aria-hidden="true" />
          </button>
        </DesignSystemDisabledTooltip>
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
            :placeholder="`Item ${index + 1}…`"
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
            min="0.01"
            step="0.01"
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
            >Valor unitário do item {{ index + 1 }}</span
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
          <span class="quote-item__label">Total do item {{ index + 1 }}</span>
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
      @click="emit('add')"
    >
      Adicionar item
    </UButton>
    <div class="builder-total">
      <div>
        <span>Subtotal</span><strong>{{ formatCurrency(subtotal) }}</strong>
      </div>
      <label>
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
      <div>
        <span>Total</span
        ><strong>{{
          formatCurrency(Math.max(0, subtotal - quote.discount))
        }}</strong>
      </div>
    </div>
  </DesignSystemSurfaceCard>
</template>
