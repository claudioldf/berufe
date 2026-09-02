<script setup lang="ts">
import { computed, onMounted } from "vue";
import ProviderServiceEditorial from "~/components/public/provider/ProviderServiceEditorial.vue";
import { fetchPublicServiceDemand } from "~/services/api/public-discovery";
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

const { data: providerContent } = await useAsyncData(
  () => `provider-content-${serviceSlug.value}`,
  () =>
    queryCollection("providerPages")
      .where("serviceSlug", "=", serviceSlug.value)
      .first(),
);
const publishedContent = computed(() =>
  providerContent.value?.published ? providerContent.value : null,
);

const detectedLocation = useDetectedSearchLocation();
const { location, resolve: resolveLocation } = detectedLocation;
onMounted(() => {
  void resolveLocation();
});

const { data: demand } = await useAsyncData(
  () => `service-demand-${serviceSlug.value}-${location.value.cityCode}`,
  () =>
    fetchPublicServiceDemand(client, {
      serviceSlug: serviceSlug.value,
      stateSlug: location.value.stateSlug,
      citySlug: location.value.citySlug,
    }),
  { watch: [location] },
);

const serviceName = computed(() => service.value?.name ?? "");
const title = computed(
  () =>
    publishedContent.value?.title ??
    `Como conseguir clientes de ${serviceName.value.toLocaleLowerCase("pt-BR")}`,
);
const description = computed(
  () =>
    publishedContent.value?.description ??
    `Divulgação gratuita para ${serviceName.value.toLocaleLowerCase("pt-BR")}: portfólio, identidade confirmada e contato direto pelo WhatsApp, sem pagar por lead.`,
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
  robots: () => (publishedContent.value ? "index, follow" : "noindex, follow"),
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
      { name: "Para profissionais", item: "/para-profissionais" },
      { name: service.value.name, item: canonicalUrl.value },
    ],
  }),
]);
</script>

<template>
  <ProviderServiceEditorial
    v-if="service"
    :service="service"
    :content="publishedContent"
    :demand="demand ?? null"
    :location="location"
  />
</template>
