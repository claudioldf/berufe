<script setup lang="ts">
withDefaults(
  defineProps<{
    title?: string;
    showTerms?: boolean;
  }>(),
  {
    title: "Privacidade e uso responsável",
    showTerms: true,
  },
);

defineSlots<{
  default(): unknown;
}>();
</script>

<template>
  <aside class="legal-inline-notice">
    <UIcon name="i-lucide-shield-check" aria-hidden="true" />
    <div>
      <strong>{{ title }}</strong>
      <p><slot /></p>
      <span>
        Consulte a
        <NuxtLink to="/privacidade" target="_blank" rel="noopener">
          Política de Privacidade
        </NuxtLink>
        <template v-if="showTerms">
          e os
          <NuxtLink to="/termos-de-uso" target="_blank" rel="noopener">
            Termos de Uso </NuxtLink
          >.
        </template>
      </span>
    </div>
  </aside>
</template>

<style scoped>
.legal-inline-notice {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 10px;
  padding: 14px;
  border: 1px solid var(--line);
  border-radius: 12px;
  background: var(--color-brand-tint-muted);
  color: var(--ink-soft);
  font-size: 0.78rem;
  line-height: 1.5;
}

.legal-inline-notice > svg {
  margin-top: 2px;
  color: var(--color-brand);
  font-size: 1.05rem;
}

.legal-inline-notice strong {
  display: block;
  margin-bottom: 3px;
  color: var(--ink);
}

.legal-inline-notice p {
  margin: 0 0 4px;
}

.legal-inline-notice a {
  color: var(--color-brand);
  font-weight: 800;
}
</style>
