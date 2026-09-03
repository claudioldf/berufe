<script setup lang="ts">
import { computed } from "vue";
import type { Quote, QuotePricingMode, QuoteValidationErrors } from "~/types";
import { formatCurrency } from "~/utils/formatters";
import { quoteItemTotal, quoteLumpSumDelta } from "~/utils/quotes";

const props = defineProps<{
  subtotal: number;
  itemsAmount: number;
  errors?: QuoteValidationErrors;
}>();
const quote = defineModel<Quote>({ required: true });
const emit = defineEmits<{
  add: [];
  remove: [id: string];
  dirty: [];
  setPricingMode: [mode: QuotePricingMode];
  applyItemsAmount: [];
}>();

const isLumpSum = computed(() => quote.value.pricingMode === "lump_sum");
const delta = computed(() => quoteLumpSumDelta(quote.value));
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="builder-card">
    <header>
      <div>
        <span>03</span>
        <div>
          <h2>
            {{
              isLumpSum ? "Cálculo e valor do serviço" : "Itens do orçamento"
            }}
          </h2>
          <p>
            {{
              isLumpSum
                ? "Use os itens como um cálculo privado para chegar ao valor final."
                : "Descreva os itens, as quantidades e os valores."
            }}
          </p>
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
    <fieldset class="quote-pricing-mode">
      <legend>Como você vai cobrar?</legend>
      <div class="quote-pricing-mode__options">
        <label :class="{ 'quote-pricing-mode__option--active': !isLumpSum }">
          <input
            type="radio"
            name="pricing-mode"
            value="itemized"
            :checked="!isLumpSum"
            @change="emit('setPricingMode', 'itemized')"
          />
          Por itens
        </label>
        <label :class="{ 'quote-pricing-mode__option--active': isLumpSum }">
          <input
            type="radio"
            name="pricing-mode"
            value="lump_sum"
            :checked="isLumpSum"
            @change="emit('setPricingMode', 'lump_sum')"
          />
          Preço fechado
        </label>
      </div>
    </fieldset>
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
        <button
          v-if="isLumpSum || quote.items.length > 1"
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
      v-if="!isLumpSum && props.errors?.itemsMessage"
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
    <div v-if="!isLumpSum" class="builder-total">
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
    <div v-else class="builder-lump-sum">
      <div class="builder-lump-sum__calc">
        <span>Cálculo interno</span>
        <strong>{{ formatCurrency(itemsAmount) }}</strong>
        <small>Só você vê este cálculo.</small>
      </div>
      <label
        class="builder-lump-sum__field"
        :class="{
          'builder-lump-sum__field--invalid': props.errors?.lumpSumAmount,
        }"
      >
        <span>Valor do serviço</span>
        <span class="builder-lump-sum__control">
          <em>R$</em>
          <input
            v-model.number="quote.lumpSumAmount"
            name="lump-sum-amount"
            type="number"
            inputmode="decimal"
            autocomplete="off"
            :aria-describedby="
              props.errors?.lumpSumAmount
                ? 'quote-lump-sum-amount-error'
                : undefined
            "
            :aria-invalid="Boolean(props.errors?.lumpSumAmount)"
            min="0"
            step="0.01"
            @input="emit('dirty')"
          />
        </span>
        <small
          v-if="props.errors?.lumpSumAmount"
          id="quote-lump-sum-amount-error"
          class="builder-lump-sum__error"
        >
          {{ props.errors.lumpSumAmount }}
        </small>
      </label>
      <UButton
        v-if="itemsAmount > 0"
        size="sm"
        color="neutral"
        variant="outline"
        icon="i-lucide-refresh-ccw"
        @click="emit('applyItemsAmount')"
      >
        Usar {{ formatCurrency(itemsAmount) }}
      </UButton>
      <p v-if="itemsAmount > 0 && delta !== 0" class="builder-lump-sum__delta">
        <UIcon
          :name="delta > 0 ? 'i-lucide-arrow-up' : 'i-lucide-arrow-down'"
        />
        {{ formatCurrency(Math.abs(delta)) }}
        {{ delta > 0 ? "acima" : "abaixo" }} do cálculo interno
      </p>
      <label class="builder-lump-sum__toggle">
        <input
          v-model="quote.itemsVisibleToCustomer"
          type="checkbox"
          @change="emit('dirty')"
        />
        Mostrar o detalhamento do serviço ao cliente
      </label>
      <small class="builder-lump-sum__hint"
        >O cliente vê o que será feito, sem os valores por item.</small
      >
    </div>
  </DesignSystemSurfaceCard>
</template>
