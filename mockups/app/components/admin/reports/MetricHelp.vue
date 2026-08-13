<script setup lang="ts">
defineProps<{
  title: string
  meaning: string
  goal: string
  reading?: string
}>()
</script>

<template>
  <UPopover :content="{ side: 'bottom', align: 'end', sideOffset: 7, collisionPadding: 12 }" arrow>
    <button
      type="button"
      class="metric-help__trigger"
      :aria-label="`Entender a métrica: ${title}`"
    >
      <UIcon name="i-lucide-info" aria-hidden="true" />
    </button>

    <template #content>
      <aside class="metric-help__content" role="note" :aria-label="`Explicação: ${title}`">
        <header>
          <span><UIcon name="i-lucide-info" aria-hidden="true" /></span>
          <div><small>Sobre esta métrica</small><strong>{{ title }}</strong></div>
        </header>
        <dl>
          <div><dt>O que significa</dt><dd>{{ meaning }}</dd></div>
          <div><dt>Objetivo</dt><dd>{{ goal }}</dd></div>
          <div v-if="reading"><dt>Como interpretar</dt><dd>{{ reading }}</dd></div>
        </dl>
      </aside>
    </template>
  </UPopover>
</template>

<style scoped>
.metric-help__trigger { display: grid; flex: 0 0 auto; place-items: center; width: 28px; height: 28px; padding: 0; border: 1px solid rgba(23,53,47,.16); border-radius: 9px; background: rgba(255,255,255,.72); color: #48635d; cursor: help; transition: border-color .16s ease, background .16s ease, color .16s ease, transform .16s ease; }
.metric-help__trigger:hover { border-color: rgba(23,53,47,.32); background: white; color: #17352f; transform: translateY(-1px); }
.metric-help__trigger:focus-visible { outline: 3px solid rgba(248,117,93,.32); outline-offset: 2px; }
.metric-help__content { width: min(340px, calc(100vw - 32px)); padding: 16px; color: #17352f; }
.metric-help__content header { display: grid; grid-template-columns: auto 1fr; align-items: center; gap: 9px; padding-bottom: 12px; border-bottom: 1px solid rgba(23,53,47,.12); }
.metric-help__content header > span { display: grid; place-items: center; width: 32px; height: 32px; border-radius: 10px; background: #e8f4f0; color: #2f6b5f; }
.metric-help__content header small, .metric-help__content header strong { display: block; }
.metric-help__content header small { color: #59706a; font-size: var(--font-size-min); font-weight: 750; }
.metric-help__content header strong { margin-top: 1px; font-size: .86rem; }
.metric-help__content dl { display: grid; gap: 12px; margin: 13px 0 0; }
.metric-help__content dl > div { display: grid; gap: 3px; }
.metric-help__content dt { color: #2f6b5f; font-size: var(--font-size-min); font-weight: 900; letter-spacing: .06em; text-transform: uppercase; }
.metric-help__content dd { margin: 0; color: #48635d; font-size: var(--font-size-min); line-height: 1.55; }
</style>
