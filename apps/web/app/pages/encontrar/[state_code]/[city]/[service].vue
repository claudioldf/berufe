<script setup lang="ts">
import { computed } from "vue";
import LocalServiceEditorial from "~/components/public/local/LocalServiceEditorial.vue";
import LocalServiceProfessionals from "~/components/public/local/LocalServiceProfessionals.vue";
import { fetchPublicProfessionalListing } from "~/services/api/public-discovery";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import {
  buildLocalServiceSchema,
  isLocalPageIndexable,
} from "~/utils/seoContent";

const route = useRoute();
const client = useApiClient();
const stateSlug = computed(() => String(route.params.state_code));
const citySlug = computed(() => String(route.params.city));
const serviceSlug = computed(() => String(route.params.service));

const { data: listing, error } = await useAsyncData(
  () => `listing-${stateSlug.value}-${citySlug.value}-${serviceSlug.value}`,
  () =>
    fetchPublicProfessionalListing(client, {
      serviceSlug: serviceSlug.value,
      stateSlug: stateSlug.value,
      citySlug: citySlug.value,
    }),
);
if (error.value || !listing.value) {
  const notFound =
    error.value instanceof ApiRequestError && error.value.code === "not_found";
  throw createError({
    statusCode: notFound ? 404 : 503,
    statusMessage: notFound
      ? "Serviço ou cidade não encontrados"
      : "Listagem temporariamente indisponível.",
  });
}

const { data: localContent } = await useAsyncData(
  () =>
    `local-content-${stateSlug.value}-${citySlug.value}-${serviceSlug.value}`,
  () =>
    queryCollection("localPages")
      .where("stateSlug", "=", stateSlug.value)
      .where("citySlug", "=", citySlug.value)
      .where("serviceSlug", "=", serviceSlug.value)
      .first(),
);

const publishedContent = computed(() =>
  localContent.value?.published ? localContent.value : null,
);
const serviceName = computed(() => listing.value?.service.name ?? "");
const cityName = computed(() => listing.value?.location.city ?? "");
const title = computed(
  () =>
    publishedContent.value?.title ??
    `${serviceName.value} em ${cityName.value} — profissionais verificados`,
);
const description = computed(
  () =>
    publishedContent.value?.description ??
    `${listing.value?.totalCount ?? 0} profissionais de ${serviceName.value.toLocaleLowerCase("pt-BR")} em ${cityName.value}. Veja portfólio, referências e fale direto pelo WhatsApp.`,
);
const indexable = computed(() =>
  isLocalPageIndexable(
    listing.value?.indexable ?? false,
    publishedContent.value,
  ),
);
const siteUrl = withSiteUrl("/");
const siteRoot = computed(() => siteUrl.value.replace(/\/$/, ""));
const canonicalUrl = computed(() => `${siteRoot.value}${route.path}`);

useSeoMeta({
  title: () => title.value,
  description: () => description.value,
  ogTitle: () => title.value,
  ogDescription: () => description.value,
  ogUrl: () => canonicalUrl.value,
  ogType: "website",
  robots: () => (indexable.value ? "index, follow" : "noindex, follow"),
});
useHead(() => ({ link: [{ rel: "canonical", href: canonicalUrl.value }] }));
defineOgImageSafely("BerufeDefault", {
  title: () => title.value,
  description: () => description.value,
});

useSchemaOrg([
  buildLocalServiceSchema({
    canonicalUrl: canonicalUrl.value,
    siteRoot: siteRoot.value,
    serviceName: listing.value.service.name,
    cityName: listing.value.location.city,
    stateCode: listing.value.location.stateCode,
    description: description.value,
    professionals: listing.value.professionals.map((professional) => ({
      name: professional.name,
      slug: professional.slug,
    })),
  }),
  defineBreadcrumb({
    itemListElement: [
      { name: "Berufe", item: "/" },
      {
        name: listing.value.location.city,
        item: `/encontrar/${stateSlug.value}/${citySlug.value}`,
      },
      { name: listing.value.service.name, item: canonicalUrl.value },
    ],
  }),
  defineItemList({
    itemListElement: listing.value.professionals.map((professional) => ({
      name: professional.name,
      url: `${siteRoot.value}${buildPublicProfilePath(professional.slug)}`,
    })),
  }),
]);
</script>

<template>
  <div v-if="listing" class="listing">
    <section class="listing__masthead">
      <DesignSystemContainer class="listing__masthead-inner">
        <DesignSystemEyebrow>
          <NuxtLink :to="`/encontrar/${stateSlug}/${citySlug}`">
            {{ cityName }}
          </NuxtLink>
        </DesignSystemEyebrow>
        <h1>
          {{ serviceName }} <em>em {{ cityName }}</em>
        </h1>
        <p>
          {{ listing.totalCount }}
          {{
            listing.totalCount === 1
              ? "profissional verificado"
              : "profissionais verificados"
          }}
          — veja portfólio, referências e fale direto pelo WhatsApp.
        </p>
        <NuxtLink
          :to="`/encontrar/${stateSlug}/${citySlug}`"
          class="listing__search-link"
        >
          <UIcon name="i-lucide-search" aria-hidden="true" />
          Buscar outro serviço em {{ cityName }}
        </NuxtLink>
      </DesignSystemContainer>
    </section>

    <LocalServiceProfessionals
      :listing="listing"
      :state-slug="stateSlug"
      :city-slug="citySlug"
      :service-slug="serviceSlug"
    />

    <LocalServiceEditorial
      v-if="publishedContent"
      :content="publishedContent"
      :professional-count="listing.totalCount"
      :service-name="serviceName"
      :city-name="cityName"
    />
  </div>
</template>

<style scoped lang="scss">
.listing {
  &__masthead {
    padding: 40px 0 32px;
    background: #dff1eb;
  }

  &__masthead-inner h1 {
    margin: 8px 0 0;
    font-family: var(--font-display);
    font-size: clamp(2.1rem, 4.5vw, 3.4rem);
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
    max-width: 680px;
    margin: 14px 0 22px;
    color: var(--ink-soft);
    line-height: 1.6;
  }

  &__search-link {
    display: inline-flex;
    align-items: center;
    gap: 7px;
    color: var(--color-brand);
    font-size: 0.86rem;
    font-weight: 800;
    text-decoration: none;
  }
}
</style>
