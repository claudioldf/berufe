<script setup lang="ts">
interface Props {
  label: string
  hint?: string
  error?: string
}

defineProps<Props>()

defineSlots<{
  default(): unknown
  label?(): unknown
}>()
</script>

<template>
  <label class="form-field">
    <span class="form-field__label">
      <slot name="label">{{ label }}</slot>
    </span>
    <slot />
    <small v-if="error" class="form-field__error">{{ error }}</small>
    <small v-else-if="hint" class="form-field__hint">{{ hint }}</small>
  </label>
</template>

<style scoped lang="scss">
.form-field {
  display: grid;
  gap: 7px;
  color: var(--ink);
  font-size: 0.82rem;
  font-weight: 800;

  &__label {
    display: flex;
    justify-content: space-between;
    gap: 12px;
  }

  &__label :slotted(em) {
    color: #8a9995;
    font-size: 0.82rem;
    font-style: normal;
    font-weight: 700;
  }

  & :slotted(input),
  & :slotted(select),
  & :slotted(textarea) {
    width: 100%;
    padding: 11px 12px;
    border: 1px solid var(--line);
    border-radius: 10px;
    background: white;
    color: var(--ink);
    outline: none;
    transition:
      border-color 0.15s ease,
      box-shadow 0.15s ease;
  }

  & :slotted(input:focus),
  & :slotted(select:focus),
  & :slotted(textarea:focus) {
    border-color: #397a69;
    box-shadow: 0 0 0 3px rgba(63, 131, 114, 0.12);
  }

  & :slotted(textarea) {
    min-height: 110px;
    resize: vertical;
  }

  &__hint,
  &__error {
    font-size: 0.84rem;
    font-weight: 500;
    line-height: 1.45;
  }

  &__hint {
    color: var(--ink-soft);
  }

  &__error {
    color: #b42318;
  }
}
</style>
