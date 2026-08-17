<script setup lang="ts">
const props = defineProps<{
  title: string;
  description: string;
}>();
</script>

<template>
  <div class="admin-page">
    <section class="admin-heading">
      <DesignSystemContainer class="admin-heading__inner">
        <div>
          <DesignSystemEyebrow class="admin-heading__eyebrow" tone="inverse">
            Berufe Operações
          </DesignSystemEyebrow>
          <h1 class="admin-heading__title">{{ props.title }}</h1>
          <p class="admin-heading__description">{{ props.description }}</p>
        </div>
        <div class="admin-heading__user">
          <span class="admin-heading__avatar">CD</span>
          <div>
            <strong class="admin-heading__user-name">Cláudio Dias</strong>
            <small class="admin-heading__user-role"> Administrador </small>
          </div>
          <UIcon class="admin-heading__shield" name="i-lucide-shield-check" />
        </div>
      </DesignSystemContainer>
    </section>

    <DesignSystemContainer class="admin-content">
      <slot />
    </DesignSystemContainer>
  </div>
</template>

<style scoped lang="scss">
.admin-page {
  min-height: 100vh;
  padding-bottom: 80px;
  background: #f2f0ea;
}
.admin-heading {
  padding: 32px 0 36px;
  background: var(--color-brand-strong);
  color: white;
  &__inner {
    display: flex;
    justify-content: space-between;
    align-items: end;
    gap: 20px;
  }
  &__eyebrow {
    margin-bottom: 7px;
  }
  &__title {
    margin: 0;
    font-family: var(--font-display);
    font-size: 2.6rem;
    font-weight: 500;
    letter-spacing: -0.04em;
  }
  &__description {
    margin: 7px 0 0;
    color: rgb(255 255 255 / 58%);
    font-size: 0.82rem;
  }
  &__user {
    display: grid;
    grid-template-columns: auto 1fr auto;
    align-items: center;
    gap: 9px;
    padding: 9px 11px;
    border: 1px solid rgb(255 255 255 / 14%);
    border-radius: 12px;
    background: rgb(255 255 255 / 6%);
  }
  &__avatar {
    display: grid;
    place-items: center;
    width: 34px;
    height: 34px;
    border-radius: 9px;
    background: var(--coral);
    font-size: 0.86rem;
    font-weight: 900;
  }
  &__user-name,
  &__user-role {
    display: block;
  }
  &__user-name {
    font-size: 0.86rem;
  }
  &__user-role {
    margin-top: 2px;
    color: rgb(255 255 255 / 55%);
    font-size: 0.82rem;
  }
  &__shield {
    color: var(--color-brand-muted);
  }
}
.admin-content {
  padding-top: 22px;
}
@media (width <= 800px) {
  .admin-heading__user {
    display: none;
  }
}
</style>
