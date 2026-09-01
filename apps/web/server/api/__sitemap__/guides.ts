import { queryCollection } from "@nuxt/content/server";

export default defineSitemapEventHandler(async (event) => {
  const guides = await queryCollection(event, "guias").all();

  return guides.map((guide) => ({
    loc: guide.path,
    lastmod: guide.updatedAt ?? guide.publishedAt,
  }));
});
