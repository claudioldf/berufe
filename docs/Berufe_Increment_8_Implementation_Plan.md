# Berufe — Increment 8 Implementation Plan

**Status:** implemented

**Updated:** August 28, 2026

## Source precedence

Increment 8 promotes V2-006 ("Publish dedicated SEO category landing pages") out of `Berufe_V2_Stories.md`: its revisit trigger — "organic acquisition becomes an explicit channel" — was met directly by the product decision behind this increment. Organic search is the only acquisition channel the product permits (`Berufe_MVP_Feature_Plan.md` §5 permanently excludes paid ranking, lead selling, and advertising), so this document records the approved scope for making the public site indexable and building a real professional-acquisition surface. Where this document is silent, `Berufe_MVP_Feature_Plan.md` and `Berufe_MVP_Infrastructure_Architecture.md` remain authoritative.

## Stories

### S059 — Make every public page genuinely crawlable

**Story:** As a search engine, I want a sitemap, robots.txt, canonical URLs, and structured data on every public page so that I can index Berufe correctly.

**Acceptance criteria:**

- `@nuxtjs/seo` (robots, sitemap, og-image, schema-org, site-config, link-checker) is installed and configured from `site.url`/`site.name`.
- `/robots.txt` disallows `/app`, `/orcamento`, `/recomendacao`, `/foundation`; production emits `index, follow` elsewhere, non-production defaults to `noindex`.
- `/sitemap.xml` includes every static public route, every self-service published professional slug, every indexable service×city listing/city-hub/service-hub URL, and every `/para-profissionais/:service` page — sourced live from Rails, not hand-maintained.
- Every public page emits a canonical `<link>`, and a page rendering one visitor's free-text query (`?q=`) is `noindex, follow` and canonicalizes to the clean URL.
- Site-wide `Organization` (identity) and `WebSite` (with a `SearchAction`) JSON-LD render on every page; `/`, professional profiles, and listing pages add their own `WebPage`/`ProfilePage`/`Person`/`BreadcrumbList`/`ItemList` nodes with explicit `@id`s so they never collide with the site identity node.
- A branded Open Graph image renders per page (`satori`, `BerufeDefault`/`BerufeProfessional` templates) instead of a generic screenshot.

### S060 — Decide what may be indexed, on the API side

**Story:** As the product, I want Rails to be the single source of truth for what search engines may index so that thin or unclaimed content never drags down the whole domain's quality signal.

**Acceptance criteria:**

- `PublicIndexability` (`apps/api/app/services/public_indexability.rb`) is the only place that decides indexability.
- A professional profile is indexable only when self-service (never an external, unclaimed, referral-created profile — indexing those is both a quality risk and a privacy question the referral legitimate-interest assessment does not cover), published, with a photo, and with at least one piece of evidence (portfolio item, recommendation, or verification label). `GET /public/professionals/{slug}` and the professional workspace (`is_indexable`) both expose this via the same computation.
- A service×city listing is indexable only at ≥3 published professionals (`PublicIndexability::MINIMUM_LISTING_PROFESSIONALS`); below that it is a real page (a recruitment opportunity — "be the first electrician in Blumenau") but `noindex, follow`.
- Nuxt never re-derives this decision; it renders whatever Rails reports.

### S061 — Publish gated service×city listing pages

**Story:** As a customer, I want a real, indexable page listing professionals for one service in one city so that I can find and evaluate them without an interactive search step; as the product, I want that page's traffic to be visible proof of demand.

**Acceptance criteria:**

- `GET /api/v1/public/professional-listings` (service_slug, state_slug, city_slug) is a cacheable GET, backed by the existing `PublicProfessionalSearch#call_with_filters`, that records no search event and consumes no interactive-search rate limit.
- `/encontrar/:state_code/:city/:service` server-renders real professional cards, `indexable`-gated `noindex`/`index`, canonical, `BreadcrumbList`, and `ItemList` JSON-LD.
- A supported city with zero current supply for that service renders an empty, `noindex` page with a "be the first" call to action rather than a 404 or 422.
- `GET /api/v1/public/service-coverage` (the service×city professional-count matrix) powers `/servicos` (hub), `/servicos/:service` (cities with supply), and the city page's own service list, all sharing the identical supply criterion so counts never disagree with the linked page.
- `/encontrar/:state_code/:city` (moved to `[city]/index.vue` to coexist with the sibling `[service].vue` route — see delivery notes) server-renders a real city hub: canonical, `BreadcrumbList`, and the city's indexable services, in addition to its existing interactive search.

### S062 — Publish the professional-acquisition surface

**Story:** As a prospective professional searching "como conseguir clientes como eletricista" or "vale a pena pagar por lead," I want to find Berufe's answer directly, so that I choose a free profile over a paid-lead competitor.

**Acceptance criteria:**

- `/para-profissionais` is a real pillar page: answer-first value proposition (free forever, no per-contact charge, direct WhatsApp, verified identity, portfolio, peer recommendations), real published professionals as examples, links to every `/para-profissionais/:service` page and to `/guias`, and a visible FAQ (written for readers and answer engines, not for the deprecated `FAQPage` rich result).
- `/para-profissionais/:service` exists for every catalog service, each answer-first for its own provider-intent query cluster, and shows the 30-day search-demand line for the visitor's detected city when released (S063) — real, current proof that people are already looking for that trade.
- `AppHeader` and `AppFooter` link to `/para-profissionais`, `/servicos`, and `/guias`; these were previously an anchor into the homepage and four links respectively.
- The professional dashboard nudges a published-but-not-yet-indexable profile toward the specific gap (photo, portfolio, or verification) rather than leaving indexability invisible to the professional.

### S063 — Release search demand as a public, privacy-safe proof point

**Story:** As a prospective professional, I want to see that people are already searching for my trade in my city, so that I believe joining is worth it — without Berufe ever exposing an individually-identifying search count.

**Acceptance criteria:**

- `GET /api/v1/public/service-demand` (service_slug, state_slug, city_slug) returns a 30-day search count for one service in one city, combining not-yet-rolled-up `SearchEvent` rows with `SearchDailyRollup` sums (mirroring `Admin::Reports::SearchAggregate`'s combine strategy, so the two sources never double count).
- The count is released only at ≥3 searches in the window (`PublicServiceDemand::MINIMUM_RELEASABLE_SEARCHES`); below that, `searches` is `null` and nothing is shown — no rounding or fuzzing substitutes for withholding.

### S064 — Publish hand-written provider-intent guides

**Story:** As a prospective professional researching how to get clients, I want direct, non-templated guidance so that Berufe earns organic traffic and answer-engine citations without becoming a content farm.

**Acceptance criteria:**

- `@nuxt/content` (collection `guias`, `apps/web/content/guias/*.md`) backs `/guias` and `/guias/:slug`; every article is hand-written and reviewed through the normal PR process — the `Berufe_MVP_Feature_Plan.md` Feature B3 exclusion of "complex SEO content generation" continues to apply and bounds this collection's growth.
- Each guide opens with a direct 40–60 word answer to its query, consistent with how retrieval-based answer engines evaluate a page.

## Delivery notes

- **Routing conflict:** a page file `[city].vue` sharing its dynamic-segment name with a sibling directory `[city]/` makes Nuxt treat the file as an implicit parent for everything under that directory; since it has no `<NuxtPage />` outlet, a nested `[service].vue` route never renders and the parent silently absorbs the extra path segment instead of 404ing. The fix was moving `pages/encontrar/[state_code]/[city].vue` to `pages/encontrar/[state_code]/[city]/index.vue`, which does not change the resolved URL.
- **Nuxt Site Config in dev:** `NUXT_PUBLIC_SITE_URL=http://localhost:3000` is intentionally rejected by `nuxt-site-config` as a non-production URL; this only affects local development ergonomics (a console warning), not production behavior once a real domain is configured.
- Not built in this increment: the `entry_surface` measurement dimension on `professional_daily_metrics` (organic landing-page attribution in the admin growth report — R005 currently starts every funnel stage at a search event, so a visitor arriving directly on a profile or listing page from Google is invisible to it), and end-to-end Playwright coverage of the new public routes. Both remain open follow-ups.

## Delivery order

1. `PublicIndexability`, the OpenAPI contract additions, and the three new public read endpoints (listings, service-coverage, service-demand) plus the sitemap-professionals endpoint, each with request specs.
2. `@nuxtjs/seo` installation and site-wide configuration (robots, sitemap sources, schema-org identity, OG image templates).
3. The professional-acquisition surface (`/para-profissionais`, `/guias`) and the footer/header link mesh.
4. The demand-side pages (`/encontrar/:state/:city/:service`, `/servicos`, `/servicos/:service`) and the city hub upgrade.
5. Profile-page structured data, indexability-driven `robots`, and the dashboard nudge.
6. Backend, contract, frontend, and typecheck/test validation through Docker Compose.
