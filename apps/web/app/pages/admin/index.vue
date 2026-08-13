<script setup lang="ts">
import { computed } from 'vue'
import moderationData from '../../../data/moderation.json'

const route = useRoute()
const view = computed(() => String(route.query.view ?? 'moderacao'))

const heading = computed(() => {
  if (view.value === 'catalogos') return { title: 'Catálogos', description: 'Gerencie a linguagem controlada da plataforma.' }
  if (view.value === 'relatorios') return { title: 'Visão do produto', description: 'Sinais para conduzir o crescimento inicial da rede.' }
  return { title: 'Fila de moderação', description: 'Analise evidências e conteúdo na ordem de chegada.' }
})

useSeoMeta({ title: 'Operações e moderação' })
</script>

<template>
  <div class="admin-page">
    <section class="admin-heading">
      <DesignSystemContainer class="admin-heading__inner">
        <div>
          <DesignSystemEyebrow tone="inverse">Berufe Operações</DesignSystemEyebrow>
          <h1>{{ heading.title }}</h1>
          <p>{{ heading.description }}</p>
        </div>
        <div class="admin-heading__user">
          <span>CD</span>
          <div><strong>Cláudio Dias</strong><small>Administrador · MFA ativo</small></div>
          <UIcon name="i-lucide-shield-check" />
        </div>
      </DesignSystemContainer>
    </section>

    <DesignSystemContainer class="admin-content">
      <div v-if="view === 'moderacao'" class="admin-summary">
        <article v-for="item in moderationData.summary" :key="item.label" :class="`admin-summary--${item.tone}`">
          <span><UIcon :name="item.icon" /></span>
          <div><strong>{{ item.value }}</strong><small>{{ item.label }}</small></div>
        </article>
      </div>

      <AdminModerationQueue v-if="view === 'moderacao'" />
      <AdminCatalogManager v-else-if="view === 'catalogos'" />
      <AdminReportsGrowthReports v-else />
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
  background: #17352f;
  color: white;
  &__inner {
    display: flex;
    justify-content: space-between;
    align-items: end;
    gap: 20px;
  }
  & .eyebrow {
    margin-bottom: 7px;
  }
  & h1 {
    margin: 0;
    font-family: Georgia, serif;
    font-size: 2.6rem;
    font-weight: 500;
    letter-spacing: -0.04em;
  }
  &__inner > div:first-child > p:last-child {
    margin: 7px 0 0;
    color: rgba(255, 255, 255, 0.58);
    font-size: 0.82rem;
  }
  &__user {
    display: grid;
    grid-template-columns: auto 1fr auto;
    align-items: center;
    gap: 9px;
    padding: 9px 11px;
    border: 1px solid rgba(255, 255, 255, 0.14);
    border-radius: 12px;
    background: rgba(255, 255, 255, 0.06);
  }
  &__user > span {
    display: grid;
    place-items: center;
    width: 34px;
    height: 34px;
    border-radius: 9px;
    background: var(--coral);
    font-size: 0.86rem;
    font-weight: 900;
  }
  &__user strong,
  &__user small {
    display: block;
  }
  &__user strong {
    font-size: 0.86rem;
  }
  &__user small {
    margin-top: 2px;
    color: rgba(255, 255, 255, 0.55);
    font-size: 0.82rem;
  }
  &__user > svg {
    color: #a7d7c8;
  }
}
.admin-content {
  padding-top: 22px;
}
.admin-summary {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 9px;
  margin-bottom: 18px;
  & article {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 15px;
    border: 1px solid var(--line);
    border-radius: 14px;
    background: white;
  }
  & article > span {
    display: grid;
    place-items: center;
    width: 36px;
    height: 36px;
    border-radius: 10px;
    background: #f0eee8;
  }
  & strong,
  & small {
    display: block;
  }
  & strong {
    font-family: Georgia, serif;
    font-size: 1.3rem;
  }
  & small {
    color: var(--ink-soft);
    font-size: 0.82rem;
  }
  &--warning > span {
    background: #fff2cf !important;
    color: #947019;
  }
  &--success > span {
    background: var(--mint) !important;
    color: #397a69;
  }
  &--error > span {
    background: #ffe8e4 !important;
    color: #b54b39;
  }
}
@media (max-width: 800px) {
  .admin-heading {
    &__user {
      display: none;
    }
  }
  .admin-summary {
    grid-template-columns: repeat(2, 1fr);
  }
}
@media (max-width: 500px) {
  .admin-summary {
    grid-template-columns: 1fr;
  }
}
</style>
