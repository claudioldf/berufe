<script setup lang="ts">
const catalogResult = await useCatalogs();
if (catalogResult.error.value || !catalogResult.data.value) {
  throw createError({
    statusCode: 503,
    statusMessage: "Catálogo temporariamente indisponível.",
  });
}
const categories = computed(() => catalogResult.data.value?.categories ?? []);
const services = computed(() => catalogResult.data.value?.services ?? []);

function servicesFor(categoryId: string) {
  // Category `id` here is actually the category slug -- see
  // mapPublicCatalog in app/services/api/catalog.ts.
  return services.value.filter((service) => service.category === categoryId);
}

const title = "Serviços para sua casa";
const description =
  "Encontre profissionais verificados por serviço: elétrica, hidráulica, pintura, reformas e mais.";
const canonicalUrl = withSiteUrl("/servicos");

useSeoMeta({
  title,
  description,
  ogTitle: title,
  ogDescription: description,
  ogUrl: () => canonicalUrl.value,
  ogType: "website",
});
useHead(() => ({ link: [{ rel: "canonical", href: canonicalUrl.value }] }));
defineOgImageSafely("BerufeDefault", { title, description });
</script>

<template>
  <div class="services-hub">
    <section class="services-hub__masthead">
      <DesignSystemContainer class="services-hub__masthead-inner">
        <DesignSystemEyebrow>Serviços</DesignSystemEyebrow>
        <h1>Encontre o <em>serviço certo</em> para sua casa</h1>
        <p>
          Profissionais verificados, organizados por especialidade. Escolha um
          serviço para ver quem atende na sua cidade.
        </p>
      </DesignSystemContainer>
    </section>

    <DesignSystemPageSection class="services-hub__content">
      <DesignSystemContainer>
        <div
          v-for="category in categories"
          :key="category.id"
          class="category-block"
        >
          <h2>{{ category.name }}</h2>
          <div class="category-block__grid">
            <NuxtLink
              v-for="service in servicesFor(category.id)"
              :key="service.id"
              :to="`/servicos/${service.slug}`"
              class="service-tile"
            >
              <UIcon :name="service.icon" aria-hidden="true" />
              <span>{{ service.name }}</span>
            </NuxtLink>
          </div>
        </div>
      </DesignSystemContainer>
    </DesignSystemPageSection>
  </div>
</template>

<style scoped lang="scss">
.services-hub {
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
    font-style: normal;
  }

  &__masthead-inner > p {
    max-width: 640px;
    margin: 15px 0 0;
    color: var(--ink-soft);
    line-height: 1.65;
  }
}

.category-block {
  margin-bottom: 34px;

  h2 {
    margin: 0 0 14px;
    font-family: var(--font-display);
    font-size: 1.2rem;
  }

  &__grid {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
  }
}

.service-tile {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 11px 16px;
  border: 1px solid var(--line);
  border-radius: 12px;
  color: var(--ink);
  font-size: 0.9rem;
  font-weight: 700;
  text-decoration: none;
  transition: border-color 0.15s ease;

  &:hover {
    border-color: var(--color-brand);
  }

  svg {
    color: var(--color-brand);
  }
}
</style>
