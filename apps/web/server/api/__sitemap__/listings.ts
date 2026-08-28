interface ServiceCoverageResponse {
  data: {
    entries: Array<{
      service: { slug: string };
      location: { state_slug: string; city_slug: string };
      indexable: boolean;
    }>;
  };
}

export default defineSitemapEventHandler(async () => {
  const config = useRuntimeConfig();
  const response = await $fetch<ServiceCoverageResponse>(
    "/api/v1/public/service-coverage",
    { baseURL: config.apiInternalBaseUrl },
  );
  const indexable = response.data.entries.filter((entry) => entry.indexable);

  const listingUrls = indexable.map((entry) => ({
    loc: `/encontrar/${entry.location.state_slug}/${entry.location.city_slug}/${entry.service.slug}`,
  }));

  const cityHubs = new Set(
    indexable.map(
      (entry) =>
        `/encontrar/${entry.location.state_slug}/${entry.location.city_slug}`,
    ),
  );
  const serviceHubs = new Set(
    indexable.map((entry) => `/servicos/${entry.service.slug}`),
  );

  return [
    ...listingUrls,
    ...[...cityHubs].map((loc) => ({ loc })),
    ...[...serviceHubs].map((loc) => ({ loc })),
  ];
});
