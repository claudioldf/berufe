import { searchExpressionQueryKey } from "~/utils/searchExpression";

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
  encodedExpression: string;
  interactionToken?: string;
  requestMessage?: string;
}

export function buildPublicProfilePath(slug: string) {
  return `/be/${slug}`;
}

export function buildPublicProfileResultUrl(
  options: PublicProfileResultUrlOptions,
) {
  const query = new URLSearchParams({
    [searchExpressionQueryKey]: options.encodedExpression,
  });
  if (options.interactionToken) {
    query.set("contexto", options.interactionToken);
  }
  if (options.requestMessage) {
    query.set("pedido", options.requestMessage);
  }

  return `${buildPublicProfilePath(options.slug)}?${query.toString()}`;
}

interface SearchResultWhatsAppUrlOptions {
  apiBaseUrl: string;
  professionalId: string;
  interactionToken?: string;
  requestMessage?: string;
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
    url.searchParams.set("interaction_token", options.interactionToken);
  }
  if (options.requestMessage) {
    url.searchParams.set("request_message", options.requestMessage);
  }

  return url.toString();
}

interface PublicProfileWhatsAppUrlOptions {
  apiBaseUrl: string;
  professionalId: string;
  interactionToken: string;
  requestMessage?: string;
}

export function buildPublicProfileWhatsAppUrl(
  options: PublicProfileWhatsAppUrlOptions,
) {
  const url = new URL(
    `/api/v1/public/professionals/${options.professionalId}/whatsapp`,
    `${options.apiBaseUrl.replace(/\/$/, "")}/`,
  );
  url.searchParams.set("source", "public_profile");
  url.searchParams.set("interaction_token", options.interactionToken);
  if (options.requestMessage) {
    url.searchParams.set("request_message", options.requestMessage);
  }

  return url.toString();
}
