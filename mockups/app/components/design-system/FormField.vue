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

<style scoped>
.form-field {
  display: grid;
  gap: 7px;
  color: var(--ink);
  font-size: .82rem;
  font-weight: 800;
}

.form-field__label {
  display: flex;
  justify-content: space-between;
  gap: 12px;
}

.form-field__label :slotted(em) {
  color: #8a9995;
  font-size: .82rem;
  font-style: normal;
  font-weight: 700;
}

.form-field :slotted(input),
.form-field :slotted(select),
.form-field :slotted(textarea) {
  width: 100%;
  padding: 11px 12px;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: white;
  color: var(--ink);
  outline: none;
  transition: border-color .15s ease, box-shadow .15s ease;
}

.form-field :slotted(input:focus),
.form-field :slotted(select:focus),
.form-field :slotted(textarea:focus) {
  border-color: #397a69;
  box-shadow: 0 0 0 3px rgba(63, 131, 114, .12);
}

.form-field :slotted(textarea) {
  min-height: 110px;
  resize: vertical;
}

.form-field__hint,
.form-field__error {
  font-size: .84rem;
  font-weight: 500;
  line-height: 1.45;
}

.form-field__hint {
  color: var(--ink-soft);
}

.form-field__error {
  color: #b42318;
}
</style>
