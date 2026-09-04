# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

| Path                          | What it is                                                                                                                  |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `apps/api/`                   | **Rails 8.1 API** (Ruby 3.4, PostgreSQL, GoodJob, Pundit). Owns all data, auth, authorization, and metric semantics.        |
| `apps/web/`                   | **Nuxt 4 + Vue 3 + Nuxt UI 4** frontend for the public, professional, and administrator surfaces. Talks only to `apps/api`. |
| `apps/contracts/openapi.yaml` | **The API boundary.** Hand-edited; Rails validates against it in specs and Nuxt generates its types from it.                |
| `docs/`                       | Product source of truth: MVP stories, feature plan, infrastructure/architecture decisions, increment plans, V2 backlog.     |
| `leads/`                      | Independent, dependency-free Node ≥22 scraper/HTTP service (`achei-o-profissional`). Unrelated to the product apps.         |
| `full_mockups/`               | Frozen snapshot of an earlier prototype iteration, kept for reference. Do not edit; it is not built or tested.              |
| `mockups/`, `qa-screenshots/` | Leftover artifacts (a stray CSS file, before/after QA screenshots). Not part of any build.                                  |

There is no root `package.json`. `apps/web` uses **pnpm** (`packageManager: pnpm@10.34.5`, Node pinned to 24.18.0 by `.node-version`); `apps/api` uses Bundler (Ruby 3.4.10 by `.ruby-version`); `leads/` has its own `package.json` and uses `node --test`.

## Environment

A single root `.env` (gitignored, copied from `.env.example`) configures every service — Compose passes it to all four containers with `env_file`. `Berufe::Environment` (`apps/api/lib/berufe/environment.rb`) validates it at boot and **Rails refuses to start** when a required variable is missing or an adapter does not match the `BERUFE_ENV` matrix in `apps/api/README.md`. Adapter selection is explicit and never falls back at runtime.

Only `NUXT_PUBLIC_*` values reach the browser bundle. `apps/web/nuxt.config.ts` loads the root `.env` when it exists, so host-run `pnpm dev` / `build` / `test` work outside Compose; variables already in the environment win, so Compose and CI stay authoritative.

## Commands

**When Claude Code runs lint/format/style/typecheck checks while working on a change, scope them to the files actually changed** (e.g. `pnpm exec eslint <files>`, `pnpm exec stylelint <files>`, `pnpm exec prettier --check <files>`, `pnpm exec vue-tsc --noEmit <files>`, `bundle exec standardrb <files>`) instead of the whole-repo `pnpm lint` / `pnpm stylelint` / `pnpm typecheck` / `pnpm check` / `bundle exec standardrb` — and only for files under `apps/api/` or `apps/web/`, never `docs/`, `.railway/`, or other root paths. Run the full untargeted gate only when the user asks for it (e.g. before a PR).

Docker Compose is the supported way to run everything (`web` :3000, `api` :3001, `worker` probe :7001, `db` PostgreSQL 18.4):

```bash
docker compose up --build          # start the four-service stack
docker compose exec web pnpm check # frontend gate
docker compose exec api bin/check  # backend gate: standardrb + brakeman + rspec
docker compose down
```

Running on the host works too (`corepack enable` provides pnpm; `bundle install` in `apps/api`), but the API still needs PostgreSQL.

**`apps/web/`** — every script is a pnpm script and `check` calls `pnpm` internally, so `npm run check` fails:

```bash
pnpm dev                 # Nuxt dev server
pnpm build               # Nitro server build
pnpm check               # full gate: format:check + lint + stylelint + typecheck + test
pnpm api:generate        # regenerate app/services/api/schema.d.ts from ../contracts/openapi.yaml
```

Focused: `pnpm lint` / `lint:fix`, `pnpm stylelint` / `stylelint:fix`, `pnpm typecheck` (vue-tsc, strict), `pnpm format`, `pnpm test`, `pnpm test:coverage`, `pnpm test:e2e`. `pnpm format:repo:check` covers the root README, `docs/`, `compose.yaml`, and the workflows.

Single unit test / single case:

```bash
pnpm vitest run tests/unit/quotes.test.ts
pnpm vitest run tests/unit/workflow-composables.test.ts -t "moderation queue"
```

Single e2e test: `pnpm playwright test tests/e2e/public-flow.spec.ts -g "visitor can discover"`. Playwright builds and serves the Nitro output on `127.0.0.1:4173` itself (projects: `chromium`, `mobile-chromium`), so e2e runs are slow and always exercise the production build.

Vitest runs in the Nuxt environment (`@nuxt/test-utils`, happy-dom); coverage is scoped to `app/components/**`, `app/composables/**`, `app/middleware/**`, `app/utils/**`, and an explicit allowlist of `app/services/api/*.ts` — **a new API adapter must be added to that list in `vitest.config.ts`**.

**`apps/api/`**:

```bash
bundle exec rspec                  # specs + OpenAPI contract coverage
bundle exec standardrb             # style (no separate RuboCop config)
bundle exec brakeman --quiet --no-pager --exit-on-warn --exit-on-error
bin/rails db:migrate               # DATABASE_URL; specs use TEST_DATABASE_URL
bin/rails zeitwerk:check           # boot and eager-load check, as CI runs it
```

`leads/`: `npm start` (HTTP service), `npm run scrape -- <city-slug> [cli|json|csv]`, `npm test`.

CI (`.github/workflows/ci.yml`) runs three jobs: **backend** (standardrb, brakeman, migrations, `zeitwerk:check`, rspec, seeds), **frontend** (regenerate types and **fail on `schema.d.ts` drift**, format, lint, stylelint, typecheck, vitest, production build), and **integration** (build both images, boot the Compose stack, probe the API, Nuxt-to-Rails rendering, and worker connectivity).

## The API contract

`apps/contracts/openapi.yaml` is the boundary and is edited by hand. Both sides derive from it:

- Rails registers it through `openapi_first` in `spec/rails_helper.rb`; request specs tagged `openapi: true` validate real responses against it, so an undocumented or mismatched response fails the suite.
- Nuxt generates `app/services/api/schema.d.ts` with `pnpm api:generate`. It is committed, and CI fails if it drifts from the contract.

**Changing an endpoint means editing the contract first**, then Rails, then regenerating types.

## Architecture of `apps/api`

Standard Rails layering with thin controllers and named service objects:

- `app/controllers/api/v1/` — versioned endpoints under `public`, `professional`, and `admin` groupings. `BaseController` centralizes Pundit, error rendering (`render_api_error` with `code` / `message` / `field_errors`), the `Origin` check on state-changing requests, and the session/role `before_action`s. Every error message is Brazilian Portuguese.
- `app/services/` — one purpose per class, `#call`-shaped (`ModerationDecision`, `ProfessionalQuoteSharer`, `Admin::Reports::GrowthReport`). This is where behavior lives; models stay thin.
- `app/queries/` — read models for public projections and search.
- `app/policies/` — Pundit policies; authorization is enforced at the API boundary, never assumed from the frontend.
- `app/serializers/` — explicit response shaping; never expose an Active Record object directly.
- `app/jobs/` — GoodJob. Recurring jobs are registered as cron entries in `config/initializers/good_job.rb`.

Sessions are cookie-backed (`ApplicationSession`), with `Current.user_account`, `Current.application_session`, and `Current.request_id` set per request. Administrator surfaces additionally require `authentication_method == "password"` — an OTP-authenticated admin is refused.

Data-shaped configuration (reporting targets, retention windows) lives in `config.x.berufe.*`, set from validated environment values in `config/initializers/berufe_environment.rb`.

## Architecture of `apps/web`

All product data comes from the Rails API through the typed client. The layering is deliberate and enforced by review, not by tooling:

- `app/services/api/` — one module per API area, each exporting typed functions over the shared `openapi-fetch` client in `client.ts`. They map snake_case contract fields to the camelCase domain types and normalize errors through `errors.ts` (`ApiRequestError`, `normalizeApiError`). **Pages and components never call `fetch` or the Rails routes directly.**
- `app/types/` — shared domain contracts (`Professional`, `Service`, quotes, moderation, reports, onboarding, UI). `index.ts` is a barrel; always import from `~/types`. These are hand-written domain types, distinct from generated `schema.d.ts`.
- `app/utils/` — pure functions only (formatters, catalog/service matching and relevance scoring, quote math, WhatsApp URL building, social-profile parsing, `pt-BR` text normalization).
- `app/composables/` — stateful workflows, each accepting optional injected dependencies so tests can drive them without a network. Cross-component state uses `useState` (`useAppRole` → `app-role`, `useToast` → `app-toast`, session state in `useApplicationSession`); everything else is per-instance.
- `app/components/design-system/` — auto-imported with the `DesignSystem` prefix (`<DesignSystemSurfaceCard>`). Read `app/components/design-system/README.md` before touching these; it defines the component boundaries and the `FormField` scoped-slot accessibility contract.
- `app/components/<feature>/` — page features (`home`, `profile`, `public`, `auth`, `dashboard/*`, `admin/*`, `onboarding`, `quotes`, `legal`). Widgets stay in their feature folder until the same complete pattern is genuinely reused.

**Remaining fixtures:** `data/catalogs.json` and `data/professionals.json` are no longer read by the app — Rails seeds import them (`CatalogSeed`, `PublicDiscoveryDemoSeed`, mounted at `/catalog-data`), and two unit tests still import them as sample input. `data/dashboard.json`, `moderation.json`, and `quotes.json` are leftovers awaiting removal by their owning stories. Do not wire new UI to `data/*.json`; add an API adapter instead.

**URL-backed state:** search filters (`?servico=`, `?bairro=`) and report periods live in the route, so views stay linkable and back/forward behaves. Add new filter state to the query, not to component refs.

**Rendering:** `nuxt.config.ts` `routeRules` control this per route — public pages are server-rendered at request time (`prerender: false`), `/app/**` is client-only (`ssr: false`) with `private, no-store`, and `/orcamento/**` adds `no-referrer` and `x-robots-tag: noindex, nofollow`. Security headers apply to `/**`. **A new route with different privacy or caching needs its own rule.**

**Auth:** `app/middleware/authenticated.global.ts` guards `/app/**` — it restores the session, redirects to the matching login page, enforces the professional/admin role for the path, and requires password authentication for `/app/admin`. `useAppRole` is only the header's "Explorar como" switcher for public surfaces; it is not auth.

**Icons:** `@iconify-json/lucide` is bundled through an explicit allowlist in `nuxt.config.ts` (`icon.clientBundle.icons`) alongside `scan: true`. Icons referenced indirectly — from API responses (a report metric's `icon`, `service.icon`) or from composable constants such as `professionalOnboardingSteps` — are not found by the scanner and must be added to that list or they render blank.

## Styling

Tailwind v4 + Nuxt UI 4 + SCSS, with a strict split:

- `app/assets/css/tailwind.css` — framework entry point only: `@import "tailwindcss"`, `@import "@nuxt/ui"`, and the `@theme static` palette (`forest-*`, `coral-*`, font stack). Stays plain CSS.
- `app/assets/scss/main.scss` — authored globals inside Tailwind layers: semantic tokens and Nuxt UI variable overrides in `@layer theme`, document defaults and reduced-motion in `@layer base`, accessibility helpers in `@layer utilities`.
- `app/app.config.ts` — Nuxt UI color aliases (`primary: emerald`, `neutral: stone`, …) and component default variants.

Component styles are always `<style scoped lang="scss">`. When a page shell owns styles for markup that was extracted into children, wrap those selectors in `:deep()` rather than going global. Nest BEM as `&__element` / `&--modifier` under the owning block. Never wrap SFC styles in cascade layers. Prefer semantic custom properties (`var(--color-brand)`, `var(--radius-md)`, `var(--shadow-sm)`) over raw values.

Prettier is the sole formatter (ESLint formatting rules are off); stylelint uses `stylelint-config-standard-scss` + the Vue SCSS config. ESLint is Nuxt's flat config with `vue/html-self-closing: always` (including components), `vue/multi-word-component-names` off, and `vue/no-v-html` as an error.

## Conventions

- **Language:** code identifiers, file names, data keys, and API fields in English; every user-facing string in Brazilian Portuguese, on both sides of the boundary. `htmlAttrs.lang` is `pt-BR`, and text comparison uses `toLocaleLowerCase("pt-BR")` / accent-stripping via `~/utils/text`.
- Composition API with `<script setup lang="ts">` everywhere; TypeScript strict with `typeCheck: true` in the Nuxt config, so `vue-tsc` runs alongside `dev` and fails `build`.
- Ruby is `# frozen_string_literal: true`, standardrb-formatted, and Brakeman-clean.
- **Rails owns semantics.** Counts, denominators, rates, period boundaries, money, and status transitions are computed server-side; Nuxt formats a typed response. Do not re-derive a metric in the frontend.
- Prefer Nuxt UI components (`UButton`, form controls, `UApp`) and their built-in accessibility before writing custom controls. Mobile-first, semantic HTML, visible labels and errors, and no status conveyed by color alone.
- Add an abstraction only after a real second use; keep changes small and purpose-specific.
- Verification labels and catalog entries (services, Joinville neighborhoods) are controlled values seeded from `data/catalogs.json`, never free-form.
- Everything in `data/*.json` and `public/images/` is synthetic. Do not present it as real people, work, credentials, or endorsements.
- Privacy is a design constraint: visitor search is anonymous and stored only as aggregates, admin reporting is aggregate-only, and access logs record identifiers rather than content.

## Behavior worth knowing

- Non-production SMS OTP uses the fake adapter and the fixed code in `FAKE_SMS_OTP_CODE` (`123456` in `.env.example`). E2E tests depend on this. Every environment except `test` otherwise uses Infobip, with a recipient allowlist outside production.
- The administrator seed (`ADMIN_AUTH_EMAIL` / `ADMIN_AUTH_PASSWORD`) refuses to run in production.
- Tokenized quote links (`/orcamento/:token`) are request-time only, `no-store`, and `noindex`, and the page renders without the site layout.
- Professional onboarding state persists in `localStorage` under `berufe:professional-onboarding:v1` with a `version: 1` field; bump/migrate deliberately if the shape changes.
- Retention is enforced by scheduled jobs, not by hand: raw anonymous search events are rolled up and deleted after 90 days, aggregates are kept 730 days, and identity evidence is deleted 30 days after a decision.
- Google Analytics 4 loads from `app/plugins/analytics.client.ts`, gated on `NUXT_PUBLIC_GA_MEASUREMENT_ID` and off whenever `import.meta.dev` is true, so local development never reports to the property. Page paths carrying a bearer token (`/orcamento/:token`, `/recomendacao/:token`, `/exclusao-de-conta/:token`) are redacted by `app/utils/analytics.ts` before a page view is sent.

## Product docs

Read `docs/` before changing product behavior — the code is downstream of these. `Berufe_MVP_Feature_Plan.md` (scope and value loop), `Berufe_MVP_Stories.md` (acceptance criteria for MVP surfaces, `Sxxx`), `Berufe_Reports_Stories.md` (admin reporting, `Rxxx`), `Berufe_MVP_Infrastructure_Architecture.md` (Rails API + Nuxt split, Compose layout, auth, storage, development standards), `Berufe_Increment_*_Implementation_Plan.md` (approved decisions that refine the stories for a given increment; these take precedence where they intentionally differ), `Berufe_V2_Stories.md` (explicitly deferred; identifiers are never reused).

## Git workflow

Commits are titled `[Sxxx]: <imperative summary>` for a story, or a plain imperative summary otherwise. Never add a `Co-Authored-By` trailer, a Claude/session link, or any other AI-attribution footer to a commit message or PR description.

Always commit; never leave finished work sitting uncommitted. Split changes into well-scoped commits along the boundaries the change actually has — a bug fix, a refactor, and a new feature that happen to land together are separate commits, not one. Each commit should be reviewable on its own and its message should describe why that scoped change was made, not restate the diff.
