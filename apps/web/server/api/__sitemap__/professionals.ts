interface SitemapProfessionalsResponse {
  data: {
    professionals: Array<{ slug: string; updated_at: string | null }>;
  };
}

export default defineSitemapEventHandler(async () => {
  const config = useRuntimeConfig();
  const response = await $fetch<SitemapProfessionalsResponse>(
    "/api/v1/public/sitemap-professionals",
    { baseURL: config.apiInternalBaseUrl },
  );

  return response.data.professionals.map((professional) => ({
    loc: `/profissionais/${professional.slug}`,
    lastmod: professional.updated_at ?? undefined,
  }));
});
