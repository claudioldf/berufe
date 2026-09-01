<script setup lang="ts">
const { data: guides } = await useAsyncData("guias-index", () =>
  queryCollection("guias").order("publishedAt", "DESC").all(),
);

const title = "Guias para profissionais";
const description =
  "Como conseguir clientes, divulgar seu trabalho e fechar mais orçamentos sem pagar por cada contato.";
const canonicalUrl = withSiteUrl("/guias");

useSeoMeta({
  title,
  description,
  ogTitle: title,
  ogDescription: description,
  ogUrl: () => canonicalUrl.value,
  ogType: "website",
  robots: "index, follow",
});
useHead(() => ({ link: [{ rel: "canonical", href: canonicalUrl.value }] }));
defineOgImageSafely("BerufeDefault", { title, description });
</script>

<template>
  <div class="guides">
    <section class="guides__masthead">
      <DesignSystemContainer class="guides__masthead-inner">
        <DesignSystemEyebrow>Para profissionais</DesignSystemEyebrow>
        <h1>Guias para <em>conseguir mais clientes</em></h1>
        <p>
          Conteúdo direto sobre divulgação, orçamento e confiança — sem fórmula
          mágica, sem pagar por contato.
        </p>
      </DesignSystemContainer>
    </section>

    <DesignSystemPageSection class="guides__content">
      <DesignSystemContainer>
        <div class="guides__grid">
          <NuxtLink
            v-for="guide in guides"
            :key="guide.path"
            :to="guide.path"
            class="guide-card"
          >
            <h2>{{ guide.title }}</h2>
            <p>{{ guide.description }}</p>
            <span class="guide-card__cta">
              Ler guia
              <UIcon name="i-lucide-arrow-right" aria-hidden="true" />
            </span>
          </NuxtLink>
        </div>
      </DesignSystemContainer>
    </DesignSystemPageSection>
  </div>
</template>

<style scoped lang="scss">
.guides {
  &__masthead {
    padding: 40px 0 44px;
    background: #dff1eb;
  }

  &__masthead-inner h1 {
    margin: 0;
    font-family: var(--font-display);
    font-size: clamp(2.4rem, 5vw, 4rem);
    font-weight: 500;
    letter-spacing: -0.045em;
    line-height: 1;
  }

  &__masthead-inner h1 em {
    color: var(--color-brand);
    font-weight: inherit;
  }

  &__masthead-inner > p {
    max-width: 640px;
    margin: 15px 0 0;
    color: var(--ink-soft);
    line-height: 1.65;
  }

  &__grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 20px;
  }
}

.guide-card {
  display: flex;
  flex-direction: column;
  padding: 24px;
  border: 1px solid var(--line);
  border-radius: 18px;
  color: inherit;
  text-decoration: none;
  transition: border-color 0.15s ease;

  &:hover {
    border-color: var(--color-brand);
  }

  h2 {
    margin: 0 0 10px;
    font-family: var(--font-display);
    font-size: 1.25rem;
    font-weight: 600;
  }

  p {
    flex: 1;
    margin: 0 0 16px;
    color: var(--ink-soft);
    font-size: 0.9rem;
    line-height: 1.55;
  }

  &__cta {
    display: flex;
    align-items: center;
    gap: 6px;
    color: var(--color-brand);
    font-size: 0.86rem;
    font-weight: 800;
  }
}
</style>
