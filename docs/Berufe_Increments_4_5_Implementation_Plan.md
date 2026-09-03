# Berufe — Increments 4–5 Implementation Plan

**Status:** complete

**Updated:** August 18, 2026

**Scope:** S042, S043, S046, S047, and S049–S051 — existing-member trust, professional dashboard, profile sharing, and quote utility

> Historical implementation record. Portfolio and profile moderation rules are superseded by `Berufe_Post_Publication_Moderation_Decision.md`.

## 1. Source-of-truth order

This document records the approved implementation detail for Increments 4 and 5. It is read together with, in priority order:

1. `Berufe_MVP_Feature_Plan.md` for product scope and user-facing behavior;
2. this combined implementation plan for decisions made while reconciling that scope with the existing mockups;
3. `Berufe_MVP_Infrastructure_Architecture.md` for technical and operational constraints;
4. `Berufe_MVP_Stories.md` for acceptance criteria and delivery status;
5. `Berufe_Reports_Stories.md` for reusable eligibility and aggregate-reporting rules;
6. the existing `apps/web` mockups for the allowed pages, fields, labels, and interaction surfaces.

The implementation must not add a field, page, route, or user-facing claim absent from the approved documents and mockups. Any later conflict or divergence requires a recorded product decision in `docs/` before code changes.

## 2. Delivery order and status

Stories are implemented serially in dependency and deployment order:

`S042 → S043 → S046 → S047 → S049 → S050 → S051`

| Story | Status | Outcome                                                                                 |
| ----- | ------ | --------------------------------------------------------------------------------------- |
| S042  | DONE   | An eligible professional can send a private relationship request from a public profile. |
| S043  | DONE   | The recipient can accept or decline once from authenticated workspace data.             |
| S046  | DONE   | Recipient-accepted relationships expose honest public direction without admin review.   |
| S047  | DONE   | The professional dashboard is fully backed by the authenticated Rails workspace.        |
| S049  | DONE   | Quotes are private, owner-scoped, server-calculated, persistent, and live-editable.     |
| S050  | DONE   | Published professionals can expose quotes through stable, digest-only bearer links.     |
| S051  | DONE   | Explicit copy and WhatsApp share actions use secure URLs and aggregate counters.        |

S047 and S049 are delivered consecutively so the dashboard quote action and recent-quote table never target a fixture-backed editor in a release candidate.

## 3. Approved product decisions

### Relationship initiation and response

- The existing dashboard action leads to Finder, then to a published professional's existing public-profile page.
- The existing **Solicitar relação profissional** action opens a compact dialog on that page. It contains only the relationship type (`recommendation` or `worked_together`) and the existing optional context note, limited to 300 characters.
- The action is hidden for the current professional's own profile and when the authenticated account is not eligible. Rails independently enforces active professional ownership, approved identity verification, published recipient eligibility, self protection, and exact directional duplicate protection.
- Pending inbound relationships use the dashboard's existing confirmation surface. No relationship page, notification center, messaging, invitation, follower, or feed surface is added.

### Dashboard readiness

- Readiness has four existing setup rows worth 25 percent each:
  1. complete identity and contact data;
  2. at least one valid service and valid Joinville coverage record;
  3. at least one reviewable portfolio item in `pending` or `approved` moderation state;
  4. an approved identity verification.
- Rejected, hidden, deleted, or otherwise non-reviewable work does not complete the portfolio row.
- The workspace returns the professional's real publication state, allowed next actions, pending moderation/verification work, pending relationship confirmations, and recent quotes. It never substitutes demonstration rows.
- The public-profile URL is derived from configured site origin plus the stable published slug. Web Share remains progressive enhancement with copy fallback.
- Professional-facing analytics and traffic charts remain outside the MVP.

### Quote persistence and live editing

- The existing `/app/professional/quotes/new` screen is both creator and editor. An existing quote is loaded with `?quote={uuid}`; no additional quote page is introduced.
- A blank editor shows no quote number. The per-professional number is assigned only by the first valid server create and is concurrency-safe.
- Rails owns decimal line-total, subtotal, discount, and final-total calculation. Browser totals are preview-only.
- Quotes support fixed-price and itemized modes. Fixed-price rows are an
  owner-only cost calculator and the professional enters an independent final
  customer price; the anonymous representation exposes only that price.
  Itemized quotes expose their ordered breakdown. A separate price-free
  materials list tells the customer what to provide.
- The workspace remembers the professional's last successfully saved pricing
  mode for new quotes, with fixed price as the initial account default. Switching
  modes resets pricing inputs while preserving all non-pricing draft data.
- A shared quote remains editable by its owner. Editing preserves `shared` status, the original `shared_at`, and the same active token; resolving the customer link returns the latest saved content.
- The recent-quotes dashboard surface is empty until real quotes exist and links back to the same editor route.

### Secure quote sharing

- A quote can be shared or resolved only while its owner remains an active, currently published professional whose published revision is valid. Approved identity presentation is conditional on an actual approved identity verification.
- Raw bearer tokens are deterministic from protected server secret material and quote identity, are never stored, and are accepted by an anonymous resolver request body rather than an API path.
- Invalid, malformed, unknown, non-shared, revoked, non-public, or suspended-owner tokens receive the same generic not-found response.
- Each explicit `whatsapp` or `copy` share attempt increments the professional's daily `quotes_shared` aggregate, including repeat shares and copy fallback. Berufe does not claim message delivery or customer acceptance.

## 4. Backend implementation

### S042–S046 — professional relationships

- Add `POST /api/v1/professional/relationships` and `POST /api/v1/professional/relationships/{id}/response` with authenticated owner/recipient policy checks and transactional state changes.
- Add `professional_daily_activities`, unique by professional and São Paulo product date, with non-negative `profile_updates`, `evidence_creations`, `relationship_interactions`, and `quotes_created` counters. Increment relationship interactions on successful request/response mutations.
- Extend the professional workspace with current profile identity, relationship eligibility, and pending inbound requests.
- Keep `pending`, `accepted`, and `declined` as the complete recipient-owned relationship lifecycle. Relationships never enter the moderation resolver, queue, filters, audit transitions, or moderation contract enums.
- Public relationship queries require accepted status and both parties to remain active and published. Public projections include direction so recommendation authorship is explicit.

### S047 — professional workspace

- Calculate the four readiness steps from authoritative profile, service, coverage, portfolio, and verification records without a checklist table.
- Return only owner-scoped workspace data, including publication state, rejection/pending information, inbound relationship requests, stable share URL ingredients, and recent quotes.
- Replace dashboard fixture imports and local response state with a typed API service/composable and focused presentational components.

### S049–S051 — quotes

- Add UUID-backed `quotes`, `quote_items`, and customer-supplied
  `quote_materials` with owner foreign keys, database checks/indexes,
  deterministic order, decimal money/quantity fields, and a unique
  per-professional quote number.
- Add owner-scoped list/create/show/update endpoints. Persist nested items transactionally and recalculate all monetary values with `BigDecimal`.
- Add share and anonymous resolve endpoints. First share atomically sets `shared`, `shared_at`, and the token digest; later shares reproduce the active token and preserve lifecycle state.
- Return only quote content and approved public professional identity to anonymous resolvers with private `no-store` behavior.
- Add `quotes_shared` aggregate increments to each explicit share request and return an encoded generic WhatsApp URL plus the stable share URL.

## 5. HTTP contract

Increments 4 and 5 add these OpenAPI operations and regenerate the committed Nuxt schema with each consuming story:

- `POST /api/v1/professional/relationships`
- `POST /api/v1/professional/relationships/{id}/response`
- the expanded authenticated professional workspace operation
- `GET /api/v1/professional/quotes`
- `POST /api/v1/professional/quotes`
- `GET /api/v1/professional/quotes/{id}`
- `PATCH /api/v1/professional/quotes/{id}`
- `POST /api/v1/professional/quotes/{id}/share`
- `POST /api/v1/shared-quotes/resolve`

The existing admin moderation operations remain stable and do not accept professional relationships as targets.

## 6. Verification and completion gate

Each story adds focused Rails model/service/request/contract tests and behavior-focused Vitest coverage for changed Vue surfaces before an atomic story commit. Required combined coverage includes:

- relationship eligibility, self/duplicate/race behavior, recipient-only one-time response, immediate accepted visibility, direction, exclusion rules, counts, and daily activity;
- all dashboard readiness states, owner isolation, pending/rejected/empty states, profile-share fallback, and removal of runtime fixtures;
- quote validation, both pricing modes, fixed-price privacy, material order,
  decimal arithmetic, item order, concurrent numbering, ownership, live shared
  edits, stable token reproduction, digest-only persistence, generic
  invalid-token behavior, publication gates, cache controls, logging/privacy
  boundaries, and share counters;
- API-backed Playwright journeys for relationship request/direct recipient confirmation and quote creation/share/customer view/live update without external WhatsApp navigation.

The combined increment closes only after OpenAPI-generated types are current; full Rails and Nuxt tests, coverage, lint, type-check, and production builds pass; required browser journeys pass at supported sizes; and the working tree is clean.
