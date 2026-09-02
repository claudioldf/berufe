import { queryCollection } from "@nuxt/content/server";
import { buildProviderSitemapUrls } from "~~/app/utils/seoContent";

interface CatalogResponse {
  data: {
    services: Array<{ slug: string }>;
  };
}

// Provider-acquisition pages do not depend on local supply, but they only
// enter the sitemap after their own editorial content is reviewed and
// published.
export default defineSitemapEventHandler(async (event) => {
  const config = useRuntimeConfig();
  const [pages, catalog] = await Promise.all([
    queryCollection(event, "providerPages")
      .where("published", "=", true)
      .select("serviceSlug", "publishedAt", "updatedAt")
      .all(),
    $fetch<CatalogResponse>("/api/v1/catalog", {
      baseURL: config.apiInternalBaseUrl,
    }),
  ]);

  return buildProviderSitemapUrls(
    pages,
    catalog.data.services.map((service) => service.slug),
  );
});
