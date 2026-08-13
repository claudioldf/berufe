# Berufe — MVP Feature Plan

**Updated:** August 13, 2026

This document contains only launch-MVP product scope. Capabilities removed during scope review retain their former identifiers in `Berufe_V2_Stories.md`; identifiers are intentionally not reused.

## 1. Product analysis

### Product thesis

Berufe should not behave like a marketplace that sells customer contacts. It should be a verified professional network for residential renovation and maintenance:

> Professionals build a credible identity and network; customers find evidence and contact the chosen professional directly.

The core asset is not a list of service requests. It is a local trust graph showing who does what, where they work, what evidence they can present, and who recommends or has worked with them.

### Initial market

- **Location:** Joinville.
- **Supply:** 30–50 connected founding professionals.
- **Categories:** electricians, painters, plumbers, masons, flooring/tile installers, drywall/plaster professionals, carpenters, furniture installers, handymen, architects, and interior designers.
- **Users:** service professionals and customers. Admin users operate verification and moderation.
- **Not part of the first market:** domestic workers, sweets, events, photography, beauty, or unrelated service categories.

### MVP question

Can a small, connected group of professionals create enough visible trust for customers to find and contact them directly—without Berufe selling leads?

### MVP value loop

1. A professional creates and verifies a profile.
2. They add services, coverage, work examples, and trusted relationships.
3. Published professionals ask existing Berufe members to confirm recommendations or prior collaboration.
4. Customers search and inspect that evidence.
5. Customers contact a chosen professional directly through WhatsApp.
6. More confirmed professional relationships strengthen the network.

### MVP principles

- Show specific evidence; do not invent an opaque “trust score.”
- Keep the basic profile and direct contact free.
- Do not sell, gate, or auction customer contacts.
- Use a responsive web application, not a native app.
- Use manual operations where automation is not yet justified by volume.
- Collect the minimum data required for identity, discovery, and trust.
- Clearly distinguish verified facts from professional declarations.

### MVP success signals

The first launch should measure learning signals, not vanity totals:

- Number of approved, searchable professionals out of the 30–50 recruited.
- Percentage with a verified identity, at least three portfolio items, and at least two trust relationships.
- Searches that return at least one relevant result.
- Search-to-profile-open rate.
- Profile-to-WhatsApp-click rate.
- Number of confirmed professional relationships.

## 2. MVP scope by product

## A. Berufe Perfil

### Feature A1 — Professional account and onboarding

#### 1. Summary

Allows a professional to create an account, confirm their phone, and enter the minimum information required to start a profile.

#### 2. Why we need it

Every trust signal must belong to a real account. Phone confirmation also gives the professional a low-friction way to sign in and supports WhatsApp as the primary contact channel.

#### 3. How it works and implementation overview

1. The professional enters their phone number.
2. Rails synchronously asks Infobip to start a one-time-code challenge and gives the professional an immediate accepted, rate-limited, invalid, rejected, or unavailable result.
3. After confirmation, the professional enters their name and accepts the terms/privacy notice.
4. Berufe creates a draft profile and opens a short setup checklist.
5. Only professionals and admins have accounts in the MVP. Customers do not create general-purpose accounts.

Use Infobip's 2FA API only to start and verify SMS OTP challenges. Keep one-time codes outside the business database. After Infobip confirms the challenge, Rails finds or creates its own account by the unique verified phone and creates an opaque application session. The browser never receives an Infobip credential. Rails owns the user UUID, roles, suspension, logout, session revocation, and admin MFA state.

#### 4. Suggested feature-scoped data schema

**`user_account`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key |
| `phone_e164` | text | Unique; confirmed before activation |
| `role` | enum | `professional` or `admin` |
| `status` | enum | `active`, `suspended` |
| `terms_accepted_at` | timestamp | Required before profile setup |
| `created_at` | timestamp | Required |
| `last_login_at` | timestamp | Nullable |

**`application_session`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key |
| `user_account_id` | UUID | Required foreign reference |
| `authentication_method` | enum | `sms_otp` at launch |
| `token_digest` | text | Unique; raw token is never stored |
| `csrf_token_digest` | text | Binds the rotating CSRF token to the session |
| `authenticated_at` | timestamp | Required |
| `mfa_authenticated_at` | timestamp | Required for admin sessions; otherwise nullable |
| `last_active_at` | timestamp | Required; writes may be throttled |
| `idle_expires_at` | timestamp | Required |
| `absolute_expires_at` | timestamp | Required |
| `revoked_at` | timestamp | Nullable; set by logout, suspension, or administrative revocation |

**`otp_challenge`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key; not the browser credential |
| `public_token_digest` | text | Unique; only the high-entropy raw token is returned to the browser |
| `infobip_challenge_id_ciphertext` | text | Encrypted reference required for verification |
| `phone_e164_ciphertext` | text | Encrypted phone bound to this challenge |
| `expires_at` | timestamp | Short required lifetime |
| `consumed_at` | timestamp | Nullable; prevents reuse after success |
| `created_at` | timestamp | Required |

**`admin_totp_credential`**

| Field | Type | Rules |
| --- | --- | --- |
| `user_account_id` | UUID | Primary/foreign key; admin accounts only |
| `secret_ciphertext` | text | Encrypted with Rails application-level encryption |
| `recovery_code_digests` | jsonb | Array of one-way digests; raw codes shown only at enrollment |
| `enrolled_at` | timestamp | Required before admin access |
| `reset_at` | timestamp | Nullable; audited manual reset |

#### 5. Explicitly not in MVP

- Password login.
- Social login.
- Customer accounts.
- Multiple users managing one profile.
- Company teams and complex permissions.

---

### Feature A2 — Professional profile, services, and service area

#### 1. Summary

Creates the public professional identity: name, photo, description, experience declaration, WhatsApp contact, services, and areas served.

#### 2. Why we need it

This is the base of both trust and discovery. Without structured services and coverage, customers cannot find relevant professionals; without a credible profile, they cannot decide whom to contact.

#### 3. How it works and implementation overview

1. The professional completes a guided form.
2. They select services from Berufe’s approved residential renovation catalog.
3. They select Joinville and the neighborhoods they serve. “All Joinville” is allowed.
4. They add a short introduction and declared years of experience.
5. The editor shows an inline representation of the public fields, and the professional submits the profile for approval.
6. An approved profile becomes searchable. A material edit returns the profile to moderation; the founding-cohort operations team may assist when an urgent correction is required.

Use structured service selections rather than free-form specialties. Allow a short free-text description for context, but do not use it as the only search source. Generate a stable, shareable public slug.

#### 4. Suggested feature-scoped data schema

**`professional_profile`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key |
| `owner_user_id` | UUID | Foreign reference to account; unique |
| `public_slug` | text | Unique, stable, human-readable |
| `display_name` | text | Required |
| `photo_url` | text | Nullable until uploaded |
| `headline` | text | Short public description |
| `bio` | text | Short, length-limited |
| `years_experience_declared` | smallint | Nullable; explicitly labeled “declared” |
| `whatsapp_phone_e164` | text | Defaults to confirmed account phone |
| `profile_status` | enum | `draft`, `pending_review`, `published`, `suspended` |
| `created_at` | timestamp | Required |
| `updated_at` | timestamp | Required |

**`professional_service`**

| Field | Type | Rules |
| --- | --- | --- |
| `professional_id` | UUID | Foreign reference to profile |
| `service_id` | UUID | Foreign reference to managed service catalog |
| `is_primary` | boolean | At least one primary service |
| `note` | text | Optional short specialization note |

Unique key: `professional_id + service_id`.

**`professional_service_area`**

| Field | Type | Rules |
| --- | --- | --- |
| `professional_id` | UUID | Foreign reference to profile |
| `city_code` | text | Fixed to Joinville in initial launch |
| `neighborhood_code` | text | Nullable when serving the entire city |

Unique key: `professional_id + city_code + neighborhood_code`.

#### 5. Explicitly not in MVP

- Live calendar or real-time availability.
- Pricing tables.
- Map radius calculations.
- Multiple cities at launch.
- Team/company profiles.
- A calculated trust score.
- A dedicated draft-profile preview route.
- Parallel pending revisions that preserve a separate last-approved snapshot.

---

### Feature A3 — Portfolio

#### 1. Summary

Lets professionals publish a small set of photos and descriptions of completed work.

#### 2. Why we need it

For renovation services, customers need visual evidence of relevant experience. A structured portfolio is more useful than a generic biography and reduces uncertainty before contact.

#### 3. How it works and implementation overview

1. The professional uploads an image, selects the related service, adds a title, and optionally adds a short description.
2. The application compresses the image and removes unnecessary image metadata.
3. The item enters moderation.
4. Approved items appear newest first with deterministic tie-breaking.
5. Limit the MVP to 12 items per professional to keep storage and moderation manageable.

Use direct-to-object-storage uploads with private temporary access before approval and public optimized versions after approval.

#### 4. Suggested feature-scoped data schema

**`portfolio_item`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key |
| `professional_id` | UUID | Foreign reference to profile |
| `service_id` | UUID | Required; selected from catalog |
| `image_url` | text | Optimized public asset after approval |
| `title` | text | Required, short |
| `description` | text | Nullable, length-limited |
| `moderation_status` | enum | `pending`, `approved`, `rejected`, `hidden` |
| `created_at` | timestamp | Required |

#### 5. Explicitly not in MVP

- Video.
- Albums or project case studies.
- Before/after comparison widgets.
- Customer tagging.
- Unlimited uploads.
- Manual portfolio reordering.

---

### Feature A4 — Verification and public evidence labels

#### 1. Summary

Allows Berufe to publish “Phone confirmed” after authentication and manually review identity evidence for a precise “Identity verified” label.

#### 2. Why we need it

Verification is the foundation of the positioning. However, Berufe must not imply that every claim is verified or that a verified person’s work is guaranteed. Separate labels make the evidence understandable and honest.

#### 3. How it works and implementation overview

1. Phone confirmation is created automatically through account authentication.
2. The professional requests identity verification and uploads the required private image(s).
3. Berufe quarantines each upload and accepts it for review only after its signature, size, dimensions, safe decoding, metadata removal, and re-encoding succeed.
4. An admin reviews only the regenerated private image and approves or rejects it with a reason.
5. Only the label and verification date are public; private files and document identifiers are never public.
6. The UI always distinguishes verified identity from declarations, professional recommendations, and confirmed collaboration.

For the first 30–50 professionals, accept only JPEG/PNG evidence up to 10 MiB and 25 megapixels, use manual review, encrypt files at rest, restrict regenerated-file access to admins, keep an access log, and define a short retention rule before launch. Do not store full document numbers unless operationally essential. PDFs and malware-scanning infrastructure are deferred together; arbitrary documents are not accepted without that safety gate.

#### 4. Suggested feature-scoped data schema

**`verification_request`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key |
| `professional_id` | UUID | Foreign reference to profile |
| `verification_type` | enum | `identity` at launch |
| `status` | enum | `pending`, `approved`, `rejected`, `expired` |
| `submitted_at` | timestamp | Required |
| `reviewed_at` | timestamp | Nullable |
| `reviewed_by_user_id` | UUID | Nullable; admin account |
| `review_note` | text | Private; required on rejection |
| `public_label` | text | Controlled label, never user-written |

**`verification_file`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key |
| `verification_request_id` | UUID | Foreign reference to request |
| `private_storage_key` | text | Never public |
| `file_kind` | text | Controlled internal category |
| `uploaded_at` | timestamp | Required |
| `deleted_at` | timestamp | Nullable; supports retention policy |

#### 5. Explicitly not in MVP

- Automated government or professional-registry integrations.
- Background checks.
- A guarantee or insurance promise from Berufe.
- A single combined “trust score.”
- Automatic certificate expiration monitoring.
- Company and certificate verification labels.

---

### Feature A6 — Professional dashboard and profile sharing

#### 1. Summary

Gives the professional one simple home screen showing profile readiness, pending actions, and the public profile link.

#### 2. Why we need it

Professionals need to understand what to do next and be able to share their public profile. A focused dashboard also makes profile maintenance and relationship confirmations easy to find.

#### 3. How it works and implementation overview

The dashboard contains:

- Profile status and missing setup steps.
- Copy/share profile link button.
- Pending verification and moderation statuses.
- Pending professional relationship confirmations.
- Primary actions: edit profile, add a portfolio item, request identity verification, and manage existing-member relationships.

The share action opens the device share sheet when available and falls back to copying the stable URL. Berufe still records the minimal privacy-friendly search/profile/contact aggregates required to evaluate the MVP, but professional-facing activity reporting is deferred.

#### 4. Suggested feature-scoped data schema

**`professional_daily_metric`**

| Field | Type | Rules |
| --- | --- | --- |
| `professional_id` | UUID | Foreign reference to profile |
| `metric_date` | date | Local product date |
| `profile_views` | integer | Non-negative aggregate |
| `whatsapp_clicks` | integer | Non-negative aggregate |
| `whatsapp_clicks_public_profile` | integer | Non-negative subset used for profile conversion |
| `whatsapp_clicks_search_result` | integer | Non-negative subset used to distinguish result-card handoffs |

Unique key: `professional_id + metric_date`.

The setup checklist is calculated from existing feature data; it does not need its own table.

#### 5. Explicitly not in MVP

- Detailed visitor identities.
- Complex reports or charts.
- Lead pipeline or CRM.
- Notifications center.
- Social engagement metrics.
- Professional-facing activity counts and traffic-source reporting.

## B. Berufe Finder (Berufe Encontrar)

### Feature B1 — Public home and search

#### 1. Summary

Lets customers search for a service in Joinville and reach relevant professionals.

#### 2. Why we need it

Discovery turns the trust profiles into customer value. It also tests whether customers understand the service taxonomy and whether supply covers real demand.

#### 3. How it works and implementation overview

1. The home page asks “What service do you need?” and defaults the location to Joinville.
2. Suggestions come from the controlled service catalog.
3. The search endpoint filters only published profiles that serve the selected area and offer the selected service.
4. If there are no results, the page suggests nearby related services or asks the visitor to change the neighborhood; it does not create or sell a lead.

For 30–50 professionals, use ordinary relational database queries and indexed columns. Do not introduce a separate search engine. Normalize common spelling variations in application code. Record anonymous search aggregates to identify missing supply.

#### 4. Suggested feature-scoped data schema

**`search_event`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key |
| `service_id` | UUID | Nullable only when no suggestion selected |
| `query_text_normalized` | text | No names, phone numbers, or free-form notes retained |
| `city_code` | text | Joinville at launch |
| `neighborhood_code` | text | Nullable |
| `result_count` | integer | Non-negative |
| `created_at` | timestamp | Required |

No customer account or persistent identity is required.

#### 5. Explicitly not in MVP

- Natural-language AI search.
- Maps and distance-based ranking.
- Nationwide or multi-city search.
- Saved searches.
- Paid placement.
- A form that sends one request to many professionals.
- Dedicated SEO category landing pages.

---

### Feature B2 — Transparent result list

#### 1. Summary

Shows matching professionals with enough evidence for the customer to choose whom to inspect.

#### 2. Why we need it

A search result cannot be only a name and photo. The list must communicate why each person is relevant and trustworthy without hiding the logic behind a score.

#### 3. How it works and implementation overview

Each result card shows:

- Photo and name.
- Exact matching service.
- Neighborhood/city coverage.
- Precise public verification labels.
- Portfolio item count.
- Confirmed professional relationship count.

MVP ordering is simple and explainable:

1. Exact service match.
2. Serves the selected neighborhood.
3. Identity verified.
4. Has approved portfolio evidence.
5. Has approved professional recommendations or confirmed collaborations.
6. Most recently updated profile as a final tie-breaker.

The interface does not display a numeric score. Filters are limited to service and neighborhood.

#### 4. Suggested feature-scoped data schema

No new persistent table is required. This feature is a read-only query/projection over published profile, service area, verification, portfolio, and relationship data.

#### 5. Explicitly not in MVP

- Side-by-side comparison tool.
- Dozens of filters.
- Personalized ranking.
- Sponsored or purchased ranking.
- Real-time availability filter.
- Price sorting.

---

### Feature B3 — Public professional profile

#### 1. Summary

Presents all approved evidence about one professional on a public, mobile-first page.

#### 2. Why we need it

This is the customer’s decision page and the professional’s shareable digital identity. It must make the distinction between verified facts, declarations, professional recommendations, and confirmed collaboration clear.

#### 3. How it works and implementation overview

The page contains, in this order:

1. Name, photo, main service, coverage, and WhatsApp action.
2. Public verification labels with a short explanation.
3. Services and declared experience.
4. Portfolio.
5. Professional recommendations and confirmed collaborations.
6. A plain disclaimer that verification is evidence checking, not a service guarantee.

The page is server-rendered or statically cached for fast mobile loading and link previews. Only approved content is included.

#### 4. Suggested feature-scoped data schema

No new persistent table is required. The page is a public read model assembled from the feature-owned tables. The `public_slug` in the profile is its stable identifier.

#### 5. Explicitly not in MVP

- Public posts or feed.
- Customer comments.
- Booking calendar.
- Public phone number displayed as raw text; the primary action is the WhatsApp link.
- Complex SEO content generation.

---

### Feature B4 — Direct WhatsApp contact

#### 1. Summary

Lets a customer contact one chosen professional directly from a search result or profile.

#### 2. Why we need it

The product promise is direct contact without buying a lead. WhatsApp matches the professionals’ existing behavior and avoids building an internal messaging system.

#### 3. How it works and implementation overview

1. The customer taps “Contact on WhatsApp.”
2. Berufe records one anonymous aggregate click for that professional.
3. The device opens WhatsApp with a short prefilled message: the customer found the professional on Berufe and names the service viewed.
4. The conversation and negotiation happen entirely in WhatsApp.

Use a standard deep link. Do not proxy messages or collect the message content. Apply basic bot/rate filtering so automated clicks do not inflate the dashboard.

#### 4. Suggested feature-scoped data schema

No raw contact record is required. The feature increments `whatsapp_clicks` in the dashboard’s daily aggregate. If technical deduplication is needed, use a short-lived server cache rather than a permanent visitor table.

#### 5. Explicitly not in MVP

- Internal chat.
- Broadcasting a request to multiple professionals.
- Call recording or WhatsApp message capture.
- Appointment booking.
- Payment or commission.
- Claiming that a click equals a hired service.

## C. Berufe Rede

### Feature C1 — Existing-member recommendation and collaboration confirmation

#### 1. Summary

Allows verified professionals already on Berufe to recommend another published member or confirm that they have worked together.

#### 2. Why we need it

This is the main differentiator from a standard directory. It creates the first local professional trust graph and gives customers evidence beyond anonymous ratings. The founding cohort itself provides enough members to test the loop before productizing external recruitment.

#### 3. How it works and implementation overview

1. A verified professional finds another published professional.
2. They select “Recommend” or “Worked together” and add an optional short context note.
3. The recipient accepts or declines.
4. Accepted relationships enter moderation and become public only after approval.

Only verified professionals can initiate a public relationship. Both parties must confirm “worked together.” A recommendation is displayed with its author and cannot be anonymous.

#### 4. Suggested feature-scoped data schema

**`professional_relationship`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key |
| `initiator_professional_id` | UUID | Foreign reference to profile |
| `recipient_professional_id` | UUID | Foreign reference to profile; cannot equal initiator |
| `relationship_type` | enum | `recommendation`, `worked_together` |
| `context_note` | text | Optional and short |
| `status` | enum | `pending`, `accepted`, `declined`, `hidden` |
| `created_at` | timestamp | Required |
| `responded_at` | timestamp | Nullable |

Unique key: `initiator_professional_id + recipient_professional_id + relationship_type`.

#### 5. Explicitly not in MVP

- A professional social feed.
- Internal messages.
- Technical discussion forums.
- Open job posts.
- Team builder.
- Supplier content.
- Public follower/following counts.
- Invitations and relationship links for professionals who have not registered.

## E. Berufe Admin

### Feature E1 — Verification and moderation queue

#### 1. Summary

Gives a small Berufe operations team one place to approve identity-verification requests and moderate profiles, portfolios, and professional relationships.

#### 2. Why we need it

The public promise depends on accurate evidence and controlled content. With only 30–50 founding professionals, manual review is simpler and safer than building premature automated fraud systems.

#### 3. How it works and implementation overview

1. Admins sign in with an admin role and stronger authentication controls.
2. The queue groups pending items by type and oldest submission.
3. The reviewer sees only the information required for that review.
4. They approve, reject with a private reason, or hide previously approved content.
5. Every admin decision is recorded in an audit trail.
6. Public pages never show pending or rejected content.

Public pages expose a visible Berufe support/report contact. The founding-cohort operations team records and handles reports through the documented manual support process; an in-product reporting workflow is deferred.

#### 4. Suggested feature-scoped data schema

**`moderation_action`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key |
| `target_type` | enum | `profile`, `portfolio_item`, `professional_relationship`, `verification_request` |
| `target_id` | UUID | ID in target feature |
| `action` | enum | `approved`, `rejected`, `hidden`, `restored` |
| `reason` | text | Private; required for rejection/hide |
| `admin_user_id` | UUID | Foreign reference to admin account |
| `created_at` | timestamp | Required |

#### 5. Explicitly not in MVP

- Machine-learning fraud detection.
- Automated document approval.
- Complex case management.
- Public appeals/dispute threads.
- Separate moderator permission levels.
- Bulk moderation workflows.
- An in-product content-report form, report records, or case workflow.

---

### Feature E2 — Service and location catalog

#### 1. Summary

Maintains the small controlled catalog of renovation services and Joinville neighborhoods used by profiles and search.

#### 2. Why we need it

The same vocabulary must power onboarding and Finder. A controlled catalog prevents duplicate categories, improves search quality, and keeps the MVP inside its chosen market.

#### 3. How it works and implementation overview

1. Seed the approved renovation categories, services, and Joinville neighborhoods before launch.
2. Operations changes the launch catalog through reviewed seed/code changes.
3. Stable codes/slugs prevent those changes from breaking historical references.
4. New entries are added only through an operational decision, not by professionals.

Do not build a catalog administration form for the founding cohort.

#### 4. Suggested feature-scoped data schema

**`service_category`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key |
| `name` | text | Unique within active catalog |
| `slug` | text | Unique |
| `is_active` | boolean | Defaults to true |
| `sort_order` | smallint | Required |

**`service`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key |
| `category_id` | UUID | Foreign reference to category |
| `name` | text | Required |
| `slug` | text | Unique |
| `is_active` | boolean | Defaults to true |
| `sort_order` | smallint | Required |

**`neighborhood`**

| Field | Type | Rules |
| --- | --- | --- |
| `code` | text | Primary key |
| `city_code` | text | Joinville at launch |
| `name` | text | Required |
| `is_active` | boolean | Defaults to true |

#### 5. Explicitly not in MVP

- Professional-created categories.
- Tags without moderation.
- Multi-city hierarchy.
- Search synonym management interface.
- Pricing or market-rate data per service.
- Catalog administration UI.

## 3. MVP release slices

### Slice 1 — Build credible supply

- Professional account and onboarding.
- Profile, services, and service area.
- Portfolio.
- Verification labels.
- Admin queue and service catalog.

**Outcome:** the founding 30–50 professionals can become approved, credible, and publicly presentable.

### Slice 2 — Build the trust graph and discovery

- Existing-member professional recommendations and collaborations.
- Public home and service/neighborhood search.
- Transparent results and public profiles.
- Direct WhatsApp contact.

**Outcome:** customers can find evidence-backed professionals while the founding cohort proves whether confirmed peer relationships improve trust.

### Slice 3 — Launch and learn safely

- Professional dashboard and profile sharing.
- Privacy-friendly internal product aggregates.
- Production operations, recovery, and release-critical tests.

**Outcome:** Berufe can operate the focused value loop safely and collect enough evidence to choose V2 priorities.

## 4. MVP 2.0 — evidence-based enhancements

All capabilities removed from the launch MVP, including their former story IDs, acceptance criteria, dependencies, and evidence-based follow-ons, are tracked in `Berufe_V2_Stories.md`. Moving an item there preserves it for prioritization but does not authorize implementation before the MVP launches.

## 5. Explicit product exclusions for the MVP

The following are intentionally outside the MVP and should not appear as partial features:

- Instagram-like feed or public posting system.
- Internal chat.
- Payments, escrow, service commission, or financial intermediation.
- Lead selling or paid access to customer contact details.
- Paid ranking or sponsored search placement.
- Native iOS/Android applications.
- Mandatory professional subscription.
- Enterprise recruitment, private provider networks, or company homologation.
- Advertising and sponsored training.
- Berufe Pro, CRM, agenda, work orders, contracts, and financial control.
- Open job board, technical forum, supplier marketplace, or events.
- Expansion beyond residential renovation/maintenance and Joinville.

## 6. Recommended technical shape

Keep the first implementation conventional:

- Responsive web application.
- Relational database such as PostgreSQL.
- Infobip 2FA SMS verification followed by Rails-owned accounts and opaque application sessions; Rails-managed TOTP protects admins as a separate factor.
- OpenAPI 3.1 as the shared contract between the independently deployed Rails and Nuxt applications, with generated frontend types and Rails contract tests.
- Object storage for profile and portfolio images and private verification files.
- Server-side authorization for every professional/admin mutation.
- Server-rendered or cached public home, result, and profile pages.
- Background jobs only for image sanitization/processing, cleanup, aggregate maintenance, and nonurgent provider reconciliation. Interactive one-time-code initiation remains synchronous.
- Simple admin interface in the same application.
- Product events stored as privacy-friendly aggregates where possible.
- Redacted error-only reporting for Rails, background jobs, Nuxt browser code, and Nuxt SSR.

Avoid microservices, a separate search engine, event streaming, a graph database, or machine-learning ranking. The MVP’s network relationships fit comfortably in relational tables; those technologies solve scale problems the first launch will not have.

## 7. Final MVP definition

The complete MVP can be summarized as:

> A verified professional profile with structured services, work evidence, confirmed relationships with existing Berufe professionals, public search, direct WhatsApp contact, and profile sharing—supported by manual moderation.

This scope directly tests Berufe’s core “why”: whether a local network of visible, evidence-based professional trust is more valuable than a marketplace that sells leads.
