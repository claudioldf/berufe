<script setup lang="ts">
defineEmits<{
  recommend: [];
}>();
</script>

<template>
  <DesignSystemSurfaceCard
    as="section"
    class="actions-card"
    aria-labelledby="quick-actions-title"
  >
    <header class="actions-card__header">
      <h2 id="quick-actions-title">Ações rápidas</h2>
    </header>
    <div class="actions-card__list">
      <NuxtLink to="/app/professional/profile" aria-label="Editar perfil">
        <span class="actions-card__icon">
          <UIcon name="i-lucide-pencil" aria-hidden="true" />
        </span>
        <strong>
          <span class="actions-card__label-full">Editar perfil</span>
          <span class="actions-card__label-compact">Perfil</span>
        </strong>
      </NuxtLink>
      <NuxtLink
        to="/app/professional/profile?tab=portfolio"
        aria-label="Adicionar novo trabalho"
      >
        <span class="actions-card__icon">
          <UIcon name="i-lucide-image-plus" aria-hidden="true" />
        </span>
        <strong>
          <span class="actions-card__label-full">Novo trabalho</span>
          <span class="actions-card__label-compact">Trabalho</span>
        </strong>
      </NuxtLink>
      <NuxtLink
        to="/app/professional/profile?tab=verificacoes"
        aria-label="Ver verificações"
      >
        <span class="actions-card__icon">
          <UIcon name="i-lucide-id-card" aria-hidden="true" />
        </span>
        <strong>
          <span class="actions-card__label-full">Ver verificações</span>
          <span class="actions-card__label-compact">Verificar</span>
        </strong>
      </NuxtLink>
      <NuxtLink
        to="/app/professional/services"
        aria-label="Acompanhar serviços"
      >
        <span class="actions-card__icon">
          <UIcon name="i-lucide-clipboard-check" aria-hidden="true" />
        </span>
        <strong>
          <span class="actions-card__label-full">Acompanhar serviços</span>
          <span class="actions-card__label-compact">Serviços</span>
        </strong>
      </NuxtLink>
      <button
        type="button"
        aria-label="Recomendar um profissional"
        @click="$emit('recommend')"
      >
        <span class="actions-card__icon">
          <UIcon name="i-lucide-handshake" aria-hidden="true" />
        </span>
        <strong>
          <span class="actions-card__label-full">Recomendar profissional</span>
          <span class="actions-card__label-compact">Recomendar</span>
        </strong>
      </button>
    </div>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.actions-card {
  display: grid;
  grid-template-columns: minmax(150px, 0.75fr) minmax(0, 4fr);
  overflow: hidden;

  &__header {
    display: flex;
    align-items: center;
    padding: 18px 20px;
    border-right: 1px solid var(--line);
    background: var(--color-surface-neutral);
  }

  &__header h2 {
    margin: 0;
    font-family: var(--font-display);
    font-size: 1.25rem;
    font-weight: 600;
    letter-spacing: -0.02em;
  }

  &__list {
    display: grid;
    grid-template-columns: repeat(5, minmax(0, 1fr));
    min-width: 0;
  }

  &__list a,
  &__list button {
    display: flex;
    min-width: 0;
    min-height: 92px;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    gap: 8px;
    padding: 12px 8px;
    border: 0;
    border-left: 1px solid var(--line);
    background: transparent;
    color: var(--ink);
    text-align: center;
    text-decoration: none;
    cursor: pointer;
    transition:
      background-color var(--motion-fast) ease,
      color var(--motion-fast) ease;
  }

  &__list > :first-child {
    border-left: 0;
  }

  &__list a:hover,
  &__list button:hover {
    background: var(--color-brand-tint-subtle);
    color: var(--color-brand);
  }

  &__list a:focus-visible,
  &__list button:focus-visible {
    z-index: 1;
    outline: 2px solid var(--color-focus);
    outline-offset: -3px;
  }

  &__list strong {
    min-width: 0;
    font-size: 0.82rem;
    line-height: 1.25;
    text-wrap: balance;
  }

  &__label-compact {
    display: none;
  }

  &__icon {
    display: grid;
    place-items: center;
    width: 34px;
    height: 34px;
    flex-shrink: 0;
    border-radius: 10px;
    background: var(--mint);
    color: var(--color-brand);
  }
}

@media (width <= 700px) {
  .actions-card {
    grid-template-columns: minmax(0, 1fr);

    &__header {
      justify-content: center;
      padding: 11px 14px;
      border-right: 0;
      border-bottom: 1px solid var(--line);
    }

    &__header h2 {
      font-size: 1rem;
    }

    &__list a,
    &__list button {
      min-height: 80px;
      gap: 6px;
      padding: 9px 3px;
    }

    &__list strong {
      font-size: 0.7rem;
    }

    &__icon {
      width: 29px;
      height: 29px;
      border-radius: 9px;
    }

    &__label-full {
      display: none;
    }

    &__label-compact {
      display: inline;
    }
  }
}
</style>
