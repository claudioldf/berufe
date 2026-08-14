<script setup lang="ts">
defineProps<{
  title: string;
  meaning: string;
  goal: string;
  reading?: string;
}>();
</script>

<template>
  <UPopover
    :content="{
      side: 'bottom',
      align: 'end',
      sideOffset: 7,
      collisionPadding: 12,
    }"
    arrow
  >
    <button
      type="button"
      class="metric-help__trigger"
      :aria-label="`Entender a métrica: ${title}`"
    >
      <UIcon name="i-lucide-info" aria-hidden="true" />
    </button>

    <template #content>
      <aside
        class="metric-help__content"
        role="note"
        :aria-label="`Explicação: ${title}`"
      >
        <header>
          <span><UIcon name="i-lucide-info" aria-hidden="true" /></span>
          <div>
            <small>Sobre esta métrica</small><strong>{{ title }}</strong>
          </div>
        </header>
        <dl>
          <div>
            <dt>O que significa</dt>
            <dd>{{ meaning }}</dd>
          </div>
          <div>
            <dt>Objetivo</dt>
            <dd>{{ goal }}</dd>
          </div>
          <div v-if="reading">
            <dt>Como interpretar</dt>
            <dd>{{ reading }}</dd>
          </div>
        </dl>
      </aside>
    </template>
  </UPopover>
</template>

<style scoped lang="scss">
.metric-help {
  &__trigger {
    display: grid;
    flex: 0 0 auto;
    place-items: center;
    width: 28px;
    height: 28px;
    padding: 0;
    border: 1px solid rgba(23, 53, 47, 0.16);
    border-radius: 9px;
    background: rgba(255, 255, 255, 0.72);
    color: #48635d;
    cursor: help;
    transition:
      border-color 0.16s ease,
      background 0.16s ease,
      color 0.16s ease,
      transform 0.16s ease;
  }
  &__trigger:hover {
    border-color: rgba(23, 53, 47, 0.32);
    background: white;
    color: #17352f;
    transform: translateY(-1px);
  }
  &__trigger:focus-visible {
    outline: 3px solid rgba(248, 117, 93, 0.32);
    outline-offset: 2px;
  }
  &__content {
    width: min(340px, calc(100vw - 32px));
    padding: 16px;
    color: #17352f;
  }
  &__content header {
    display: grid;
    grid-template-columns: auto 1fr;
    align-items: center;
    gap: 9px;
    padding-bottom: 12px;
    border-bottom: 1px solid rgba(23, 53, 47, 0.12);
  }
  &__content header > span {
    display: grid;
    place-items: center;
    width: 32px;
    height: 32px;
    border-radius: 10px;
    background: #e8f4f0;
    color: #2f6b5f;
  }
  &__content header small,
  &__content header strong {
    display: block;
  }
  &__content header small {
    color: #59706a;
    font-size: var(--font-size-min);
    font-weight: 750;
  }
  &__content header strong {
    margin-top: 1px;
    font-size: 0.86rem;
  }
  &__content dl {
    display: grid;
    gap: 12px;
    margin: 13px 0 0;
  }
  &__content dl > div {
    display: grid;
    gap: 3px;
  }
  &__content dt {
    color: #2f6b5f;
    font-size: var(--font-size-min);
    font-weight: 900;
    letter-spacing: 0.06em;
    text-transform: uppercase;
  }
  &__content dd {
    margin: 0;
    color: #48635d;
    font-size: var(--font-size-min);
    line-height: 1.55;
  }
}
</style>
