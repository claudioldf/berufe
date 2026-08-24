<script setup lang="ts">
defineEmits<{
  recommend: [];
}>();
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="actions-card">
    <header class="actions-card__header">
      <span>Ações rápidas</span>
    </header>
    <div class="actions-card__list">
      <NuxtLink to="/app/professional/profile">
        <span class="actions-card__icon">
          <UIcon name="i-lucide-pencil" aria-hidden="true" />
        </span>
        <strong>Editar perfil</strong>
        <UIcon name="i-lucide-chevron-right" aria-hidden="true" />
      </NuxtLink>
      <NuxtLink to="/app/professional/profile?tab=portfolio">
        <span class="actions-card__icon">
          <UIcon name="i-lucide-image-plus" aria-hidden="true" />
        </span>
        <strong>Novo trabalho</strong>
        <UIcon name="i-lucide-chevron-right" aria-hidden="true" />
      </NuxtLink>
      <NuxtLink to="/app/professional/profile?tab=verificacoes">
        <span class="actions-card__icon">
          <UIcon name="i-lucide-id-card" aria-hidden="true" />
        </span>
        <strong>Ver verificações</strong>
        <UIcon name="i-lucide-chevron-right" aria-hidden="true" />
      </NuxtLink>
      <NuxtLink to="/app/professional/services">
        <span class="actions-card__icon">
          <UIcon name="i-lucide-clipboard-check" aria-hidden="true" />
        </span>
        <strong>Acompanhar serviços</strong>
        <UIcon name="i-lucide-chevron-right" aria-hidden="true" />
      </NuxtLink>
      <button type="button" @click="$emit('recommend')">
        <span class="actions-card__icon">
          <UIcon name="i-lucide-handshake" aria-hidden="true" />
        </span>
        <strong>Recomendar um profissional</strong>
        <UIcon name="i-lucide-chevron-right" aria-hidden="true" />
      </button>
    </div>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.actions-card {
  padding: 18px;

  &__header {
    margin-bottom: 12px;
  }

  &__header span {
    font-family: var(--font-display);
    font-size: 1.25rem;
    font-weight: 600;
  }

  &__list {
    display: grid;
    gap: 7px;
  }

  &__list a,
  &__list button {
    display: grid;
    grid-template-columns: auto minmax(0, 1fr) auto;
    align-items: center;
    gap: 10px;
    min-height: 52px;
    padding: 9px 10px;
    border: 1px solid var(--line);
    border-radius: 12px;
    background: #faf9f6;
    color: var(--ink);
    text-align: left;
    text-decoration: none;
    cursor: pointer;
    transition: 0.15s ease;
  }

  &__list a:hover,
  &__list button:hover {
    border-color: #9fc8bb;
    background: var(--color-brand-tint-subtle);
  }

  &__list strong {
    font-size: 0.82rem;
  }

  &__list > a > svg,
  &__list > button > svg {
    color: #84958f;
  }

  &__icon {
    display: grid;
    place-items: center;
    width: 32px;
    height: 32px;
    border-radius: 9px;
    background: var(--mint);
    color: var(--color-brand);
  }
}
</style>
