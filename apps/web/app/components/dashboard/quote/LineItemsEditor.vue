<script setup lang="ts">
import type { Quote } from "~/types";
import { formatCurrency } from "~/utils/formatters";
import { quoteItemTotal } from "~/utils/quotes";

defineProps<{ subtotal: number }>();
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
          <p>Os totais abaixo são uma prévia da interface.</p>
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
        <label>
          <span class="sr-only">Descrição do item {{ index + 1 }}</span>
          <input
            v-model="item.description"
            :name="`item-${item.id}-description`"
            autocomplete="off"
            :placeholder="`Item ${index + 1}…`"
            maxlength="160"
          />
        </label>
        <label>
          <span class="sr-only">Quantidade do item {{ index + 1 }}</span>
          <input
            v-model.number="item.quantity"
            :name="`item-${item.id}-quantity`"
            type="number"
            inputmode="decimal"
            autocomplete="off"
            min="0.01"
            step="0.01"
          />
        </label>
        <label>
          <span class="sr-only">Unidade do item {{ index + 1 }}</span>
          <select
            v-model="item.unit"
            :name="`item-${item.id}-unit`"
            autocomplete="off"
          >
            <option>serviço</option>
            <option>hora</option>
            <option>ponto</option>
            <option>m²</option>
            <option>unidade</option>
          </select>
        </label>
        <label>
          <span class="sr-only">Valor unitário do item {{ index + 1 }}</span>
          <input
            v-model.number="item.unitPrice"
            :name="`item-${item.id}-unit-price`"
            type="number"
            inputmode="decimal"
            autocomplete="off"
            min="0"
            step="0.01"
          />
        </label>
        <strong>{{ formatCurrency(quoteItemTotal(item)) }}</strong>
        <button
          type="button"
          :aria-label="`Remover item ${index + 1}`"
          :disabled="quote.items.length === 1"
          @click="emit('remove', item.id)"
        >
          <UIcon name="i-lucide-trash-2" aria-hidden="true" />
        </button>
      </div>
    </div>
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
        <div>
          <em>R$</em>
          <input
            v-model.number="quote.discount"
            name="discount"
            type="number"
            inputmode="decimal"
            autocomplete="off"
            min="0"
            :max="subtotal"
            step="0.01"
            @input="emit('dirty')"
          />
        </div>
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
