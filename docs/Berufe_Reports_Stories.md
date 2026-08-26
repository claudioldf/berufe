# Berufe — Reports Stories and Metric Specification

**Status:** launch-MVP implementation stories for Feature E3

**Updated:** August 18, 2026

## 1. Purpose and source of truth

This document is the implementation specification for the launch-MVP administrative growth report represented by `./apps/web/app/components/admin/reports`. R001–R014 are required MVP stories and ship as one aggregate-only, admin-authorized feature.

The approved decisions in `Berufe_Increment_6_Implementation_Plan.md` take precedence where they intentionally refine this specification, including contact attribution, previous-stage supply percentages, retention truncation, the five-stage discovery funnel, and report-specific retention.

It explains what each card or widget means, which records it reads, the required associations and filters, and the exact calculation to return from the Rails API. Launch widgets use only MVP domains. Sections concerning client recommendations, external invitations, professional-facing metrics, or persisted content reports remain conditional on their corresponding V2 stories; unavailable domains are omitted or explicitly unavailable, never fabricated as zero activity.

It is derived from:

- `Berufe_MVP_Feature_Plan.md`, especially the MVP value loop and success signals;
- `Berufe_MVP_Stories.md` for launch data and `Berufe_V2_Stories.md` for deferred domains;
- `Berufe_MVP_Infrastructure_Architecture.md`, especially the PostgreSQL, privacy, moderation, and analytics decisions;
- `apps/contracts/openapi.yaml`, which must describe the report endpoint and response consumed by Nuxt once implementation begins;
- the current report mockup and its three periods: since launch, last 30 days, and last 7 days.

The Feature Plan contains proposed data structures, not implemented migrations. This document therefore uses conventional Rails plural table names for clarity and explicitly marks every metric that needs a field or aggregate not yet present in the approved documents. A report must never fabricate a value when the required data does not exist.

The report is designed for the zero-to-initial-liquidity stage. Its primary questions are:

1. Are enough professionals becoming searchable?
2. Is the published supply credible and sufficiently distributed?
3. Are customer searches finding useful choices?
4. Does discovery produce profile interest and WhatsApp handoffs?
5. Do professionals return to create more value?
6. Are existing-member trust relationships and quotes being completed?
7. Can the manual moderation operation keep up?

These are operating indicators, not a numeric trust score, lead marketplace, hiring tracker, or revenue dashboard.

## 2. Global reporting rules

### 2.1 Periods and time zone

All timestamps are stored as UTC `timestamptz`. Reporting boundaries use `America/Sao_Paulo`, matching the product's initial Joinville market.

| Period key     | Start, inclusive                             | End, exclusive                  |
| -------------- | -------------------------------------------- | ------------------------------- |
| `since_launch` | Start of the configured product launch date  | Start of tomorrow in local time |
| `last_30_days` | Start of the local date 29 days before today | Start of tomorrow in local time |
| `last_7_days`  | Start of the local date 6 days before today  | Start of tomorrow in local time |

`since_launch` must use an explicit application setting such as `product_launch_date`. Do not silently substitute the oldest database row, because seeds, previews, and pre-launch tests would corrupt the result.

Comparisons use the immediately preceding window of equal duration. `since_launch` has no previous comparison and should show a milestone or an absolute explanation instead.

### 2.2 Three kinds of metric

The endpoint must identify the semantic type of each metric so that the UI does not imply an incorrect period meaning:

- **Flow:** an event happened inside `[period_start, period_end)`, for example quotes created or searches performed.
- **Cohort outcome:** records entered the funnel inside the period, and their later/current outcome is measured, for example requests created in the period that were eventually completed. These values may mature after the period ends.
- **Current stock:** the state at report generation time, for example published profiles or pending moderation work. A current stock does not become “last 7 days” merely because the period selector changes.

The current mockup mixes these concepts. The production response should return `metricType` or the UI copy should clearly state “agora”, “no período”, or “da coorte iniciada no período”.

### 2.3 Empty and small samples

- A count with no records is `0`.
- A ratio with a zero denominator is `null`, rendered as `—`, never `0%`.
- Every ratio returns both numerator and denominator.
- Counts and `n/N` take precedence over percentage-only presentation while the base is small.
- Comparisons whose current or previous denominator is below 5 should be labeled as directional, not statistically conclusive.
- Percentage-point change is used for rates; percentage change is used for counts.

### 2.4 Reusable eligibility scopes

The report service should define these scopes once and reuse them across widgets.

#### Publicly eligible professional

Join `professional_profiles.owner_user_id` to `user_accounts.id` and require:

- `professional_profiles.profile_status = 'published'`;
- `user_accounts.status = 'active'`;
- the approved public snapshot, not an unapproved pending revision, is used;
- the profile has the selected active service and coverage when the query is for search supply.

A suspended account/profile is excluded immediately from current public stock. A profile that was later suspended remains in historical publication and retention cohorts unless it was legally deleted; this prevents retrospective rewriting of cohort denominators.

#### Approved portfolio item

Require `portfolio_items.moderation_status = 'approved'` and a publicly eligible parent profile. Rejected, pending, or hidden items do not count.

#### Approved identity verification

Require at least one `verification_requests` row with:

- `professional_id = professional_profiles.id`;
- `verification_type = 'identity'`;
- `status = 'approved'`.

Rejected, pending, expired, and non-identity verification types do not satisfy activation.

#### Public professional relationship

Require all of the following:

- `professional_relationships.status = 'accepted'`;
- both initiator and recipient accounts are active;
- both profiles are published.

The relationship counts for both the initiator and recipient. A self-relationship must be prohibited by domain validation. Use a `UNION ALL` of the two endpoints followed by `COUNT(DISTINCT relationship_id)` per professional so a relationship is never double-counted for the same profile.

`professional_relationships.status = 'accepted'` is the complete relationship decision. The party eligibility checks remain necessary because a suspended account or unpublished profile cannot contribute public evidence.

#### Valid anonymous search

Use reportable `search_events` rows that passed the search endpoint's input validation and completed professional matching. Repeated searches by the same keyed request subject count once inside 24 hours only when the normalized query and total result count are also unchanged. Require `city_code` for Joinville and `created_at` inside the selected period. Include matched and unmatched service queries because unmatched demand is part of the coverage denominator. This aggregate growth report never returns individual events or raw search text; the separately authorized six-month search-audit endpoint owns that operational view.

### 2.5 Associations used by the report

The intended associations are:

- `UserAccount has_one ProfessionalProfile, foreign_key: :owner_user_id`;
- `ProfessionalProfile has_many ProfessionalServices` and `has_many Services, through: :professional_services`;
- `ProfessionalProfile has_many ProfessionalServiceAreas`;
- `ProfessionalProfile has_many PortfolioItems`;
- `ProfessionalProfile has_many VerificationRequests`;
- `ProfessionalProfile has_many initiated_relationships` and `received_relationships`;
- `ProfessionalProfile has_many Quotes` and `ProfessionalDailyMetrics`;
- `ModerationAction` identifies a target through `target_type` and `target_id`;
- `ClientRecommendation belongs_to ClientRecommendationRequest, foreign_key: :request_id`;
- `Quote has_many QuoteItems`.

The report must use IDs and explicit associations. It must not infer identity from names, phone numbers, public slugs, or free text.

## 3. Data support required before implementation

### 3.1 Fields already required by stories but absent from the Feature Plan table sketches

The implementation stories already require these data points; migrations must make them explicit:

| Data                                        | Recommended implementation                                                                                         | Required by   |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ------------- |
| A search produced at least one profile open | `search_events.profile_opened boolean NOT NULL DEFAULT false`                                                      | S034–S035     |
| WhatsApp handoff source                     | `professional_daily_metrics.whatsapp_clicks_public_profile` and `whatsapp_clicks_search_result`, both non-negative | MVP S037      |
| Invite claimant                             | `professional_invites.invitee_professional_id`, nullable until claimed                                             | V2-011–V2-012 |
| Invite-created relationship                 | `professional_invites.professional_relationship_id`, nullable and unique                                           | V2-012        |
| Immutable request correlation               | `moderation_actions.request_id`                                                                                    | S023          |

Keep `professional_daily_metrics.whatsapp_clicks` for the Feature Plan total and enforce:

`whatsapp_clicks = whatsapp_clicks_public_profile + whatsapp_clicks_search_result`

If a third source is introduced later, either add it to the invariant or compute the total from source rows.

### 3.2 Minimal report-specific additions

#### First publication timestamp

Add `professional_profiles.published_at timestamptz`, set only on the first successful profile publication transaction. It supports publication flows and publication cohorts without interpreting later `updated_at` values.

It is possible to derive this from the earliest profile `moderation_actions.action = 'approved'`, but a dedicated immutable timestamp is safer and cheaper. Later revision approvals, restoration, or suspension must not overwrite it.

#### Meaningful professional activity aggregate

Add a privacy-safe daily aggregate rather than an external analytics provider:

`professional_daily_activities`

| Field                       | Type        | Rule                                                           |
| --------------------------- | ----------- | -------------------------------------------------------------- |
| `professional_id`           | UUID FK     | Required                                                       |
| `activity_date`             | local date  | Required                                                       |
| `profile_updates`           | integer     | Non-negative                                                   |
| `evidence_creations`        | integer     | Non-negative; portfolio item or recommendation request created |
| `relationship_interactions` | integer     | Non-negative; initiated, accepted, or declined                 |
| `quotes_created`            | integer     | Non-negative                                                   |
| `created_at`, `updated_at`  | timestamptz | Required                                                       |

Unique index: `(professional_id, activity_date)`.

Each domain transaction increments the applicable counter atomically. This table stores no visitor data and no free text. It prevents `professional_profiles.updated_at` from being misread as user activity when an admin moderation or system job touched the profile.

#### Search-to-contact journey

If the “Contato iniciado” stage remains inside the search funnel, add:

`search_events.whatsapp_handoff_occurred boolean NOT NULL DEFAULT false`

The first WhatsApp action carrying the anonymous, short-lived search-event context sets it to true. It stores no visitor identity, target profile list, message, or hiring outcome. Later clicks from the same search do not increase the search-level numerator.

Without this field, Berufe can show total WhatsApp handoffs and source counts from `professional_daily_metrics`, but cannot honestly calculate “searches that produced contact”. In that case the last stage must be removed from the search funnel.

#### Moderation submission time

Every moderation queue projection needs an immutable `submitted_at`. Existing records already provide it for recommendations and verification requests. Profiles/profile revisions and portfolio items need either an explicit `submitted_at` or a shared moderation-submission record. `updated_at` must not be used for queue age. Relationships are not queue targets; `responded_at` is used only for relationship funnel reporting.

### 3.3 Prototype-only data that must not be represented as real

The “Convidados” stage in the earlier prototype represented the manually mapped 30–50 founding professionals. The approved MVP has no recruiting/CRM table. `professional_invites` cannot be used: those rows are peer invitations to create a trust relationship, not administrator recruitment of the founding supply. The current MVP mock correctly starts at “Cadastrados”.

For MVP production, choose one of these options:

1. Recommended: start the measurable funnel at “Cadastrados” and show the 30–50 founding goal as a target line/configuration.
2. If pre-registration conversion becomes operationally essential, approve a separate admin onboarding-invitation story and a minimal tokenized table. Do not turn `professional_invites` into two different concepts.

Until option 2 is approved, the API must return the `invited` stage as unavailable or omit it. It must not return an externally maintained number as if it came from PostgreSQL.

## 4. Reporting stories

## R001 — Authorize and serve the aggregate growth report

**Story:** As an administrator, I want a single privacy-safe report endpoint so that I can monitor the MVP loop without access to visitor-level behavior or private customer content.

### API and implementation

- Endpoint: `GET /api/v1/admin/reports/growth?period=since_launch|last_30_days|last_7_days`.
- OpenAPI operation ID: `getAdminGrowthReport`. The contract defines the period enum, application-session security, aggregate response sections, shared error envelope, and `200`, `401`, `403`, and `422` responses. The exact-origin rule applies to mutations, not this `GET` operation.
- Rails owns all calculations and authorization. Nuxt only formats returned values.
- Require an authenticated `user_accounts.role = 'admin'`, `status = 'active'`, and the stronger admin authentication policy from the Infrastructure document.
- Return aggregates only. Never serialize individual `search_events`, phone numbers, client fingerprints, token hashes, moderation private notes, quote customer names, or WhatsApp content.
- Compute one `generated_at` timestamp and one period boundary pair per response so all widgets use the same snapshot.
- Keep query code in report/query objects such as `Admin::Reports::GrowthReport`, with a small object per section. Do not place cross-domain SQL in controllers.
- PostgreSQL is the source of truth. No external analytics provider is required.
- Nuxt consumes the generated operation types through the single `app/services/api/client.ts`; it does not maintain a parallel handwritten report response type.

### Response requirements

For every rate return `{ numerator, denominator, rate }`, where `rate` is `null` on a zero denominator. Return counts as integers and duration percentiles as decimal hours or integer minutes. The UI can round for display.

### Acceptance criteria

- Non-admin users receive `403`; unauthenticated users receive `401`.
- Invalid period keys receive `422` with the allowed values.
- All search information is aggregate-only.
- One response contains summary, supply, discovery, engagement, trust, quotes, and moderation sections.
- An empty database returns zeros and null rates without raising an exception.

**Depends on:** MVP S005–S009, S017, S034, S036–S037, S046, and S049–S051.

## R002 — Show the five-card growth scorecard

**Story:** As an administrator, I want five leading indicators at the top of the page so that I can detect whether supply, discovery, contact intent, and professional recurrence are moving together.

### Card 1 — Publicados no período

**Meaning:** Profiles that became publicly searchable for the first time inside the selected period.

**Goal:** Reach the initial 30–50 published professionals while maintaining distribution by service and neighborhood.

**Source and association:** `professional_profiles`, joined to `user_accounts` through `owner_user_id` for current eligibility details.

**Flow filter:**

- `professional_profiles.published_at >= period_start`;
- `professional_profiles.published_at < period_end`;
- production records only.

**Calculation:** `COUNT(DISTINCT professional_profiles.id)`.

The target progress detail should separately use the **current publicly eligible stock**, not the period flow:

`current_published / target_minimum`, with the target range configured as 30–50.

Do not filter historical first publications by current status when calculating the flow; a later suspension must not erase that a publication occurred. Show a separate current-stock value if the administrator needs to know how many profiles are searchable now.

**Data requirement:** `professional_profiles.published_at` from §3.2.

### Card 2 — Perfis ativados

**Meaning:** Newly published profiles in the selected period that currently satisfy all three transparent quality criteria: approved identity, at least three approved portfolio items, and at least two public professional relationships.

**Goal:** Increase the fraction of published profiles that provide enough visible trust evidence, without collapsing the criteria into an opaque score.

**Denominator:** profiles whose `published_at` is inside the selected period.

**Numerator:** denominator profiles for which all three `EXISTS`/count conditions in R004 are true at report generation time.

**Calculation:**

`activated_rate = activated_published_cohort / published_cohort`

This is a cohort outcome and can improve after the period ends as a professional adds evidence. The tooltip/UI must say “dos perfis publicados no período que hoje cumprem os critérios”. A separate current-stock activation rate is defined in R004.

### Card 3 — Buscas com resultado

**Meaning:** Valid anonymous searches in the period whose recorded `result_count` was at least one.

**Goal:** Move toward full search coverage and use recurring zero-result demand to guide recruitment or catalog decisions.

**Source:** `search_events`.

**Filters:** valid search scope from §2.4 and `created_at` inside the period.

**Calculation:**

- denominator: `COUNT(*)`;
- numerator: `COUNT(*) FILTER (WHERE result_count >= 1)`;
- rate: numerator / denominator.

Use the result count captured at search time. Do not recompute old searches against today's supply.

### Card 4 — Contatos iniciados

**Meaning:** Deduplicated WhatsApp handoff actions in the selected period, from a result card or public profile.

**Goal:** Verify that useful discovery produces observable contact intent.

**Source:** `professional_daily_metrics`.

**Filters:** `metric_date` inside the local date range. For the total, sum `whatsapp_clicks` across professionals.

**Calculations:**

- total handoffs: `SUM(whatsapp_clicks)`;
- profile-origin conversion: `SUM(whatsapp_clicks_public_profile) / SUM(profile_views)`;
- search-result handoffs: `SUM(whatsapp_clicks_search_result)`.

The mockup currently divides all handoffs by all profile views. That mixes result-card handoffs with profile-origin views and must be corrected. Use only `whatsapp_clicks_public_profile` in the profile-view conversion.

A handoff is an opportunity signal only. It is not a message delivered, response, hire, or payment.

### Card 5 — Profissionais recorrentes

**Meaning:** Published professionals with a meaningful action in the selected period whose first recorded meaningful action occurred before that action/date; a login alone does not count.

**Goal:** Increase useful weekly recurrence and W1/W4 retention, proving the product has value after initial profile publication.

**Source:** `professional_daily_activities`, joined to `professional_profiles` and `user_accounts`.

**Eligible denominator:** current publicly eligible professionals whose `published_at < period_end`.

**Meaningful activity condition:** the sum of the four counters for a date is greater than zero.

**Returning numerator:** distinct eligible professionals who:

1. have a meaningful activity date inside the selected period; and
2. have an earlier meaningful activity date before that in-period activity date.

This definition excludes the first-ever action but counts a professional who returns on another local date. Multiple actions on the same day do not by themselves make the professional recurring.

**Calculation:** `returning_professionals / eligible_professionals`.

### Change badge under each card

For `last_7_days` and `last_30_days`, calculate the badge against the immediately preceding equal-length window using the same formula and cohort semantics:

- published: current publication flow minus previous publication flow;
- activated: current publication-cohort activated count minus the previous publication-cohort activated count;
- search coverage: current result rate minus previous result rate, in percentage points;
- contacts: current handoff count minus previous handoff count;
- returning: current distinct returning count minus previous distinct returning count.

Do not show a percentage change when the previous count is zero. For `since_launch`, return milestone copy derived from explicit thresholds—for example first 10 published—or omit the badge. Milestones must be configuration/rules, not manually typed report data.

**Acceptance criteria for R002**

- Each card returns its numerator/denominator and metric type.
- The published target uses current stock while the headline published count uses period flow.
- Zero-denominator rates are null.
- Suspended professionals are excluded from current denominators but not erased from historical flows/cohorts.
- Contact conversion never treats a WhatsApp click as a completed job.

## R003 — Show the professional supply funnel

**Story:** As an administrator, I want to see where professionals stop between account creation and activation so that launch support addresses the actual bottleneck.

The measurable production funnel is cohort-based. Its denominator is professional profiles created during the selected period. Later stages show how many of that same cohort have reached each state by report generation time.

| Stage                 | Source and association                          | Condition                                                                                   | Calculation                           |
| --------------------- | ----------------------------------------------- | ------------------------------------------------------------------------------------------- | ------------------------------------- |
| Cadastrados           | `professional_profiles` → `user_accounts`       | profile `created_at` in period; account role `professional`; account not a seed/test record | Distinct profile IDs                  |
| Publicados            | cohort                                          | `published_at IS NOT NULL`                                                                  | Distinct cohort profile IDs           |
| Identidade verificada | published cohort → `verification_requests`      | at least one identity request currently `approved` with confirmed identity match            | Distinct published cohort profile IDs |
| Ativados              | cohort → verification, portfolio, relationships | all R004 criteria currently true                                                            | Distinct cohort profile IDs           |

“Cadastrado” means a successful professional registration that created the one draft profile required by S016. It is not merely an OTP challenge attempt.

The stages are monotonic for a cohort: registered ≥ published ≥ identity verified/activated. Identity verification and activation are outcomes within the published cohort; their order relative to one another is not implied.

### Founding target and prototype “Convidados” stage

- Render the target band of 30–50 as configuration, alongside current published stock.
- Omit “Convidados” until a distinct onboarding-invitation domain is approved.
- Never count peer `professional_invites` as founding recruitment.

### Optional conversion and time diagnostics

For each supported transition return `stage_count / cohort_registered_count`. Also return median elapsed time for:

- registration → first publication;
- first publication → activation.

Elapsed times require immutable milestone timestamps. Do not calculate them from mutable status or `updated_at`.

### Acceptance criteria

- All stages refer to the same registration cohort.
- The API identifies stages whose data support is unavailable.
- A profile whose current content is rejected remains in the historical “Publicados” milestone once first publication occurred, even if it is currently unavailable because no approved fallback exists.
- A later suspended profile remains in the historical cohort stages but is excluded from the separate current published stock.

**Depends on:** S016, S019–S024, S030, S046.

## R004 — Measure supply quality and activation

**Story:** As an administrator, I want transparent quality criteria for the currently published supply so that I can see which evidence gap prevents activation.

This widget is a current-stock snapshot and its denominator is the current publicly eligible professional scope from §2.4. The selected period may change the comparison/delta, but not the meaning of the current denominator.

### Identity verified

**Source:** `verification_requests` belonging to each published professional.

**Condition:** `verification_type = 'identity' AND status = 'approved'`.

**Calculation:** count distinct denominator professionals satisfying the condition. The rate is count / current published denominator.

### Three or more works

**Source:** `portfolio_items` belonging to each published professional.

**Condition:** `moderation_status = 'approved'`.

**Calculation:** profiles with `COUNT(DISTINCT portfolio_items.id) >= 3`, divided by current published denominator.

Pending, rejected, and hidden portfolio items do not count. The twelve-item upload cap does not alter this threshold.

### Two or more relationships

**Source:** `professional_relationships` through both initiator and recipient associations, plus both parties' accounts/profiles.

**Condition:** public relationship scope from §2.4.

**Calculation:** profiles with at least two distinct public relationship IDs, divided by current published denominator.

Client recommendations do not count toward this criterion; they are shown separately in the trust funnel.

### Activated profile

**Condition:** the same professional satisfies all three conditions above.

**Calculation:** intersection, not the minimum or sum, of the three sets:

`identity_verified_ids ∩ portfolio_ready_ids ∩ relationship_ready_ids`

`activation_rate = size(intersection) / current_published_count`

### Goal and interpretation

The initial goal is upward movement in every criterion and in their intersection. The administrator should address the lowest criterion first, but must not approve weak or fraudulent evidence merely to increase the rate.

### Acceptance criteria

- Each row returns `value`, `total`, and `rate`.
- The activated count never exceeds any individual criterion count.
- Hiding a portfolio item or relationship updates the current quality snapshot immediately.
- Pending profile revisions do not remove the previously approved public snapshot from the denominator.

**Depends on:** S024, S028, S030, S046.

## R005 — Measure the customer discovery journey

**Story:** As an administrator, I want to see the anonymous search journey from demand to contact so that I can separate lack of supply, weak choice, weak profile interest, and weak handoff intent.

All funnel stages use the same set of valid `search_events` created in the selected period.

| Stage               | Field/association           | Condition          | Calculation                |
| ------------------- | --------------------------- | ------------------ | -------------------------- |
| Buscas realizadas   | `search_events`             | valid search scope | `COUNT(*)`                 |
| Com algum resultado | `result_count`              | `>= 1`             | count and count / searches |
| Com 3+ opções       | `result_count`              | `>= 3`             | count and count / searches |
| Com perfil aberto   | `profile_opened`            | `true`             | count and count / searches |
| Contato iniciado    | `whatsapp_handoff_occurred` | `true`             | count and count / searches |

The three-option stage indicates choice depth; it must use profiles returned at search time, not the current number of professionals in that category.

The profile-open boolean is set once for a search even if several result profiles are opened. The WhatsApp boolean follows the same search-level rule if the extension in §3.2 is approved.

### Additional discovery values

**Profile views:** sum `professional_daily_metrics.profile_views` for local dates in the period. This is a page-view aggregate and may be greater than searches with profile open because one search can open multiple profiles and profiles can be reached directly.

**Search-to-profile-open:** searches with `profile_opened = true` / all valid searches.

**Profile-to-WhatsApp:** `SUM(whatsapp_clicks_public_profile) / SUM(profile_views)` for the period.

**Result-to-WhatsApp:** if the search-level handoff boolean exists, searches with `whatsapp_handoff_occurred = true` / all valid searches. Otherwise show `SUM(whatsapp_clicks_search_result)` as a count only, without calling it a search conversion rate.

### Privacy constraints

- No visitor/user ID, IP-derived identity, fingerprint, or cross-session identifier.
- Short-lived context may carry only the search event token/ID needed for idempotent booleans.
- Do not record WhatsApp messages or whether the professional answered.
- Admin API exposes aggregates, never search-event rows.

### Acceptance criteria

- Each later search stage is less than or equal to total searches.
- Repeated profile opens/contact clicks for the same search do not increase search-level numerators.
- Daily professional counters continue to count deduplicated handoff actions for the professional dashboard.
- The full funnel hides its final stage when the required field is unavailable.

**Depends on:** MVP S033–S037.

## R006 — Show demand by service

**Story:** As an administrator, I want aggregate service demand so that recruitment focuses on the categories customers actually request.

### Source and associations

Use `search_events.service_id` joined to `services.id`, then to `service_categories` for grouping/display metadata.

### Filters

- valid search scope;
- `search_events.created_at` inside the selected period;
- `service_id IS NOT NULL` for the catalog-service ranking.

Do not filter historical events by the service's current active state. If a service was later deactivated, preserve its historical name and mark it inactive in the response.

### Calculation

Group by service ID, count events, order by:

1. search count descending;
2. localized service name ascending as a stable tie-breaker.

Return the top five for the chart and `other_count` for the remaining matched services. The chart value is number of searches, not unique people.

Unmatched normalized queries (`service_id IS NULL`) are not silently added to “Other”. They belong to the catalog-gap logic in R007.

### Goal and interpretation

Demand concentration determines where the first supply should be strongest. High demand alone is not success; compare it with result coverage and current searchable professionals for that service.

### Acceptance criteria

- One search contributes to at most one service bucket.
- The report does not expose query text or individual searches.
- Counts reconcile to matched searches: top buckets + other = searches with a matched service.

**Depends on:** S011–S014, S034.

## R007 — Identify growth-blocking service and neighborhood gaps

**Story:** As an administrator, I want recurring demand with little or no matching supply so that I can decide whether to recruit professionals or extend the service catalog.

### Demand source

Aggregate valid `search_events` inside the selected period by:

- `service_id` when matched;
- `neighborhood_code`, with null represented as all Joinville;
- for unmatched catalog demand, a safe server-side normalized query bucket.

### Historical search result condition

A gap candidate has `result_count < 3` at search time. Classify each demand event as:

- `zero_supply`: `result_count = 0`;
- `thin_supply`: `result_count BETWEEN 1 AND 2`.

This captures both complete failure and fragile choice.

### Current searchable supply

For a matched service/neighborhood pair, separately count current publicly eligible professionals by joining:

- `professional_services` with matching `service_id`;
- `professional_service_areas` where `neighborhood_code` matches the searched neighborhood or is null for all Joinville.

Use `COUNT(DISTINCT professional_profiles.id)`. This current supply value explains whether the historical gap has already been addressed; it must not replace the recorded `result_count` used to classify past searches.

### Priority calculation

For each bucket return:

- total searches;
- zero-result searches;
- thin-result searches;
- current searchable professionals;
- catalog status: `active`, `inactive`, or `outside_mvp`.

Recommended ordering:

1. zero-result searches descending;
2. total gap searches descending;
3. current supply ascending.

Only display buckets with at least 2 searches in a 7-day report or at least 3 searches in longer reports. Keep suppressed counts in the aggregate total but do not expose low-frequency unmatched text, reducing re-identification/sensitive-query risk.

### Unmatched catalog demand

When `service_id IS NULL`, the admin must receive only grouped, safely normalized terms that meet the minimum count threshold. Never return a one-off query. Mark these rows `outside_mvp`; the action is “avaliar catálogo”, not “recrutar agora”.

### Goal and interpretation

The zero-stage goal is to eliminate repeated zero-result demand in the approved catalog, then increase important searches to at least three options. A catalog gap and a recruitment gap are different operational decisions and must be labeled separately.

### Acceptance criteria

- A city-wide service area satisfies any Joinville neighborhood query for current supply.
- Suspended/unpublished profiles and inactive professional-service associations are excluded.
- Historical gap classification uses recorded result count.
- Low-frequency unmatched terms are suppressed.
- The UI never labels an outside-MVP service as an existing service with zero professionals.

**Depends on:** S012–S014, S033–S034.

## R008 — Show meaningful professional actions and frequency

**Story:** As an administrator, I want to know which published professionals generate value after onboarding so that logins are not mistaken for engagement.

### Source and denominator

Use `professional_daily_activities`, joined to the current publicly eligible professional scope. `eligible_professionals` is the count of current published professionals with `published_at < period_end`.

### Meaningful active professional

A professional is active in the period when at least one daily row inside the local date range has a positive meaningful counter.

`meaningful_actives = COUNT(DISTINCT professional_id)`

`meaningful_active_rate = meaningful_actives / eligible_professionals`

### Action bars

Each bar counts distinct professionals who performed that type at least once, not the number of raw actions:

| UI label             | Aggregate field             | Domain actions that increment it                                     |
| -------------------- | --------------------------- | -------------------------------------------------------------------- |
| Atualizou perfil     | `profile_updates`           | owner saves a material profile edit                                  |
| Criou evidência      | `evidence_creations`        | creates portfolio item or client recommendation request              |
| Interagiu com a rede | `relationship_interactions` | initiates a relationship/invite, accepts, or declines a relationship |
| Criou orçamento      | `quotes_created`            | successfully creates a quote draft                                   |

One professional can appear in multiple bars, so the bars must never be summed to derive active professionals.

### Recurring professionals

Use the definition from R002: at least one in-period meaningful action on a local date after the professional's first meaningful-action date. Return distinct professionals and rate over eligible professionals.

### Active-weeks distribution

For a stable frequency measure, use the trailing four complete/local reporting weeks ending at `period_end`, independent of whether the selector is 7 or 30 days. For each eligible professional count distinct local week starts with meaningful activity and bucket as:

- `0 weeks`;
- `1 week`;
- `2–3 weeks`;
- `4 weeks`.

If the report intentionally uses a different lookback, return it as `frequency_window` and update the labels; do not display “4 weeks” for a 7-day calculation.

### Goal and interpretation

The initial objective is to move professionals from zero or one active week toward repeated useful actions, especially quotes and new trust evidence. Activity growth should be read with cohort retention because total activity naturally rises when the published base rises.

### Acceptance criteria

- Authentication/login events never increment meaningful activity.
- Admin moderation does not count as a professional profile update.
- Domain update and daily aggregate increment occur transactionally or through an idempotent after-commit job.
- Replayed jobs cannot double-increment counters.
- Bars represent distinct professionals, and the endpoint states that explicitly.

**Depends on:** MVP S019, S027, S042–S043, S046, and S049; V2-008 and V2-011–V2-012 as implemented.

## R009 — Measure W1 and W4 publication-cohort retention

**Story:** As an administrator, I want retention by first-publication cohort so that I can tell whether new professionals find reasons to return after launch support ends.

### Cohort source

Use `professional_profiles.published_at`. Convert it to local date and group by Monday-starting local week.

`cohort_size` is the number of profiles first published in that week. Keep later-suspended profiles in the denominator so churn is not hidden.

### Retention windows

For a profile published at local date `D`:

- **W1 retained:** at least one meaningful daily activity on dates `D + 7` through `D + 13`, inclusive.
- **W4 retained:** at least one meaningful daily activity on dates `D + 28` through `D + 34`, inclusive.

This uses per-profile elapsed windows, even though rows are grouped into weekly cohorts. It avoids giving a Monday publication more opportunity than a Sunday publication.

`W1 = retained_in_w1 / cohort_size`

`W4 = retained_in_w4 / cohort_size`

If `period_end` has not passed the end of a retention window for every profile in the cohort, return that cell as `null`/immature. Do not treat immature profiles as not retained.

### Selection behavior

- `since_launch`: return all cohorts since launch, paginated or limited to the most recent 12 with an overall weighted total.
- `last_30_days` and `last_7_days`: select cohorts whose `published_at` falls in the period, but their W1/W4 cells may be immature.

### Goal and interpretation

W1 indicates whether onboarding leads to a second useful visit. W4 indicates whether trust and quote workflows become recurring utility. Always show `n/N`; a movement from 1/2 to 2/3 is useful context but not a stable percentage trend.

### Acceptance criteria

- Publication-day activity does not count as W1.
- Multiple activity rows count the professional once per retention window.
- Immature cells are null.
- Later suspension does not shrink the historical cohort.
- Time-zone boundary tests cover activity around midnight UTC/local time.

**Depends on:** `published_at`, `professional_daily_activities`, R008.

## R010 — Measure the existing-member relationship funnel

**Story:** As an administrator, I want to see response and acceptance outcomes for existing-member relationships so that I can improve the confirmation flow.

The launch row is a cohort funnel: “iniciadas” means created inside the selected period, while later columns show the current outcome of those same records. This avoids dividing unrelated period events.

### Client recommendations — conditional post-MVP row

**Started:** `client_recommendation_requests.created_at` inside the period.

**Completed:** started requests that have their unique associated `client_recommendation`, equivalently a successfully consumed request. Do not rely only on the request's current status if the associated record is missing.

**Approved:** completed recommendations with `moderation_status = 'approved'` at report generation time.

**Rates:** completed / started; approved / completed.

Expired, revoked, and still-open requests remain only in started. Rejected/hidden recommendations remain completed but not approved. A hidden recommendation can therefore reduce the current cohort approval rate.

### Existing-member relationships

**Started:** `professional_relationships.created_at` inside the period and not generated by a peer invite, if `professional_invite_id`/inverse association identifies the source.

**Completed:** started relationships with `responded_at IS NOT NULL`; this includes accepted and declined responses.

**Approved:** started relationships with `status = 'accepted'` that satisfy the party-eligibility portion of the public relationship scope from §2.4. “Approved” means approved by the recipient, not by an administrator.

**Rates:** responded / started; public approved / responded.

This makes decline visible as a completed flow outcome while keeping it out of public trust evidence.

### Invitations to unregistered professionals — conditional post-MVP row

**Started:** `professional_invites.created_at` inside the period.

**Completed:** started invitations with `status = 'accepted'` and a non-null `invitee_professional_id`, after the invitee's approved profile and relationship acceptance as defined by V2-012.

**Approved:** completed invitations whose linked `professional_relationship_id` satisfies the public relationship scope.

**Rates:** completed / started; public approved / completed.

Expired/revoked invitations remain in the started cohort but not completed. Invite claim and relationship links must be explicit fields; names or phone values are not safe join keys.

### Goal and interpretation

- Improve legitimate completion by making requests clear and easy to finish.
- Treat a rising expiry/open rate as a flow or follow-up problem.
- Do not maximize approval rate by pressuring recipients. Declines are legitimate user decisions, not automatically product failures.

### Acceptance criteria

- The visible MVP relationship stages always refer to the same created cohort.
- A declined relationship is completed but not approved.
- An accepted relationship is approved without admin review, but it is excluded from public evidence while either party is not publicly eligible.
- Client-recommendation or invitation rows are omitted entirely until their V2 transactions, associations, privacy rules, and tests are implemented.

**Depends on:** MVP S023, S042–S043, and S046. V2-008–V2-012 apply only if their optional rows are later approved.

## R011 — Measure recurring quote utility

**Story:** As an administrator, I want to know whether professionals create and actually attempt to share quotes so that Berufe validates weekly utility beyond public discovery.

The main quote widget is a creation-cohort funnel.

### Quotes created

**Source:** `quotes`.

**Filter:** `quotes.created_at` inside the selected period.

**Calculation:** `COUNT(DISTINCT quotes.id)`.

Draft and shared quotes both count because every quote begins as a draft. Quote items are not joined for this count.

### Quotes shared

**Source:** the same created quote cohort.

**Condition:** `quotes.status = 'shared' AND quotes.shared_at IS NOT NULL`.

**Calculation:** count distinct cohort quote IDs that reached shared state by report generation time.

`quote_share_rate = shared_quotes / created_quotes`

This is distinct from `professional_daily_metrics.quotes_shared`, which counts user-initiated share actions and can include re-shares. The widget's created→shared conversion must use unique `quotes`, while the daily metric may support a secondary “share actions” count.

### Unique creators

`COUNT(DISTINCT quotes.professional_id)` among quotes created in the period.

Only authenticated professional owners can create quotes. Current suspension does not erase historical creation activity.

### Repeat creators

Count distinct professionals with at least two distinct quotes created inside the selected period.

This is within-period repeated use, not lifetime recurrence. Name it “criadores com 2+ no período” in the tooltip. If product wants return behavior across periods, use `professional_daily_activities` and require quote activity on at least two local dates.

### Goal and interpretation

Increase unique creators, repeat creators, and the share conversion. A low share rate can indicate abandoned drafts or friction. A share action does not mean WhatsApp delivery, customer acceptance, payment, or completed service.

### Acceptance criteria

- A quote with ten items counts once.
- Re-sharing one quote does not increase unique shared quotes.
- First share sets `status` and `shared_at` atomically.
- Zero created quotes returns a null share rate.
- Private customer fields never appear in the report response.

**Depends on:** MVP S049–S051.

## R012 — Monitor moderation health

**Story:** As an administrator, I want current queue pressure and review-time distributions so that credible supply is not blocked by manual operations.

The moderation widget combines a current queue snapshot with decision flows inside the selected period. The API/UI must label this distinction.

### Shared moderation queue projection

Use the exact same query object as the admin moderation queue to prevent reporting drift. It should union pending work from:

| Target                         | Pending condition                                              | Submission timestamp                      |
| ------------------------------ | -------------------------------------------------------------- | ----------------------------------------- |
| Profile/profile revision/photo | pending-review revision/snapshot                               | immutable `submitted_at`                  |
| Portfolio item                 | `moderation_status = 'pending'`                                | `submitted_at` or initial submission time |
| Client recommendation          | `moderation_status = 'pending'`                                | `submitted_at`                            |
| Professional relationship      | `status = 'accepted'` and no effective approve/reject decision | `responded_at`                            |
| Verification request           | `status = 'pending'`                                           | `submitted_at`                            |

Content reports are triage work but should be returned separately from evidence moderation unless the product intentionally includes them in the same queue.

### Pendentes

**Metric type:** current stock.

**Calculation:** count items in the shared pending projection at `generated_at`.

### Mais antigo

**Metric type:** current stock.

**Calculation:** `(generated_at - MIN(submitted_at))` across the pending projection, expressed in hours. Return null when no item is pending.

The launch operational goal is no moderation item older than 24 hours. This is an operating threshold, not a promise to end users unless separately published as an SLA.

### Tempo mediano and P90 de análise

**Metric type:** decision flow.

Use `moderation_actions` whose `created_at` is inside the selected period and whose action is an initial decision: `approved` or `rejected`. Exclude `hidden` and `restored` because they are later safety/lifecycle actions.

Join each action to the target's immutable submission timestamp and compute review duration:

`decision_at - submitted_at`

Use PostgreSQL `percentile_cont(0.5)` for median and `percentile_cont(0.9)` for P90. If a target was resubmitted, associate the action with the relevant submission/version, not the first-ever submission. This is easiest with a first-class moderation submission/revision identifier on `moderation_actions`.

### Approval and rejection

**Reviewed:** initial `approved` + `rejected` decisions created in the period.

**Rejected:** initial `rejected` decisions created in the period.

**Approved:** initial `approved` decisions created in the period.

`approval_rate = approved / reviewed`

Return counts by `target_type` as a drill-down aggregate. Do not interpret rejection as an error to minimize at all costs; spikes may indicate confusing upload requirements, abuse, or a supply-quality problem.

### Hidden content and conditional reports

The launch MVP returns hidden-content actions only:

- `hidden_actions`: `moderation_actions.action = 'hidden'` and `created_at` in period.

If V2-007 is later implemented, return `reports_created` and current-stock `open_reports` as separate fields and widgets. Never combine hidden actions and reports into one ambiguous count or display missing report records as zero.

### Goal and interpretation

Keep the oldest item under 24 hours and reduce median/P90 without weakening review. P90 is crucial because the median can look healthy while a few profiles remain blocked for days.

### Acceptance criteria

- Current pending/oldest values remain the same when changing only the period selector.
- Review-time and decision values follow the period selector.
- Restores/hides do not enter initial-decision duration or approval denominator.
- Targets without a reliable submission timestamp are reported as data-quality errors, not assigned a zero duration.
- Queue and report use the same pending projection.

**Depends on:** MVP S023–S024, S026, S028, S030, S046; V2-007 and V2-010 when implemented.

## R013 — Protect privacy and metric integrity

**Story:** As a product owner, I want metrics that are useful but privacy-minimal so that early growth measurement does not create tracking or trust debt.

### Rules

- Do not create a customer or visitor account for reporting.
- Do not add third-party analytics, cross-session IDs, advertising IDs, IP hashes, or device fingerprints.
- Search-level booleans are one-way journey facts on the anonymous event, not a visitor history.
- Daily professional aggregates contain counts and source, not customer identity.
- Never infer hires, completed services, revenue, or WhatsApp message delivery.
- Never expose client phone fingerprints, quote customer names, token hashes, verification documents, moderation notes, or report contact details in growth responses.
- Apply the S053 retention matrix to raw anonymous search events and retain longer-lived daily aggregates only for the approved period.
- Log report access with admin ID, request ID, period, and time, but not response payload or sensitive filters.

### Integrity constraints

- Non-negative checks on all aggregate counters.
- Unique `(professional_id, metric_date)` and `(professional_id, activity_date)` indexes.
- Idempotent marking of `search_events.profile_opened` and `whatsapp_handoff_occurred`.
- Domain transaction and aggregate increment must not diverge silently; use transactional increments where practical or idempotent jobs with reconciliation.
- A scheduled reconciliation can compare quote/activity domain counts and daily aggregates without storing new visitor identities.

### Acceptance criteria

- Serializer tests prove sensitive columns are absent.
- Authorization tests cover professional, admin, suspended, and anonymous callers.
- Replayed requests/jobs do not increase idempotent metrics twice.
- Data retention can delete raw anonymous events without breaking retained daily professional totals.

**Depends on:** MVP S034, S036–S037, S049–S053, and the reported MVP domains. V2 domains apply only to later optional rows.

## R014 — Validate formulas, performance, and zero-state behavior

**Story:** As the delivery team, we want deterministic report tests so that the administrator can trust small numbers and edge cases.

### Required backend tests

1. Period boundaries around local midnight and daylight/time-zone conversion.
2. Zero database and zero denominators.
3. Published flow versus current published stock.
4. Current activation intersection and hidden evidence removal.
5. Relationship counted for both parties but once per party.
6. Search result thresholds at 0, 1, 2, and 3.
7. First profile-open and first search-contact booleans are idempotent.
8. Source-aware WhatsApp totals and the total/source invariant.
9. Meaningful actions exclude logins and admin/system updates.
10. W1/W4 exact day windows and immature cohort cells.
11. The existing-member relationship funnel uses one creation cohort rather than unrelated event counts; later V2 funnels do the same if approved.
12. Quote creation cohort, unique sharing, creators, and repeat creators.
13. Moderation median/P90 with odd/even samples, resubmissions, and missing timestamps.
14. Hidden actions remain distinct; persisted content reports are tested separately only if V2-007 is implemented.
15. Suspended profiles are excluded from current public scopes but retained in historical cohorts.
16. Aggregate-only serializer and admin authorization.
17. `openapi_first` validates the report request plus `200`, `401`, `403`, and `422` responses against `apps/contracts/openapi.yaml`, and contract coverage includes `getAdminGrowthReport`.

### Required frontend tests

- Period selector requests the correct period key and handles loading/error/empty states.
- Null rates and immature retention cells render `—`.
- Tooltips match the metric definitions and explicitly distinguish count, conversion, and outcome limitations.
- The “Convidados” stage and search-contact conversion are hidden or marked unavailable when backend support is absent.
- Small-sample `n/N` remains visible on mobile.
- Current-stock moderation labels do not imply they are period flows.
- The component/API layer compiles against the generated `getAdminGrowthReport` types and normalizes the shared error envelope through `app/services/api/errors.ts`.

### Performance

For the initial 30–50-profile market, direct indexed PostgreSQL aggregate queries are sufficient. Add indexes for:

- `professional_profiles(published_at)` and `(profile_status)`;
- `verification_requests(professional_id, verification_type, status)`;
- `portfolio_items(professional_id, moderation_status)`;
- `professional_relationships(initiator_professional_id, status)` and `(recipient_professional_id, status)`;
- `search_events(created_at, service_id, neighborhood_code)`;
- `professional_daily_metrics(metric_date, professional_id)`;
- `professional_daily_activities(activity_date, professional_id)`;
- `quotes(created_at, professional_id)`;
- `moderation_actions(created_at, action, target_type)`;
- `content_reports(created_at, status)` only if V2-007 is implemented.

Do not add Redis, a warehouse, event streaming, or an external analytics/search platform for this report. Consider a short Rails cache only after measuring query latency, and never cache one admin's authorization context as shared public data.

## 5. Metric-to-table reference matrix

| Card/widget               | Primary tables                            | Supporting tables                                                                         | Metric type                | Additional support                                                     |
| ------------------------- | ----------------------------------------- | ----------------------------------------------------------------------------------------- | -------------------------- | ---------------------------------------------------------------------- |
| Publicados no período     | `professional_profiles`                   | `user_accounts`                                                                           | Flow                       | `published_at`                                                         |
| Perfis ativados           | `professional_profiles`                   | `verification_requests`, `portfolio_items`, `professional_relationships`, `user_accounts` | Cohort outcome             | `published_at`; accepted public-relationship query                     |
| Buscas com resultado      | `search_events`                           | `services`                                                                                | Flow                       | none beyond S034 fields                                                |
| Contatos iniciados        | `professional_daily_metrics`              | —                                                                                         | Flow                       | source counters from MVP S037                                          |
| Profissionais recorrentes | `professional_daily_activities`           | `professional_profiles`, `user_accounts`                                                  | Flow/current eligible base | new daily activity aggregate                                           |
| Funil de profissionais    | `professional_profiles`                   | `user_accounts`, `verification_requests`, evidence/relationship tables                    | Cohort outcome             | first submission and publication timestamps; no founding invite source |
| Qualidade da oferta       | `professional_profiles`                   | verification, moderated portfolio, accepted relationships, accounts                       | Current stock              | reusable public scopes                                                 |
| Cobertura da jornada      | `search_events`                           | `professional_daily_metrics`                                                              | Flow                       | `profile_opened`; optional search handoff boolean                      |
| Demanda por serviço       | `search_events`                           | `services`, `service_categories`                                                          | Flow                       | aggregate-only query                                                   |
| Gaps de crescimento       | `search_events`                           | services, professional services/areas/profiles/accounts                                   | Flow + current supply      | privacy threshold for unmatched terms                                  |
| Ações significativas      | `professional_daily_activities`           | domain tables for reconciliation                                                          | Flow                       | new daily activity aggregate                                           |
| Coortes W1/W4             | `professional_profiles`                   | `professional_daily_activities`                                                           | Cohort                     | `published_at`                                                         |
| Relações profissionais    | `professional_relationships`              | profiles/accounts                                                                         | Cohort outcome             | response timestamp and accepted public-relationship scope              |
| Orçamentos                | `quotes`                                  | `professional_daily_metrics`                                                              | Cohort outcome             | existing timestamps/status                                             |
| Saúde da moderação        | queue target tables, `moderation_actions` | `content_reports`                                                                         | Current stock + flow       | immutable/versioned submission time                                    |

## 6. Recommended delivery order

1. Confirm the implemented MVP domains; do not add fields for unapproved V2 domains merely to satisfy a report mockup.
2. Add `published_at` and the daily meaningful-activity aggregate.
3. Implement reusable public-eligibility, public-relationship, and moderation-queue queries.
4. Implement report period boundaries and the aggregate-only admin endpoint.
5. Add `getAdminGrowthReport` to OpenAPI, regenerate the committed Nuxt schema, and make its Rails request specs contract-conformant.
6. Deliver supply, activation, discovery, existing-member relationship, quote, meaningful-activity/retention, and moderation widgets from their implemented MVP records and aggregates.
7. Omit client-recommendation, external-invitation, persisted content-report, and professional-facing metric rows until their corresponding V2 transactions exist.
8. Remove the founding “Convidados” stage and search-contact funnel stage until their explicit data support is approved.
9. Run reconciliation fixtures and the empty/small-sample frontend states before replacing mock JSON with the API.

## 7. Definition of done

The reports feature is complete when:

- every visible number has the source, filter, period semantics, and denominator defined here;
- every report query is covered by boundary, lifecycle, and privacy tests;
- the OpenAPI operation, generated frontend types, Rails contract tests, and Nuxt consumer change together and CI reports no generated-file drift;
- no prototype-only value is shown as production data;
- public eligibility and moderation logic are shared with the product flows rather than reimplemented inconsistently;
- the report remains useful from zero records through the 30–50-professional founding target;
- administrators can understand each metric through the UI tooltip without being led to infer hires, revenue, message delivery, or a trust score;
- raw anonymous behavior and private business/customer data never leave the Rails aggregate boundary.
