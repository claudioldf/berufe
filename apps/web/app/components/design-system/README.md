# Berufe design system

These components contain presentation rules that are shared by more than one page or feature. Nuxt auto-imports them with the `DesignSystem` prefix.

| Component     | Responsibility                                                          |
| ------------- | ----------------------------------------------------------------------- |
| `Avatar`      | Render a person's image or initials, with optional verification state.  |
| `Brand`       | Render the Berufe home link and wordmark.                               |
| `Container`   | Constrain page width and responsive horizontal gutters.                 |
| `Eyebrow`     | Render the accent-line eyebrow typography role.                         |
| `FormField`   | Connect a label, direct form control, hint, error, and accessibility IDs. |
| `Heading`     | Separate semantic heading level from display, section, or workspace style. |
| `PageSection` | Apply shared responsive vertical page spacing.                          |
| `SectionCopy` | Render supporting section copy.                                         |
| `StatusDot`   | Render a semantic status color without status-specific copy.            |
| `SurfaceCard` | Apply the shared card surface while callers compose the content.        |
| `Toast`       | Render and dismiss the application toast notification.                  |

## Boundaries

- Keep the Tailwind v4 and Nuxt UI imports plus `@theme` configuration in `assets/css/tailwind.css`; this file is a framework entry point and intentionally remains plain CSS.
- Keep authored global styles in `assets/scss/main.scss`, using the existing Tailwind layers: semantic tokens and Nuxt UI overrides in `theme`, document defaults and reduced-motion behavior in `base`, and true accessibility helpers in `utilities`.
- Keep every SFC style block scoped. When a feature shell deliberately owns styles for extracted child markup, place those selectors inside `:deep()` so they remain bounded by the shell's scope attribute instead of becoming global.
- Nest BEM elements and modifiers beneath their owning block with `&__element` and `&--modifier`; avoid deeper structural nesting that couples styles to markup.
- Do not wrap SFC styles in cascade layers or replace Vue's scoped styles with `@scope`; reserve native scoping for a future content-boundary use case that cannot be expressed cleanly with component ownership.
- Use props for small, orthogonal visual contracts and slots for caller-owned content.
- Do not add feature data, route behavior, or unrelated modes to a design-system component.
- Keep search, moderation, dashboard, and quote widgets in their feature folders until the same complete pattern is reused across features.
- Keep administrative reporting widgets together under `components/admin/reports`; compose the shared primitives without adding a charting library.
- Continue using Nuxt UI's `UButton` for buttons and button-like links; a local wrapper would only duplicate its existing typed variants.

## Form contract

Use the `FormField` scoped-slot values on direct controls whenever a field has a hint, an error, or an explicit ID:

```vue
<DesignSystemFormField id="customer-name" v-slot="field" label="Nome" required>
  <input
    :id="field.controlId"
    :aria-describedby="field.describedBy"
    :aria-invalid="field.invalid"
    name="customer-name"
    required
  />
</DesignSystemFormField>
```

Feature components own validation and draft state; `FormField` only owns presentation and accessible relationships.
