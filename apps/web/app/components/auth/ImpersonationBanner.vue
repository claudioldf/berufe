<script setup lang="ts">
const props = defineProps<{
  displayName: string;
  stopping: boolean;
  error: string;
}>();

const emit = defineEmits<{
  stop: [];
}>();
</script>

<template>
  <aside class="impersonation-banner" aria-live="polite">
    <DesignSystemContainer class="impersonation-banner__inner">
      <p>
        <UIcon name="i-lucide-shield-user" aria-hidden="true" />
        <span>
          Você está gerenciando a conta de
          <strong>{{ props.displayName }}</strong>
        </span>
      </p>
      <UButton
        color="neutral"
        variant="solid"
        size="sm"
        :label="props.stopping ? 'Voltando…' : 'Voltar ao admin'"
        :loading="props.stopping"
        :disabled="props.stopping"
        @click="emit('stop')"
      />
      <span v-if="props.error" class="impersonation-banner__error" role="alert">
        {{ props.error }}
      </span>
    </DesignSystemContainer>
  </aside>
</template>

<style scoped lang="scss">
.impersonation-banner {
  border-bottom: 1px solid var(--color-warning);
  background: var(--color-warning-tint);
  color: var(--color-text);

  &__inner {
    display: flex;
    min-height: 56px;
    align-items: center;
    gap: 16px;
    padding-block: 8px;
  }

  p {
    display: flex;
    flex: 1;
    align-items: center;
    gap: 8px;
    margin: 0;
    font-size: 0.84rem;
  }

  &__error {
    color: var(--color-danger);
    font-size: 0.78rem;
    font-weight: 700;
  }
}

@media (width <= 650px) {
  .impersonation-banner__inner {
    align-items: stretch;
    flex-direction: column;
    gap: 8px;
  }
}
</style>
