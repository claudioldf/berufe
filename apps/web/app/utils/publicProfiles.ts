const recentSnapshotWindowMilliseconds = 90 * 24 * 60 * 60 * 1000;

export function isRecentPublicSnapshot(
  reviewedAt: string | null,
  now = Date.now(),
) {
  if (!reviewedAt) return false;

  const reviewedAtMilliseconds = Date.parse(reviewedAt);
  return (
    Number.isFinite(reviewedAtMilliseconds) &&
    reviewedAtMilliseconds <= now &&
    now - reviewedAtMilliseconds <= recentSnapshotWindowMilliseconds
  );
}

interface PublicProfileResultUrlOptions {
  slug: string;
  serviceSlug: string;
  neighborhoodCode: string;
  interactionToken?: string;
}

export function buildPublicProfileResultUrl(
  options: PublicProfileResultUrlOptions,
) {
  const query = new URLSearchParams({
    servico: options.serviceSlug,
    bairro: options.neighborhoodCode,
  });
  if (options.interactionToken) {
    query.set("contexto", options.interactionToken);
  }

  return `/profissionais/${options.slug}?${query.toString()}`;
}

interface SearchResultWhatsAppUrlOptions {
  apiBaseUrl: string;
  professionalId: string;
  interactionToken?: string;
}

export function buildSearchResultWhatsAppUrl(
  options: SearchResultWhatsAppUrlOptions,
) {
  const url = new URL(
    `/api/v1/public/professionals/${options.professionalId}/whatsapp`,
    `${options.apiBaseUrl.replace(/\/$/, "")}/`,
  );
  url.searchParams.set("source", "search_result");
  if (options.interactionToken) {
    url.searchParams.set("interactionToken", options.interactionToken);
  }

  return url.toString();
}

interface PublicProfileWhatsAppUrlOptions {
  apiBaseUrl: string;
  professionalId: string;
  interactionToken: string;
}

export function buildPublicProfileWhatsAppUrl(
  options: PublicProfileWhatsAppUrlOptions,
) {
  const url = new URL(
    `/api/v1/public/professionals/${options.professionalId}/whatsapp`,
    `${options.apiBaseUrl.replace(/\/$/, "")}/`,
  );
  url.searchParams.set("source", "public_profile");
  url.searchParams.set("interactionToken", options.interactionToken);

  return url.toString();
}
