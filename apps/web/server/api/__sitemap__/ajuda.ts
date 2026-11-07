import { queryCollection } from "@nuxt/content/server";

export default defineSitemapEventHandler(async (event) => {
  const articles = await queryCollection(event, "ajuda").all();

  return articles.map((article) => ({
    loc: article.path,
    lastmod: article.updatedAt ?? article.publishedAt,
  }));
});
