<script setup lang="ts">
type ApiStatus = "idle" | "pending" | "success" | "error";

defineProps<{
  status: ApiStatus;
  service?: string;
  serviceStatus?: string;
  errorMessage?: string;
}>();

const emit = defineEmits<{
  retry: [];
}>();
</script>

<template>
  <section class="api-card" aria-labelledby="api-card-title">
    <div>
      <DesignSystemEyebrow>Integração real</DesignSystemEyebrow>
      <h2 id="api-card-title">Nuxt conectado ao Rails</h2>
      <p>
        O estado abaixo vem da operação tipada
        <code>getApiStatus</code>.
      </p>
    </div>

    <div v-if="status === 'pending'" class="api-card__state" role="status">
      <USkeleton class="h-5 w-44" />
      <span>Consultando a API…</span>
    </div>

    <div
      v-else-if="status === 'error'"
      class="api-card__state api-card__state--error"
      role="alert"
    >
      <UIcon name="i-lucide-circle-alert" aria-hidden="true" />
      <span>{{ errorMessage }}</span>
      <UButton
        type="button"
        color="error"
        variant="soft"
        size="sm"
        @click="emit('retry')"
      >
        Tentar novamente
      </UButton>
    </div>

    <div
      v-else-if="status === 'success'"
      class="api-card__state api-card__state--success"
      role="status"
      data-testid="api-status"
    >
      <UIcon name="i-lucide-cloud-check" aria-hidden="true" />
      <span
        ><strong>{{ service }}</strong
        >: {{ serviceStatus }}</span
      >
    </div>
  </section>
</template>

<style scoped lang="scss">
.api-card {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(280px, 0.72fr);
  gap: 32px;
  align-items: center;
  padding: clamp(24px, 5vw, 44px);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-xl);
  background: var(--color-surface);
  box-shadow: var(--shadow-sm);

  h2 {
    margin: 8px 0;
    font-family: var(--font-display);
    font-size: clamp(1.75rem, 4vw, 2.5rem);
    font-weight: 500;
    letter-spacing: -0.035em;
  }

  p {
    margin: 0;
    color: var(--color-text-muted);
  }

  code {
    font-size: 0.9em;
  }

  &__state {
    display: flex;
    min-height: 96px;
    flex-wrap: wrap;
    align-items: center;
    gap: 12px;
    padding: 20px;
    border-radius: var(--radius-lg);
    background: var(--color-surface-neutral);
    color: var(--color-text-muted);
  }

  &__state svg {
    flex: 0 0 auto;
    font-size: 1.5rem;
  }

  &__state--success {
    background: var(--color-success-tint);
    color: var(--color-success);
  }

  &__state--error {
    background: var(--color-danger-tint);
    color: var(--color-danger);
  }
}

@media (width <= 760px) {
  .api-card {
    grid-template-columns: 1fr;
  }
}
</style>
