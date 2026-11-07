<script setup lang="ts">
import { ref } from "vue";

const route = useRoute();
const { data: article } = await useAsyncData(`ajuda-${route.path}`, () =>
  queryCollection("ajuda").path(route.path).first(),
);
if (!article.value) {
  throw createError({
    statusCode: 404,
    statusMessage: "Página não encontrada",
  });
}

const supportOpen = ref(false);
const canonicalUrl = withSiteUrl(route.path);

useSeoMeta({
  title: () => article.value?.title,
  description: () => article.value?.description,
  ogTitle: () => article.value?.title,
  ogDescription: () => article.value?.description,
  ogUrl: () => canonicalUrl.value,
  ogType: "article",
  robots: "index, follow",
});
useHead(() => ({ link: [{ rel: "canonical", href: canonicalUrl.value }] }));
defineOgImageSafely("BerufeDefault", {
  title: article.value?.title,
  description: article.value?.description,
});
</script>

<template>
  <div v-if="article" class="help">
    <section class="help__masthead">
      <DesignSystemContainer class="help__masthead-inner">
        <DesignSystemEyebrow>
          <NuxtLink to="/ajuda">Central de ajuda</NuxtLink>
        </DesignSystemEyebrow>
        <h1>{{ article.title }}</h1>
        <p>{{ article.description }}</p>
      </DesignSystemContainer>
    </section>

    <DesignSystemPageSection>
      <DesignSystemContainer class="help__body">
        <div class="help__content">
          <ContentRenderer :value="article" />
        </div>
        <HelpRetentionSection
          v-if="article.retention"
          @contact="supportOpen = true"
        />
        <HelpCtaSection v-bind="article.cta" />
      </DesignSystemContainer>
    </DesignSystemPageSection>

    <HelpSupportContactModal
      v-model:open="supportOpen"
      :topic="article.action"
    />
  </div>
</template>

<style scoped lang="scss">
.help {
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

  &__content :deep(h2) {
    margin: 36px 0 14px;
    font-family: var(--font-display);
    font-size: 1.4rem;
  }

  &__content :deep(h3) {
    margin: 24px 0 8px;
    font-family: var(--font-display);
    font-size: 1.1rem;
  }

  &__content :deep(p) {
    margin: 0 0 16px;
    color: var(--ink-soft);
    line-height: 1.7;
  }

  &__content :deep(ul),
  &__content :deep(ol) {
    margin: 0 0 16px;
    padding-left: 22px;
    color: var(--ink-soft);
    line-height: 1.7;
  }

  &__content :deep(a) {
    color: var(--color-brand);
    font-weight: 700;
  }
}
</style>
