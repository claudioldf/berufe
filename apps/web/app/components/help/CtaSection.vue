<script setup lang="ts">
defineProps<{
  title: string;
  description: string;
  label: string;
  to: string;
}>();
</script>

<template>
  <section class="help-cta" aria-labelledby="help-cta-title">
    <div>
      <h2 id="help-cta-title">{{ title }}</h2>
      <p>{{ description }}</p>
    </div>
    <UButton :to="to" color="primary" trailing-icon="i-lucide-arrow-right">
      {{ label }}
    </UButton>
  </section>
</template>

<style scoped lang="scss">
.help-cta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  margin-top: 36px;
  padding: 24px;
  border-radius: var(--radius-lg, 18px);
  background: var(--color-brand-tint-muted);

  & h2 {
    margin: 0 0 6px;
    font-family: var(--font-display);
    font-size: 1.25rem;
  }

  & p {
    margin: 0;
    color: var(--ink-soft);
    line-height: 1.55;
  }

  @media (width <= 640px) {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>
