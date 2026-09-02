import { queryCollection } from "@nuxt/content/server";
import { buildLocalSitemapUrls } from "~~/app/utils/seoContent";

interface ServiceCoverageResponse {
  data: {
    entries: Array<{
      service: { slug: string };
      location: { state_slug: string; city_slug: string };
      indexable: boolean;
    }>;
  };
}

export default defineSitemapEventHandler(async (event) => {
  const config = useRuntimeConfig();
  const [response, publishedPages] = await Promise.all([
    $fetch<ServiceCoverageResponse>("/api/v1/public/service-coverage", {
      baseURL: config.apiInternalBaseUrl,
    }),
    queryCollection(event, "localPages")
      .where("published", "=", true)
      .select(
        "stateSlug",
        "citySlug",
        "serviceSlug",
        "publishedAt",
        "updatedAt",
      )
      .all(),
  ]);
  return buildLocalSitemapUrls(
    response.data.entries.map((entry) => ({
      stateSlug: entry.location.state_slug,
      citySlug: entry.location.city_slug,
      serviceSlug: entry.service.slug,
      indexable: entry.indexable,
    })),
    publishedPages,
  );
});
