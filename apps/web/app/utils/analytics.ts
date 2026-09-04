// Routes whose dynamic segment is bearer material (grants access to a quote,
// a recommendation form, or an account-deletion status) rather than an
// opaque resource id. `docs/LGPD_OPERATIONS.md` forbids letting these tokens
// reach analytics or monitoring metadata, so the segment is replaced with a
// literal placeholder before a page view is ever sent.
const TOKEN_ROUTE_PATTERNS: ReadonlyArray<readonly [RegExp, string]> = [
  [/^\/orcamento\/[^/]+\/?$/, "/orcamento/[token]"],
  [/^\/recomendacao\/[^/]+\/?$/, "/recomendacao/[token]"],
  [/^\/exclusao-de-conta\/[^/]+\/?$/, "/exclusao-de-conta/[token]"],
];

export function analyticsPagePath(fullPath: string): string {
  const path = fullPath.split(/[?#]/)[0] || "/";
  const match = TOKEN_ROUTE_PATTERNS.find(([pattern]) => pattern.test(path));
  return match ? path.replace(match[0], match[1]) : path;
}

// Search terms sent to analytics are built only from controlled catalog
// values (matched service names, resolved city) — never the visitor's raw
// free-text query, which is separately retained for up to six months under
// restricted access per the privacy policy and must not also reach a
// third party.
export function analyticsSearchTerm(
  serviceNames: readonly string[],
  city: string | null | undefined,
): string {
  return [serviceNames[0], city].filter(Boolean).join(" - ");
}
