# Berufe — V2 Stories

**Status:** post-MVP backlog; not authorized for launch implementation

**Created:** August 13, 2026

**Sources:** *Berufe — MVP Feature Plan*, *Berufe — MVP Implementation Stories*, and *Berufe — Reports Stories and Metric Specification*

## 1. Purpose

This document preserves every capability moved out of the launch MVP during the August 2026 scope review. It is a parking lot, not a commitment to build every item. Product evidence after launch determines priority and may simplify or replace a story before implementation.

Former MVP story and feature IDs are recorded for traceability and are not reused. A V2 story is not ready merely because it appears here: before implementation it needs current product evidence, privacy/security review where relevant, and updated OpenAPI, backend, frontend, test, and operational acceptance criteria.

## 2. Scope moved from the launch MVP

### V2-001 — Manage service and location catalogs in the admin UI

**Former scope:** S018; Feature E2 partial.

**Story:** As an admin, I want to rename, reorder, activate, and deactivate catalog entries so that Berufe can correct its controlled vocabulary without a code deployment.

**Preserved acceptance criteria:**

- Admin API and Nuxt forms support rename, reorder, activation, and deactivation for service categories, services, and neighborhoods; each reorderable table persists deterministic order.
- Referenced entries cannot be hard-deleted.
- Only admins can mutate the catalog; policy tests prove professional and anonymous denial.
- Professionals and public search cannot select inactive entries for new records.

**Depends on:** MVP S010, S015, and S017.

**Revisit when:** catalog changes become frequent enough that reviewed seed/code changes slow operations or create mistakes.

### V2-002 — Add company and certificate verification

**Former scope:** Feature A4 and MVP S029–S030 partial.

**Story:** As a professional, I want Berufe to review company or certificate evidence so that an additional precise public label can support relevant claims.

**Preserved acceptance criteria:**

- Add controlled `company` and `certificate` verification types without changing the meaning of identity verification.
- Define the exact evidence required, reviewer instructions, public wording, expiry behavior, and rejection reasons for each type before accepting uploads.
- Evidence uses the MVP quarantine, signature/size/dimension validation, safe decoding, metadata stripping, re-encoding, restricted access, audit, and retention controls.
- Phone, identity, company, and certificate labels remain distinct; none implies guaranteed work quality.

**Depends on:** MVP S025, S029–S031.

**Revisit when:** customer research shows these labels affect selection or founding professionals repeatedly request them.

### V2-003 — Add a dedicated draft-profile preview

**Former scope:** Feature A2 and S021 partial.

**Story:** As a professional, I want to preview my complete draft through the public-profile presentation before submission so that I can review its final composition.

**Preserved acceptance criteria:**

- The owner can preview draft and pending content through an authenticated route and endpoint.
- The preview clearly marks declarations, pending evidence, and content that is not public.
- Anonymous and non-owner requests cannot access or infer preview records.
- The preview reuses the public presentation without weakening public serializers.

**Depends on:** MVP S021 and S036.

**Revisit when:** inline editor representation causes avoidable submission mistakes or professional confusion.

### V2-004 — Preserve an approved profile while a revision is pending

**Former scope:** Feature A2 and S022–S024 partial.

**Story:** As a published professional, I want my last approved profile to remain public while material edits are reviewed so that routine maintenance does not remove me from search.

**Preserved acceptance criteria:**

- Editing material approved content creates a separate pending revision.
- The last approved snapshot remains public and unchanged until the revision is approved.
- Approval atomically replaces the approved projection; rejection keeps the previous projection public and returns the revision to a private editable state with a reason.
- Public serializers can never mix approved fields with unreviewed revision fields.
- State-transition, policy, and serializer tests cover first publication, revision approval/rejection, hiding, suspension, restoration, and concurrent edits.

**Depends on:** MVP S022–S024.

**Revisit when:** temporary removal during review materially harms active professionals or creates excessive manual corrections.

### V2-005 — Manually order portfolio items

**Former scope:** Feature A3 and S027 partial.

**Story:** As a professional, I want to order approved work examples so that my strongest or most relevant evidence appears first.

**Preserved acceptance criteria:**

- The owner can reorder only their own approved items.
- Order is persisted with deterministic, conflict-safe values and validated by Rails.
- Pending, rejected, hidden, and deleted items do not create public-order gaps or expose private records.
- Public portfolio queries use the configured order with a deterministic tie-breaker.

**Depends on:** MVP S027–S028.

**Revisit when:** professionals ask to curate ordering or newest-first presentation performs poorly in customer research.

### V2-006 — Publish dedicated SEO category landing pages

**Former scope:** Feature B1 and S032 partial.

**Story:** As a customer arriving through search or a shared category link, I want a stable service page so that I understand the category and can reach matching professionals.

**Preserved acceptance criteria:**

- Stable category routes show the service name, a short reviewed explanation, and a path to filtered results.
- Routes use active catalog services and provide correct title, description, canonical URL, and share metadata.
- Inactive or unknown categories do not expose stale or fabricated content.
- The feature does not become complex generated SEO content or a CMS by default.

**Depends on:** MVP S010 and S032–S035.

**Revisit when:** organic acquisition becomes an explicit channel with enough approved profiles per category.

### V2-007 — Accept and triage in-product content reports

**Former scope:** S038; Feature E1 partial.

**Story:** As a visitor, I want to report questionable public content so that Berufe operations can review it without creating a public dispute system.

**Preserved acceptance criteria:**

- Public profiles expose a report form with controlled category, required length-limited explanation, and optional private contact.
- Reports can target profiles, portfolio items, client recommendations when implemented, or professional relationships.
- Valid reports enter the admin operations area with `open`, `resolved`, or `dismissed` status.
- Reporter contact and details are private and excluded from public APIs and logs.
- There are no public replies, appeals, or complex case-management workflows.

**Preserved data shape:** `content_report` contains UUID `id`, controlled `target_type`, required `target_id`, controlled `reason_category`, length-limited `details`, optional private `reporter_contact`, `open|resolved|dismissed` status, and `created_at`.

**Depends on:** MVP S023 and S036.

**Revisit when:** report volume or response-time risk makes the documented support channel insufficient.

### V2-008 — Create and share a client recommendation request

**Former scope:** Feature A5; S039.

**Story:** As a professional, I want a one-time recommendation link so that a past client can confirm completed work without creating an account.

**Preserved acceptance criteria:**

- The owner creates a request tied to their profile with an expiry and `open` status.
- Rails stores only a hash of a high-entropy token; the raw token is shown only in the generated share URL.
- The professional can open an explicit WhatsApp deep link containing the request URL, with copy-link fallback, and can revoke an open request.
- Expired, completed, revoked, malformed, and unknown tokens reveal no private data and cannot be submitted.
- Request creation does not send an automated WhatsApp message.

**Preserved data shape:** `client_recommendation_request` contains UUID `id`, `professional_id`, unique `token_hash`, `open|completed|expired|revoked` status, `created_at`, and `expires_at`.

**Depends on:** MVP S014 and S024.

**Revisit when:** customer recommendations are shown to improve trust beyond identity, portfolio, and professional relationships.

### V2-009 — Submit a phone-confirmed client recommendation

**Former scope:** Feature A5; S040.

**Story:** As a past client, I want to confirm the service and submit a short recommendation so that my experience can support the professional's profile.

**Preserved acceptance criteria:**

- A valid request shows the professional and permits a display name, request-relevant service, approximate service period, short recommendation, and required service confirmation.
- The client requests and verifies a single-purpose SMS challenge without creating a `user_account` or Berufe session.
- The challenge uses the same cooldown, daily allowance, generic-response, synchronous provider, and no-OTP-storage rules as professional authentication.
- Rails stores a keyed one-way phone fingerprint for duplicate/abuse detection, not a public phone number.
- Submission atomically consumes the request and creates one pending recommendation.
- There are no stars, anonymous submissions, replies, exact service address, or imported reviews.

**Preserved data shape:** `client_recommendation` contains UUID `id`, unique `request_id`, `service_id`, privacy-minimized `client_display_name`, private `client_phone_fingerprint`, approximate `service_period`, length-limited `recommendation_text`, required `service_confirmed`, `pending|approved|rejected|hidden` moderation status, and `submitted_at`.

**Depends on:** MVP S011 and V2-008.

**Revisit when:** V2-008 is approved and the privacy, consent, provider-cost, duplicate, and abuse policies are accepted.

### V2-010 — Moderate and publish client recommendations

**Former scope:** Feature A5; S041.

**Story:** As an admin, I want to review client recommendations so that only controlled social proof appears publicly.

**Preserved acceptance criteria:**

- Pending recommendations appear in the shared moderation queue.
- Approval publishes display name, service, approximate period, text, and the phone-confirmed indication.
- Rejection or hiding records a private reason and removes public visibility and counts.
- Approved recommendations appear on the correct profile and contribute only to an explicitly labeled client-recommendation count.
- Duplicate indicators assist manual review but do not automatically accuse or publicly label a client.
- Public pages and ordering distinguish client recommendations from professional relationships.

**Depends on:** MVP S023 and S036; V2-009.

**Revisit when:** V2-008–V2-009 are approved with sufficient moderation ownership.

### V2-011 — Invite a professional who is not registered

**Former scope:** Feature C1 partial; S044.

**Story:** As a verified professional, I want to invite a trusted collaborator through a one-time link so that they can join Berufe and later confirm our relationship.

**Preserved acceptance criteria:**

- The inviter provides only invitee first name and intended relationship type.
- Rails creates an expiring, revocable invitation and stores only the token hash.
- Sharing opens an explicit WhatsApp deep link containing the invitation URL, with copy-link fallback; Berufe sends no automated message.
- The invited person can begin registration from a valid token.
- Invalid, expired, accepted, or revoked tokens do not reveal inviter-private data or permit reuse.

**Preserved data shape:** `professional_invite` contains UUID `id`, verified `inviter_professional_id`, minimal `invitee_first_name`, `recommendation|worked_together` intended type, unique `token_hash`, `open|accepted|expired|revoked` status, `created_at`, and `expires_at`. V2-012 may add explicit unique invitee/relationship foreign keys for safe reporting.

**Depends on:** MVP S016 and S042.

**Revisit when:** founder-led manual recruitment no longer supplies enough suitable professionals or peer invitations demonstrate better conversion.

### V2-012 — Complete a professional invitation after profile approval

**Former scope:** Feature C1 partial; S045.

**Story:** As an invited professional, I want the intended relationship offered after my profile is approved so that joining does not automatically create public trust evidence.

**Preserved acceptance criteria:**

- Registration retains the valid invitation association without storing the raw token.
- Profile approval creates or reveals the pending relationship to the invitee.
- The invitee explicitly accepts or declines it using the existing-member relationship rules.
- Acceptance marks the invitation accepted and submits the confirmed relationship to moderation; publication still requires admin approval.
- Expiry or revocation before completion prevents relationship creation.

**Depends on:** MVP S024 and S043; V2-011.

**Revisit when:** V2-011 is approved and invitation-to-publication conversion will be measured.

### V2-013 — Show professional activity metrics

**Former scope:** S048; Feature A6 partial.

**Story:** As a professional, I want simple recent activity counts so that I can understand whether my profile is producing interest without visitor tracking.

**Preserved acceptance criteria:**

- The dashboard shows 30-day totals for profile views, WhatsApp clicks, approved client recommendations when implemented, confirmed professional relationships, and quotes shared when implemented.
- Internal aggregates calculate search-to-profile-open and profile-to-WhatsApp conversion without a visitor identity.
- Public-profile views and WhatsApp actions use short-lived duplicate filtering.
- No visitor identities, individual traffic-source records, complex charts, CRM, or notification center are added.
- Metric definitions match the product-reporting specification and expose honest empty/small-sample states.

**Preserved data shape:** reuse the MVP `professional_daily_metric`; add non-negative `quotes_shared` only if V2-016 is implemented. Profile/WhatsApp totals and source counters remain the MVP aggregate fields rather than a visitor table.

**Depends on:** MVP S034, S036–S037, S046–S047; optional V2-010 and V2-016.

**Revisit when:** professionals ask for performance feedback and the data is sufficiently reliable to drive a useful action.

### V2-014 — Create and edit a draft quote

**Former scope:** Feature D1; S049.

**Story:** As a professional, I want to create a simple itemized quote so that I can use Berufe in my customer workflow.

**Preserved acceptance criteria:**

- The owner can create and edit a draft with customer name, short service description, ordered line items, optional discount, validity date, and notes.
- Quantities are greater than zero; unit prices are non-negative; discount cannot exceed subtotal.
- Rails recalculates every line total, subtotal, and total with `BigDecimal`; client calculations are preview-only.
- Quote numbers are sequential per professional and concurrency-safe.
- Draft customer and quote data is private to the owner, and to admins only when operationally required.

**Preserved data shape:**

- `quote`: UUID `id`, `professional_id`, per-professional sequential `quote_number`, required `customer_name` and short `service_description`, decimal `discount_amount` and server-calculated `total_amount`, optional `valid_until` and length-limited `notes`, `draft|shared` status, unique nullable `share_token_hash`, `created_at`, and nullable `shared_at`.
- `quote_item`: UUID `id`, `quote_id`, required description, positive decimal quantity, unit label, non-negative decimal unit price, server-calculated line total, and deterministic `sort_order`.

**Depends on:** MVP S015 and S047.

**Revisit when:** professional interviews show quoting is a high-frequency retention problem worth adding customer/financial data to Berufe.

### V2-015 — Preview and share a secure quote link

**Former scope:** Feature D1; S050.

**Story:** As a professional, I want to preview and share an unguessable quote link so that a customer can view it without an account.

**Preserved acceptance criteria:**

- The owner previews the quote in a mobile customer-facing layout before sharing.
- First share generates a high-entropy token, stores only its hash, and atomically changes status from `draft` to `shared`.
- A valid link shows the quote and approved professional public identity/labels without private profile fields.
- Invalid or unknown tokens reveal no quote or customer details.
- The token remains valid while the quote is `shared`; `valid_until` describes the commercial offer and is not token expiry.
- Token-authorized responses use `no-store` and `noindex` behavior and never enter shared caches or search indexes.
- The customer can use browser print; Berufe does not generate a PDF, acceptance, signature, invoice, or payment flow in this story.

**Depends on:** MVP S030; V2-014.

**Revisit when:** V2-014 is approved with privacy, retention, revocation, and customer-data procedures.

### V2-016 — Share a quote through WhatsApp and record the action

**Former scope:** Feature D1; S051.

**Story:** As a professional, I want to share a quote through my device so that the customer receives the secure link using my normal WhatsApp workflow.

**Preserved acceptance criteria:**

- Sharing opens an explicit WhatsApp deep link with a short message and quote URL, with copy-link fallback.
- Tapping the action increments a privacy-friendly quote-share aggregate; Berufe does not claim delivery.
- Berufe does not send, read, or track a WhatsApp message or claim the quote was accepted or paid.
- The initial quote lifecycle remains only `draft` or `shared`.

**Depends on:** MVP S037's aggregate pattern and V2-015. V2-013 is an optional consumer, not a prerequisite.

**Revisit when:** V2-014–V2-015 are approved and share attempts are a meaningful success signal.

### V2-017 — Deliver the administrative growth report

**Former scope:** R001–R014 in `Berufe_Reports_Stories.md`.

**Story:** As an administrator, I want a privacy-safe aggregate growth report so that I can understand supply, discovery, trust, retention, moderation health, and later utility loops without visitor-level tracking.

**Preserved acceptance criteria:**

- Use `Berufe_Reports_Stories.md` as the detailed metric and test specification, updating it against the domains actually implemented when this story is approved.
- Ship the aggregate-only endpoint, OpenAPI operation, generated Nuxt types, authorization, period semantics, empty/small-sample behavior, and formula tests together.
- Do not fabricate invitation, client-recommendation, quote, report, or professional-facing metric values before their corresponding V2 domains exist.
- Keep PostgreSQL as the source of truth and avoid an analytics provider, warehouse, Redis, or event stream unless measured need separately justifies one.

**Depends on:** the MVP aggregate events plus only those V2 domains selected for reporting.

**Revisit when:** manual queries cannot support recurring product decisions or multiple operators need the same trusted view.

## 3. Evidence-triggered V2 candidates already identified

These ideas were already outside the MVP before the scope review. They remain preserved here, but should become implementation stories only after their trigger occurs.

| Candidate | Evidence required |
| --- | --- |
| Multiple managers for one company/team profile | Several founding businesses cannot maintain profiles with one owner. |
| Automatically expiring availability status | Customers repeatedly contact unavailable professionals and professionals agree to maintain it. |
| Additional cities | Joinville has healthy supply, search usage, and repeatable onboarding operations. |
| Before/after pairs and project albums | Professionals reach the portfolio limit or customers cannot understand project context. |
| Automated company/certificate checks | The manual V2 verification workflow becomes slow or inconsistent. |
| Stronger recommendation abuse rules and evidence attachments | Client recommendations are implemented and suspicious/disputed submissions become repeatable. |
| “Ask the network for an indication” on no results | Aggregate searches show repeated unmet demand and the professional network is dense enough to respond without selling leads. |
| Availability and additional coverage filters | Service plus neighborhood no longer narrows the result set adequately. |
| Side-by-side evidence comparison | Research shows customers repeatedly switch profiles and miss important differences. |
| Optional post-contact outcome check | Berufe needs to distinguish useful contacts from accidental clicks and users will answer one question. |
| Partner search, work opportunities, and team formation | Verified professionals return regularly and demonstrate a cross-trade collaboration need. |
| Quote PDF, acceptance, templates, and version history | The basic V2 quote flow is used repeatedly and needs formality. Payment remains a separate decision. |
| Rule-based moderation risk flags and specialized queues | Submission volume or repeatable abuse makes oldest-first manual review too slow. |
| Managed search synonyms and suggestions | Aggregate unmatched searches repeatedly map to existing services. |

## 4. Explicitly still excluded

Moving work to V2 does not reopen unrelated platform scope. Payments, lead selling, paid ranking, automated WhatsApp delivery, internal chat, social feeds, a job board, a generic CRM, native applications, graph databases, and multi-city infrastructure remain excluded until a separate product decision supplies evidence and updates the approved plan.
