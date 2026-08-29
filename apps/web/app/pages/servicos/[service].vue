<script setup lang="ts">
import { fetchPublicServiceCoverage } from "~/services/api/public-discovery";
import { useApiClient } from "~/services/api/client";

const route = useRoute();
const client = useApiClient();
const serviceSlug = computed(() => String(route.params.service));

const catalogResult = await useCatalogs();
const service = computed(() =>
  catalogResult.data.value?.services.find(
    (candidate) => candidate.slug === serviceSlug.value,
  ),
);
if (!service.value) {
  throw createError({
    statusCode: 404,
    statusMessage: "Serviço não encontrado",
  });
}

const { data: coverage } = await useAsyncData(
  () => `service-hub-coverage-${serviceSlug.value}`,
  () => fetchPublicServiceCoverage(client, { serviceSlug: serviceSlug.value }),
);
const indexableCoverage = computed(
  () => coverage.value?.filter((entry) => entry.indexable) ?? [],
);
const isIndexable = computed(() => indexableCoverage.value.length > 0);

const serviceName = computed(() => service.value?.name ?? "");
const title = computed(() => `${serviceName.value} — encontre por cidade`);
const description = computed(
  () =>
    `${service.value?.description ?? ""} Veja profissionais de ${serviceName.value.toLocaleLowerCase("pt-BR")} verificados por cidade.`,
);
const siteUrl = withSiteUrl("/");
const canonicalUrl = computed(
  () => `${siteUrl.value.replace(/\/$/, "")}${route.path}`,
);

useSeoMeta({
  title: () => title.value,
  description: () => description.value,
  ogTitle: () => title.value,
  ogDescription: () => description.value,
  ogUrl: () => canonicalUrl.value,
  ogType: "website",
  robots: () => (isIndexable.value ? "index, follow" : "noindex, follow"),
});
useHead(() => ({ link: [{ rel: "canonical", href: canonicalUrl.value }] }));
defineOgImageSafely("BerufeDefault", {
  title: () => title.value,
  description: () => description.value,
});

function listingPath(entry: {
  location: { stateSlug: string; citySlug: string };
}) {
  return `/encontrar/${entry.location.stateSlug}/${entry.location.citySlug}/${serviceSlug.value}`;
}
</script>

<template>
  <div v-if="service" class="service-hub">
    <section class="service-hub__masthead">
      <DesignSystemContainer class="service-hub__masthead-inner">
        <DesignSystemEyebrow>{{ serviceName }}</DesignSystemEyebrow>
        <h1>{{ serviceName }} <em>perto de você</em></h1>
        <p>{{ service.description }}</p>
      </DesignSystemContainer>
    </section>

    <DesignSystemPageSection class="service-hub__content">
      <DesignSystemContainer>
        <template v-if="indexableCoverage.length">
          <h2>
            Cidades com profissionais de
            {{ serviceName.toLocaleLowerCase("pt-BR") }}
          </h2>
          <div class="city-grid">
            <NuxtLink
              v-for="entry in indexableCoverage"
              :key="`${entry.location.cityCode}`"
              :to="listingPath(entry)"
              class="city-card"
            >
              <strong>{{ entry.location.city }}</strong>
              <span>
                {{ entry.professionalCount }}
                {{
                  entry.professionalCount === 1
                    ? "profissional"
                    : "profissionais"
                }}
              </span>
            </NuxtLink>
          </div>
        </template>
        <PublicServiceHubEmptyState
          v-else
          :service-name="serviceName"
          :service-slug="serviceSlug"
          :service-icon="service.icon"
        />
      </DesignSystemContainer>
    </DesignSystemPageSection>
  </div>
</template>

<style scoped lang="scss">
.service-hub {
  &__masthead {
    padding: 40px 0 44px;
    background: #dff1eb;
  }

  &__masthead-inner h1 {
    margin: 0;
    font-family: var(--font-display);
    font-size: clamp(2.2rem, 4.5vw, 3.6rem);
    font-weight: 500;
    letter-spacing: -0.04em;
    line-height: 1.1;
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

  &__content h2 {
    margin: 0 0 18px;
    font-family: var(--font-display);
    font-size: 1.3rem;
  }
}

.city-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 14px;
}

.city-card {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 18px;
  border: 1px solid var(--line);
  border-radius: 14px;
  color: inherit;
  text-decoration: none;
  transition: border-color 0.15s ease;

  &:hover {
    border-color: var(--color-brand);
  }

  strong {
    font-family: var(--font-display);
    font-size: 1.05rem;
  }

  span {
    color: var(--ink-soft);
    font-size: 0.84rem;
  }
}
</style>
