// nuxt-og-image disables its own auto-imports when SSR is off -- which is
// how @nuxt/test-utils' vitest "nuxt" environment always boots, regardless
// of the project's real SSR config. `typeof` is the one JS construct that
// never throws for an undeclared identifier, so this stays safe in both
// environments without needing to mock the module in every page test.
export function defineOgImageSafely(
  component: string,
  props?: Record<string, unknown>,
) {
  if (typeof defineOgImage === "function") {
    (defineOgImage as (name: string, props?: Record<string, unknown>) => void)(
      component,
      props,
    );
  }
}
