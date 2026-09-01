<script setup lang="ts">
import { fetchPublicProfessionalListing } from "~/services/api/public-discovery";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";

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

const serviceName = computed(() => listing.value?.service.name ?? "");
const cityName = computed(() => listing.value?.location.city ?? "");
const title = computed(
  () => `${serviceName.value} em ${cityName.value} — profissionais verificados`,
);
const description = computed(
  () =>
    `${listing.value?.totalCount ?? 0} profissionais de ${serviceName.value.toLocaleLowerCase("pt-BR")} em ${cityName.value}. Veja portfólio, referências e fale direto pelo WhatsApp.`,
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
  robots: () =>
    listing.value?.indexable ? "index, follow" : "noindex, follow",
});
useHead(() => ({ link: [{ rel: "canonical", href: canonicalUrl.value }] }));
defineOgImageSafely("BerufeDefault", {
  title: () => title.value,
  description: () => description.value,
});
useSchemaOrg([
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
      url: buildPublicProfilePath(professional.slug),
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

    <DesignSystemPageSection class="listing__content">
      <DesignSystemContainer>
        <div v-if="listing.professionals.length" class="listing__grid">
          <NuxtLink
            v-for="professional in listing.professionals"
            :key="professional.id"
            :to="buildPublicProfilePath(professional.slug)"
            class="listing-card"
          >
            <DesignSystemAvatar
              :name="professional.name"
              :src="professional.photoUrl ?? undefined"
              size="lg"
              shape="rounded"
              loading="lazy"
            />
            <div class="listing-card__body">
              <strong>{{ professional.name }}</strong>
              <span v-if="professional.headline">{{
                professional.headline
              }}</span>
              <span class="listing-card__coverage">
                <UIcon name="i-lucide-map-pin" aria-hidden="true" />
                {{
                  professional.coverage.wholeCity
                    ? `Toda ${professional.coverage.city?.name ?? cityName}`
                    : professional.coverage.neighborhoods
                        .slice(0, 2)
                        .map((neighborhood) => neighborhood.name)
                        .join(" e ") || cityName
                }}
              </span>
            </div>
            <UIcon name="i-lucide-arrow-up-right" aria-hidden="true" />
          </NuxtLink>
        </div>

        <DesignSystemSurfaceCard v-else class="listing__empty">
          <h2>
            Ainda não temos
            {{ serviceName.toLocaleLowerCase("pt-BR") }} publicado em
            {{ cityName }}.
          </h2>
          <p>Seja o primeiro a aparecer para quem procura esse serviço.</p>
          <UButton
            :to="`/para-profissionais/${serviceSlug}`"
            color="primary"
            trailing-icon="i-lucide-arrow-right"
          >
            Criar perfil grátis
          </UButton>
        </DesignSystemSurfaceCard>

        <div v-if="listing.relatedServices.length" class="listing__related">
          <span>Serviços relacionados:</span>
          <NuxtLink
            v-for="related in listing.relatedServices"
            :key="related.id"
            :to="`/encontrar/${stateSlug}/${citySlug}/${related.slug}`"
          >
            {{ related.name }}
          </NuxtLink>
        </div>
      </DesignSystemContainer>
    </DesignSystemPageSection>
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

  &__grid {
    display: grid;
    gap: 12px;
  }

  &__empty {
    padding: 40px;
    text-align: center;
  }

  &__empty h2 {
    margin: 0 0 8px;
    font-family: var(--font-display);
    font-size: 1.3rem;
  }

  &__empty p {
    margin: 0 0 20px;
    color: var(--ink-soft);
  }

  &__related {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 8px;
    margin-top: 24px;
    font-size: 0.86rem;

    span {
      color: var(--ink-soft);
      font-weight: 700;
    }

    a {
      padding: 6px 12px;
      border: 1px solid var(--line);
      border-radius: 9px;
      color: var(--ink);
      font-weight: 700;
      text-decoration: none;
    }
  }
}

.listing-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px;
  border: 1px solid var(--line);
  border-radius: 16px;
  color: inherit;
  text-decoration: none;
  transition: border-color 0.15s ease;

  &:hover {
    border-color: var(--color-brand);
  }

  &__body {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 3px;
    min-width: 0;
  }

  &__body strong {
    font-family: var(--font-display);
    font-size: 1.05rem;
  }

  &__body > span {
    color: var(--ink-soft);
    font-size: 0.86rem;
  }

  &__coverage {
    display: flex;
    align-items: center;
    gap: 4px;
  }

  > svg:last-child {
    flex-shrink: 0;
    color: var(--ink-soft);
  }
}
</style>
