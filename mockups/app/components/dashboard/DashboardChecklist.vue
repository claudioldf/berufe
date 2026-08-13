<script setup lang="ts">
defineProps<{
  readiness: number
  items: Array<{
    id: string
    label: string
    description: string
    done: boolean
    to: string
  }>
}>()
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="checklist-card">
    <header>
      <div>
        <span>Seu perfil está</span>
        <strong>{{ readiness }}% completo</strong>
      </div>
      <div class="checklist-card__ring" :style="{ '--progress': `${readiness * 3.6}deg` }">
        <span>{{ readiness }}%</span>
      </div>
    </header>
    <p>Complete estas etapas para mostrar mais evidências aos clientes.</p>
    <div class="checklist-card__items">
      <NuxtLink v-for="item in items" :key="item.id" :to="item.to" :class="{ done: item.done }">
        <span class="checklist-card__check"><UIcon :name="item.done ? 'i-lucide-check' : 'i-lucide-circle'" /></span>
        <span><strong>{{ item.label }}</strong><small>{{ item.description }}</small></span>
        <UIcon name="i-lucide-chevron-right" />
      </NuxtLink>
    </div>
  </DesignSystemSurfaceCard>
</template>

<style scoped>
.checklist-card { padding: 22px; }.checklist-card header { display: flex; justify-content: space-between; align-items: center; }.checklist-card header span, .checklist-card header strong { display: block; }.checklist-card header > div:first-child span { color: var(--ink-soft); font-size: .86rem; font-weight: 700; }.checklist-card header > div:first-child strong { margin-top: 4px; font-family: Georgia, serif; font-size: 1.5rem; }.checklist-card__ring { display: grid; place-items: center; width: 58px; height: 58px; border-radius: 99px; background: conic-gradient(#397a69 var(--progress), #e0e5e2 0); }.checklist-card__ring::before { content: ""; grid-area: 1/1; width: 45px; height: 45px; border-radius: 99px; background: white; }.checklist-card__ring span { z-index: 1; grid-area: 1/1; font-size: .86rem; font-weight: 900; }.checklist-card > p { margin: 14px 0 18px; color: var(--ink-soft); font-size: .82rem; line-height: 1.5; }.checklist-card__items { display: grid; }.checklist-card__items a { display: grid; grid-template-columns: auto 1fr auto; align-items: center; gap: 10px; padding: 13px 0; border-top: 1px solid var(--line); color: var(--ink); text-decoration: none; }.checklist-card__check { display: grid; place-items: center; width: 29px; height: 29px; border: 1px solid #b8c7c2; border-radius: 9px; color: #81938d; }.checklist-card__items a.done .checklist-card__check { border-color: transparent; background: var(--mint); color: #397a69; }.checklist-card__items strong, .checklist-card__items small { display: block; }.checklist-card__items strong { font-size: .82rem; }.checklist-card__items small { margin-top: 3px; color: var(--ink-soft); font-size: .84rem; }.checklist-card__items > a > svg { color: #84958f; }
</style>
