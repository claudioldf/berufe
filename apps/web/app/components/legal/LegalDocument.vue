<script setup lang="ts">
import type { LegalDocumentSection } from "~/types";

defineProps<{
  eyebrow: string;
  title: string;
  description: string;
  version: string;
  updatedAt: string;
  sections: LegalDocumentSection[];
}>();

defineSlots<{
  default(): unknown;
}>();
</script>

<template>
  <article class="legal-document">
    <header class="legal-document__hero">
      <div class="legal-document__hero-shape" />
      <DesignSystemContainer class="legal-document__hero-inner">
        <div class="legal-document__heading">
          <DesignSystemEyebrow tone="inverse">{{
            eyebrow
          }}</DesignSystemEyebrow>
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
      </DesignSystemContainer>
    </header>

    <div class="legal-document__draft">
      <DesignSystemContainer class="legal-document__draft-inner">
        <UIcon name="i-lucide-file-check-2" />
        <p>
          <strong>Minuta para revisão.</strong>
          Este documento reflete o produto planejado e ainda depende de
          validação jurídica e dos dados oficiais da responsável pela Berufe
          antes do lançamento com usuários reais.
        </p>
      </DesignSystemContainer>
    </div>

    <DesignSystemContainer class="legal-document__layout">
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
    </DesignSystemContainer>
  </article>
</template>

<style scoped lang="scss">
.legal-document {
  background: var(--color-surface-warm);
  &__hero {
    position: relative;
    overflow: hidden;
    padding: 78px 0 72px;
    background: var(--color-brand-strong);
    color: white;
  }
  &__hero-shape {
    position: absolute;
    top: -170px;
    right: -70px;
    width: 430px;
    height: 430px;
    border: 92px solid rgb(216 240 231 / 8%);
    border-radius: 999px;
  }
  &__hero-inner {
    position: relative;
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    align-items: end;
    gap: 70px;
  }
  &__heading {
    max-width: 780px;
  }
  &__heading h1 {
    max-width: 760px;
    margin: 0;
    font-family: Georgia, "Times New Roman", serif;
    font-size: clamp(2.8rem, 6vw, 5.4rem);
    font-weight: 500;
    letter-spacing: -0.055em;
    line-height: 0.98;
  }
  &__heading > p:last-child {
    max-width: 680px;
    margin: 25px 0 0;
    color: rgb(255 255 255 / 67%);
    font-size: 1rem;
    line-height: 1.75;
  }
  &__metadata {
    display: grid;
    min-width: 210px;
    margin: 0;
    border-top: 1px solid rgb(255 255 255 / 18%);
  }
  &__metadata > div {
    padding: 13px 0;
    border-bottom: 1px solid rgb(255 255 255 / 18%);
  }
  &__metadata dt {
    color: rgb(255 255 255 / 50%);
    font-size: var(--font-size-min);
    font-weight: 800;
    letter-spacing: 0.08em;
    text-transform: uppercase;
  }
  &__metadata dd {
    margin: 5px 0 0;
    font-size: 0.86rem;
    font-weight: 800;
  }
  &__draft {
    border-bottom: 1px solid #d5a99f;
    background: var(--color-accent-tint);
    color: #773d32;
  }
  &__draft-inner {
    display: grid;
    grid-template-columns: auto 1fr;
    align-items: center;
    gap: 11px;
    padding-block: 14px;
  }
  &__draft-inner > svg {
    font-size: 1.25rem;
  }
  &__draft p {
    margin: 0;
    font-size: 0.84rem;
    line-height: 1.55;
  }
  &__layout {
    display: grid;
    grid-template-columns: 250px minmax(0, 760px);
    justify-content: center;
    gap: 78px;
    padding-block: 68px 100px;
  }
  &__aside {
    min-width: 0;
  }
  &__aside nav {
    position: sticky;
    top: 24px;
  }
  &__aside nav > p {
    margin: 0 0 14px;
    color: var(--color-brand);
    font-size: var(--font-size-min);
    font-weight: 850;
    letter-spacing: 0.1em;
    text-transform: uppercase;
  }
  &__aside ol {
    display: grid;
    gap: 0;
    margin: 0;
    padding: 0;
    border-top: 1px solid var(--line);
    list-style: none;
    counter-reset: legal-section;
  }
  &__aside li {
    counter-increment: legal-section;
    border-bottom: 1px solid var(--line);
  }
  &__aside a {
    display: grid;
    grid-template-columns: 24px 1fr;
    gap: 7px;
    padding: 10px 0;
    color: var(--ink-soft);
    font-size: var(--font-size-min);
    font-weight: 720;
    line-height: 1.35;
    text-decoration: none;
  }
  &__aside a::before {
    content: counter(legal-section, decimal-leading-zero);
    color: #98a9a4;
    font-family: var(--font-display);
    font-size: var(--font-size-min);
  }
  &__aside a:hover {
    color: var(--color-brand);
  }
  &__content {
    min-width: 0;
  }
  &__content :deep(.legal-lead) {
    margin: 0 0 48px;
    padding: 24px 26px;
    border: 1px solid var(--line);
    border-radius: 18px;
    background: #f2f7f4;
    color: var(--ink);
    font-size: 0.94rem;
    line-height: 1.75;
  }
  &__content :deep(.legal-lead p) {
    margin: 0;
  }
  &__content :deep(.legal-lead p + p) {
    margin-top: 12px;
  }
  &__content :deep(.legal-section) {
    scroll-margin-top: 24px;
    padding: 0 0 42px;
    margin: 0 0 42px;
    border-bottom: 1px solid var(--line);
  }
  &__content :deep(.legal-section:last-child) {
    padding-bottom: 0;
    margin-bottom: 0;
    border-bottom: 0;
  }
  &__content :deep(.legal-section h2) {
    margin: 0 0 20px;
    font-family: Georgia, "Times New Roman", serif;
    font-size: clamp(1.75rem, 3vw, 2.35rem);
    font-weight: 500;
    letter-spacing: -0.035em;
    line-height: 1.12;
  }
  &__content :deep(.legal-section h3) {
    margin: 28px 0 10px;
    color: var(--ink);
    font-size: 0.94rem;
    font-weight: 850;
  }
  &__content :deep(.legal-section p) {
    margin: 0 0 14px;
    color: var(--ink-soft);
    font-size: 0.91rem;
    line-height: 1.8;
  }
  &__content :deep(.legal-section ul),
  &__content :deep(.legal-section ol) {
    display: grid;
    gap: 10px;
    margin: 14px 0 18px;
    padding-left: 21px;
    color: var(--ink-soft);
    font-size: 0.91rem;
    line-height: 1.7;
  }
  &__content :deep(.legal-section strong) {
    color: var(--ink);
  }
  &__content :deep(.legal-section a) {
    color: var(--color-brand);
    font-weight: 800;
    text-underline-offset: 3px;
  }
  &__content :deep(.legal-note) {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 9px;
    margin: 20px 0;
    padding: 15px 17px;
    border-left: 3px solid var(--color-brand);
    border-radius: 0 12px 12px 0;
    background: #edf7f3;
  }
  &__content :deep(.legal-note svg) {
    margin-top: 3px;
    color: var(--color-brand);
  }
  &__content :deep(.legal-note p) {
    margin: 0;
  }
  &__content :deep(.legal-table-wrap) {
    overflow-x: auto;
    margin: 18px 0 22px;
    border: 1px solid var(--line);
    border-radius: 14px;
  }
  &__content :deep(.legal-table) {
    width: 100%;
    min-width: 620px;
    border-collapse: collapse;
    background: white;
    text-align: left;
  }
  &__content :deep(.legal-table th) {
    padding: 12px 14px;
    background: #e7f2ee;
    color: var(--ink);
    font-size: var(--font-size-min);
    letter-spacing: 0.03em;
  }
  &__content :deep(.legal-table td) {
    padding: 13px 14px;
    border-top: 1px solid var(--line);
    color: var(--ink-soft);
    font-size: var(--font-size-min);
    line-height: 1.55;
    vertical-align: top;
  }
}

@media (width <= 920px) {
  .legal-document {
    &__hero-inner {
      grid-template-columns: 1fr;
      gap: 35px;
    }
    &__metadata {
      grid-template-columns: repeat(2, 1fr);
      width: min(100%, 460px);
    }
    &__metadata > div {
      border-top: 1px solid rgb(255 255 255 / 18%);
    }
    &__layout {
      grid-template-columns: 1fr;
      gap: 40px;
    }
    &__aside nav {
      position: static;
    }
    &__aside ol {
      grid-template-columns: repeat(2, 1fr);
      column-gap: 26px;
    }
  }
}

@media (width <= 620px) {
  .legal-document {
    &__hero {
      padding: 54px 0 50px;
    }
    &__heading > p:last-child {
      font-size: 0.91rem;
    }
    &__metadata {
      min-width: 0;
    }
    &__layout {
      padding-block: 44px 70px;
    }
    &__aside ol {
      grid-template-columns: 1fr;
    }
    &__content :deep(.legal-lead) {
      margin-bottom: 38px;
      padding: 19px;
    }
    &__content :deep(.legal-section) {
      padding-bottom: 34px;
      margin-bottom: 34px;
    }
  }
}
</style>
