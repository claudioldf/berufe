<script setup lang="ts">
import type { LocalPagesCollectionItem } from "@nuxt/content";

defineProps<{
  content: LocalPagesCollectionItem;
  professionalCount: number;
  serviceName: string;
  cityName: string;
}>();
</script>

<template>
  <DesignSystemPageSection class="local-editorial">
    <DesignSystemContainer class="local-editorial__inner">
      <aside class="local-editorial__live" aria-label="Oferta atual">
        <UIcon name="i-lucide-users-round" aria-hidden="true" />
        <p>
          <strong>{{ professionalCount }}</strong>
          {{
            professionalCount === 1 ? "perfil publicado" : "perfis publicados"
          }}
          de {{ serviceName.toLocaleLowerCase("pt-BR") }} em {{ cityName }}.
        </p>
      </aside>
      <article class="local-editorial__body">
        <ContentRenderer :value="content" />
      </article>
    </DesignSystemContainer>
  </DesignSystemPageSection>
</template>

<style scoped lang="scss">
.local-editorial {
  padding-top: 8px;

  &__inner {
    max-width: 760px;
  }

  &__live {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 28px;
    padding: 16px 18px;
    border: 1px solid var(--line);
    border-radius: 14px;
    background: var(--color-brand-tint-muted);
  }

  &__live svg {
    flex-shrink: 0;
    color: var(--color-brand);
    font-size: 1.3rem;
  }

  &__live p {
    margin: 0;
    color: var(--ink-soft);
  }

  &__live strong {
    color: var(--ink);
  }

  &__body :deep(h2) {
    margin: 34px 0 13px;
    font-family: var(--font-display);
    font-size: 1.45rem;
  }

  &__body :deep(p) {
    margin: 0 0 16px;
    color: var(--ink-soft);
    line-height: 1.72;
  }

  &__body :deep(ul) {
    margin: 0 0 18px;
    padding-left: 22px;
    color: var(--ink-soft);
    line-height: 1.7;
  }

  &__body :deep(strong) {
    color: var(--ink);
  }
}
</style>
