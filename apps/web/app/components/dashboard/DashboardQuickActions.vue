<script setup lang="ts">
defineEmits<{
  recommend: [];
}>();
</script>

<template>
  <DesignSystemSurfaceCard
    as="section"
    class="actions-card"
    aria-label="Ações rápidas"
  >
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
          <span class="actions-card__label-compact">Indicar</span>
        </strong>
      </button>
    </div>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.actions-card {
  overflow: hidden;
  border-color: rgb(255 255 255 / 16%);
  border-bottom: 0;
  border-radius: 16px 16px 0 0;
  background: rgb(255 255 255 / 6%);
  box-shadow: none;

  &__list {
    display: grid;
    grid-template-columns: repeat(5, minmax(0, 1fr));
    min-width: 0;
  }

  &__list a,
  &__list button {
    display: flex;
    min-width: 0;
    min-height: 60px;
    justify-content: center;
    align-items: center;
    gap: 8px;
    padding: 10px 12px;
    border: 0;
    border-left: 1px solid rgb(255 255 255 / 14%);
    background: transparent;
    color: white;
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
    background: rgb(255 255 255 / 9%);
    color: white;
  }

  &__list a:focus-visible,
  &__list button:focus-visible {
    z-index: 1;
    outline: 2px solid var(--color-brand-muted);
    outline-offset: -3px;
  }

  &__list strong {
    min-width: 0;
    font-size: 0.82rem;
    line-height: 1.15;
    text-wrap: balance;
  }

  &__label-compact {
    display: none;
  }

  &__icon {
    display: grid;
    place-items: center;
    width: 30px;
    height: 30px;
    flex-shrink: 0;
    border-radius: 9px;
    background: rgb(255 255 255 / 10%);
    color: var(--color-brand-muted);
  }
}

@media (width <= 700px) {
  .actions-card {
    &__list a,
    &__list button {
      min-height: 54px;
      gap: 4px;
      padding: 8px 3px;
    }

    &__list strong {
      font-size: 0.64rem;
      white-space: nowrap;
    }

    &__icon {
      width: 24px;
      height: 24px;
      border-radius: 7px;
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
