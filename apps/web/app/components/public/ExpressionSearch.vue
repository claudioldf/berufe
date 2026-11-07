<script setup lang="ts">
import { computed, shallowRef } from "vue";
import type {
  ExpressionSearchPayload,
  SearchLocation,
  SearchLocationSource,
} from "~/types";

const props = withDefaults(
  defineProps<{
    compact?: boolean;
    loading?: boolean;
    location?: SearchLocation;
    cities?: SearchLocation[];
    locationSource?: SearchLocationSource;
  }>(),
  {
    compact: false,
    loading: false,
    cities: () => [],
    locationSource: "fallback",
  },
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

// The location fields appear once the visitor focuses the search and stay open
// after that; they are a secondary control, so they never take focus on load.
const expanded = shallowRef(false);

function submit() {
  const value = expression.value.trim();
  if (props.loading || !value || value.length > MAXIMUM_EXPRESSION_LENGTH)
    return;

  emit("submit", { expression: value });
}
</script>

<template>
  <div
    class="expression-search-shell"
    :class="{ 'expression-search-shell--compact': compact }"
    @focusin="expanded = true"
  >
    <form
      class="expression-search"
      :aria-busy="loading"
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
        icon="i-lucide-arrow-right"
        trailing
        :loading="loading"
        :disabled="loading"
      >
        <span>Buscar</span>
      </UButton>
    </form>

    <div
      v-if="location"
      class="expression-search-shell__panel"
      :class="{ 'expression-search-shell__panel--open': expanded }"
      :inert="!expanded"
    >
      <div class="expression-search-shell__panel-inner">
        <PublicSearchLocationFields
          :location="location"
          :cities="cities"
          :source="locationSource"
          @change="emit('locationChange', $event)"
        />
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.expression-search-shell {
  position: relative;
  z-index: 10;
  width: 100%;
  padding: 9px;
  border: 1px solid rgb(23 53 47 / 14%);
  border-radius: 18px;
  background: white;
  box-shadow: 0 20px 55px rgb(23 53 47 / 13%);

  &--compact {
    box-shadow: var(--shadow-sm);
  }
}

// The panel animates its height through grid rows, so the card and the centered
// hero content glide into place instead of jumping when the fields open.
.expression-search-shell__panel {
  display: grid;
  grid-template-rows: 0fr;
  transition: grid-template-rows 460ms cubic-bezier(0.22, 1, 0.36, 1);

  &--open {
    grid-template-rows: 1fr;
  }
}

.expression-search-shell__panel-inner {
  min-height: 0;
  overflow: hidden;
  opacity: 0;
  transform: translateY(-8px);
  transition:
    opacity 260ms ease,
    transform 460ms cubic-bezier(0.22, 1, 0.36, 1);

  .expression-search-shell__panel--open > & {
    opacity: 1;
    transform: none;
    transition-delay: 60ms;
  }
}

.expression-search {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: stretch;
  gap: 10px;
  width: 100%;

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

  :deep(input[type="search"]::-webkit-search-cancel-button) {
    appearance: none;
  }
}

@media (prefers-reduced-motion: reduce) {
  .expression-search-shell__panel,
  .expression-search-shell__panel-inner {
    transition: none;
  }
}

@media (width <= 760px) {
  .expression-search-shell {
    padding: 8px;
  }

  .expression-search {
    grid-template-columns: 1fr;
    gap: 4px;

    &__field {
      padding: 10px 12px;
    }

    &__button {
      min-height: 50px;
    }
  }
}
</style>
