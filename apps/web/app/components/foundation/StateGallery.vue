<script setup lang="ts">
const emit = defineEmits<{
  retry: [];
  create: [];
}>();
</script>

<template>
  <section class="state-gallery" aria-labelledby="state-gallery-title">
    <header>
      <DesignSystemEyebrow>Feedback</DesignSystemEyebrow>
      <h2 id="state-gallery-title">Estados previsíveis</h2>
      <p>Carregamento, vazio e erro mantêm contexto e uma próxima ação.</p>
    </header>

    <div class="state-gallery__grid">
      <article aria-labelledby="loading-state-title">
        <h3 id="loading-state-title">Carregando</h3>
        <div role="status" aria-label="Carregando conteúdo">
          <USkeleton class="mb-3 h-4 w-2/3" />
          <USkeleton class="mb-3 h-4 w-full" />
          <USkeleton class="h-10 w-32" />
        </div>
      </article>

      <article>
        <UIcon name="i-lucide-inbox" aria-hidden="true" />
        <h3>Nenhum item ainda</h3>
        <p>Comece criando o primeiro registro desta área.</p>
        <UButton
          type="button"
          color="neutral"
          variant="outline"
          size="sm"
          @click="emit('create')"
        >
          Criar item
        </UButton>
      </article>

      <article class="state-gallery__error" role="alert">
        <UIcon name="i-lucide-circle-alert" aria-hidden="true" />
        <h3>Não foi possível carregar</h3>
        <p>Seus dados continuam seguros. Tente novamente.</p>
        <UButton
          type="button"
          color="error"
          variant="soft"
          size="sm"
          @click="emit('retry')"
        >
          Tentar novamente
        </UButton>
      </article>
    </div>
  </section>
</template>

<style scoped lang="scss">
.state-gallery {
  display: grid;
  gap: 24px;

  header {
    max-width: 620px;
  }

  h2 {
    margin: 8px 0;
    font-family: var(--font-display);
    font-size: clamp(1.8rem, 4vw, 2.6rem);
    font-weight: 500;
    letter-spacing: -0.035em;
  }

  header p,
  article p {
    color: var(--color-text-muted);
  }

  &__grid {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 16px;
  }

  article {
    min-height: 240px;
    padding: 24px;
    border: 1px solid var(--color-border);
    border-radius: var(--radius-lg);
    background: var(--color-surface);
  }

  article > svg {
    font-size: 1.5rem;
    color: var(--color-brand);
  }

  article h3 {
    margin: 16px 0 8px;
  }

  &__error > svg,
  &__error h3 {
    color: var(--color-danger);
  }
}

@media (width <= 820px) {
  .state-gallery__grid {
    grid-template-columns: 1fr;
  }

  .state-gallery article {
    min-height: auto;
  }
}
</style>
