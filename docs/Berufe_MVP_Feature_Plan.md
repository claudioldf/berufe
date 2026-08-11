# Berufe — MVP Feature Plan

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

Can a small, connected group of professionals create enough visible trust for customers to find and contact them—and enough recurring utility for professionals to keep their information current—without Berufe selling leads?

### MVP value loop

1. A professional creates and verifies a profile.
2. They add services, coverage, work examples, and trusted relationships.
3. They invite past clients and collaborators to confirm evidence.
4. Customers search and inspect that evidence.
5. Customers contact a chosen professional directly through WhatsApp.
6. The professional uses Berufe to create and share a quote.
7. More confirmed work and recommendations strengthen the network.

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
- Number of client recommendations completed.
- Number of confirmed professional relationships.
- Number of quotes created and shared each week.
- Percentage of professionals who return to update a profile, request a recommendation, confirm a relationship, or create a quote.

## 2. MVP scope by product

## A. Berufe Perfil

### Feature A1 — Professional account and onboarding

#### 1. Summary

Allows a professional to create an account, confirm their phone, and enter the minimum information required to start a profile.

#### 2. Why we need it

Every trust signal must belong to a real account. Phone confirmation also gives the professional a low-friction way to sign in and supports WhatsApp as the primary contact channel.

#### 3. How it works and implementation overview

1. The professional enters their phone number.
2. Berufe sends a one-time code through a supported authentication provider.
3. After confirmation, the professional enters their name and accepts the terms/privacy notice.
4. Berufe creates a draft profile and opens a short setup checklist.
5. Only professionals and admins have accounts in the MVP. Customers do not create general-purpose accounts.

Use a hosted passwordless authentication service. Keep authentication credentials and one-time codes outside the business database when the provider supports it. The application stores only the account identifier, verified phone, role, and status.

#### 4. Suggested feature-scoped data schema

**`user_account`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key |
| `auth_provider_id` | text | Unique external auth identifier |
| `phone_e164` | text | Unique; confirmed before activation |
| `role` | enum | `professional` or `admin` |
| `status` | enum | `active`, `suspended` |
| `terms_accepted_at` | timestamp | Required before profile setup |
| `created_at` | timestamp | Required |
| `last_login_at` | timestamp | Nullable |

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
5. They preview the public page and submit it for approval.
6. An approved profile becomes searchable. The professional can edit it; material edits return only the changed content to moderation.

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
4. Approved items appear on the public profile in a manually selected order.
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
| `sort_order` | smallint | Professional-controlled |
| `created_at` | timestamp | Required |

#### 5. Explicitly not in MVP

- Video.
- Albums or project case studies.
- Before/after comparison widgets.
- Customer tagging.
- Unlimited uploads.

---

### Feature A4 — Verification and public evidence labels

#### 1. Summary

Allows Berufe to review evidence and publish precise labels such as “Phone confirmed,” “Identity verified,” “Company verified,” or “Certificate checked.”

#### 2. Why we need it

Verification is the foundation of the positioning. However, Berufe must not imply that every claim is verified or that a verified person’s work is guaranteed. Separate labels make the evidence understandable and honest.

#### 3. How it works and implementation overview

1. Phone confirmation is created automatically through account authentication.
2. The professional chooses a verification type and uploads the required private file(s).
3. An admin reviews the submission and approves or rejects it with a reason.
4. Only the label and verification date are public; private files and document identifiers are never public.
5. The UI always distinguishes verified evidence from declarations, recommendations, and completed-service confirmations.

For the first 30–50 professionals, use manual review. Encrypt files at rest, restrict file access to admins, keep an access log, and define a short retention rule before launch. Do not store full document numbers unless operationally essential.

#### 4. Suggested feature-scoped data schema

**`verification_request`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key |
| `professional_id` | UUID | Foreign reference to profile |
| `verification_type` | enum | `identity`, `company`, `certificate` |
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

---

### Feature A5 — Client recommendation request

#### 1. Summary

Lets a professional request a recommendation from a past client through a one-time link, without requiring the client to create a full account.

#### 2. Why we need it

Client recommendations provide useful social proof and help founding professionals bring existing trust into the network. A controlled request flow is more credible than unrestricted public reviews.

#### 3. How it works and implementation overview

1. The professional creates a recommendation request and shares its one-time link through WhatsApp.
2. The client opens the link, enters a display name, selects the service performed, confirms that the service occurred, and writes a short recommendation.
3. The client confirms a phone number with a one-time code. Berufe stores a one-way phone fingerprint for duplicate detection, not a public number.
4. The recommendation enters moderation.
5. Once approved, it appears on the professional profile as “Client recommendation” and contributes to the visible confirmed-service count.

Do not use star ratings in the MVP. Show the service, recommendation text, approximate completion period, and that the client phone was confirmed.

#### 4. Suggested feature-scoped data schema

**`client_recommendation_request`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key |
| `professional_id` | UUID | Foreign reference to profile |
| `token_hash` | text | Unique; raw token never stored |
| `status` | enum | `open`, `completed`, `expired`, `revoked` |
| `created_at` | timestamp | Required |
| `expires_at` | timestamp | Required |

**`client_recommendation`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key |
| `request_id` | UUID | Foreign reference; unique |
| `service_id` | UUID | Foreign reference to service catalog |
| `client_display_name` | text | Prefer first name + last initial |
| `client_phone_fingerprint` | text | Private; duplicate/abuse detection |
| `service_period` | text | Month/year or year; no exact address |
| `recommendation_text` | text | Short, length-limited |
| `service_confirmed` | boolean | Must be true to submit |
| `moderation_status` | enum | `pending`, `approved`, `rejected`, `hidden` |
| `submitted_at` | timestamp | Required |

#### 5. Explicitly not in MVP

- Open reviews from anyone browsing the site.
- Star ratings or category scores.
- Public customer profiles.
- Anonymous reviews.
- Review replies and public disputes.
- Importing reviews from other platforms.

---

### Feature A6 — Professional dashboard and profile sharing

#### 1. Summary

Gives the professional one simple home screen showing profile readiness, pending actions, basic activity, and the public profile link.

#### 2. Why we need it

Professionals need to understand what to do next and whether the profile is producing interest. A focused dashboard also makes recurring actions—requesting recommendations, confirming relationships, and creating quotes—easy to find.

#### 3. How it works and implementation overview

The dashboard contains:

- Profile status and missing setup steps.
- Copy/share profile link button.
- Pending verification and moderation statuses.
- Pending professional relationship confirmations.
- Counts for profile views, WhatsApp clicks, recommendations, and quotes shared in the last 30 days.
- Primary actions: edit profile, add portfolio item, request recommendation, invite collaborator, create quote.

Use privacy-friendly daily aggregates instead of a detailed visitor log. The share action opens the device share sheet when available and falls back to copying the URL.

#### 4. Suggested feature-scoped data schema

**`professional_daily_metric`**

| Field | Type | Rules |
| --- | --- | --- |
| `professional_id` | UUID | Foreign reference to profile |
| `metric_date` | date | Local product date |
| `profile_views` | integer | Non-negative aggregate |
| `whatsapp_clicks` | integer | Non-negative aggregate |
| `quotes_shared` | integer | Non-negative aggregate |

Unique key: `professional_id + metric_date`.

The setup checklist is calculated from existing feature data; it does not need its own table.

#### 5. Explicitly not in MVP

- Detailed visitor identities.
- Complex reports or charts.
- Lead pipeline or CRM.
- Notifications center.
- Social engagement metrics.

## B. Berufe Finder (Berufe Encontrar)

### Feature B1 — Public home, categories, and search

#### 1. Summary

Lets customers search for a service in Joinville and reach relevant category pages and professionals.

#### 2. Why we need it

Discovery turns the trust profiles into customer value. It also tests whether customers understand the service taxonomy and whether supply covers real demand.

#### 3. How it works and implementation overview

1. The home page asks “What service do you need?” and defaults the location to Joinville.
2. Suggestions come from the controlled service catalog.
3. A category page explains the service and lists matching professionals.
4. The search endpoint filters only published profiles that serve the selected area and offer the selected service.
5. If there are no results, the page suggests nearby related services or asks the visitor to change the neighborhood; it does not create or sell a lead.

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
- Approved client recommendation count.
- Confirmed professional relationship count.

MVP ordering is simple and explainable:

1. Exact service match.
2. Serves the selected neighborhood.
3. Identity verified.
4. Has approved portfolio evidence.
5. Has approved recommendations/confirmed relationships.
6. Most recently updated profile as a final tie-breaker.

The interface does not display a numeric score. Filters are limited to service and neighborhood.

#### 4. Suggested feature-scoped data schema

No new persistent table is required. This feature is a read-only query/projection over published profile, service area, verification, portfolio, recommendation, and relationship data.

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

This is the customer’s decision page and the professional’s shareable digital identity. It must make the distinction between verified facts, declarations, recommendations, and relationships clear.

#### 3. How it works and implementation overview

The page contains, in this order:

1. Name, photo, main service, coverage, and WhatsApp action.
2. Public verification labels with a short explanation.
3. Services and declared experience.
4. Portfolio.
5. Client recommendations.
6. Professional recommendations and confirmed collaborations.
7. A plain disclaimer that verification is evidence checking, not a service guarantee.

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

### Feature C1 — Professional invitation, recommendation, and collaboration confirmation

#### 1. Summary

Allows verified professionals to invite trusted collaborators, recommend another professional, and confirm that they have worked together.

#### 2. Why we need it

This is the main differentiator from a standard directory. It creates the local professional trust graph, supports the founder-led growth model, and gives customers evidence beyond anonymous ratings.

#### 3. How it works and implementation overview

There are two paths:

**Existing member**

1. A verified professional finds another published professional.
2. They select “Recommend” or “Worked together” and add an optional short context note.
3. The recipient accepts or declines.
4. Accepted relationships become public on both profiles with the exact relationship type.

**Professional not yet registered**

1. The founder creates an invitation with the person’s first name and intended relationship.
2. Berufe generates a one-time link that the founder shares through WhatsApp.
3. The invited person registers through the link.
4. After profile approval, they accept or decline the relationship.

Only verified professionals can initiate a public relationship. Both parties must confirm “worked together.” A recommendation is displayed with its author and cannot be anonymous.

#### 4. Suggested feature-scoped data schema

**`professional_invite`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key |
| `inviter_professional_id` | UUID | Must be verified |
| `invitee_first_name` | text | Minimal invite context |
| `intended_relationship_type` | enum | `recommendation`, `worked_together` |
| `token_hash` | text | Unique; raw token never stored |
| `status` | enum | `open`, `accepted`, `expired`, `revoked` |
| `created_at` | timestamp | Required |
| `expires_at` | timestamp | Required |

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

## D. Berufe Ferramentas

### Feature D1 — Simple quote generator and share link

#### 1. Summary

Lets a professional create a clear service quote and share a customer-facing link through WhatsApp.

#### 2. Why we need it

The profile helps professionals get discovered; the quote helps them do real work and gives them a reason to return. It also connects discovery to a meaningful next step without Berufe processing payment or taking commission.

#### 3. How it works and implementation overview

1. The professional starts a quote from the dashboard.
2. They enter the customer name, a short service description, line items, optional discount, validity date, and notes.
3. Berufe calculates subtotal and total.
4. The professional previews the mobile public page.
5. Tapping “Share on WhatsApp” marks the quote as shared, increments the daily aggregate, and opens WhatsApp with the public link.
6. The customer can view or print the quote without an account.

The shared page shows the professional’s public identity and verification labels. It is accessible through a long, unguessable token. The MVP statuses are only `draft` and `shared`; Berufe does not represent whether the quote was accepted or paid.

#### 4. Suggested feature-scoped data schema

**`quote`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key |
| `professional_id` | UUID | Foreign reference to profile |
| `quote_number` | integer | Sequential per professional |
| `customer_name` | text | Required; no customer account |
| `service_description` | text | Required, short |
| `discount_amount` | decimal(12,2) | Defaults to zero; cannot exceed subtotal |
| `total_amount` | decimal(12,2) | Server-calculated |
| `valid_until` | date | Nullable |
| `notes` | text | Nullable, length-limited |
| `status` | enum | `draft`, `shared` |
| `share_token_hash` | text | Unique; created when shared |
| `created_at` | timestamp | Required |
| `shared_at` | timestamp | Nullable |

**`quote_item`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key |
| `quote_id` | UUID | Foreign reference to quote |
| `description` | text | Required |
| `quantity` | decimal(10,2) | Greater than zero |
| `unit_label` | text | Examples: service, hour, m² |
| `unit_price` | decimal(12,2) | Zero or greater |
| `line_total` | decimal(12,2) | Server-calculated |
| `sort_order` | smallint | Required |

#### 5. Explicitly not in MVP

- Customer acceptance workflow or electronic signature.
- Payment, installments, or escrow.
- Automatic invoice or tax document.
- Expense and profit calculation.
- Client CRM.
- Contract templates.
- Work orders, scheduling, or financial control.
- Server-generated branded PDF; the browser print function is sufficient initially.

## E. Berufe Admin

### Feature E1 — Verification and moderation queue

#### 1. Summary

Gives a small Berufe operations team one place to approve verification requests and moderate profiles, portfolios, recommendations, and relationships.

#### 2. Why we need it

The public promise depends on accurate evidence and controlled content. With only 30–50 founding professionals, manual review is simpler and safer than building premature automated fraud systems.

#### 3. How it works and implementation overview

1. Admins sign in with an admin role and stronger authentication controls.
2. The queue groups pending items by type and oldest submission.
3. The reviewer sees only the information required for that review.
4. They approve, reject with a private reason, or hide previously approved content.
5. Every admin decision is recorded in an audit trail.
6. Public pages never show pending or rejected content.

Add a simple “Report this profile” link that collects a category, explanation, and optional contact. Reports enter the same operations area. This is not a public dispute system.

#### 4. Suggested feature-scoped data schema

**`moderation_action`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key |
| `target_type` | enum | `profile`, `portfolio_item`, `client_recommendation`, `professional_relationship`, `verification_request` |
| `target_id` | UUID | ID in target feature |
| `action` | enum | `approved`, `rejected`, `hidden`, `restored` |
| `reason` | text | Private; required for rejection/hide |
| `admin_user_id` | UUID | Foreign reference to admin account |
| `created_at` | timestamp | Required |

**`content_report`**

| Field | Type | Rules |
| --- | --- | --- |
| `id` | UUID | Primary key |
| `target_type` | enum | `profile`, `portfolio_item`, `client_recommendation`, `professional_relationship` |
| `target_id` | UUID | Required |
| `reason_category` | enum | Small controlled list |
| `details` | text | Required, length-limited |
| `reporter_contact` | text | Optional; private |
| `status` | enum | `open`, `resolved`, `dismissed` |
| `created_at` | timestamp | Required |

#### 5. Explicitly not in MVP

- Machine-learning fraud detection.
- Automated document approval.
- Complex case management.
- Public appeals/dispute threads.
- Separate moderator permission levels.
- Bulk moderation workflows.

---

### Feature E2 — Service and location catalog

#### 1. Summary

Maintains the small controlled catalog of renovation services and Joinville neighborhoods used by profiles and search.

#### 2. Why we need it

The same vocabulary must power onboarding and Finder. A controlled catalog prevents duplicate categories, improves search quality, and keeps the MVP inside its chosen market.

#### 3. How it works and implementation overview

1. Seed the approved renovation categories, services, and Joinville neighborhoods before launch.
2. Admins can rename, reorder, activate, or deactivate entries.
3. Deactivation does not delete historical references.
4. New categories are added only through an operational decision, not by professionals.

Build a minimal internal form. Do not build a general taxonomy platform.

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

## 3. MVP release slices

### Slice 1 — Build credible supply

- Professional account and onboarding.
- Profile, services, and service area.
- Portfolio.
- Verification labels.
- Admin queue and service catalog.

**Outcome:** the founding 30–50 professionals can become approved, credible, and publicly presentable.

### Slice 2 — Build the trust graph and discovery

- Client recommendation requests.
- Professional invitations, recommendations, and collaborations.
- Public home/search/category pages.
- Transparent results and public profiles.
- Direct WhatsApp contact.

**Outcome:** customers can find evidence-backed professionals, while founding professionals grow the network through real relationships.

### Slice 3 — Create recurring professional utility

- Professional dashboard and profile sharing.
- Simple quote generator and share link.
- Basic aggregate product metrics.

**Outcome:** professionals have a reason to return even when they are not editing their profile or waiting for discovery.

## 4. MVP 2.0 — evidence-based enhancements

These are not included in the MVP. Each enhancement should be built only when the stated signal appears.

| MVP feature | MVP 2.0 enhancement | Real reason / trigger |
| --- | --- | --- |
| Professional account | Multiple managers for one company/team profile | Several founding businesses cannot keep profiles updated with a single owner. |
| Profile and service area | Availability status that automatically expires | Customers repeatedly contact unavailable professionals and professionals agree to maintain the status. |
| Profile and service area | Additional cities | Joinville has healthy supply, search usage, and repeatable onboarding operations. |
| Portfolio | Before/after pairs and project albums | Professionals consistently reach the 12-item limit or customers struggle to understand project context. |
| Verification | Automated company/certificate checks | Manual review becomes the launch bottleneck or produces inconsistent decisions. |
| Client recommendations | Stronger duplicate/abuse rules and evidence attachment | The closed founder network starts receiving suspicious or disputed recommendations. |
| Dashboard | Trends and traffic-source reporting | Professionals use the basic counts and ask what actions improve profile outcomes. |
| Search | “Ask the network for an indication” when no result exists | Search logs show repeated unmet demand and the professional network is dense enough to answer requests reliably. The request remains free and is never sold. |
| Search/results | Availability and more coverage filters | The result set becomes large enough that service + neighborhood no longer narrows it sufficiently. |
| Public profile | Side-by-side evidence comparison | Customer research shows people repeatedly switch between multiple profiles and miss important differences. |
| WhatsApp contact | Optional post-contact outcome check | Berufe needs to distinguish useful contacts from accidental clicks and users are willing to answer a one-question follow-up. |
| Professional relationships | Partner search, work opportunities, and team formation | A sufficient number of verified professionals return regularly and actively need cross-trade collaboration. This does not require a social feed. |
| Quote generator | Branded PDF, acceptance status, templates, and version history | Professionals repeatedly share quotes and need a more formal workflow. Payment remains a separate future decision. |
| Admin moderation | Rule-based risk flags and specialized queues | Submission volume makes oldest-first manual review too slow or abuse patterns become repeatable. |
| Service catalog | Managed synonyms and search suggestions | Search-event data shows common unmatched terms that correspond to existing services. |

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
- Hosted passwordless phone authentication.
- Object storage for profile and portfolio images and private verification files.
- Server-side authorization for every professional/admin mutation.
- Server-rendered or cached public profile and category pages.
- Background jobs only for image processing, one-time-code delivery, and expired-token cleanup.
- Simple admin interface in the same application.
- Product events stored as privacy-friendly aggregates where possible.

Avoid microservices, a separate search engine, event streaming, a graph database, or machine-learning ranking. The MVP’s network relationships fit comfortably in relational tables; those technologies solve scale problems the first launch will not have.

## 7. Final MVP definition

The complete MVP can be summarized as:

> A verified professional profile with structured services, work evidence, client recommendations, confirmed professional relationships, public search, direct WhatsApp contact, and a simple shareable quote—supported by manual moderation.

This scope directly tests Berufe’s core “why”: whether a local network of visible, evidence-based professional trust is more valuable than a marketplace that sells leads.
