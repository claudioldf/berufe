// Global entity signals, registered here (rather than in a page or
// app.vue) so they resolve reliably after nuxt-schema-org's own "defaults"
// plugin sets up the base WebSite/WebPage nodes — a page-level
// defineOrganization/defineWebSite call loses that race.
//
// Organization is what lets AI Overviews and answer engines cite Berufe
// with confidence: consistent entity data matters more than any single
// page's markup. The WebSite SearchAction is what makes a Sitelinks
// Searchbox possible on the SERP entry.
export default defineNuxtPlugin(() => {
  const siteConfig = useSiteConfig();

  useSchemaOrg([
    defineOrganization({
      name: "Berufe",
      url: siteConfig.url,
      logo: `${siteConfig.url}/icon-512.png`,
      description:
        "Rede de profissionais verificados para reforma e manutenção residencial no Brasil.",
      areaServed: {
        "@type": "Country",
        name: "Brasil",
      },
    }),
    defineWebSite({
      name: siteConfig.name,
      potentialAction: [
        {
          "@type": "SearchAction",
          target: {
            "@type": "EntryPoint",
            urlTemplate: `${siteConfig.url}/encontrar?q={search_term_string}`,
          },
          "query-input": "required name=search_term_string",
        },
      ],
    }),
  ]);
});
