# Berufe — Code vs. Documentation Review

**Reviewed range:** `de50e94e03df58f5c22b575b34a0edebe2eb8dd4..e5a75a6` (41 commits, S001–S051, Increments 0–5)
**Scope:** `apps/api`, `apps/web`, `apps/contracts`, `compose.yaml`, `.github/workflows`, `.env.example`
**Reference documents:** `docs/Berufe_MVP_Feature_Plan.md`, `docs/Berufe_MVP_Stories.md`, `docs/Berufe_MVP_Infrastructure_Architecture.md`

---

## Read this first

This document lists places where the **code does not match the product documentation**. It is not a
verdict on code quality (see `REVIEW_CODE.md`) or on vulnerabilities (see `REVIEW_SECURITY.md`).

Before the list of problems, the honest summary: **the implementation follows the specification
closely.** Almost every acceptance criterion in S001–S051 has real code and real tests behind it.
The database schema in particular is an unusually faithful translation of the Feature Plan's data
tables — UUID primary keys, `timestamptz`, foreign keys everywhere, and dozens of `CHECK`
constraints that encode business rules the documents only describe in prose. The 12 findings below
are the exceptions, not the rule.

If you are new to the project: the documentation is the **source of truth**. `docs/Berufe_MVP_Stories.md`
§2 says it explicitly — _"The Feature Plan is the product source of truth. The architecture may add
implementation detail, but it must not replace a Feature Plan behavior, scope boundary, data rule,
or user experience. Conflicts are resolved in favor of the Feature Plan."_ So when this document
says the code disagrees with the docs, the default assumption is that **the code must change**,
unless the team deliberately decides to amend the specification instead (D9 is such a case).

---

## Summary

| ID                                                                                                   | Finding                                                                 | Severity     | Primary file                                                           |
| ---------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- | ------------ | ---------------------------------------------------------------------- |
| [D1](#d1--the-administrator-growth-report-shows-invented-numbers)                                    | The administrator growth report shows invented numbers                  | **Critical** | `apps/web/app/components/admin/reports/GrowthReports.vue:3`            |
| [D2](#d2--a-shared-quote-link-can-never-be-revoked)                                                  | A shared quote link can never be revoked                                | **High**     | `apps/api/app/services/quote_share_token.rb:11`                        |
| [D3](#d3--approved-images-are-streamed-through-rails-instead-of-the-public-bucket)                   | Approved images are streamed through Rails instead of the public bucket | **High**     | `apps/api/app/services/public_profile_photo_image_url.rb`              |
| [D4](#d4--professional-relationships-have-no-hidden-state-visibility-is-inferred-from-the-audit-log) | Professional relationships have no `hidden` state                       | **Medium**   | `apps/api/app/models/professional_relationship.rb:5`                   |
| [D5](#d5--public-search-results-are-not-paginated)                                                   | Public search results are not paginated                                 | **Medium**   | `apps/api/app/queries/public_professional_search.rb:77`                |
| [D6](#d6--every-profile-edit-is-treated-as-a-material-edit)                                          | Every profile edit is treated as a "material" edit                      | **Medium**   | `apps/api/app/services/professional_profile_revision_editor.rb:32`     |
| [D7](#d7--the-professional-profile-editor-still-renders-prototype-fixture-data)                      | The professional profile editor still renders prototype fixture data    | **Medium**   | `apps/web/app/pages/app/professional/profile.vue:16`                   |
| [D8](#d8--the-openapi-contract-mixes-snake_case-and-camelcase)                                       | The OpenAPI contract mixes `snake_case` and `camelCase`                 | **Medium**   | `apps/contracts/openapi.yaml:2598` vs `:4600`                          |
| [D9](#d9--quote-decimal-precision-differs-from-the-feature-plan)                                     | Quote decimal precision differs from the Feature Plan                   | **Low**      | `apps/api/db/schema.rb:500`                                            |
| [D10](#d10--public-read-endpoints-send-cache-control-no-store)                                       | Public read endpoints send `Cache-Control: no-store`                    | **Low**      | `apps/api/app/controllers/api/v1/public_professionals_controller.rb:6` |
| [D11](#d11--claudemd-still-describes-the-deleted-prototype)                                          | `CLAUDE.md` still describes the deleted prototype                       | **Low**      | `CLAUDE.md`                                                            |
| [D12](#d12--known-gaps-tracked-for-the-launch-gate-not-defects)                                      | Known gaps tracked for the launch gate (not defects)                    | Info         | —                                                                      |

---

## D1 — The administrator growth report shows invented numbers

**Severity:** Critical
**Where:** `apps/web/app/components/admin/reports/GrowthReports.vue:3`, `apps/web/app/pages/app/admin/reports.vue`, `apps/web/app/components/AppHeader.vue:30`, `apps/web/data/reports.json`

### What the documentation expects

Feature Plan E3 §3:

> 1. An active administrator with a password-authenticated session selects since launch, 30 days, or 7 days.
> 2. **Rails calculates every metric from PostgreSQL** using one time-zone-aware report snapshot and returns aggregates only through one OpenAPI operation.

Infrastructure §18 (launch gate):

> the administrator report is restricted to password-authenticated admins, **uses the OpenAPI-generated client**, exposes aggregates only, suppresses low-frequency unmatched demand, and passes formula, period, zero-state, and privacy tests

### What the code does today

The report page is live, is linked from the admin navigation, and reads a checked-in JSON fixture:

```vue
// apps/web/app/components/admin/reports/GrowthReports.vue:3 import reportsData
from "@data/reports.json"; ... const reports = reportsData as GrowthReportsData;
const report = computed(() => reports.data[selectedPeriod.value]);
```

```ts
// apps/web/app/components/AppHeader.vue:30
{ label: "Relatórios", to: "/app/admin/reports" },
```

On the backend there is **no reports code at all** — no controller under
`apps/api/app/controllers/api/v1/admin/`, no query object, no serializer, and no
`getAdminGrowthReport` operation in `apps/contracts/openapi.yaml`. Increment 6 (R001–R014) has not
been implemented.

### Why it matters

An administrator opening "Relatórios" sees a complete, confident-looking dashboard — supply funnel,
search coverage, conversion, moderation health — and **every number is fabricated**. Nothing on the
page says so. The Feature Plan's entire justification for E3 is that these numbers drive launch
decisions:

> The MVP must learn whether it is building enough credible supply and whether discovery produces
> useful action.

Someone will make a real go/no-go decision on synthetic data. This is also a direct violation of the
project's own rule in `CLAUDE.md`: _"Everything in `data/*.json` and `public/images/` is synthetic.
Do not present it as real people, work, credentials, or endorsements."_

### How to fix it

Pick **one** of these. Option A is correct; Option B is the safe stopgap if Increment 6 is not
scheduled yet.

**Option A — implement Increment 6 (the specified fix).**

1. Read `docs/Berufe_Reports_Stories.md` R001–R014 for the exact metric definitions.
2. Add `apps/api/app/queries/admin_growth_report_query.rb` computing every metric with SQL
   aggregates over `professional_profiles`, `search_events`, `professional_daily_metrics`,
   `professional_daily_activities`, `professional_relationships`, `quotes`, and `moderation_actions`.
   Use `America/Sao_Paulo` for the period boundaries — `ProfessionalDailyMetric::PRODUCT_TIME_ZONE`
   already holds this constant.
3. Add `apps/api/app/serializers/admin_growth_report_serializer.rb` returning **aggregates only** —
   never a `search_events` row, never a quote's `customer_name`.
4. Add `Api::V1::Admin::GrowthReportsController < ModerationBaseController` (it already inherits
   `authenticate_password_admin_session!`), routed as
   `get "growth-report", to: "growth_reports#show"` inside the existing `namespace :admin`.
5. Add the `getAdminGrowthReport` operation to `apps/contracts/openapi.yaml`, then run
   `cd apps/web && pnpm api:generate` and commit the regenerated `app/services/api/schema.d.ts`.
6. Replace the `@data/reports.json` import with a typed call through `useApiClient()`, following the
   pattern in `apps/web/app/services/api/admin-moderation.ts`.
7. Delete `apps/web/data/reports.json`.

**Option B — make the placeholder honest (do this today if A is not scheduled).**

1. Remove the `{ label: "Relatórios", to: "/app/admin/reports" }` entry from
   `apps/web/app/components/AppHeader.vue:30`.
2. Add a permanent, unmissable banner at the top of `GrowthReports.vue`:
   `"Dados de demonstração. O relatório real será calculado pelo Rails no Incremento 6."`
3. Add a comment above the `@data/reports.json` import linking to this finding.

### How to verify

- **Option A:** an RSpec request spec proving anonymous and professional callers receive `403`, that
  the response contains no `customer_name`/`query_text_normalized` field, and that the period
  boundaries land on `America/Sao_Paulo` midnights. `bundle exec rspec` must pass OpenAPI contract
  coverage for the new operation, and `pnpm api:generate && git diff --exit-code app/services/api/schema.d.ts`
  must be clean.
- **Option B:** `grep -rn "reports.json" apps/web/app` returns exactly one hit, and that file renders
  the demo banner.

---

## D2 — A shared quote link can never be revoked

**Severity:** High
**Where:** `apps/api/app/services/quote_share_token.rb:11-19`, `apps/api/app/services/professional_quote_sharer.rb:22-36`, `apps/api/app/models/quote.rb:3`

### What the documentation expects

Infrastructure §5 (shared quote page):

> Rails hashes the supplied token, returns only the matching shared quote plus approved public
> professional identity, and returns the same generic not-found response for malformed, unknown, or
> **revoked** tokens.

Story S050:

> First share **generates a high-entropy token**, stores only its hash, and atomically changes status
> from `draft` to `shared`.
> Malformed, invalid, **revoked**, or unknown tokens reveal no quote or customer details.

Feature Plan D1 §3.5:

> First share atomically marks the quote shared, **creates a long unguessable bearer token** whose
> hash alone is stored […]

### What the code does today

The token is not random. It is a deterministic HMAC of the quote's own id:

```ruby
# apps/api/app/services/quote_share_token.rb:11
def self.issue(quote_id)
  digest = OpenSSL::HMAC.digest(
    "SHA256",
    signing_key,
    "quote_share_v1\0#{quote_id}"
  )
  "#{PREFIX}#{Base64.urlsafe_encode64(digest, padding: false)}"
end
```

`signing_key` is derived once from `SECRET_KEY_BASE` via `Rails.application.key_generator`, so for a
given quote the token is **the same value forever**. `ProfessionalQuoteSharer` re-derives it on every
share and refuses the operation if it does not match what is stored:

```ruby
# apps/api/app/services/professional_quote_sharer.rb:30
elsif quote.share_token_hash != token_digest
  raise Unavailable
end
```

`Quote::STATUSES` is `%w[draft shared]` and there is no transition back to `draft`, no
`share_token_hash = nil` anywhere, and no revoke route in `config/routes.rb`.

### Why it matters

"Revoked" appears in the specification three times, so a professional is expected to be able to kill
a link. Today they cannot. A quote link forwarded to the wrong WhatsApp group, or pasted into a
public chat, exposes the customer's name, the itemised prices, and the professional's notes
**permanently**, and support has no lever to pull. See `REVIEW_SECURITY.md` S1 for the additional
key-compromise consequence of the token being derived rather than random.

### How to fix it

1. Make the token random and per-share:

   ```ruby
   # apps/api/app/services/quote_share_token.rb
   def self.issue
     "#{PREFIX}#{SecureRandom.urlsafe_base64(32, false)}"
   end
   ```

   Delete `self.matches?` — it exists only to support the derived scheme. Keep `self.digest` (the
   keyed HMAC used for the stored `share_token_hash`) and keep `self.valid?` for the cheap format
   pre-check. Note `SecureRandom.urlsafe_base64(32, false)` produces 43 characters, which already
   matches `ENCODED_BYTES_LENGTH`, so `PATTERN` needs no change.

2. In `ProfessionalQuoteSharer#call`, issue a new token only on the `draft → shared` transition. When
   the quote is already `shared`, **reuse the stored digest** and rebuild the URL from a raw token you
   no longer have — which means you must return the raw token to the owner at share time and never
   again. The practical shape: keep the raw token in memory for the response only, and for re-shares
   of an already-shared quote either (a) return the same URL by storing an encrypted copy of the raw
   token alongside the digest, or (b) rotate — issue a fresh token, replace `share_token_hash`, and
   tell the owner in the UI that the previous link stopped working. **Option (b) is simpler and
   safer**; S051 says _"Sharing a previously shared quote reuses the active token"_, so if you choose
   (b) you must also amend S051. Discuss with the product owner before implementing.
3. Add revocation:
   - Route: `delete "share", on: :member` inside the existing `resources :quotes` block.
   - Service: `ProfessionalQuoteRevoker` setting `status: "draft"`, `share_token_hash: nil`,
     `shared_at: nil` inside `quote.with_lock`.
   - The existing DB constraint `quotes_consistent_share_state` already enforces that these three
     move together, so a partial revoke cannot be persisted.
   - Policy: reuse `QuotePolicy#share?` (owner only).
4. Add a "Revogar link" action to `apps/web/app/components/dashboard/QuoteBuilder.vue` with a
   confirmation, since it breaks a link the customer may already hold.

### How to verify

An RSpec spec that: shares a quote twice and asserts the second raw token differs from the first (or
matches, depending on the decision in step 2); revokes it; then asserts
`POST /api/v1/shared-quotes/resolve` with the old token returns the generic `404` envelope with no
`customer_name` in the body.

---

## D3 — Approved images are streamed through Rails instead of the public bucket

**Severity:** High
**Where:** `apps/api/app/services/public_profile_photo_image_url.rb`, `apps/api/app/services/public_portfolio_image_url.rb`, `apps/api/app/controllers/api/v1/public_profile_photos_controller.rb`, `apps/api/app/controllers/api/v1/public_portfolio_images_controller.rb`

### What the documentation expects

Infrastructure §10 defines two buckets:

| Bucket                 | Access          | Contents                                         |
| ---------------------- | --------------- | ------------------------------------------------ |
| `berufe-public-media`  | **Public read** | Approved profile and optimized portfolio images. |
| `berufe-private-media` | Private         | Pending uploads and verification evidence.       |

and step 6 of the storage flow:

> Approval creates the optimized public object for profile/portfolio media and **records its public
> URL/key on the approved projection**.

### What the code does today

Approval **does** write the object into the public bucket (`ModerationMediaPublisher#publish`), and
`public_key` **is** recorded on the record — that half is correct. But the URL handed to the browser
points back at Rails, not at R2:

```ruby
# apps/api/app/services/public_profile_photo_image_url.rb
def self.call(photo, environment: ENV)
  base_url = environment.fetch("API_PUBLIC_URL").delete_suffix("/")
  "#{base_url}/api/v1/public/profile-photos/#{photo.id}/image"
end
```

and the controller loads the whole image into Ruby memory and re-sends it on every request:

```ruby
# apps/api/app/controllers/api/v1/public_profile_photos_controller.rb:8
body = MediaStorage.build.read(scope: :public, key: photo.public_key)
send_data(body, type: photo.content_type, disposition: "inline", ...)
```

with `Cache-Control: public, max-age=0, must-revalidate` — meaning browsers revalidate every single
image on every page view.

### Why it matters

Every public profile page carries one profile photo plus up to 12 portfolio images. With this design,
one page view becomes up to 13 extra Rails requests, each doing a full R2 `GET` and buffering the
bytes in a Puma thread. The API is configured with `RAILS_MAX_THREADS=5`
(`lib/berufe/environment.rb` enforces it), so a handful of concurrent visitors can saturate the web
process with image proxying and starve the actual API. That directly threatens the launch gate in
Infrastructure §15:

> Public Rails API requests must meet p95 ≤ 500 ms and public HTML time-to-first-byte must meet
> p95 ≤ 1.5 seconds.

It also makes the public bucket pointless — you are paying for public-read storage and then not using
it.

### How to fix it

1. Add a public base URL for R2 to the environment contract. In `lib/berufe/environment.rb`, add
   `R2_PUBLIC_BASE_URL` to `R2_REQUIRED`, and add it to `.env.example` with a comment that it is the
   bucket's public development URL or the custom domain in front of it.
2. Change both URL builders to return the object URL directly:

   ```ruby
   # apps/api/app/services/public_profile_photo_image_url.rb
   def self.call(photo, environment: ENV)
     "#{environment.fetch("R2_PUBLIC_BASE_URL").delete_suffix("/")}/#{photo.public_key}"
   end
   ```

   Because `public_key` already contains a `SecureRandom.uuid` segment
   (`moderation/profile_photo/<id>/<uuid>.jpg`), the URL changes whenever the image is re-published,
   which gives you free cache-busting.

3. Keep the local-disk path working: when `media_storage_adapter == "local"`, keep returning the
   Rails route so `docker compose up` still shows images. A small branch on
   `Rails.configuration.x.berufe.environment.media_storage_adapter` inside the URL builders is enough.
4. Once step 3 is in place, restrict the two `public_*_images` routes to local storage the same way
   (see `REVIEW_SECURITY.md` S8 for the identical pattern on the upload route).
5. Set a long `Cache-Control` on the R2 objects at publish time in `ModerationMediaPublisher#publish`
   — `cache_control: "public, max-age=31536000, immutable"` is safe because the key is unique per
   publication.

### How to verify

`GET /api/v1/public/professionals/:slug` returns `photoUrl` and `portfolio[].imageUrl` values whose
host is the R2 public base URL, and hitting one of those URLs directly (unauthenticated) returns the
image. Re-run the existing `spec/serializers/public_professional_profile_serializer_spec.rb` after
updating its expectations.

---

## D4 — Professional relationships have no `hidden` state; visibility is inferred from the audit log

**Severity:** Medium
**Where:** `apps/api/app/models/professional_relationship.rb:5`, `apps/api/app/services/moderation_decision.rb` (`transition_relationship!`), `apps/api/app/services/professional_relationship_moderation_state.rb`, `apps/api/app/queries/public_professional_relationship_query.rb`

### What the documentation expects

Feature Plan C1 §4, `professional_relationship` table:

| Field    | Type | Rules                                           |
| -------- | ---- | ----------------------------------------------- |
| `status` | enum | `pending`, `accepted`, `declined`, **`hidden`** |

Infrastructure §13 (Rails development standards):

> Represent workflows with **explicit states** such as `draft`, `pending_review`, `approved`, and `rejected`.

### What the code does today

```ruby
# apps/api/app/models/professional_relationship.rb:5
STATUSES = %w[pending accepted declined].freeze
```

`hidden` is missing, and so is any notion of `approved`. The moderation handler writes **nothing** to
the relationship record:

```ruby
# apps/api/app/services/moderation_decision.rb
def transition_relationship!(relationship, attributes)
  raise Conflict, "professional relationship is not accepted" unless relationship.status == "accepted"

  latest_action = ProfessionalRelationshipModerationState.latest_action_for(relationship.id)
  allowed = case attributes[:action] ...
  raise Conflict, "..." unless allowed
end
```

It only validates the transition; the state itself lives in the `moderation_actions` audit table.
Every read then has to re-derive it. The public query does this with a correlated subquery:

```sql
-- apps/api/app/queries/public_professional_relationship_query.rb
(
  SELECT moderation_actions.action
  FROM moderation_actions
  WHERE moderation_actions.target_type = 'professional_relationship'
    AND moderation_actions.target_id = professional_relationships.id
  ORDER BY moderation_actions.created_at DESC, moderation_actions.id DESC
  LIMIT 1
) IN (?)
```

Every other moderated entity in the system (`ProfessionalProfileRevision`, `ProfessionalProfilePhoto`,
`PortfolioItem`, `VerificationRequest`) stores its state on the record. Relationships are the only
exception.

### Why it matters

Three concrete problems:

1. **The audit trail becomes load-bearing.** `moderation_actions` is meant to be an append-only
   record of _who decided what and when_. Here it is also the primary state store. Any future data
   cleanup, archival, or partitioning of that table silently changes which relationships are public.
2. **Performance.** The derivation runs as a `LIMIT 1` correlated subquery for every relationship on
   every public profile render and every search result card (see `REVIEW_CODE.md` C6).
3. **Two sources of truth.** `ProfessionalRelationshipModerationState.call` and
   `PublicProfessionalRelationshipQuery.latest_action_sql` implement the same rule twice — once in
   Ruby, once in SQL. They can drift.

### How to fix it

1. Migration: add a `moderation_status` column to `professional_relationships`, defaulting to
   `pending_review`, with a check constraint matching the other tables:

   ```ruby
   add_column :professional_relationships, :moderation_status, :text,
     null: false, default: "pending_review"
   add_check_constraint :professional_relationships,
     "moderation_status IN ('pending_review', 'approved', 'rejected', 'hidden')",
     name: "professional_relationships_known_moderation_status"
   add_index :professional_relationships, %i[status moderation_status]
   ```

   Backfill it from the existing `moderation_actions` using the same `latest action` rule, inside the
   migration, so no history is lost.

2. In `ModerationDecision#transition_relationship!`, keep the existing transition guards but now
   actually write the new value with `relationship.update!(moderation_status: ...)`, mapping
   `approved`/`restored` → `approved`, `rejected` → `rejected`, `hidden` → `hidden`.
3. Simplify `PublicProfessionalRelationshipQuery.call` to
   `.where(status: "accepted", moderation_status: "approved")`, keeping the two `party_is_public_sql`
   `EXISTS` clauses (those are still correct and necessary).
4. Delete `ProfessionalRelationshipModerationState` — `ModerationQueueQuery#professional_relationships`
   can read the column directly.
5. Update the Feature Plan C1 table to list the real states (`pending`, `accepted`, `declined` for
   the recipient response, plus the separate `moderation_status`), because the current single-enum
   design in the doc conflates two independent decisions.

### How to verify

`spec/queries/public_professional_relationship_query_spec.rb` must still pass unchanged — the public
result set is the contract, and the refactor must not alter it. Add a spec asserting that hiding an
approved relationship removes it from `PublicProfessionalRelationshipQuery.call` in the same request.

---

## D5 — Public search results are not paginated

**Severity:** Medium
**Where:** `apps/api/app/queries/public_professional_search.rb:77`, `apps/api/app/serializers/public_professional_search_serializer.rb`

### What the documentation expects

Infrastructure §5 (API contract):

> Use **pagination** and deterministic ordering for lists.

Story S006:

> Lists support deterministic ordering and pagination when needed.

### What the code does today

`matching_professionals` builds the relation with filters, eager loads, and a five-clause ordering —
but never a `LIMIT`:

```ruby
# apps/api/app/queries/public_professional_search.rb:77
def matching_professionals(service, neighborhood)
  relation = ProfessionalProfile.publicly_eligible
    .joins(published_revision: :professional_profile_services)
    .where(professional_profile_services: {service_id: service.id})
  relation = relation.where(coverage_sql, neighborhood.code) if neighborhood
  relation.includes(...).order(*ranking_order(neighborhood))
end
```

The serializer then maps the entire set, and the controller calls `result.professionals.length` to
record the search event. Every matching professional is loaded, serialized, and sent.

### Why it matters

At the launch target of 30–50 professionals this is genuinely fine, and the ordering _is_
deterministic (the final tie-breaker is `professional_profiles.id ASC`), so half the requirement is
met. The problem is that the response shape is now baked into the OpenAPI contract and into
`apps/web/app/composables/useProfessionalSearch.ts`. Adding pagination later is a breaking change to
a public endpoint; adding it now is a one-day task. Note also that `PublicProfessionalCardSerializer`
runs a per-card relationship count query (`REVIEW_CODE.md` C6), so an unbounded result set is also an
unbounded number of queries.

### How to fix it

1. Add `page` and `per_page` to the `postPublicProfessionalSearch` request schema in
   `apps/contracts/openapi.yaml`, with `per_page` defaulting to 20 and capped at 50 — the same limits
   `ModerationQueueQuery::MAX_PER_PAGE` already uses, so the codebase stays consistent.
2. Add a `meta` object (`page`, `per_page`, `total_count`, `total_pages`) to the response schema,
   matching the shape `ModerationQueueQuery#call` already returns.
3. In `PublicProfessionalSearch#call`, apply `.limit(per_page).offset((page - 1) * per_page)` and
   compute `total_count` with a separate `.count` on the unpaginated relation **before** the eager
   loads are applied.
4. Keep passing the full `result_count` to `PublicSearchEventRecorder` — the search event must record
   how many professionals matched, not how many were returned on page 1. This is what the
   `search_events.result_count` column means in Feature Plan B1.
5. Regenerate types (`pnpm api:generate`) and add "carregar mais" or numbered paging to
   `apps/web/app/pages/encontrar.vue`.

### How to verify

A request spec creating 25 matching professionals and asserting that page 1 returns 20 items,
`meta.total_count` is 25, and the recorded `SearchEvent#result_count` is 25 (not 20).

---

## D6 — Every profile edit is treated as a "material" edit

**Severity:** Medium
**Where:** `apps/api/app/services/professional_profile_revision_editor.rb:9,32`

### What the documentation expects

Feature Plan A2 §3.8:

> An approved profile becomes searchable. **A material edit** returns the profile to moderation; the
> founding-cohort operations team may assist when an urgent correction is required.

Story S022:

> Editing **material published content** creates or updates one private pending revision while the
> previous approved revision remains the complete public snapshot.

The word "material" is load-bearing in both documents — it implies edits exist that are _not_
material.

### What the code does today

`ProfessionalProfileRevisionEditor` is called from both `ProfessionalProfileIdentityUpdater` and
`ProfessionalProfileSupplyUpdater`, i.e. from every save on the profile form. For a published
profile it unconditionally produces a `pending_review` revision:

```ruby
# apps/api/app/services/professional_profile_revision_editor.rb:32
status: profile.published_revision ? "pending_review" : "draft",
submitted_at: profile.published_revision ? Time.current : nil
```

and a rejected revision is re-submitted on the next keystroke-save:

```ruby
# apps/api/app/services/professional_profile_revision_editor.rb:9
if revision.status == "rejected" && profile.published_revision
  revision.update!(status: "pending_review", submitted_at: Time.current, ...)
end
```

There is no comparison against the currently published values anywhere.

### Why it matters

A published professional who fixes a typo in their bio, or reorders their services, is pushed back
into the moderation queue. With 30–50 founding professionals and a manual review team, this
generates avoidable queue volume and an avoidable delay before the correction is public. It also
means the moderator cannot tell a real change from a no-op: `ModerationQueueQuery#profile_entry`
renders the generic string _"O perfil voltou para análise após uma alteração material."_ for both.

Worse, because saving is what triggers submission, a professional can be re-queued by an edit that
changes nothing at all — open the form, click save, back to `pending_review`.

### How to fix it

1. Define what "material" means, in code, next to the revision model. The public serializer already
   tells you: the fields that reach the public are `display_name`, `headline`, `bio`,
   `years_experience`, `whatsapp_e164`, `instagram_url`, `youtube_url`, plus the service and coverage
   selections. Add:

   ```ruby
   # apps/api/app/models/professional_profile_revision.rb
   MATERIAL_FIELDS = %i[
     display_name headline bio years_experience whatsapp_e164 instagram_url youtube_url
   ].freeze

   def material_snapshot
     attributes.symbolize_keys.slice(*MATERIAL_FIELDS).merge(
       services: professional_profile_services.map { |s| [s.service_id, s.is_primary, s.note] }.sort,
       areas: professional_profile_service_areas.map { |a| [a.city_code, a.neighborhood_code] }.sort
     )
   end
   ```

2. In `ProfessionalProfileRevisionEditor`, after applying the edit, compare
   `revision.material_snapshot` against `profile.published_revision.material_snapshot`. Only set
   `pending_review` / `submitted_at` when they differ; when they match, mark the working revision
   `approved` and leave the published pointer where it is.
3. Remove the automatic re-submission of a `rejected` revision at line 9. A rejected revision should
   stay privately editable until the professional explicitly submits — which is exactly what S022
   says: _"rejection […] returns the rejected revision to an editable private state."_ The existing
   `POST /api/v1/professional/profile/submission` endpoint is how they submit; wire the frontend
   "Enviar para análise" button to it for the rejected case.
4. Note the closely-related bug in `ProfessionalProfileSubmitter#validate_state!`: it requires
   `profile.profile_status == "draft"`, so a professional whose revision was rejected **while a
   published snapshot exists** (status stays `published`) cannot use the submission endpoint at all.
   Fix that guard at the same time — allow submission when the working revision is `draft` or
   `rejected`, regardless of the profile-level status.

### How to verify

A spec that saves a published profile with byte-identical values and asserts `profile_status` stays
`published` and no new `pending_review` revision exists; and a second spec that changes `bio` and
asserts a `pending_review` revision _is_ created while the published snapshot still serves the old bio
publicly.

---

## D7 — The professional profile editor still renders prototype fixture data

**Severity:** Medium
**Where:** `apps/web/app/pages/app/professional/profile.vue:3,16,51`

### What the documentation expects

`CLAUDE.md` (project convention):

> Everything in `data/*.json` and `public/images/` is **synthetic. Do not present it as real people,
> work, credentials, or endorsements.**

Story S021:

> The authenticated editor presents **the draft's public fields** and clearly marks declarations,
> pending evidence, and content that is not yet public.

### What the code does today

The page imports the prototype fixture and uses its first record as the base object, then overwrites
some fields with real workspace data:

```ts
// apps/web/app/pages/app/professional/profile.vue:3
import professionalsData from "@data/professionals.json";
// :16
const mockProfessional = (professionalsData as Professional[])[0]!;
// :51
const professional = computed<Professional>(() => ({
  ...mockProfessional,
  id: workspace.value!.profile.id,
  name: workspace.value!.profile.identity.name,
  ...
}));
```

Every `Professional` field **not** explicitly overridden after the spread — and the type carries
more than the ~18 that are — silently keeps the synthetic value from `professionals.json`.

### Why it matters

A real professional editing their profile sees another (invented) person's data mixed into their own.
Which fields leak depends entirely on which keys happen to be overridden below the spread, so it will
drift every time someone adds a field to the `Professional` type. It is also the exact pattern the
project convention forbids.

### How to fix it

1. Delete the `professionalsData` import and the `mockProfessional` constant.
2. Build the object explicitly from `workspace.value.profile`, with real empty-state defaults for
   anything the workspace does not provide:

   ```ts
   const professional = computed<Professional>(() => ({
     id: workspace.value!.profile.id,
     slug: workspace.value!.profile.publicSlug,
     name: workspace.value!.profile.identity.name,
     // ...every remaining field of Professional, explicitly
     avatar: workspace.value!.profile.photo.publishedImageUrl ?? "",
     portfolio: [],
   }));
   ```

   TypeScript strict mode will list every field you still owe once the spread is gone — let the
   compiler drive the work.

3. If some field genuinely has no backend source yet, that is a missing API field, not a reason to
   borrow a fixture. Add it to the workspace serializer and the contract.
4. Then confirm the fixture is fully unused: after D1 removes `reports.json`, the only remaining
   `@data/*` import should be none. `apps/web/data/professionals.json` is still legitimately used by
   `PublicDiscoveryDemoSeed` for local seeding, so keep the file — just stop importing it into pages.

### How to verify

`grep -rn "@data/" apps/web/app` returns no results. `pnpm typecheck` passes. A Vitest test mounting
the page with a stub workspace asserts no fixture value (e.g. the fixture's `headline` string) appears
in the rendered output.

---

## D8 — The OpenAPI contract mixes `snake_case` and `camelCase`

**Severity:** Medium
**Where:** `apps/contracts/openapi.yaml:2598` and `:2638` vs `:4600` and `:4749`

### What the documentation expects

Infrastructure §5:

> OpenAPI 3.1.0 in `apps/contracts/openapi.yaml` is the **source of truth** for the HTTP boundary.

Story S057 (launch gate):

> OpenAPI generation has a **clean diff**, Rails contract coverage […] passes

The documents do not mandate a casing style — but they do mandate one coherent contract, and a
contract that uses two conventions for the same concept is not coherent.

### What the code does today

Private, professional and admin schemas use `snake_case`:

```yaml
# apps/contracts/openapi.yaml:2598
display_name:
# :3222
public_slug:
```

Public discovery schemas use `camelCase`:

```yaml
# apps/contracts/openapi.yaml:4597
publicSlug:
# :4600
displayName:
```

This mirrors the serializers: `ProfessionalWorkspaceSerializer` and `ProfessionalQuoteSerializer`
emit `snake_case`; `PublicProfessionalProfileSerializer` and `PublicProfessionalCardSerializer` emit
`camelCase`.

### Why it matters

Frontend code has to remember which half of the API it is talking to. You can see the cost already in
`apps/web/app/pages/app/professional/profile.vue`, where `workspace.value.profile.identity.name`
(camel, hand-mapped) sits beside API fields named `display_name`. Every new consumer pays this tax,
and mixed-casing bugs are invisible to the type checker when a field is optional.

### How to fix it

This is a coordinated change across four artefacts — the definition of done in
`docs/Berufe_MVP_Stories.md` §3 requires exactly this:

> Every API change updates `apps/contracts/openapi.yaml`, regenerated Nuxt types, Rails contract
> tests, and the typed frontend consumer **in the same story**.

1. **Decide the convention and write it down.** Recommendation: `snake_case` everywhere. Rationale —
   it is what Rails produces naturally, it is what the majority of the existing contract already uses
   (roughly 4 of the 5 public schemas are the exception, not the rule), and the Feature Plan's data
   tables are all `snake_case`. Record the decision in `docs/Berufe_MVP_Infrastructure_Architecture.md`
   §5 so it is not re-argued.
2. Rewrite the five public serializers (`PublicProfessionalProfileSerializer`,
   `PublicProfessionalCardSerializer`, `PublicProfessionalSearchSerializer`,
   `PublicServiceSuggestionSerializer`, `SharedQuoteSerializer`) to emit the chosen casing.
3. Update the corresponding schemas in `apps/contracts/openapi.yaml`.
4. Run `cd apps/web && pnpm api:generate` and commit the regenerated `schema.d.ts`.
5. `pnpm typecheck` will now list every frontend site that needs updating — work through the errors.
6. `bundle exec rspec` will surface the serializer specs that need new expectations.

Do this **before** more consumers are written; the cost grows with every new page.

### How to verify

`pnpm api:generate && git diff --exit-code app/services/api/schema.d.ts` is clean, `pnpm typecheck`
passes, `bundle exec rspec` passes including OpenAPI contract coverage, and
`grep -nE "^        [a-z]+[A-Z]" apps/contracts/openapi.yaml` (or the inverse) returns nothing.

---

## D9 — Quote decimal precision differs from the Feature Plan

**Severity:** Low
**Where:** `apps/api/db/schema.rb:500-525`

### What the documentation expects

Feature Plan D1 §4:

| Table        | Field                             | Documented type |
| ------------ | --------------------------------- | --------------- |
| `quote`      | `discount_amount`, `total_amount` | `decimal(12,2)` |
| `quote_item` | `quantity`                        | `decimal(10,2)` |
| `quote_item` | `unit_price`, `line_total`        | `decimal(12,2)` |

### What the code does today

```ruby
# apps/api/db/schema.rb:500
t.decimal "line_total", precision: 14, scale: 2, null: false
t.decimal "quantity",   precision: 12, scale: 3, null: false
t.decimal "unit_price", precision: 14, scale: 2, null: false
# :516
t.decimal "discount_amount", precision: 14, scale: 2, default: "0.0", null: false
t.decimal "subtotal_amount", precision: 14, scale: 2, default: "0.0", null: false
t.decimal "total_amount",    precision: 14, scale: 2, default: "0.0", null: false
```

The schema also adds a `subtotal_amount` column the Feature Plan does not list.

### Why it matters

Functionally, nothing is wrong — the code's choices are _better_. `scale: 3` on `quantity` lets a
professional quote `1.5 m²` or `0.125 t`, which the documented `scale: 2` would round. Persisting
`subtotal_amount` is what makes the excellent `quotes_consistent_totals` check constraint possible:

```sql
discount_amount <= subtotal_amount AND total_amount = (subtotal_amount - discount_amount)
```

That constraint enforces Infrastructure §9's rule (_"browser totals are previews and are never trusted
for persistence"_) at the database level, which is stronger than anything the documentation asked for.

This is therefore a documentation bug, not a code bug. It is listed because an undocumented
divergence is still a divergence — the next person to read the Feature Plan will believe the wrong
thing.

### How to fix it

Update the two tables in `docs/Berufe_MVP_Feature_Plan.md` Feature D1 §4 to match the implementation:
`quantity decimal(12,3)`, money columns `decimal(14,2)`, and add the `subtotal_amount` row with the
note that it exists so the `quotes_consistent_totals` constraint can be enforced in PostgreSQL.

### How to verify

The Feature Plan tables and `db/schema.rb` agree. No code change.

---

## D10 — Public read endpoints send `Cache-Control: no-store`

**Severity:** Low
**Where:** `apps/api/app/controllers/api/v1/public_professionals_controller.rb:6`, `apps/api/app/controllers/api/v1/public_professional_searches_controller.rb:6`

### What the documentation expects

Infrastructure §5:

> Launch with fresh SSR and no Redis or separate cache for 30–50 profiles. […] If the latency budgets
> in §15 fail, block launch until a separate change adds a 60-second Nuxt/CDN stale-while-revalidate
> cache with explicit invalidation. **Private dashboard, admin, restricted-file, and token-authorized
> quote responses must never use a shared cache.**

The prohibition is scoped to private, admin, restricted-file and token-quote responses. Public
responses are explicitly the ones that may be cached, and §5 names an SWR policy as the planned
remedy if latency targets fail.

### What the code does today

```ruby
# apps/api/app/controllers/api/v1/public_professionals_controller.rb:6
before_action :prevent_caching
```

which sets `Cache-Control: no-store` on the public profile and public search responses.

### Why it matters

`no-store` forbids every cache, including the CDN layer that §5 designates as the escape hatch if the
p95 ≤ 500 ms target is missed. If the launch measurement fails, the fix the architecture already
approved cannot be applied without first finding and removing this line. It is a small thing that
closes a door the specification deliberately left open.

### How to fix it

1. Remove `before_action :prevent_caching` from `PublicProfessionalsController` and
   `PublicProfessionalSearchesController`.
2. Leave it in place everywhere else. Confirm with
   `grep -rn "prevent_caching" apps/api/app/controllers` that it still covers the session, admin,
   professional, OTP and media controllers — those are the ones §5 names.
3. `SharedQuotesController` correctly uses its own stronger `protect_bearer_response`
   (`private, no-store` + `no-referrer` + `X-Robots-Tag`) — do not touch it.
4. Note that `PublicProfessionalSearchesController` is a `POST` that records a `SearchEvent`, so it is
   not cacheable anyway; removing the header there is cosmetic. The one that matters is the profile
   `GET`.

### How to verify

`curl -I` against a public profile endpoint shows no `no-store`, while the same check against
`/api/v1/session` and `/api/v1/admin/moderation` still does.

---

## D11 — `CLAUDE.md` still describes the deleted prototype

**Severity:** Low
**Where:** `CLAUDE.md`

### What the documentation expects

`CLAUDE.md` is the onboarding contract for anyone (human or agent) working in this repository. Its
opening line: _"This file provides guidance […] when working with code in this repository."_

### What the code does today

It describes a repository that no longer exists. Concretely wrong statements:

| `CLAUDE.md` says                                                                                                                | Reality                                                                                                                       |
| ------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| "`apps/web/` — **The active codebase.** […] static interactive prototype"                                                       | `apps/api/` is a 175-file Rails backend; `apps/web` is one half of a monorepo                                                 |
| "**There is no backend.** Backend-shaped fixtures live in `apps/web/data/*.json` and are imported directly by pages/components" | There is a Rails API; two fixture imports remain and are bugs (D1, D7)                                                        |
| "There is no root `package.json`"                                                                                               | Correct, but the reason changed — there is a root `compose.yaml` orchestrating four services                                  |
| "`npm run dev`", "`npm run check`"                                                                                              | The project uses **pnpm** (`packageManager: pnpm@10.34.5`); `npm` will produce a wrong lockfile                               |
| "`npm run generate` — static build into `.output/public`"                                                                       | The app is SSR now; `routeRules` set `prerender: false` on every public route                                                 |
| "`/orcamento/BERUFE-DEMO-1042` is prerendered"                                                                                  | The route is `/orcamento/[token]`, request-time only, resolved through the API                                                |
| "Every 'mutation' is local component/composable state; nothing persists"                                                        | Everything persists in PostgreSQL                                                                                             |
| "The sign-in flow accepts the fixed OTP `123456` (`usePhoneAuthFlow`)"                                                          | The fixed code now comes from `FAKE_SMS_OTP_CODE` in the **backend** `FakeSmsOtpClient`, and only in `local`/`test`/`preview` |
| "Adding a page requires adding its route to `nitro.prerender.routes`"                                                           | There is no `nitro.prerender.routes` block any more                                                                           |

### Why it matters

A new developer following `CLAUDE.md` runs `npm install` (corrupting the pnpm lockfile), looks for
business logic in `apps/web/app/composables/` (it is in `apps/api/app/services/`), and assumes
mutations are local state (they hit a real database). It is the single highest-leverage file to fix
because it is read first.

### How to fix it

Rewrite `CLAUDE.md` around the monorepo. At minimum:

1. **Repository layout** — `apps/api` (Rails 8.1 API-only), `apps/web` (Nuxt 4), `apps/contracts`
   (OpenAPI 3.1, source of truth), `docs/`, `compose.yaml`. Mark `full_mockups/`, `mockups/`,
   `qa-screenshots/`, `leads/` as out of scope.
2. **Commands** — `docker compose up --build` for the full stack; `cd apps/api && bundle exec rspec`,
   `bundle exec standardrb`, `bundle exec brakeman`; `cd apps/web && pnpm check`, `pnpm api:generate`.
   State clearly that the frontend uses **pnpm, not npm**.
3. **Architecture** — the Rails layering rules from Infrastructure §6 (controllers authenticate,
   authorize, validate shape and delegate; workflows live in service objects; serializers define what
   leaves the API; policies are explicit). This is the rule the codebase actually follows and it is
   nowhere in `CLAUDE.md`.
4. **The contract workflow** — any API change touches `openapi.yaml` + `pnpm api:generate` +
   Rails contract test + frontend consumer, in one change.
5. Keep the existing styling and Portuguese-copy conventions sections; those are still accurate and
   still followed.

### How to verify

A developer with no prior context can clone, run `docker compose up --build`, and reach a working
local stack using only `CLAUDE.md` and `README.md`.

---

## D12 — Known gaps tracked for the launch gate (not defects)

**Severity:** Info

These are **not** implementation errors — the corresponding stories are still `PENDING` in
`docs/Berufe_MVP_Stories.md`. They are listed so the launch gate in Infrastructure §18 has a single
place to check against.

| Area               | Documented requirement                                                                                 | Current state                                                                                                                                                      | Story       |
| ------------------ | ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------- |
| Error tracking     | Infra §15: Bugsnag for Rails, GoodJob, Nuxt browser and Nuxt SSR, error-only, with redaction callbacks | No Bugsnag gem, no Nuxt plugin, no redaction config. `BUGSNAG_API_KEY` is required at boot for `production` in `lib/berufe/environment.rb` but nothing consumes it | S052        |
| Admin reporting    | Feature Plan E3, Reports R001–R014                                                                     | Backend absent — see **D1**, which _is_ a defect because the UI ships anyway                                                                                       | Increment 6 |
| End-to-end tests   | Infra §14: five release-critical Playwright flows                                                      | Two spec files exist (`tests/e2e/public-flow.spec.ts`, `tests/e2e/increments-4-5.spec.ts`); the admin-approval and OTP-login flows are not yet separate            | S055        |
| Deployment         | Infra §14: isolated stable staging, mock-only previews, Render/Vercel config                           | No deployment manifests in the repository; `compose.yaml` covers local only                                                                                        | S054        |
| Privacy operations | Infra §9: retention matrix, correction/suspension/deletion procedures, Brazilian legal review          | `VerificationFileRetentionCleanupJob` implements the 30-day identity-evidence rule; the broader matrix and procedures are undocumented                             | S053        |
| Backups            | Infra §15: paid managed plan, verified retention, one completed restore test                           | Not applicable until S054                                                                                                                                          | S056        |

**Recommended action:** none of these blocks current development. Confirm each is on the Increment 7
board so none is discovered during the launch gate.

---

## Suggested order of work

1. **D1** — stop showing fabricated metrics to an administrator. Option B takes minutes.
2. **D7** — stop mixing fixture data into a real professional's editor.
3. **D2** — add quote-link revocation (do this together with `REVIEW_SECURITY.md` S1; they are one change).
4. **D3** — serve approved media from R2 before the latency gate is measured.
5. **D11** — fix `CLAUDE.md` so the next person starts from the truth.
6. **D8**, **D5**, **D4**, **D6** — contract and workflow corrections, cheapest while consumers are few.
7. **D9**, **D10** — small corrections.
