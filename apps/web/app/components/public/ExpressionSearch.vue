<script setup lang="ts">
import { computed } from "vue";
import type {
  ExpressionSearchPayload,
  SearchLocation,
  SearchLocationSource,
} from "~/types";

withDefaults(
  defineProps<{
    compact?: boolean;
    location?: SearchLocation;
    cities?: SearchLocation[];
    locationSource?: SearchLocationSource;
  }>(),
  { compact: false, cities: () => [], locationSource: "fallback" },
);

const emit = defineEmits<{
  submit: [payload: ExpressionSearchPayload];
  locationChange: [location: SearchLocation];
}>();
const MAXIMUM_EXPRESSION_LENGTH = 200;
const expression = defineModel<string>({ default: "" });
const canSubmit = computed(() => {
  const length = expression.value.trim().length;
  return length > 0 && length <= MAXIMUM_EXPRESSION_LENGTH;
});

function submit() {
  const value = expression.value.trim();
  if (!value || value.length > MAXIMUM_EXPRESSION_LENGTH) return;

  emit("submit", { expression: value });
}
</script>

<template>
  <div class="expression-search-shell">
    <form
      class="expression-search"
      :class="{ 'expression-search--compact': compact }"
      @submit.prevent="submit"
    >
      <div class="expression-search__field">
        <UIcon name="i-lucide-search" aria-hidden="true" />
        <label>
          <span>O que você precisa?</span>
          <UInput
            v-model="expression"
            class="expression-search__input"
            name="expression"
            type="search"
            autocomplete="off"
            required
            :maxlength="MAXIMUM_EXPRESSION_LENGTH"
            placeholder="Ex.: Preciso pintar um quarto infantil"
            :ui="{
              base: 'rounded-none p-0 border-0 ring-0 shadow-none bg-transparent focus-visible:outline-none focus-visible:ring-0',
            }"
          />
        </label>
      </div>

      <UButton
        v-if="canSubmit"
        type="submit"
        color="primary"
        class="expression-search__button"
      >
        <span>Buscar profissionais</span>
        <UIcon name="i-lucide-arrow-right" aria-hidden="true" />
      </UButton>
    </form>

    <PublicSearchLocationHint
      v-if="location"
      :location="location"
      :cities="cities"
      :source="locationSource"
      @change="emit('locationChange', $event)"
    />
  </div>
</template>

<style scoped lang="scss">
.expression-search-shell {
  width: 100%;
}

.expression-search {
  position: relative;
  z-index: 10;
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: stretch;
  gap: 10px;
  width: 100%;
  padding: 9px;
  border: 1px solid rgb(23 53 47 / 14%);
  border-radius: 18px;
  background: white;
  box-shadow: 0 20px 55px rgb(23 53 47 / 13%);

  &__field {
    display: grid;
    grid-template-columns: auto minmax(0, 1fr);
    align-items: center;
    gap: 9px;
    min-width: 0;
    height: 3.63rem;
    padding: 6px 12px;
  }

  &__field > svg {
    color: var(--color-brand);
    font-size: 1.2rem;
  }

  &__field label {
    display: grid;
    min-width: 0;
  }

  &__field label > span {
    color: var(--ink-soft);
    font-size: 0.76rem;
    font-weight: 800;
    letter-spacing: 0.06em;
    text-transform: uppercase;
  }

  &__input {
    width: 100%;
    min-width: 0;
    color: var(--ink);
    font-size: 0.94rem;
    font-weight: 500;
  }

  &__button {
    min-height: 58px;
    justify-content: center;
    padding-inline: 25px;
    border-radius: 13px;
    font-weight: 800;
  }

  &--compact {
    box-shadow: var(--shadow-sm);
  }

  :deep(input[type="search"]::-webkit-search-cancel-button) {
    appearance: none;
  }
}

@media (width <= 760px) {
  .expression-search {
    grid-template-columns: 1fr;
    gap: 4px;
    padding: 8px;

    &__field {
      padding: 10px 12px;
    }

    &__button {
      min-height: 50px;
    }
  }
}
</style>
