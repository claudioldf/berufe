<script setup lang="ts">
import { computed } from "vue";
import { useCatalogs } from "~/composables/useCatalogs";

definePageMeta({ layout: "workspace" });

const { data: catalog, error: catalogError } = await useCatalogs();
if (catalogError.value || !catalog.value) {
  throw createError({
    statusCode: 503,
    statusMessage: "Catálogo temporariamente indisponível.",
  });
}
const services = computed(() => catalog.value?.services ?? []);
const neighborhoods = computed(() =>
  (catalog.value?.neighborhoods ?? []).filter((item) => item.code !== "all"),
);

useSeoMeta({
  title: "Complete seu perfil profissional",
  robots: "noindex, nofollow",
});
</script>

<template>
  <OnboardingWizard :services="services" :neighborhoods="neighborhoods" />
</template>
