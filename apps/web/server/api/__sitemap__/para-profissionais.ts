interface CatalogResponse {
  data: {
    services: Array<{ slug: string }>;
  };
}

// Provider-acquisition pages are always indexable regardless of local
// supply -- each carries real, non-templated editorial content, unlike the
// consumer-facing listing pages gated in listings.ts.
export default defineSitemapEventHandler(async () => {
  const config = useRuntimeConfig();
  const response = await $fetch<CatalogResponse>("/api/v1/catalog", {
    baseURL: config.apiInternalBaseUrl,
  });

  return [
    { loc: "/para-profissionais" },
    ...response.data.services.map((service) => ({
      loc: `/para-profissionais/${service.slug}`,
    })),
  ];
});
