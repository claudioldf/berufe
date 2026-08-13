<script setup lang="ts">
import type { LegalDocumentSection } from '~/types'

defineProps<{
  eyebrow: string
  title: string
  description: string
  version: string
  updatedAt: string
  sections: LegalDocumentSection[]
}>()

defineSlots<{
  default(): unknown
}>()
</script>

<template>
  <article class="legal-document">
    <header class="legal-document__hero">
      <div class="legal-document__hero-shape" />
      <div class="page-container legal-document__hero-inner">
        <div class="legal-document__heading">
          <p class="eyebrow">{{ eyebrow }}</p>
          <h1>{{ title }}</h1>
          <p>{{ description }}</p>
        </div>

        <dl class="legal-document__metadata">
          <div>
            <dt>Versão</dt>
            <dd>{{ version }}</dd>
          </div>
          <div>
            <dt>Última atualização</dt>
            <dd>{{ updatedAt }}</dd>
          </div>
        </dl>
      </div>
    </header>

    <div class="legal-document__draft">
      <div class="page-container legal-document__draft-inner">
        <UIcon name="i-lucide-file-check-2" />
        <p>
          <strong>Minuta para revisão.</strong>
          Este documento reflete o produto planejado e ainda depende de validação jurídica e dos dados oficiais da responsável pela Berufe antes do lançamento com usuários reais.
        </p>
      </div>
    </div>

    <div class="page-container legal-document__layout">
      <aside class="legal-document__aside">
        <nav aria-label="Nesta página">
          <p>Nesta página</p>
          <ol>
            <li v-for="section in sections" :key="section.id">
              <a :href="`#${section.id}`">{{ section.label }}</a>
            </li>
          </ol>
        </nav>
      </aside>

      <div class="legal-document__content">
        <slot />
      </div>
    </div>
  </article>
</template>

<style scoped>
.legal-document { background: #fffdfa; }
.legal-document__hero { position: relative; overflow: hidden; padding: 78px 0 72px; background: #17352f; color: white; }
.legal-document__hero-shape { position: absolute; top: -170px; right: -70px; width: 430px; height: 430px; border: 92px solid rgba(216,240,231,.08); border-radius: 999px; }
.legal-document__hero-inner { position: relative; display: grid; grid-template-columns: minmax(0, 1fr) auto; align-items: end; gap: 70px; }
.legal-document__heading { max-width: 780px; }
.legal-document__heading .eyebrow { color: #a8d8c9; }
.legal-document__heading h1 { max-width: 760px; margin: 0; font-family: Georgia, "Times New Roman", serif; font-size: clamp(2.8rem, 6vw, 5.4rem); font-weight: 500; letter-spacing: -.055em; line-height: .98; }
.legal-document__heading > p:last-child { max-width: 680px; margin: 25px 0 0; color: rgba(255,255,255,.67); font-size: 1rem; line-height: 1.75; }
.legal-document__metadata { display: grid; min-width: 210px; margin: 0; border-top: 1px solid rgba(255,255,255,.18); }
.legal-document__metadata > div { padding: 13px 0; border-bottom: 1px solid rgba(255,255,255,.18); }
.legal-document__metadata dt { color: rgba(255,255,255,.5); font-size: var(--font-size-min); font-weight: 800; letter-spacing: .08em; text-transform: uppercase; }
.legal-document__metadata dd { margin: 5px 0 0; font-size: .86rem; font-weight: 800; }
.legal-document__draft { border-bottom: 1px solid #d5a99f; background: #fff0ec; color: #773d32; }
.legal-document__draft-inner { display: grid; grid-template-columns: auto 1fr; align-items: center; gap: 11px; padding-block: 14px; }
.legal-document__draft-inner > svg { font-size: 1.25rem; }
.legal-document__draft p { margin: 0; font-size: .84rem; line-height: 1.55; }
.legal-document__layout { display: grid; grid-template-columns: 250px minmax(0, 760px); justify-content: center; gap: 78px; padding-block: 68px 100px; }
.legal-document__aside { min-width: 0; }
.legal-document__aside nav { position: sticky; top: 24px; }
.legal-document__aside nav > p { margin: 0 0 14px; color: #397a69; font-size: var(--font-size-min); font-weight: 850; letter-spacing: .1em; text-transform: uppercase; }
.legal-document__aside ol { display: grid; gap: 0; margin: 0; padding: 0; border-top: 1px solid var(--line); list-style: none; counter-reset: legal-section; }
.legal-document__aside li { counter-increment: legal-section; border-bottom: 1px solid var(--line); }
.legal-document__aside a { display: grid; grid-template-columns: 24px 1fr; gap: 7px; padding: 10px 0; color: var(--ink-soft); font-size: var(--font-size-min); font-weight: 720; line-height: 1.35; text-decoration: none; }
.legal-document__aside a::before { content: counter(legal-section, decimal-leading-zero); color: #98a9a4; font-family: Georgia, serif; font-size: var(--font-size-min); }
.legal-document__aside a:hover { color: #397a69; }
.legal-document__content { min-width: 0; }
.legal-document__content :deep(.legal-lead) { margin: 0 0 48px; padding: 24px 26px; border: 1px solid var(--line); border-radius: 18px; background: #f2f7f4; color: var(--ink); font-size: .94rem; line-height: 1.75; }
.legal-document__content :deep(.legal-lead p) { margin: 0; }
.legal-document__content :deep(.legal-lead p + p) { margin-top: 12px; }
.legal-document__content :deep(.legal-section) { scroll-margin-top: 24px; padding: 0 0 42px; margin: 0 0 42px; border-bottom: 1px solid var(--line); }
.legal-document__content :deep(.legal-section:last-child) { padding-bottom: 0; margin-bottom: 0; border-bottom: 0; }
.legal-document__content :deep(.legal-section h2) { margin: 0 0 20px; font-family: Georgia, "Times New Roman", serif; font-size: clamp(1.75rem, 3vw, 2.35rem); font-weight: 500; letter-spacing: -.035em; line-height: 1.12; }
.legal-document__content :deep(.legal-section h3) { margin: 28px 0 10px; color: var(--ink); font-size: .94rem; font-weight: 850; }
.legal-document__content :deep(.legal-section p) { margin: 0 0 14px; color: var(--ink-soft); font-size: .91rem; line-height: 1.8; }
.legal-document__content :deep(.legal-section ul), .legal-document__content :deep(.legal-section ol) { display: grid; gap: 10px; margin: 14px 0 18px; padding-left: 21px; color: var(--ink-soft); font-size: .91rem; line-height: 1.7; }
.legal-document__content :deep(.legal-section strong) { color: var(--ink); }
.legal-document__content :deep(.legal-section a) { color: #397a69; font-weight: 800; text-underline-offset: 3px; }
.legal-document__content :deep(.legal-note) { display: grid; grid-template-columns: auto 1fr; gap: 9px; margin: 20px 0; padding: 15px 17px; border-left: 3px solid #397a69; border-radius: 0 12px 12px 0; background: #edf7f3; }
.legal-document__content :deep(.legal-note svg) { margin-top: 3px; color: #397a69; }
.legal-document__content :deep(.legal-note p) { margin: 0; }
.legal-document__content :deep(.legal-table-wrap) { overflow-x: auto; margin: 18px 0 22px; border: 1px solid var(--line); border-radius: 14px; }
.legal-document__content :deep(.legal-table) { width: 100%; min-width: 620px; border-collapse: collapse; background: white; text-align: left; }
.legal-document__content :deep(.legal-table th) { padding: 12px 14px; background: #e7f2ee; color: var(--ink); font-size: var(--font-size-min); letter-spacing: .03em; }
.legal-document__content :deep(.legal-table td) { padding: 13px 14px; border-top: 1px solid var(--line); color: var(--ink-soft); font-size: var(--font-size-min); line-height: 1.55; vertical-align: top; }

@media (max-width: 920px) {
  .legal-document__hero-inner { grid-template-columns: 1fr; gap: 35px; }
  .legal-document__metadata { grid-template-columns: repeat(2, 1fr); width: min(100%, 460px); }
  .legal-document__metadata > div { border-top: 1px solid rgba(255,255,255,.18); }
  .legal-document__layout { grid-template-columns: 1fr; gap: 40px; }
  .legal-document__aside nav { position: static; }
  .legal-document__aside ol { grid-template-columns: repeat(2, 1fr); column-gap: 26px; }
}

@media (max-width: 620px) {
  .legal-document__hero { padding: 54px 0 50px; }
  .legal-document__heading > p:last-child { font-size: .91rem; }
  .legal-document__metadata { min-width: 0; }
  .legal-document__layout { padding-block: 44px 70px; }
  .legal-document__aside ol { grid-template-columns: 1fr; }
  .legal-document__content :deep(.legal-lead) { margin-bottom: 38px; padding: 19px; }
  .legal-document__content :deep(.legal-section) { padding-bottom: 34px; margin-bottom: 34px; }
}
</style>
