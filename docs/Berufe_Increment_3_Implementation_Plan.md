# Berufe — Increment 3 Implementation Plan

**Status:** in progress

**Updated:** August 17, 2026

**Scope:** S032–S037 — public discovery and direct contact

## 1. Source-of-truth order

This document records the approved implementation detail for Increment 3. It is read together with, in priority order:

1. `Berufe_MVP_Feature_Plan.md` for product scope and user-facing behavior;
2. this Increment 3 implementation plan for the decisions made while reconciling that scope with the existing mockups;
3. `Berufe_MVP_Infrastructure_Architecture.md` for technical and operational constraints;
4. `Berufe_MVP_Stories.md` for story acceptance criteria and delivery status;
5. `Berufe_Reports_Stories.md` for reusable eligibility rules and future aggregate requirements;
6. the existing `apps/web` mockups for the allowed pages, fields, labels, and interaction surfaces.

The implementation must not add a field, page, route, or user-facing claim that is absent from the approved documents and mockups. A conflict or later divergence requires a recorded product decision in `docs/` before code changes.

## 2. Delivery order and status

Stories are implemented serially in their documented dependency order:

`S032 → S033 → S034 → S035 → S036 → S037`

| Story | Status  | Outcome                                                                                 |
| ----- | ------- | --------------------------------------------------------------------------------------- |
| S032  | DONE    | Public home and discovery foundation use approved Rails data.                           |
| S033  | DONE    | Search returns eligible professionals for a resolved service and optional neighborhood. |
| S034  | PENDING | Searches produce privacy-safe aggregate events and short-lived interaction context.     |
| S035  | PENDING | Finder renders deterministic, explainable API-backed results.                           |
| S036  | PENDING | Public profiles render approved evidence and count privacy-safe views.                  |
| S037  | PENDING | WhatsApp handoffs redirect safely and count source-aware aggregate clicks.              |

## 3. Approved product decisions

### Existing home presentation

- The hero claim **+50.000 profissionais ativos** and the small Marcos chip remain decorative mockup content. They are not supplied by Rails and must not be interpreted as measured production data.
- The service suggestions and **Profissionais em destaque** section are supplied by Rails.
- Featured professionals are the three publicly eligible profiles whose approved public snapshots were most recently reviewed, with profile UUID as the deterministic tie-breaker.
- The featured section renders one to three available profiles and is omitted when none are eligible.
- Results and profile links preserve the selected `servico` and optional `bairro` context already represented by the mockups.
- The Finder label **Atualizado recentemente** appears only when the approved public snapshot was reviewed within the previous 90 days.

### Existing public UI boundary

- Runtime public pages stop importing `apps/web/data/professionals.json`.
- No category landing page, lead form, multi-city selector, map, sponsored placement, price, availability, score, new filter, new profile field, or new relationship workflow is added.
- Existing page order, cards, portfolio modal, social links, disclaimer, support contact, share action, and mobile contact action remain the UI source of truth.
- Services, profiles, evidence labels, portfolio counts, relationship counts, and relationship entries shown as real are backed by Rails records.
- Verification presentation is conditional. The verified avatar treatment and identity label are rendered only from an approved identity verification.
- The existing relationship creation/confirmation/moderation UI belongs to S042, S043, and S046 in Increment 4 and is not wired in this increment.

### Local and test demonstration data

- `apps/web/data/professionals.json` becomes local/test seed input only. It is not a runtime frontend data source.
- The demo seed uses the existing media processing, attachment, publication, verification, and moderation paths instead of creating public storage pointers directly.
- Demo relationships are accepted and have an effective approved moderation action so the existing relationship presentation can be exercised locally and in tests.
- The demo seed is idempotent and refuses to run in preview, staging, integration, or production environments. Production contains only genuine records.
- Docker Compose mounts the seed data and source images read-only. CI may use repository paths inside the API build context.

## 4. Shared public eligibility and evidence

Rails defines one reusable publicly eligible professional relation and uses it for featured results, search, profiles, public media, and metrics:

- `professional_profiles.profile_status = 'published'`;
- the owner account is active;
- `published_revision_id` points to the complete approved public snapshot;
- search additionally requires the selected active service and selected active Joinville neighborhood, or the all-city coverage record.

Approved portfolio evidence requires an approved, non-deleted portfolio item and a currently publicly eligible parent. Approved identity evidence requires an approved identity verification. Pending, rejected, hidden, deleted, expired, or suspended evidence contributes no label, item, or count.

Increment 3 adds the relationship read-model foundation needed by the existing public mockups. A relationship is directional, cannot target the same profile, and has a unique initiator/recipient/type combination. It is public only when accepted and its latest effective moderation action is approved or restored. Both endpoint profiles and accounts must remain public and active. Public counts use distinct relationship IDs across initiator and recipient roles. Relationship creation, response, and moderation operations remain deferred to Increment 4.

## 5. Story implementation

### S032 — Publish the public home and search entry

- Add a safe, minimal public professional-card projection and `GET /api/v1/public/professionals/featured`.
- Add `GET /api/v1/public/profile-photos/{id}/image`; every read rechecks approval and parent eligibility.
- Keep active service discovery on the existing public catalog endpoint and replace home mock professional imports with typed Rails services/composables.
- Add the relationship record/read-model foundation without exposing write endpoints.
- Add canonical, description, Open Graph, and share metadata using `NUXT_PUBLIC_SITE_URL`.
- Keep public pages on fresh request-time SSR. Do not add Redis or shared stale caching.

### S033 — Search published professionals

- Add `POST /api/v1/public/professional-searches` with a service term and optional active Joinville neighborhood.
- Resolve an active service by exact stable slug, normalized name, or a controlled spelling alias. An unmatched term returns no professionals and at most three safe related active-service suggestions.
- Return only the safe card projection: profile UUID and slug, public name, approved photo URL, matching/primary service, coverage, precise labels, approved portfolio/relationship counts, and approved snapshot review time. Never return a phone number.
- Use indexed PostgreSQL joins for service and coverage. No external search engine is introduced.

### S034 — Record privacy-friendly search aggregates

- Add `search_events` with nullable service, privacy-normalized query, Joinville city code, optional neighborhood code, result count, profile-opened flag, optional search-handoff flag, and timestamps.
- Reject malformed request values but do not retain names, phone numbers, free-form notes, raw sensitive input, a customer account, a cookie identifier, or persistent visitor identity.
- Search-event persistence failure is logged safely and never blocks search results.
- A successful search response may include the event UUID and a short-lived Rails-signed interaction token containing only random/context identifiers required to mark the search-level outcome. Raw signing material is never stored or returned elsewhere.

### S035 — Show transparent, deterministic results

- Wire the existing Finder controls and cards to the typed public-search operation.
- Rank in Rails by selected service, explicit selected-neighborhood coverage, identity verification, approved portfolio evidence, approved visible relationship evidence, approved snapshot review time descending, and profile UUID ascending.
- Carry signed search-event and service context in result-to-profile and result-to-WhatsApp links.
- Show only evidence included in the safe projection. No numeric trust score or unapproved evidence influences presentation or order.

### S036 — Render the public professional profile

- Add `GET /api/v1/public/professionals/{slug}` with the complete approved public projection and a generic non-public not-found response.
- Include approved photo, identity and coverage, primary and additional services with declared experience and specialization notes, precise verification labels, approved portfolio, public relationships, present approved social links, and approved snapshot review time. Exclude the phone and all private moderation/evidence data.
- Tighten public profile-photo and portfolio-image endpoints so current parent eligibility is checked on every read.
- Replace the profile mock import while preserving the existing page order and interaction surfaces.
- Add `professional_daily_metrics`, keyed by professional and São Paulo local date, with non-negative counters and the invariant `whatsapp_clicks = whatsapp_clicks_public_profile + whatsapp_clicks_search_result`.
- Add `POST /api/v1/public/professionals/{id}/views`. A valid signed interaction is retry-idempotent during its short lifetime, may mark one search event as opened, and increments the daily profile-view aggregate. Failure never blocks profile rendering.

### S037 — Open a direct WhatsApp conversation and count the handoff

- Add `GET /api/v1/public/professionals/{id}/whatsapp` with source `search_result` or `public_profile` and a short-lived signed interaction token.
- Rails resolves the professional phone privately, increments the total and source daily counters atomically, optionally marks the search-level handoff once, and returns a `302` redirect to an allowlisted `https://wa.me/` URL with an encoded short pt-BR message naming Berufe and the viewed service.
- The Nuxt application receives only the Berufe redirect URL. It never receives the phone number in JSON or page source.
- A bounded ten-minute Rails memory cache suppresses repeated taps for the same signed interaction/profile/source. Obvious bots and link-preview agents are not counted. No visitor identity, IP-derived identifier, or permanent deduplication record is created.
- Metric/cache failure is logged without sensitive data and does not prevent a valid eligible professional from redirecting.
- The ordinary web `wa.me` redirect is the practical fallback when a native WhatsApp deep link is unavailable. Berufe does not observe message content, delivery, negotiation, or hiring.

## 6. HTTP contract

Increment 3 adds these OpenAPI operations and regenerates the committed Nuxt schema with each consuming story:

- `GET /api/v1/public/professionals/featured`
- `POST /api/v1/public/professional-searches`
- `GET /api/v1/public/professionals/{slug}`
- `GET /api/v1/public/profile-photos/{id}/image`
- `POST /api/v1/public/professionals/{id}/views`
- `GET /api/v1/public/professionals/{id}/whatsapp`

Public JSON returns approved projections only and uses the shared error envelope. Public state-changing operations obey the configured exact-origin rule, including Nuxt SSR requests. Media and redirects remain Rails responses rather than frontend-generated storage/contact URLs.

## 7. Environment contract

- Docker Compose remains the authoritative local stack for Rails, Nuxt, PostgreSQL, and GoodJob.
- Add `NUXT_PUBLIC_SITE_URL` for canonical/share URLs while preserving the existing internal/public API base URL split.
- Keep public pages request-rendered and excluded from static prerendering where necessary.
- Configure a bounded in-process ten-minute cache only for short interaction deduplication. Do not add Redis, a persistent visitor store, cross-session tracking, or an external analytics/search service.

## 8. Verification and completion gate

Each story adds focused Rails request/model/service/query tests and behavior-focused Vitest coverage for every changed Nuxt surface. Required Increment 3 coverage includes:

- public eligibility, aliases, inactive catalog entries, optional neighborhood coverage, deterministic tie-breaking, and privacy-safe projections;
- parent revalidation for profile and portfolio media;
- event-persistence failure suppression, sensitive-input handling, signed-token expiry/context/retry behavior, and search-level boolean idempotency;
- São Paulo local metric dates, non-negative counters, source-total invariant, bot filtering, bounded duplicate suppression, generic non-public responses, and allowlisted redirects;
- demo-seed idempotency, real media/moderation paths, public relationships, and refusal outside local/test;
- home, Finder, and profile rendering from typed API responses, preserved query/context links, 90-day recency behavior, conditional verification, and absence of phone data;
- a Playwright API-backed public journey that exercises search, profile open, and the WhatsApp redirect without navigating to the external service.

The increment closes only after OpenAPI-generated types are current, the full Rails and Nuxt tests and coverage pass, lint and type-check pass, production builds succeed, the public flow is exercised at desktop and mobile sizes, relevant network requests and redirects are inspected, and the browser console has no unexplained errors.
