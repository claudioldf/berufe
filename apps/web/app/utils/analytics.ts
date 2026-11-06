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

const GOOGLE_TAG_MANAGER_CONTAINER_ID = /^GTM-[A-Z0-9]+$/;

// Consent Mode declares its defaults twice: a permissive baseline, then a
// restrictive override scoped to the jurisdictions that require prior consent.
// Google applies the region-scoped command to matching traffic and the
// unscoped one to everyone else, independently of the order they arrive in.
// Berufe runs no advertising campaigns today (no Google Ads tag in
// GTM-PBP8MFLG, Google Signals off on the GA4 property), so the granted
// baseline writes no advertising cookie in practice; it exists so Tag
// Manager's consent diagnostics reflect the real posture for Brazilian
// traffic instead of reporting a blanket denial. Granting here is a
// permission, not a behavior: adding an Ads tag or enabling Signals is what
// would start writing those cookies, and `privacidade.vue` section 7 has to
// be updated in the same change if that ever happens.
const CONSENT_RESTRICTED_REGIONS = [
  // EU-27
  "AT",
  "BE",
  "BG",
  "CY",
  "CZ",
  "DE",
  "DK",
  "EE",
  "ES",
  "FI",
  "FR",
  "GR",
  "HR",
  "HU",
  "IE",
  "IT",
  "LT",
  "LU",
  "LV",
  "MT",
  "NL",
  "PL",
  "PT",
  "RO",
  "SE",
  "SI",
  "SK",
  // Remaining EEA members
  "IS",
  "LI",
  "NO",
  // Equivalent prior-consent regimes outside the EEA
  "CH",
  "GB",
] as const;

const BASELINE_CONSENT_DEFAULT = {
  ad_storage: "granted",
  ad_user_data: "granted",
  ad_personalization: "granted",
  analytics_storage: "granted",
} as const;

// No cookie banner exists, so a visitor from a prior-consent jurisdiction has
// no way to grant anything: every signal stays denied for the whole visit,
// analytics included.
const RESTRICTED_CONSENT_DEFAULT = {
  ad_storage: "denied",
  ad_user_data: "denied",
  ad_personalization: "denied",
  analytics_storage: "denied",
  region: CONSENT_RESTRICTED_REGIONS,
} as const;

interface AnalyticsPageViewTrackerOptions {
  dispatch: (...args: unknown[]) => void;
  getFullPath: () => string;
  getOrigin: () => string;
  getPageTitle: () => string;
}

export function isGoogleTagManagerContainerId(
  containerId: unknown,
): containerId is string {
  return (
    typeof containerId === "string" &&
    GOOGLE_TAG_MANAGER_CONTAINER_ID.test(containerId)
  );
}

export function googleTagManagerHead(containerId: string) {
  if (!isGoogleTagManagerContainerId(containerId)) {
    throw new TypeError("Invalid Google Tag Manager container ID");
  }

  return {
    script: [
      {
        key: "google-consent-mode",
        innerHTML: `window.dataLayer=window.dataLayer||[];window.gtag=window.gtag||function(){window.dataLayer.push(arguments);};window.gtag("consent","default",${JSON.stringify(BASELINE_CONSENT_DEFAULT)});window.gtag("consent","default",${JSON.stringify(RESTRICTED_CONSENT_DEFAULT)});`,
      },
      {
        key: "google-tag-manager",
        innerHTML: `(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src='https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);})(window,document,'script','dataLayer','${containerId}');`,
      },
    ],
    noscript: [
      {
        key: "google-tag-manager-noscript",
        innerHTML: `<iframe src="https://www.googletagmanager.com/ns.html?id=${containerId}" height="0" width="0" style="display:none;visibility:hidden"></iframe>`,
        tagPosition: "bodyOpen" as const,
      },
    ],
  };
}

export function analyticsPagePath(fullPath: string): string {
  const path = fullPath.split(/[?#]/)[0] || "/";
  const match = TOKEN_ROUTE_PATTERNS.find(([pattern]) => pattern.test(path));
  return match ? path.replace(match[0], match[1]) : path;
}

export function analyticsPageLocation(
  fullPath: string,
  origin: string,
): string {
  return new URL(analyticsPagePath(fullPath), origin).href;
}

export function createAnalyticsPageViewTracker({
  dispatch,
  getFullPath,
  getOrigin,
  getPageTitle,
}: AnalyticsPageViewTrackerOptions): () => void {
  let previousPagePath: string | undefined;

  return () => {
    const fullPath = getFullPath();
    const pagePath = analyticsPagePath(fullPath);
    if (pagePath === previousPagePath) return;

    previousPagePath = pagePath;
    dispatch("event", "page_view", {
      page_location: analyticsPageLocation(fullPath, getOrigin()),
      page_path: pagePath,
      page_title: getPageTitle(),
    });
  };
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
