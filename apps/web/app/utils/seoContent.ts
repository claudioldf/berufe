import { buildPublicProfilePath } from "~/utils/publicProfiles";

interface PublishableSeoContent {
  published: boolean;
}

export interface LocalSeoCoordinates {
  stateSlug: string;
  citySlug: string;
  serviceSlug: string;
}

export interface LocalSitemapCoverageEntry extends LocalSeoCoordinates {
  indexable: boolean;
}

export interface PublishedLocalSeoPage extends LocalSeoCoordinates {
  publishedAt: string;
  updatedAt?: string;
}

export interface SitemapUrl {
  loc: string;
  lastmod?: string;
}

export interface LocalServiceSchemaInput {
  canonicalUrl: string;
  siteRoot: string;
  serviceName: string;
  cityName: string;
  stateCode: string;
  description: string;
  professionals: Array<{ name: string; slug: string }>;
}

export function hasPublishedSeoContent(
  content: PublishableSeoContent | null | undefined,
): boolean {
  return content?.published === true;
}

export function isLocalPageIndexable(
  supplyEligible: boolean,
  content: PublishableSeoContent | null | undefined,
): boolean {
  return supplyEligible && hasPublishedSeoContent(content);
}

export function localSeoRoute(input: LocalSeoCoordinates): string {
  return `/encontrar/${input.stateSlug}/${input.citySlug}/${input.serviceSlug}`;
}

export function buildLocalSitemapUrls(
  coverage: LocalSitemapCoverageEntry[],
  pages: PublishedLocalSeoPage[],
): SitemapUrl[] {
  const contentByPath = new Map(
    pages.map((page) => [localSeoRoute(page), page]),
  );
  const indexable = coverage.filter(
    (entry) => entry.indexable && contentByPath.has(localSeoRoute(entry)),
  );
  const listingUrls = indexable.map((entry) => {
    const loc = localSeoRoute(entry);
    const content = contentByPath.get(loc);
    return {
      loc,
      lastmod: content?.updatedAt ?? content?.publishedAt,
    };
  });
  const cityHubs = new Set(
    indexable.map((entry) => `/encontrar/${entry.stateSlug}/${entry.citySlug}`),
  );
  const serviceHubs = new Set(
    indexable.map((entry) => `/servicos/${entry.serviceSlug}`),
  );

  return [
    ...listingUrls,
    ...[...cityHubs].map((loc) => ({ loc })),
    ...[...serviceHubs].map((loc) => ({ loc })),
  ];
}

export function buildProviderSitemapUrls(
  pages: Array<{
    serviceSlug: string;
    publishedAt: string;
    updatedAt?: string;
  }>,
  catalogServiceSlugs: string[],
): SitemapUrl[] {
  const knownServices = new Set(catalogServiceSlugs);

  return [
    { loc: "/para-profissionais" },
    ...pages
      .filter((page) => knownServices.has(page.serviceSlug))
      .map((page) => ({
        loc: `/para-profissionais/${page.serviceSlug}`,
        lastmod: page.updatedAt ?? page.publishedAt,
      })),
  ];
}

export function buildLocalServiceSchema(input: LocalServiceSchemaInput) {
  const provider = input.professionals.map((professional) => {
    const url = `${input.siteRoot}${buildPublicProfilePath(professional.slug)}`;
    return {
      "@type": "Person" as const,
      "@id": `${url}#person`,
      name: professional.name,
      url,
    };
  });

  return {
    "@type": "Service" as const,
    "@id": `${input.canonicalUrl}#service`,
    name: `${input.serviceName} em ${input.cityName}`,
    serviceType: input.serviceName,
    description: input.description,
    url: input.canonicalUrl,
    mainEntityOfPage: input.canonicalUrl,
    areaServed: {
      "@type": "City" as const,
      name: input.cityName,
      containedInPlace: {
        "@type": "State" as const,
        name: input.stateCode,
        containedInPlace: { "@type": "Country" as const, name: "Brasil" },
      },
    },
    broker: { "@id": `${input.siteRoot}/#identity` },
    provider: provider.length ? provider : undefined,
  };
}
