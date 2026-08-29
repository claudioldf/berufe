<script setup lang="ts">
const route = useRoute();
const { data: guide } = await useAsyncData(`guia-${route.path}`, () =>
  queryCollection("guias").path(route.path).first(),
);
if (!guide.value) {
  throw createError({ statusCode: 404, statusMessage: "Guia não encontrado" });
}

const canonicalUrl = withSiteUrl(route.path);

useSeoMeta({
  title: () => guide.value?.title,
  description: () => guide.value?.description,
  ogTitle: () => guide.value?.title,
  ogDescription: () => guide.value?.description,
  ogUrl: () => canonicalUrl.value,
  ogType: "article",
});
useHead(() => ({ link: [{ rel: "canonical", href: canonicalUrl.value }] }));
defineOgImageSafely("BerufeDefault", {
  title: guide.value?.title,
  description: guide.value?.description,
});
useSchemaOrg([
  defineArticle({
    headline: () => guide.value?.title,
    description: () => guide.value?.description,
    datePublished: () => guide.value?.publishedAt,
    dateModified: () => guide.value?.updatedAt ?? guide.value?.publishedAt,
  }),
]);
</script>

<template>
  <div v-if="guide" class="guide">
    <section class="guide__masthead">
      <DesignSystemContainer class="guide__masthead-inner">
        <DesignSystemEyebrow>
          <NuxtLink to="/guias">Guias para profissionais</NuxtLink>
        </DesignSystemEyebrow>
        <h1>{{ guide.title }}</h1>
        <p>{{ guide.description }}</p>
      </DesignSystemContainer>
    </section>

    <DesignSystemPageSection class="guide__content">
      <DesignSystemContainer class="guide__body">
        <ContentRenderer :value="guide" />
        <div class="guide__cta">
          <p><strong>Pronto para começar?</strong></p>
          <UButton
            to="/para-profissionais"
            color="primary"
            trailing-icon="i-lucide-arrow-right"
          >
            Criar perfil grátis
          </UButton>
        </div>
      </DesignSystemContainer>
    </DesignSystemPageSection>
  </div>
</template>

<style scoped lang="scss">
.guide {
  &__masthead {
    padding: 40px 0 36px;
    background: #dff1eb;
  }

  &__masthead-inner h1 {
    margin: 12px 0 0;
    font-family: var(--font-display);
    font-size: clamp(1.9rem, 4vw, 2.8rem);
    font-weight: 500;
    letter-spacing: -0.03em;
    line-height: 1.1;
  }

  &__masthead-inner > p {
    max-width: 680px;
    margin: 14px 0 0;
    color: var(--ink-soft);
    line-height: 1.6;
  }

  &__body {
    max-width: 720px;
  }

  &__body :deep(h2) {
    margin: 36px 0 14px;
    font-family: var(--font-display);
    font-size: 1.4rem;
  }

  &__body :deep(p) {
    margin: 0 0 16px;
    color: var(--ink-soft);
    line-height: 1.7;
  }

  &__body :deep(ul),
  &__body :deep(ol) {
    margin: 0 0 16px;
    padding-left: 22px;
    color: var(--ink-soft);
    line-height: 1.7;
  }

  &__body :deep(blockquote) {
    margin: 0 0 16px;
    padding: 14px 18px;
    border-left: 3px solid var(--color-brand);
    background: var(--color-brand-tint-muted);
    color: var(--ink);
  }

  &__body :deep(a) {
    color: var(--color-brand);
    font-weight: 700;
  }

  &__cta {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    margin-top: 36px;
    padding: 24px;
    border-radius: 18px;
    background: var(--color-brand-tint-muted);
  }

  &__cta p {
    margin: 0;
  }
}
</style>
