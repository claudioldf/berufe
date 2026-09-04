import { analyticsPagePath } from "@app/utils/analytics";

declare global {
  interface Window {
    dataLayer: unknown[];
    // Exposed globally (matching Google's own gtag.js snippet convention) so
    // `useAnalyticsEvent` can dispatch custom events from anywhere in the
    // app without importing this plugin. Left undefined when GA is disabled
    // (dev, or no measurement ID), which is exactly the no-op that call
    // sites already guard for.
    gtag?: (...args: unknown[]) => void;
  }
}

// Google Analytics 4. Client-only: it must never run during SSR, and the
// `import.meta.dev` guard keeps local development out of the property, the
// same way `bugsnag.client.ts` stays off in dev.
export default defineNuxtPlugin((nuxtApp) => {
  const measurementId = useRuntimeConfig().public.gaMeasurementId;
  if (!measurementId || import.meta.dev) return;

  window.dataLayer = window.dataLayer || [];
  function gtag(...args: unknown[]) {
    window.dataLayer.push(args);
  }
  window.gtag = gtag;
  // Required: without an explicit default, gtag.js treats consent as
  // "not configured" and withholds every hit rather than assuming
  // granted — confirmed via Tag Assistant showing zero hits sent despite
  // the config call firing correctly. This site loads GA4 unconditionally
  // (no cookie banner, see privacidade.vue §7), so analytics_storage is
  // granted by default; the ad_* signals stay denied since Google Signals
  // and ad personalization are off and never used.
  gtag("consent", "default", {
    ad_storage: "denied",
    ad_user_data: "denied",
    ad_personalization: "denied",
    analytics_storage: "granted",
  });
  gtag("js", new Date());
  // Enhanced measurement's automatic, history-based page views fire before
  // Nuxt updates the title and would send the raw, unredacted URL — page
  // views are sent explicitly below instead, once the router has settled.
  gtag("config", measurementId, { send_page_view: false });

  useHead({
    script: [
      {
        src: `https://www.googletagmanager.com/gtag/js?id=${measurementId}`,
        async: true,
      },
    ],
  });

  const trackPageView = () => {
    gtag("event", "page_view", {
      page_path: analyticsPagePath(nuxtApp.$router.currentRoute.value.fullPath),
      page_title: document.title,
    });
  };

  nuxtApp.$router.isReady().then(trackPageView);
  nuxtApp.$router.afterEach(trackPageView);
});
