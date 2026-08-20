<script setup lang="ts">
import type { OnboardingChecklistItem } from "~/types";

defineProps<{
  readiness: number;
  items: OnboardingChecklistItem[];
  canPublish: boolean;
  publishing: boolean;
}>();

defineEmits<{
  publish: [];
}>();
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="checklist-card">
    <header>
      <div>
        <span>Seu perfil está</span>
        <strong>{{ readiness }}% completo</strong>
      </div>
      <div
        class="checklist-card__ring"
        :style="{ '--progress': `${readiness * 3.6}deg` }"
      >
        <span>{{ readiness }}%</span>
      </div>
    </header>
    <p>Complete estas etapas para mostrar mais evidências aos clientes.</p>
    <div class="checklist-card__items">
      <NuxtLink
        v-for="item in items"
        :key="item.id"
        :to="item.to"
        :class="{ done: item.done }"
      >
        <span class="checklist-card__check"
          ><UIcon :name="item.done ? 'i-lucide-check' : 'i-lucide-circle'"
        /></span>
        <span
          ><strong>{{ item.label }}</strong
          ><small>{{ item.description }}</small></span
        >
        <UIcon name="i-lucide-chevron-right" />
      </NuxtLink>
    </div>
    <footer v-if="canPublish" class="checklist-card__footer">
      <UButton
        type="button"
        color="primary"
        icon="i-lucide-megaphone"
        block
        :loading="publishing"
        :disabled="publishing"
        @click="$emit('publish')"
      >
        Publicar perfil
      </UButton>
    </footer>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.checklist-card {
  padding: 22px;
  & header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  & header span,
  & header strong {
    display: block;
  }
  & header > div:first-child span {
    color: var(--ink-soft);
    font-size: 0.86rem;
    font-weight: 700;
  }
  & header > div:first-child strong {
    margin-top: 4px;
    font-family: var(--font-display);
    font-size: 1.5rem;
  }
  &__ring {
    display: grid;
    place-items: center;
    width: 58px;
    height: 58px;
    border-radius: 99px;
    background: conic-gradient(var(--color-brand) var(--progress), #e0e5e2 0);
  }
  &__ring::before {
    content: "";
    grid-area: 1/1;
    width: 45px;
    height: 45px;
    border-radius: 99px;
    background: white;
  }
  &__ring span {
    z-index: 1;
    grid-area: 1/1;
    font-size: 0.86rem;
    font-weight: 900;
  }
  & > p {
    margin: 14px 0 18px;
    color: var(--ink-soft);
    font-size: 0.82rem;
    line-height: 1.5;
  }
  &__items {
    display: grid;
  }
  &__items a {
    display: grid;
    grid-template-columns: auto 1fr auto;
    align-items: center;
    gap: 10px;
    padding: 13px 0;
    border-top: 1px solid var(--line);
    color: var(--ink);
    text-decoration: none;
  }
  &__check {
    display: grid;
    place-items: center;
    width: 29px;
    height: 29px;
    border: 1px solid #b8c7c2;
    border-radius: 9px;
    color: #81938d;
  }
  &__items a.done &__check {
    border-color: transparent;
    background: var(--mint);
    color: var(--color-brand);
  }
  &__items strong,
  &__items small {
    display: block;
  }
  &__items strong {
    font-size: 0.82rem;
  }
  &__items small {
    margin-top: 3px;
    color: var(--ink-soft);
    font-size: 0.84rem;
  }
  &__items > a > svg {
    color: #84958f;
  }
  &__footer {
    margin-top: 8px;
    padding-top: 18px;
    border-top: 1px solid var(--line);
  }
}
</style>
