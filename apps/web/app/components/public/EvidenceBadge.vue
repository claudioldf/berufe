<script setup lang="ts">
import { computed } from "vue";
import type { Evidence } from "~/types";

const props = defineProps<{
  evidence: Pick<Evidence, "label">;
  compact?: boolean;
}>();

const icon = computed(() => {
  if (props.evidence.label.includes("Telefone")) return "i-lucide-smartphone";
  return "i-lucide-badge-check";
});
</script>

<template>
  <span class="evidence" :class="{ 'evidence--compact': compact }">
    <UIcon :name="icon" />
    {{ evidence.label }}
  </span>
</template>

<style scoped lang="scss">
.evidence {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  min-height: 34px;
  padding: 7px 11px;
  border: 1px solid #abd3c6;
  border-radius: 999px;
  background: #eff9f5;
  color: #266253;
  font-size: 0.84rem;
  font-weight: 800;
  white-space: nowrap;
  & svg {
    font-size: 1rem;
  }
  &--compact {
    min-height: 28px;
    padding: 5px 9px;
    font-size: 0.86rem;
  }
}
</style>
