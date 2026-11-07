<script setup lang="ts">
const { data: articles } = await useAsyncData("ajuda-index", () =>
  queryCollection("ajuda").order("title", "ASC").all(),
);

const title = "Central de ajuda";
const description =
  "Passo a passo para entrar, criar conta, editar seu perfil ou excluir sua conta na Berufe.";
const canonicalUrl = withSiteUrl("/ajuda");

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
  <div class="help-index">
    <section class="help-index__masthead">
      <DesignSystemContainer>
        <DesignSystemEyebrow>Ajuda</DesignSystemEyebrow>
        <h1>Central de <em>ajuda</em></h1>
        <p>Passo a passo para as ações mais comuns da sua conta.</p>
      </DesignSystemContainer>
    </section>

    <DesignSystemPageSection>
      <DesignSystemContainer>
        <div class="help-index__grid">
          <NuxtLink
            v-for="article in articles"
            :key="article.path"
            :to="article.path"
            class="help-card"
          >
            <h2>{{ article.title }}</h2>
            <p>{{ article.description }}</p>
            <span class="help-card__cta">
              Ver passo a passo
              <UIcon name="i-lucide-arrow-right" aria-hidden="true" />
            </span>
          </NuxtLink>
        </div>
      </DesignSystemContainer>
    </DesignSystemPageSection>
  </div>
</template>

<style scoped lang="scss">
.help-index {
  &__masthead {
    padding: 40px 0 44px;
    background: #dff1eb;
  }

  &__masthead h1 {
    margin: 0;
    font-family: var(--font-display);
    font-size: clamp(2.4rem, 5vw, 4rem);
    font-weight: 500;
    letter-spacing: -0.045em;
    line-height: 1;
  }

  &__masthead h1 em {
    color: var(--color-brand);
    font-weight: inherit;
  }

  &__masthead p {
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

.help-card {
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
    font-size: 1.15rem;
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
