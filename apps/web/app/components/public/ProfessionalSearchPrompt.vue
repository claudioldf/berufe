<template>
  <DesignSystemSurfaceCard class="search-prompt">
    <span class="search-prompt__icon" aria-hidden="true">
      <UIcon name="i-lucide-search" />
    </span>
    <h2 class="search-prompt__title">Comece sua busca por um serviço.</h2>
    <p class="search-prompt__copy">
      Digite ou escolha um serviço acima para ver os profissionais disponíveis.
    </p>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.search-prompt {
  max-width: 760px;
  margin: 0 auto;
  padding: clamp(42px, 8vw, 72px) 30px;
  text-align: center;

  &__icon {
    display: grid;
    place-items: center;
    width: 58px;
    height: 58px;
    margin: 0 auto;
    border-radius: 18px;
    background: var(--mint);
    color: var(--color-brand);
    font-size: 1.5rem;
  }

  &__title {
    margin: 18px 0 7px;
    font-family: var(--font-display);
    font-size: 2rem;
  }

  &__copy {
    max-width: 520px;
    margin: 0 auto;
    color: var(--ink-soft);
    font-size: 0.9rem;
    line-height: 1.6;
  }
}
</style>
