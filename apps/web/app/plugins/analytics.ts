import { nextTick } from "vue";

import {
  createAnalyticsPageViewTracker,
  googleTagManagerHead,
  isGoogleTagManagerContainerId,
} from "@app/utils/analytics";

declare global {
  interface Window {
    dataLayer: unknown[];
    // Defined by the SSR-rendered GTM bootstrap. Keeping the standard gtag
    // command interface lets feature call sites queue events before Google's
    // asynchronously loaded container has finished initializing.
    gtag?: (...args: unknown[]) => void;
  }
}

// Google Tag Manager is rendered during SSR so its loader is present in the
// first document response. Local development remains isolated from the
// production container, matching the Bugsnag integration's dev guard.
export default defineNuxtPlugin((nuxtApp) => {
  const containerId = useRuntimeConfig().public.gtmContainerId;
  if (!isGoogleTagManagerContainerId(containerId) || import.meta.dev) return;

  useHead(googleTagManagerHead(containerId));

  if (!import.meta.client) return;

  const trackPageView = createAnalyticsPageViewTracker({
    dispatch: (...args) => window.gtag?.(...args),
    getFullPath: () => nuxtApp.$router.currentRoute.value.fullPath,
    getOrigin: () => window.location.origin,
    getPageTitle: () => document.title,
  });

  // `page:finish` covers both initial hydration and completed client-side
  // navigations. Unhead commits the destination title after Nuxt's page tick,
  // so wait for both Vue's queue and the following browser frame before
  // capturing it. The tracker itself de-duplicates the same sanitized path if
  // Nuxt emits the hook more than once.
  nuxtApp.hook("page:finish", async () => {
    await nextTick();
    window.requestAnimationFrame(trackPageView);
  });
});
