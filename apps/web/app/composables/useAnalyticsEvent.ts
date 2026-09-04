// Thin wrapper over the global `gtag` that `app/plugins/analytics.client.ts`
// exposes. `window.gtag` is only ever set when GA is actually enabled
// (`NUXT_PUBLIC_GA_MEASUREMENT_ID` set, not `import.meta.dev`), so calling
// `trackEvent` anywhere else — local dev, tests, SSR — is a silent no-op
// rather than something every call site has to guard for itself.
export function useAnalyticsEvent() {
  function trackEvent(
    name: string,
    params?: Record<string, string | number | boolean>,
  ) {
    if (!import.meta.client) return;
    window.gtag?.("event", name, params);
  }

  return { trackEvent };
}
