# Berufe design system

These components contain presentation rules that are shared by more than one page or feature. Nuxt auto-imports them with the `DesignSystem` prefix.

| Component | Responsibility |
| --- | --- |
| `Avatar` | Render a person's image or initials, with optional verification state. |
| `Brand` | Render the Berufe home link and wordmark. |
| `Container` | Constrain page width and responsive horizontal gutters. |
| `DisplayTitle` | Render the display typography role. |
| `Eyebrow` | Render the accent-line eyebrow typography role. |
| `FormField` | Compose a label, direct form control, hint, and error. |
| `Kicker` | Render the compact uppercase typography role used by widgets. |
| `PageSection` | Apply shared responsive vertical page spacing. |
| `SectionCopy` | Render supporting section copy. |
| `SectionTitle` | Render the section-title typography role. |
| `StatusDot` | Render a semantic status color without status-specific copy. |
| `SurfaceCard` | Apply the shared card surface while callers compose the content. |
| `Toast` | Render and dismiss the application toast notification. |

## Boundaries

- Keep tokens, resets, reduced-motion behavior, and true accessibility utilities in `assets/css/main.css`.
- Keep every component's visual rules in its scoped `<style>` block.
- Use props for small, orthogonal visual contracts and slots for caller-owned content.
- Do not add feature data, route behavior, or unrelated modes to a design-system component.
- Keep catalog, moderation, dashboard, quote, and report widgets in their feature folders until the same complete pattern is reused across features.
- Continue using Nuxt UI's `UButton` for buttons and button-like links; a local wrapper would only duplicate its existing typed variants.
