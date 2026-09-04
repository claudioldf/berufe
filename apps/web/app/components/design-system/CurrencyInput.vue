<script setup lang="ts">
import { computed, nextTick } from "vue";
import {
  formatCurrency,
  parseBrazilianCurrencyInput,
} from "~/utils/formatters";

const amount = defineModel<number>({ required: true });
const displayValue = computed(() =>
  Number.isFinite(Number(amount.value)) ? formatCurrency(amount.value) : "",
);

async function updateAmount(event: Event) {
  const input = event.target as HTMLInputElement;
  amount.value = parseBrazilianCurrencyInput(input.value);
  await nextTick();
  normalizeDisplay(input);
}

function normalizeDisplay(input: HTMLInputElement) {
  input.value = displayValue.value;
  input.setSelectionRange(input.value.length, input.value.length);
}

function selectAmount(event: FocusEvent) {
  (event.target as HTMLInputElement).select();
}

function finishEditing(event: FocusEvent) {
  normalizeDisplay(event.target as HTMLInputElement);
}
</script>

<template>
  <input
    type="text"
    inputmode="decimal"
    autocomplete="off"
    spellcheck="false"
    :value="displayValue"
    @input="updateAmount"
    @focus="selectAmount"
    @blur="finishEditing"
  />
</template>
