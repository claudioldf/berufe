# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

| Path              | What it is                                                                                                                  |
| ----------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `apps/web/`       | **The active codebase.** Nuxt 4 + Vue 3 + Nuxt UI 4 static interactive prototype of the Berufe product. All work happens here. |
| `docs/`           | Product source of truth: MVP stories, feature plan, infrastructure/architecture decisions, V2 backlog, reports stories.       |
| `leads/`          | Independent, dependency-free Node ≥22 scraper/HTTP service (`achei-o-profissional`). Unrelated to `apps/web`.                 |
| `full_mockups/`   | Frozen snapshot of an earlier prototype iteration, kept for reference. Do not edit; it is not built or tested.                |
| `mockups/`, `qa-screenshots/` | Leftover artifacts (a stray CSS file, before/after QA screenshots). Not part of any build.                        |

There is no root `package.json`. Run every frontend command from `apps/web/`; `leads/` has its own `package.json` and uses `node --test`.

## Commands (`apps/web/`)

```bash
npm run dev            # Nuxt dev server
npm run generate       # static build into .output/public
npm run check          # full gate: format:check + lint + stylelint + typecheck + test
```

Focused: `npm run lint` / `lint:fix`, `npm run stylelint` / `stylelint:fix`, `npm run typecheck` (vue-tsc, strict), `npm run format`, `npm run test`, `npm run test:e2e`.

Single unit test / single case:

```bash
npx vitest run tests/unit/quotes.test.ts
npx vitest run tests/unit/workflow-composables.test.ts -t "moderation queue"
```

Single e2e test: `npx playwright test tests/e2e/public-flow.spec.ts -g "visitor can discover"`. Playwright runs `npm run build` and serves the Nitro output on `127.0.0.1:4173` itself (projects: `chromium`, `mobile-chromium`), so e2e runs are slow and always exercise the production build.

Vitest runs in the Nuxt environment (`@nuxt/test-utils`, happy-dom); coverage is scoped to `app/composables/**` and `app/utils/**`, which is where testable logic is expected to live.

`leads/`: `npm start` (HTTP service), `npm run scrape -- <city-slug> [cli|json|csv]`, `npm test`.

## Architecture of `apps/web`

**There is no backend.** Backend-shaped fixtures live in `apps/web/data/*.json` and are imported directly by pages/components with relative paths (`import professionalsData from "../../data/professionals.json"`) and cast to the shared types. Every "mutation" is local component/composable state; nothing persists across reloads except the onboarding draft and the hero image index in `localStorage`.

The layering is deliberate and enforced by review, not by tooling:

- `app/types/` — shared domain contracts (`Professional`, `Service`, quotes, moderation, reports, onboarding, UI). `index.ts` is a barrel; always import from `~/types`.
- `app/utils/` — pure functions only (formatters, catalog/service matching and relevance scoring, quote math, WhatsApp URL building, social-profile parsing, `pt-BR` text normalization).
- `app/composables/` — stateful workflows. Cross-component state uses `useState` (`useAppRole` → `app-role`, `useToast` → `app-toast`); everything else is per-instance (`useProfessionalSearch`, `useQuoteDraft`, `useProfessionalProfileDraft`, `useProfessionalOnboarding`, `usePhoneAuthFlow`, `useModerationQueue`, `useShare`).
- `app/components/design-system/` — auto-imported with the `DesignSystem` prefix (`<DesignSystemSurfaceCard>`). Read `app/components/design-system/README.md` before touching these; it defines the component boundaries and the `FormField` scoped-slot accessibility contract.
- `app/components/<feature>/` — page features (`home`, `profile`, `public`, `auth`, `dashboard/*`, `admin/*`, `onboarding`, `quotes`, `legal`). Widgets stay in their feature folder until the same complete pattern is genuinely reused.

**URL-backed state:** search filters (`?servico=`, `?bairro=`) and report periods live in the route, so views stay linkable and back/forward behaves. Add new filter state to the query, not to component refs.

**Prerendering:** `nuxt.config.ts` lists every prerendered route in `nitro.prerender.routes`, and professional profile routes are generated from `data/professionals.json`. **Adding a page requires adding its route there**, otherwise it is missing from the static build.

**Icons:** `@iconify-json/lucide` is bundled through an explicit allowlist in `nuxt.config.ts` (`icon.clientBundle.icons`) alongside `scan: true`. Icons referenced indirectly — from `data/*.json` (`service.icon`) or from composable constants such as `professionalOnboardingSteps` — are not found by the scanner and must be added to that list or they render blank.

**Roles:** `useAppRole` drives the header's "Explorar como" switcher between `visitor` / `professional` / `admin` surfaces. It is a prototype affordance, not auth — there is no route guard.

## Styling

Tailwind v4 + Nuxt UI 4 + SCSS, with a strict split:

- `app/assets/css/tailwind.css` — framework entry point only: `@import "tailwindcss"`, `@import "@nuxt/ui"`, and the `@theme static` palette (`forest-*`, `coral-*`, font stack). Stays plain CSS.
- `app/assets/scss/main.scss` — authored globals inside Tailwind layers: semantic tokens and Nuxt UI variable overrides in `@layer theme`, document defaults and reduced-motion in `@layer base`, accessibility helpers in `@layer utilities`.
- `app/app.config.ts` — Nuxt UI color aliases (`primary: emerald`, `neutral: stone`, …) and component default variants.

Component styles are always `<style scoped lang="scss">`. When a page shell owns styles for markup that was extracted into children, wrap those selectors in `:deep()` rather than going global. Nest BEM as `&__element` / `&--modifier` under the owning block. Never wrap SFC styles in cascade layers. Prefer semantic custom properties (`var(--color-brand)`, `var(--radius-md)`, `var(--shadow-sm)`) over raw values.

Prettier is the sole formatter (ESLint formatting rules are off); stylelint uses `stylelint-config-standard-scss` + the Vue SCSS config. ESLint is Nuxt's flat config with `vue/html-self-closing: always` (including components), `vue/multi-word-component-names` off, and `vue/no-v-html` as an error.

## Conventions

- **Language:** code identifiers, file names, and data keys in English; every user-facing string in Brazilian Portuguese. `htmlAttrs.lang` is `pt-BR`, and text comparison uses `toLocaleLowerCase("pt-BR")` / accent-stripping via `~/utils/text`.
- Composition API with `<script setup lang="ts">` everywhere; TypeScript strict with `typeCheck: true` in the Nuxt config, so `vue-tsc` runs alongside `dev` and fails `build`.
- Prefer Nuxt UI components (`UButton`, form controls, `UApp`) and their built-in accessibility before writing custom controls. Mobile-first, semantic HTML, visible labels and errors, and no status conveyed by color alone.
- Add an abstraction only after a real second use; keep changes small and purpose-specific.
- Verification labels and catalog entries (services, Joinville neighborhoods) are controlled values from `data/catalogs.json`, never free-form.
- Everything in `data/*.json` and `public/images/` is synthetic. Do not present it as real people, work, credentials, or endorsements.

## Prototype-specific behavior worth knowing

- The sign-in flow accepts the fixed OTP `123456` (`usePhoneAuthFlow`); phone and name fields are pre-filled with demo values. E2E tests depend on this.
- `/orcamento/BERUFE-DEMO-1042` is prerendered only so the static prototype is reviewable. `docs/Berufe_MVP_Stories.md` requires the production implementation to serve tokenized quotes dynamically with `no-store` and `noindex`.
- Professional onboarding state persists in `localStorage` under `berufe:professional-onboarding:v1` with a `version: 1` field; bump/migrate deliberately if the shape changes.

## Product docs

Read `docs/` before changing product behavior — the code is downstream of these. `Berufe_MVP_Feature_Plan.md` (scope and value loop), `Berufe_MVP_Stories.md` (acceptance criteria for MVP surfaces), `Berufe_Reports_Stories.md` (admin reporting), `Berufe_MVP_Infrastructure_Architecture.md` (target Rails API + Nuxt split, Compose layout, auth, storage, development standards), `Berufe_V2_Stories.md` (explicitly deferred; identifiers are never reused).
