<script setup lang="ts">
import { computed, useId } from "vue";

interface Props {
  id?: string;
  label: string;
  hint?: string;
  error?: string;
  required?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  id: undefined,
  hint: undefined,
  error: undefined,
  required: false,
});

const generatedId = useId();
const controlId = computed(() => props.id ?? generatedId);
const hintId = computed(() => `${controlId.value}-hint`);
const errorId = computed(() => `${controlId.value}-error`);
const describedBy = computed(() => {
  if (props.error) return errorId.value;
  if (props.hint) return hintId.value;
  return undefined;
});

defineSlots<{
  default(props: {
    controlId: string;
    describedBy?: string;
    invalid: boolean;
    required: boolean;
  }): unknown;
  label?(): unknown;
}>();
</script>

<template>
  <label class="form-field" :for="controlId">
    <div class="form-field__inner">
      <span class="form-field__label">
        <slot name="label">{{ label }}</slot>
        <span v-if="required" class="form-field__required">Obrigatório</span>
      </span>
      <slot
        :control-id="controlId"
        :described-by="describedBy"
        :invalid="Boolean(error)"
        :required="required"
      />
      <small
        v-if="error"
        :id="errorId"
        class="form-field__error"
        aria-live="polite"
      >
        {{ error }}
      </small>
      <small v-else-if="hint" :id="hintId" class="form-field__hint">
        {{ hint }}
      </small>
    </div>
  </label>
</template>

<style scoped lang="scss">
.form-field {
  display: grid;
  gap: 7px;
  color: var(--ink);
  font-size: 0.82rem;
  font-weight: 800;

  &__inner {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
  }

  &__label {
    display: flex;
    justify-content: space-between;
    gap: 12px;
  }

  &__label :slotted(em) {
    color: var(--color-text-muted);
    font-size: 0.82rem;
    font-style: normal;
    font-weight: 700;
  }

  & :slotted(input),
  & :slotted(select),
  & :slotted(textarea) {
    width: 100%;
    height: 3rem;
    padding: 12px;
    border: 1px solid var(--line);
    border-radius: var(--radius-md);
    background-color: var(--color-surface);
    color: var(--ink);
    outline: none;
    transition:
      border-color var(--motion-fast) ease,
      box-shadow var(--motion-fast) ease;
  }

  & :slotted(select) {
    padding-right: 2.75rem;
  }

  & :slotted(input:focus-visible),
  & :slotted(select:focus-visible),
  & :slotted(textarea:focus-visible) {
    border-color: var(--color-brand);
    box-shadow: var(--focus-ring);
  }

  & :slotted(textarea) {
    min-height: 110px;
    resize: vertical;
  }

  &__hint,
  &__error,
  &__required {
    font-size: 0.84rem;
    font-weight: 500;
    line-height: 1.45;
  }

  &__hint {
    color: var(--ink-soft);
  }

  &__error {
    color: var(--color-danger);
  }

  &__required {
    color: var(--color-text-muted);
    font-size: var(--font-size-min);
  }
}
</style>
