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
        innerHTML: `window.dataLayer=window.dataLayer||[];window.gtag=window.gtag||function(){window.dataLayer.push(arguments);};window.gtag("consent","default",{ad_storage:"denied",ad_user_data:"denied",ad_personalization:"denied",analytics_storage:"granted"});`,
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
