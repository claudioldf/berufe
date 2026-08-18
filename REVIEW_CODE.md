# Berufe — Code Quality Review

**Reviewed range:** `de50e94e03df58f5c22b575b34a0edebe2eb8dd4..e5a75a6` (41 commits, S001–S051)
**Scope:** `apps/api` (Rails 8.1 API-only), `apps/web` (Nuxt 4 / Vue 3), `apps/contracts`, CI and Compose
**Guidelines applied:** Standard Ruby, the Rails layering rules in `docs/Berufe_MVP_Infrastructure_Architecture.md` §6, the Nuxt/Vue rules in §7 and §13, and SOLID

---

## Read this first

**This is a good codebase.** Before the criticism, the things that are genuinely well done, because
they set the bar the findings are measured against:

- **The database schema is excellent.** `apps/api/db/schema.rb` has UUID primary keys throughout,
  UTC `timestamptz`, foreign keys on every relationship, and — unusually — around 90 `CHECK`
  constraints that encode business rules in PostgreSQL rather than only in Ruby. `quotes_consistent_totals`
  enforces `total_amount = subtotal_amount - discount_amount` at the database level;
  `user_accounts_role_credentials` makes it structurally impossible to store an admin without a
  password digest or a professional with an email; `idx_revision_services_one_primary` is a partial
  unique index on `WHERE is_primary` so "exactly one primary service" cannot be violated by a race.
  The `professional_profile_service_areas` table has _two_ partial unique indexes so the nullable
  "all Joinville" row cannot be duplicated through `NULL` semantics — which is precisely what
  story S020 asked for.
- **Service objects are consistently designed.** They take keyword arguments, accept collaborators
  through the constructor for testing (`MediaUploadProcessor.new(inspector:)`,
  `PublicWhatsappHandoffRecorder.new(deduplicator:, metrics:, ...)`), return immutable
  `Data.define` results, and raise typed errors that carry `field_errors` straight to the shared
  error envelope. That is a real pattern applied uniformly, not an accident.
- **Concurrency is taken seriously.** `with_lock` / `lock!` around every multi-record transition,
  `insert_all(unique_by:)` for upsert-style counters, `update_all` with SQL increments so counters
  never lose a write, and `ActiveSupport::SecurityUtils.secure_compare` where it matters.
- **Test coverage is real.** 121 RSpec files across models, services, policies, queries, serializers,
  requests, jobs and constraints, with `openapi_first` contract validation wired into
  `spec/rails_helper.rb` and enforced in CI alongside Standard, Brakeman and a Zeitwerk eager-load
  check.

The 15 findings below are concentrated in two places: the moderation subsystem, which has grown into
two large classes that do too much, and a handful of small correctness/robustness gaps. None of them
suggest the architecture is wrong.

---

## Summary

| ID                                                                      | Finding                                                        | Severity | Primary file                                                                |
| ----------------------------------------------------------------------- | -------------------------------------------------------------- | -------- | --------------------------------------------------------------------------- |
| [C1](#c1--moderationqueuequery-paginates-in-ruby-not-in-sql)            | `ModerationQueueQuery` paginates in Ruby, not in SQL           | **High** | `apps/api/app/services/moderation_queue_query.rb:20-36`                     |
| [C4](#c4--object-storage-calls-run-inside-a-database-transaction)       | Object-storage calls run inside a database transaction         | **High** | `apps/api/app/services/moderation_decision.rb:28,123`                       |
| [C2](#c2--moderationqueuequery-is-a-god-class)                          | `ModerationQueueQuery` is a god class                          | Medium   | `apps/api/app/services/moderation_queue_query.rb`                           |
| [C3](#c3--moderationdecision-is-closed-to-extension-only-by-editing-it) | `ModerationDecision` is closed to extension only by editing it | Medium   | `apps/api/app/services/moderation_decision.rb:71-190`                       |
| [C5](#c5--saving-a-quote-destroys-and-recreates-every-line-item)        | Saving a quote destroys and recreates every line item          | Medium   | `apps/api/app/services/professional_quote_writer.rb:29`                     |
| [C6](#c6--n1-query-per-search-result-card)                              | N+1 query per search result card                               | Medium   | `apps/api/app/serializers/public_professional_card_serializer.rb:37`        |
| [C7](#c7--module-level-mutable-state-in-a-nuxt-composable)              | Module-level mutable state in a Nuxt composable                | Medium   | `apps/web/app/composables/useApplicationSession.ts:18`                      |
| [C8](#c8--the-api-client-forges-the-origin-header-during-ssr)           | The API client forges the `Origin` header during SSR           | Medium   | `apps/web/app/services/api/client.ts:39-42,64-66`                           |
| [C9](#c9--silent-rescue-argumenterror-hides-total-calculation-failures) | Silent `rescue ArgumentError` hides total-calculation failures | Medium   | `apps/api/app/models/quote.rb:57`                                           |
| [C10](#c10--infobipotpclient-does-not-rescue-tls-errors)                | `InfobipOtpClient` does not rescue TLS errors                  | Medium   | `apps/api/app/services/infobip_otp_client.rb:87`                            |
| [C11](#c11--coverage-cannot-be-updated-without-services)                | Coverage cannot be updated without services                    | Low      | `apps/api/app/controllers/api/v1/professional/profiles_controller.rb:23-27` |
| [C12](#c12--envfetch-at-request-time)                                   | `ENV.fetch` at request time                                    | Low      | `apps/api/app/controllers/api/v1/base_controller.rb:98`                     |
| [C13](#c13--a-public-serializer-filters-private-rows-in-ruby)           | A public serializer filters private rows in Ruby               | Low      | `apps/api/app/serializers/public_professional_profile_serializer.rb:81`     |
| [C14](#c14--response-headers-set-after-send_data)                       | Response headers set after `send_data`                         | Low      | `apps/api/app/controllers/api/v1/public_profile_photos_controller.rb:15`    |
| [C15](#c15--what-to-keep-doing)                                         | What to keep doing                                             | Info     | —                                                                           |

---

## C1 — `ModerationQueueQuery` paginates in Ruby, not in SQL

**Severity:** High
**Where:** `apps/api/app/services/moderation_queue_query.rb:20-36`, `:66-160`, `:271-299`

### What is wrong

The moderation queue accepts `page` and `per_page`, validates them carefully, and returns a correct
`meta` block — but the pagination happens **after every candidate row has already been loaded into
Ruby memory**:

```ruby
# apps/api/app/services/moderation_queue_query.rb:20
def call(type: "all", status: "pending_review", search: nil, page: 1, per_page: DEFAULT_PER_PAGE)
  filters = normalized_filters(...)
  entries = load_entries(filters[:type], filters[:status])
    .select { |entry| search_match?(entry, filters[:search]) }   # Ruby filter
    .sort_by { |entry| [entry.fetch(:submitted_at), entry.fetch(:target_id)] }  # Ruby sort

  total_count = entries.length
  offset = (filters[:page] - 1) * filters[:per_page]
  {
    items: entries.slice(offset, filters[:per_page]) || [],      # Ruby slice
    ...
```

`load_entries` calls five loaders and `flat_map`s them. None of them has a `LIMIT`:

```ruby
def profile_photos(status)
  scope = ProfessionalProfilePhoto.includes(professional_profile: :working_revision)
  scope = scope.where(status: moderated_statuses(status, ProfessionalProfilePhoto::STATUSES))
  scope.map { |photo| photo_entry(photo) }          # loads everything
end

def professional_relationships(status)
  relationships = ProfessionalRelationship
    .where(status: "accepted")
    .includes(initiator_professional: [...], recipient_professional: [...])
    .to_a                                            # loads everything
```

On top of that, `summary` (line 271) runs five `minimum` queries, five `count` queries, one
`ModerationAction` count and one `NOT IN` subquery — **on every single request**, including page 7 of
a filtered list.

### Why it matters

The cost of one request is proportional to the **total** amount of moderated content in the system,
not to the page size. With `status: "all"`, an admin requesting 20 items causes Rails to instantiate
every profile revision, every photo, every portfolio item, every verification request and every
accepted relationship — each with eager-loaded associations — build a Ruby hash for each, transliterate
strings for the search filter, sort the whole array, and then throw away everything except 20 entries.

At founding-cohort scale (30–50 professionals, maybe 600 moderated records) this is survivable. It
degrades quadratically with growth, and it is the kind of thing that is cheap to fix now and painful
to fix after the queue UI has been built around the response shape.

There is also a subtle correctness cost: because `summary` and the page query are computed from
separate reads, a decision made concurrently can make `meta.total_count` and `summary.pending_count`
disagree within one response.

### How to fix it

The clean fix is to make the queue a single SQL query. Because the five sources have different tables
but a common projection, `UNION ALL` is the natural tool.

1. Create a database view (through a migration) that projects each source into the common shape:

   ```sql
   CREATE VIEW moderation_queue_entries AS
     SELECT 'profile_revision' AS target_type,
            r.id               AS target_id,
            r.status           AS status,
            COALESCE(r.submitted_at, r.created_at) AS submitted_at,
            r.professional_profile_id
       FROM professional_profile_revisions r
      WHERE r.status IN ('pending_review','approved','rejected')
     UNION ALL
     SELECT 'profile_photo', p.id, p.status, p.submitted_at, p.professional_profile_id
       FROM professional_profile_photos p
     UNION ALL
     -- portfolio_items (WHERE deleted_at IS NULL), verification_requests,
     -- professional_relationships (see REVIEW_DOCS_MISMATCHES.md D4 first)
   ```

   Do **D4 first** — once relationships carry a `moderation_status` column, they fit this view
   naturally instead of needing a correlated subquery over `moderation_actions`.

2. Query the view with real SQL pagination:

   ```ruby
   entries = ModerationQueueEntry
     .where(filter_conditions)
     .order(:submitted_at, :target_id)
     .limit(per_page)
     .offset((page - 1) * per_page)
   total_count = ModerationQueueEntry.where(filter_conditions).count
   ```

3. Load the display data for **only the returned page** — group the 20 `target_id`s by `target_type`
   and issue one query per type (at most five queries, each with an `IN` list), then hydrate.

4. Move `summary` to its own endpoint (`GET /api/v1/admin/moderation/summary`) so the queue list does
   not pay for it, or compute it from the same view with one grouped query:
   `SELECT status, count(*), min(submitted_at) FROM moderation_queue_entries GROUP BY status`.

5. Move the search filter into SQL. The current `search_match?` transliterates a concatenation of
   `target_type`, `target_id`, `title`, `subtitle` and `status`. Replace it with an
   `unaccent(lower(...)) LIKE` predicate over the professional's display name plus the entry title —
   PostgreSQL's `unaccent` extension does what `I18n.transliterate` was doing.

If a view feels too heavy for now, the **minimum acceptable interim fix** is step 3's idea applied to
the existing code: give each loader `.order(...).limit(page * per_page)` so no loader can return more
rows than could possibly appear on the requested page. That caps memory without restructuring.

### How to verify

Add a spec that seeds 200 moderation targets, requests page 1 with `per_page: 20`, and asserts
(via `ActiveSupport::Notifications.subscribe("sql.active_record")` or the `db-query-matchers` gem)
that fewer than 10 queries run and that no query returns more than ~20 rows. The existing
`spec/services/moderation_queue_query_spec.rb` expectations for ordering and `meta` must keep passing
unchanged — the response contract is not what is being fixed.

---

## C2 — `ModerationQueueQuery` is a god class

**Severity:** Medium
**Where:** `apps/api/app/services/moderation_queue_query.rb` (300 lines)

### What is wrong

One class currently owns six unrelated responsibilities:

1. **Input validation** — `normalized_filters` (type, status, search length, page, per_page).
2. **Data access for five different entities** — `profile_revisions`, `profile_photos`,
   `portfolio_items`, `verification_requests`, `professional_relationships`.
3. **Presentation, in Portuguese** — every `*_entry` method builds user-facing copy:
   ```ruby
   title: "Perfil · #{revision.display_name}",
   details: "Primeiro perfil enviado para análise e publicação.",
   preview: "Imagem privada · acesso registrado na trilha de auditoria",
   ```
4. **Domain rules** — `coverage_label` re-derives "Toda Joinville", `supply_subtitle` picks the
   primary service; both duplicate logic that already exists in the public serializers.
5. **Search and pagination** (C1).
6. **Cross-entity aggregation** — `summary`, `pending_count`, `unreviewed_relationships`.

This violates the Single Responsibility Principle, and it violates the project's own layering rule in
Infrastructure §6:

> **Serializers define exactly what leaves the API.**

Here the query object defines what leaves the API. Nothing named `Serializer` is involved.

### Why it matters

Every change touches this file. Adding a sixth moderation target means editing five methods. Changing
Portuguese copy means editing a query object. Adding a filter means threading a parameter through
`call → normalized_filters → load_entries → five loaders`. Because it is one class, unit tests have to
set up all five entity graphs even to test one loader.

### How to fix it

Split along the responsibility seams. This pairs naturally with C1 — do them together.

1. **One source per entity**, behind a shared interface:

   ```ruby
   # apps/api/app/services/moderation_queue/sources/profile_revision.rb
   module ModerationQueue
     module Sources
       class ProfileRevision
         TARGET_TYPE = "profile_revision"

         def scope(status:) = ...          # returns a relation, never an array
         def hydrate(ids:)  = ...          # returns the records for one page
       end
     end
   end
   ```

   Register them: `SOURCES = [Sources::ProfileRevision, Sources::ProfilePhoto, ...]`. Adding a
   sixth target becomes adding one file plus one registry line — the Open/Closed Principle applied.

2. **One serializer for the entry copy**: `ModerationQueueEntrySerializer`, with a small subclass or
   `case` per target type, holding all the Portuguese strings. This puts the copy where the project's
   own layering rule says it belongs.

3. **Reuse existing domain helpers instead of re-deriving.** `coverage_label` and `supply_subtitle`
   duplicate logic in `PublicProfessionalProfileSerializer#as_json` and
   `ProfessionalWorkspaceSerializer#serialized_coverage`. Extract the shared rule once — a
   `ProfessionalProfileRevision#coverage_summary` method is the obvious home, since the revision owns
   the areas.

4. **Extract `ModerationQueueSummary`** as its own small object, behind its own endpoint (C1 step 4).

5. Leave `normalized_filters` in `ModerationQueueQuery` — validating and coercing its own input is
   legitimately that object's job.

Target shape: `ModerationQueueQuery` under 60 lines that validates filters, asks the sources for a
paginated set of ids, hydrates them, and hands them to a serializer.

### How to verify

`bundle exec standardrb` passes and existing `spec/services/moderation_queue_query_spec.rb`
expectations hold. Each new source gets a focused spec that no longer needs to seed the other four
entity graphs.

---

## C3 — `ModerationDecision` is closed to extension only by editing it

**Severity:** Medium
**Where:** `apps/api/app/services/moderation_decision.rb:71-190`

### What is wrong

The transition logic is a `case` on target type, where each branch is itself a `case` on action:

```ruby
# :71
def transition!(target:, target_type:, attributes:, public_keys_to_delete:, created_public_keys:)
  case target_type
  when "profile_revision"        then transition_revision!(target, attributes)
  when "profile_photo"           then transition_photo!(target, attributes, public_keys_to_delete, created_public_keys)
  when "portfolio_item"          then transition_portfolio!(target, attributes, public_keys_to_delete, created_public_keys)
  when "verification_request"    then transition_verification!(target, attributes)
  when "professional_relationship" then transition_relationship!(target, attributes)
  else raise ActiveRecord::RecordNotFound, "moderation target"
  end
end
```

Five branches × four actions = up to twenty paths in one 190-line class. Two of the five branches also
need extra out-parameters (`public_keys_to_delete`, `created_public_keys`) that the other three ignore
— a clear sign the abstraction is wrong: the method signature is shaped by its most complex case.

This is the classic Open/Closed Principle violation. A sixth moderation target requires editing
`transition!`, adding a private method, and extending `ModerationTargetResolver::MODELS` and
`ModerationAction`'s check constraint.

### Why it matters

Practically: the class is hard to read, hard to test in isolation (every spec needs the full
`ModerationDecision` setup), and the media-publishing complexity in two branches obscures the simple
state machines in the other three. It is also where C4 hides.

### How to fix it

Replace the `case` with a registry of small transition objects.

1. Define the interface:

   ```ruby
   # apps/api/app/services/moderation/transitions/base.rb
   module Moderation
     module Transitions
       class Base
         def initialize(publisher:) = @publisher = publisher

         # Returns a Result carrying the public keys created and the ones to delete
         # after the transaction commits.
         def call(target:, action:, reason:, note:, context:) = raise NotImplementedError
       end
     end
   end
   ```

2. One subclass per target: `Transitions::ProfileRevision`, `Transitions::ProfilePhoto`,
   `Transitions::PortfolioItem`, `Transitions::VerificationRequest`,
   `Transitions::ProfessionalRelationship`. Move the corresponding `transition_*!` body into each.
   Only the two media transitions ever touch `publisher`, so only they declare that dependency.

3. `ModerationDecision` becomes the orchestration shell it should be: normalize input, resolve the
   target, open the transaction, dispatch to
   `TRANSITIONS.fetch(target_type) { raise ActiveRecord::RecordNotFound }`, write the
   `ModerationAction`, and run post-commit media cleanup.

4. Keep `require_status!` and `Conflict` on the base class — every transition needs them.

5. Keep the `MODELS` map in `ModerationTargetResolver` as-is; it is already a clean registry and is a
   good template for what step 2 should look like.

### How to verify

`spec/services/moderation_decision_spec.rb` passes unchanged — the behaviour is identical, only the
structure moves. Each new transition class gets a focused spec.

---

## C4 — Object-storage calls run inside a database transaction

**Severity:** High
**Where:** `apps/api/app/services/moderation_decision.rb:28`, `:123`, `:142`, `:155`, `:167`, and `apps/api/app/services/moderation_media_publisher.rb`

### What is wrong

Approving a photo or a portfolio item copies the sanitized object from the private bucket to the
public bucket. That copy is a **network round trip to Cloudflare R2** — and it happens while a
PostgreSQL transaction is open and holding row locks:

```ruby
# apps/api/app/services/moderation_decision.rb:28
ApplicationRecord.transaction do
  target.lock!
  transition!(target:, target_type:, attributes: normalized, ...)
  ModerationAction.create!(...)
end
```

```ruby
# :118
def transition_photo!(photo, attributes, public_keys_to_delete, created_public_keys)
  profile = photo.professional_profile.lock!            # row lock held from here
  case attributes[:action]
  when "approved"
    public_key = publisher.publish(target: photo, target_type: "profile_photo")   # ← R2 GET + PUT
```

```ruby
# apps/api/app/services/moderation_media_publisher.rb
def publish(target:, target_type:)
  body = storage.read(scope: :private, key: target.private_key)     # R2 GET, up to 10 MiB
  storage.write(scope: :public, key: public_key, body:, content_type: target.content_type)  # R2 PUT
  public_key
end
```

### Why it matters

Three compounding problems:

1. **A database connection is held hostage by a third party.** The API runs with `DB_POOL=5`
   (enforced by `lib/berufe/environment.rb`). If R2 is slow, five concurrent approvals exhaust the
   pool and the entire API stops serving requests — not just moderation.
2. **Row locks are held across the same window.** `profile.lock!` blocks any concurrent write to that
   professional's profile for the duration of the R2 round trip. The professional editing their own
   profile at that moment simply hangs.
3. **The transaction can time out mid-copy.** The code already anticipates this — the
   `created_public_keys` array and `cleanup_created_public_keys` exist precisely to delete orphaned
   public objects when the transaction rolls back. That compensating logic is correct, but it is
   compensating for a problem that should not be created.

Note the code already does the _right_ thing for deletions: `public_keys_to_delete` is drained
**after** the transaction commits (line 33). Publishing should follow the same discipline.

### How to fix it

Move the network I/O outside the transaction boundary, keeping the compensating cleanup.

1. Split each media transition into a `prepare` phase (outside the transaction) and an `apply` phase
   (inside it):

   ```ruby
   def call(target_type:, target_id:, action:, reason: nil, note: nil)
     normalized = normalize(action:, reason:, note:)
     target = ModerationTargetResolver.new.call(target_type:, target_id:)

     # Phase 1 — outside the transaction. Network I/O only, no DB writes.
     prepared = prepare_media(target:, target_type:, action: normalized[:action])

     # Phase 2 — inside the transaction. DB writes only, no network.
     ApplicationRecord.transaction do
       target.lock!
       transition!(target:, target_type:, attributes: normalized, prepared:, ...)
       ModerationAction.create!(...)
     end

     # Phase 3 — after commit. Best-effort deletes.
     public_keys_to_delete.each { |key| publisher.delete(key) }
     target.reload
   rescue
     publisher.delete(prepared&.public_key)   # compensate for a prepared-but-unused object
     raise
   end
   ```

2. `prepare_media` returns `nil` for the three non-media target types and for non-publishing actions
   (`rejected`, `hidden`), so nothing changes for them.
3. The status pre-check must move into phase 1 too, so you do not copy 10 MiB for a target that is
   about to fail `require_status!`. Read the status optimistically before the copy; the authoritative
   `require_status!` inside the transaction still guards against the race, and if it fires, the
   `rescue` in step 1 deletes the orphan.
4. Once C3 is done, this becomes a two-method interface on `Transitions::ProfilePhoto` and
   `Transitions::PortfolioItem` (`#prepare` and `#apply`) — which is the real reason to do C3 first.

### How to verify

A spec injecting a `publisher` double that sleeps or raises, asserting that (a) no
`ActiveRecord::Base.connection` is checked out during the sleep, and (b) after a forced transaction
rollback, `publisher.delete` was called with the orphaned key. The existing
`spec/services/moderation_decision_spec.rb` must pass unchanged.

---

## C5 — Saving a quote destroys and recreates every line item

**Severity:** Medium
**Where:** `apps/api/app/services/professional_quote_writer.rb:29`

### What is wrong

Every update wipes the item collection and rebuilds it from scratch:

```ruby
# apps/api/app/services/professional_quote_writer.rb:26
raise ActiveRecord::RecordNotFound unless quote.professional_id == profile.id

quote.lock!
quote.quote_items.destroy_all           # ← every item deleted

quote.assign_attributes(attributes.slice(*QUOTE_FIELDS))
Array(attributes[:items]).each_with_index do |item_attributes, sort_order|
  quote.quote_items.build(...)          # ← rebuilt with fresh UUIDs
end
```

### Why it matters

1. **Item identity is destroyed on every save.** `ProfessionalQuoteSerializer` returns `item.id` to
   the frontend. After any save, every id the client holds is stale. It works today only because
   `useQuoteDraft` generates its own client-side ids with `crypto.randomUUID()` and never round-trips
   the server's — but that means the server ids in the API response are decorative, which is
   misleading to any future consumer.
2. **Write amplification.** Editing one word in one description issues `N` deletes and `N` inserts.
   Combined with the `quote.lock!`, that is a longer lock than necessary.
3. **It forecloses history.** The Feature Plan defers quote version history to V2, but destroying
   rows on every save makes even a simple `updated_at`-per-item audit impossible later.

### How to fix it

Diff instead of replace, keyed on a stable client-supplied identifier.

1. Add an optional `id` to the item schema in `apps/contracts/openapi.yaml` and to `ITEM_FIELDS`.
   The frontend already has a stable id per row (`useQuoteDraft#addItem`), so send it.
2. Replace the destroy/rebuild with a three-way diff:

   ```ruby
   incoming = Array(attributes[:items]).each_with_index.map do |item, sort_order|
     item.to_h.symbolize_keys.slice(*ITEM_FIELDS).merge(sort_order:)
   end
   existing = quote.quote_items.index_by(&:id)

   incoming.each do |item_attributes|
     id = item_attributes.delete(:id)
     if (record = existing.delete(id))
       record.assign_attributes(item_attributes)
     else
       quote.quote_items.build(item_attributes)
     end
   end
   existing.each_value(&:mark_for_destruction)
   ```

   `has_many ... autosave: true` is already declared on `Quote`, so `quote.save!` persists all three
   operations in one transaction and `mark_for_destruction` is honoured.

3. Watch the `sort_order` uniqueness constraint (`quote_items_sort_order` is unique per quote). When
   items are reordered, updating in place can transiently collide. The safe pattern is to null out
   `sort_order` for touched rows first, or to make the index deferrable:
   `ALTER TABLE quote_items ADD CONSTRAINT ... DEFERRABLE INITIALLY DEFERRED`. The deferrable
   constraint is cleaner and is what PostgreSQL is for.
4. While you are in this file: `next_quote_number` uses `MAX(quote_number) + 1` under `profile.lock!`.
   That is **correct** — the lock serializes it and the unique index is the backstop. No change needed;
   noted so nobody "fixes" it into a race.

### How to verify

A spec that creates a quote with three items, records their ids, updates one description, and asserts
all three ids are unchanged and only one row's `updated_at` moved. Add a reorder spec to prove the
`sort_order` handling in step 3.

---

## C6 — N+1 query per search result card

**Severity:** Medium
**Where:** `apps/api/app/serializers/public_professional_card_serializer.rb:37`

### What is wrong

Each result card counts the professional's public relationships with its own query:

```ruby
# apps/api/app/serializers/public_professional_card_serializer.rb:36
portfolioCount: profile.portfolio_items.count { |item| item.status == "approved" && item.deleted_at.nil? },
relationshipCount: PublicProfessionalRelationshipQuery.for_professional(profile.id).count,
```

Line 36 is fine — `portfolio_items` is eager-loaded by the search query, and `count { }` with a block
is Ruby's `Enumerable#count`, so it operates in memory.

Line 37 is not. `PublicProfessionalRelationshipQuery.for_professional` builds a query containing **two
correlated `EXISTS` subqueries** (one per relationship party, each joining `professional_profiles`,
`user_accounts` and `professional_profile_revisions`) **plus a correlated `LIMIT 1` sub-select** over
`moderation_actions`. That whole query runs once per card.

Combined with the missing pagination (`REVIEW_DOCS_MISMATCHES.md` D5), a search matching all 50
founding professionals issues 50 of these.

### Why it matters

It is the single most expensive thing on the most latency-sensitive page in the product — public
search is what Infrastructure §15's p95 ≤ 500 ms budget is measured against. It also scales with
result count, which is exactly the dimension that grows.

### How to fix it

1. Do `REVIEW_DOCS_MISMATCHES.md` D4 first. Once `professional_relationships` carries a
   `moderation_status` column, the correlated `moderation_actions` sub-select disappears and the query
   becomes a plain indexed filter.
2. Compute all counts in one grouped query, in the search/profile query layer, and pass the result
   into the serializer:

   ```ruby
   # apps/api/app/queries/public_professional_relationship_query.rb
   def self.counts_for(professional_ids)
     call
       .where(
         "initiator_professional_id IN (:ids) OR recipient_professional_id IN (:ids)",
         ids: professional_ids
       )
       .pluck(:initiator_professional_id, :recipient_professional_id)
       .flatten
       .tally
       .slice(*professional_ids)
   end
   ```

3. Change the serializer's constructor to accept the pre-computed value:

   ```ruby
   def initialize(profile, matching_service: nil, relationship_count: nil)
   ```

   and have `PublicProfessionalSearchSerializer` compute the map once for the whole page before
   mapping. Keep a lazy fallback (`relationship_count || PublicProfessionalRelationshipQuery.for_professional(profile.id).count`)
   so the serializer stays usable standalone in specs.

4. `PublicProfessionalProfileSerializer#public_relationships` has the same pattern but is called once
   per page render, so it is acceptable as-is.

### How to verify

A spec that seeds 20 published professionals with relationships, performs a search, and asserts the
number of `sql.active_record` notifications is constant regardless of result count.

---

## C7 — Module-level mutable state in a Nuxt composable

**Severity:** Medium
**Where:** `apps/web/app/composables/useApplicationSession.ts:18`

### What is wrong

The in-flight restoration promise is stored in a module-scope variable:

```ts
// apps/web/app/composables/useApplicationSession.ts:18
let restoration: Promise<boolean> | undefined;

export function useApplicationSession(...) {
  ...
  async function restoreSession(): Promise<boolean> {
    if (status.value === "authenticated") return true;
    if (status.value === "anonymous") return false;
    if (restoration) return restoration;        // ← shared across every caller
    ...
```

Everything else in this composable is done correctly — `account`, `session`, `status` and `isEnding`
all use `useState()`, which Nuxt scopes per request on the server. Only `restoration` escapes that
discipline.

### Why it matters

On the Nuxt **server**, a module-scope variable is shared by every concurrent request in that Node
process. If `restoreSession()` were ever called during SSR, request A's in-flight promise would be
returned to request B — meaning B would receive A's account and session in `useState`. That is a
cross-user session leak, and it is Nuxt's most-documented state pitfall.

**It is not exploitable today.** Every caller is client-only:

- `app/middleware/authenticated.global.ts:20` returns early when `typeof window === "undefined"`;
- `app/pages/profissionais/[slug].vue:147` calls it inside `onMounted`;
- `app/pages/app/**` runs under `routeRules` with `ssr: false`;
- `SessionLogoutButton.vue` destructures `logout`, which does not touch `restoration`.

So this is a latent hazard, not a live bug. It is rated Medium because the distance between "safe"
and "leaking authenticated sessions between strangers" is a single future `await restoreSession()`
placed outside `onMounted` — with no test or type error to catch it.

### How to fix it

Move the promise into request-scoped state, the same way the rest of the composable already does:

```ts
export function useApplicationSession(dependencies: ApplicationSessionDependencies = {}) {
  const restoration = useState<Promise<boolean> | undefined>(
    "application-session-restoration",
    () => undefined,
  );
  ...
  async function restoreSession(): Promise<boolean> {
    if (status.value === "authenticated") return true;
    if (status.value === "anonymous") return false;
    if (restoration.value) return restoration.value;

    status.value = "restoring";
    restoration.value = (async () => {
      try { ... } finally { restoration.value = undefined; }
    })();

    return restoration.value;
  }
```

`useState` is not meant to hold non-serializable values like promises, so if that causes payload
warnings, the alternative is `useNuxtApp()` with a symbol key:

```ts
const nuxtApp = useNuxtApp();
const KEY = "$berufeSessionRestoration";
if (nuxtApp[KEY]) return nuxtApp[KEY];
nuxtApp[KEY] = (async () => { ... })();
```

`nuxtApp` is created per request on the server, which is exactly the scoping needed.

Then add a guard so this cannot regress: a lint rule or a comment at the top of the file stating that
module-scope mutable state is forbidden in composables.

### How to verify

`apps/web/tests/unit/application-session-composable.test.ts` already exercises concurrent
`restoreSession()` calls — extend it to assert that two separate Nuxt app instances do not share the
in-flight promise.

---

## C8 — The API client forges the `Origin` header during SSR

**Severity:** Medium
**Where:** `apps/web/app/services/api/client.ts:39-42`, `:64-66`

### What is wrong

The shared API client sets its own `Origin` header on mutating requests when running on the server:

```ts
// apps/web/app/services/api/client.ts:38
if (options.origin && !["GET", "HEAD", "OPTIONS"].includes(request.method)) {
  request.headers.set("Origin", options.origin);
}
```

```ts
// :64
origin:
  import.meta.server && configuredSiteUrl
    ? new URL(configuredSiteUrl).origin
    : undefined,
```

On the Rails side, that header is the **entire** CSRF defence for state-changing requests:

```ruby
# apps/api/app/controllers/api/v1/base_controller.rb:97
def valid_request_origin?
  request.headers["Origin"] == ENV.fetch("WEB_ORIGIN")
end
```

Story S014 is explicit about why this works:

> Nuxt sends credentialed requests through the shared API client and **holds no token of its own; the
> browser supplies the `Origin` header, which page scripts cannot forge.**

The code makes the server forge exactly that header.

### Why it matters

**Today it is not exploitable**, and the reason is worth stating precisely: Node's `fetch` has no
cookie jar, so `credentials: "include"` does nothing on the server. SSR requests reach Rails
unauthenticated, so a forged `Origin` grants access to nothing.

The risk is structural. The moment anyone forwards the incoming browser cookie into an SSR API call —
a very natural thing to do when server-rendering an authenticated page — the forged `Origin` means
Rails' CSRF check passes unconditionally for that path. The control the architecture document relies
on would be silently disabled, and no test asserts otherwise.

Right now the header is also simply dead weight: the only SSR calls in the app are `GET`s
(`useCatalogs`, `useFeaturedProfessionals`, `profissionais/[slug].vue`) plus one `POST` — the shared
quote resolve — which is a public read modelled as a `POST`.

### How to fix it

1. Remove the `origin` option and the header-setting branch from `createApiClient`, and remove the
   `origin:` argument in `useApiClient()`.
2. That will break `POST /api/v1/shared-quotes/resolve` during SSR, because Rails treats every `POST`
   as state-changing. The correct fix is on the Rails side — it is a read operation and should not be
   subject to the origin check. Add an opt-out to the controller:

   ```ruby
   # apps/api/app/controllers/api/v1/shared_quotes_controller.rb
   skip_before_action :verify_request_origin!, raise: false
   ```

   This is safe: the endpoint mutates nothing, requires a bearer token, and returns the same generic
   404 for anything invalid. A CSRF control on a public read has no meaning.

3. If SSR ever genuinely needs to mutate, do **not** reinstate the forged header. Give the internal
   Nuxt-to-Rails hop a server-only shared secret (`NUXT_API_INTERNAL_TOKEN`, never in
   `runtimeConfig.public`) and have Rails accept it in place of the origin check for that one path.
4. Add a request spec asserting a `POST` with no `Origin` header is refused with
   `request_not_allowed`, so the control cannot be removed silently. `spec/requests/` already has
   origin coverage from S014 — extend it rather than starting fresh.

### How to verify

`apps/web/tests/unit/*-api.test.ts` still pass. A Rails request spec proves shared-quote resolution
works without an `Origin` header while every professional/admin mutation still refuses one.

---

## C9 — Silent `rescue ArgumentError` hides total-calculation failures

**Severity:** Medium
**Where:** `apps/api/app/models/quote.rb:46-58`, `apps/api/app/models/quote_item.rb:17-22`

### What is wrong

Both money calculations swallow `ArgumentError` and continue:

```ruby
# apps/api/app/models/quote.rb:46
def recalculate_totals
  subtotal = quote_items.sum do |item|
    item.recalculate_line_total
    item.line_total || 0
  end
  self.subtotal_amount = BigDecimal(subtotal.to_s).round(MONEY_SCALE, BigDecimal::ROUND_HALF_UP)
  self.discount_amount = BigDecimal(discount_amount.to_s.presence || "0").round(...)
  self.total_amount = [subtotal_amount - discount_amount, BigDecimal(0)].max
rescue ArgumentError
  # Numericality validations return the normalized field errors.
end
```

```ruby
# apps/api/app/models/quote_item.rb:17
def recalculate_line_total
  amount = BigDecimal(quantity.to_s) * BigDecimal(unit_price.to_s)
  self.line_total = amount.round(Quote::MONEY_SCALE, BigDecimal::ROUND_HALF_UP)
rescue ArgumentError
  self.line_total = nil
end
```

`BigDecimal("abc")` raises `ArgumentError`. The rescue is at **method** level, so the method aborts
wherever it raised. If `discount_amount` is unparseable, `subtotal_amount` has already been assigned
but `total_amount` retains whatever was loaded from the database.

### Why it matters

The comment is doing a lot of trust-based work. It is _currently_ right — the numericality validations
on `subtotal_amount`, `discount_amount` and `total_amount`, plus the `quotes_consistent_totals` check
constraint, mean an inconsistent record cannot be persisted. So there is no live data-corruption bug.

But money arithmetic that silently gives up is the wrong shape, for three reasons:

1. **The object is left in a half-updated state.** An in-memory `Quote` with a fresh `subtotal_amount`
   and a stale `total_amount` is observable by anything reading the object before validation runs
   (a serializer in a test, a callback, a future `before_save`).
2. **The safety net is three layers away.** The correctness of this method depends on validations
   defined elsewhere and a constraint defined in a migration. Remove or relax either and the silent
   rescue becomes silent corruption.
3. **It hides real errors.** `ArgumentError` from something other than `BigDecimal` — a bad
   `ROUND_HALF_UP` argument, a future refactor — is swallowed identically.

Infrastructure §9 is unambiguous about how much this matters:

> Calculate quote line totals, subtotal, discount, and total in Rails with decimal arithmetic;
> **browser totals are previews and are never trusted for persistence.**

Rails is the sole authority here, so its arithmetic should fail loudly.

### How to fix it

Validate the inputs before doing arithmetic, so the arithmetic cannot fail.

1. Add a coercion helper and use it in both models:

   ```ruby
   # apps/api/app/models/concerns/decimal_coercion.rb
   module DecimalCoercion
     extend ActiveSupport::Concern

     private

     def decimal_or_nil(value)
       BigDecimal(value.to_s)
     rescue ArgumentError, TypeError
       nil
     end
   end
   ```

2. In `QuoteItem#recalculate_line_total`, bail out **before** arithmetic and let the existing
   numericality validation report the field error:

   ```ruby
   def recalculate_line_total
     parsed_quantity = decimal_or_nil(quantity)
     parsed_price = decimal_or_nil(unit_price)
     return self.line_total = nil if parsed_quantity.nil? || parsed_price.nil?

     self.line_total = (parsed_quantity * parsed_price).round(Quote::MONEY_SCALE, BigDecimal::ROUND_HALF_UP)
   end
   ```

3. In `Quote#recalculate_totals`, do the same for `discount_amount`, and assign all three totals
   together or none of them, so the object is never half-updated. No `rescue` remains.
4. Replace the comment with one that states the invariant rather than excusing the rescue:
   `# Unparseable input leaves the totals nil; numericality validations surface the field error.`

### How to verify

A model spec asserting that `Quote.new(discount_amount: "abc", ...)` is invalid, that
`total_amount` is `nil` rather than a stale value, and that a valid quote still computes
`total = subtotal - discount` correctly with three-decimal quantities.

---

## C10 — `InfobipOtpClient` does not rescue TLS errors

**Severity:** Medium
**Where:** `apps/api/app/services/infobip_otp_client.rb:87`

### What is wrong

The HTTP wrapper rescues four network error families:

```ruby
# apps/api/app/services/infobip_otp_client.rb:87
rescue IOError, SocketError, SystemCallError, Timeout::Error
  log_outcome(event: "infobip_otp_request_failed", operation:)
  raise SmsOtp::ProviderUnavailable, "SMS OTP provider is unavailable"
end
```

`OpenSSL::SSL::SSLError` is not among them, and it does not inherit from any of them — its ancestry is
`OpenSSL::SSL::SSLError < OpenSSL::OpenSSLError < StandardError`. A certificate expiry, a handshake
failure, or a TLS-level connection reset therefore escapes this method untouched.

The controller's rescue chain does not catch it either:

```ruby
# apps/api/app/controllers/api/v1/otp_challenges_controller.rb
rescue SmsOtp::ProviderUnavailable, ActiveRecord::ActiveRecordError
  render_api_error(code: "otp_provider_unavailable", ..., status: :service_unavailable)
```

So the request becomes an unhandled `500`.

### Why it matters

Infrastructure §8 specifies the behaviour precisely:

> Provider outages block new challenge initiation and verification with a **safe `503`**, but existing
> Rails sessions continue until their own expiry or revocation.

and story S011 requires the tested outcome:

> Request/contract tests cover accepted, malformed phone, cooldown/daily rate limit with `Retry-After`,
> delivery rejection, **provider timeout/unavailability** […]

An expired Infobip certificate is one of the most likely real-world provider failures, and it is the
one case that produces a `500` with a stack trace instead of the specified `503` with a Portuguese
message. A `500` also means the OpenAPI contract test would fail, since `500` is presumably not a
documented response for that operation.

### How to fix it

1. Add the error class to the rescue:

   ```ruby
   require "openssl"   # add at the top with the other requires

   rescue IOError, SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError
   ```

2. Consider widening the net rather than enumerating: `Net::HTTP` can also surface
   `Net::OpenTimeout`, `Net::ReadTimeout` (both `Timeout::Error` descendants, already covered) and
   `EOFError` (an `IOError`, covered). With `OpenSSL::SSL::SSLError` added, the list is complete for
   `Net::HTTP`.
3. Confirm the same gap does not exist in `R2Storage`. It rescues nothing itself, but its callers
   (`MediaUploadProcessor#storage_error?`) classify by `error.class.name.start_with?("Aws::")`, which
   covers TLS failures because the AWS SDK wraps them. No change needed there.

### How to verify

A spec injecting an `http` double that raises `OpenSSL::SSL::SSLError`, asserting
`SmsOtp::ProviderUnavailable` is raised and that `POST /api/v1/auth/otp/challenges` returns `503` with
code `otp_provider_unavailable`.

---

## C11 — Coverage cannot be updated without services

**Severity:** Low
**Where:** `apps/api/app/controllers/api/v1/professional/profiles_controller.rb:23-27`

### What is wrong

The guard admits a request carrying only `coverage`, but the body then demands `services`:

```ruby
# apps/api/app/controllers/api/v1/professional/profiles_controller.rb:23
if params[:services].present? || params[:coverage].present?
  ProfessionalProfileSupplyUpdater.new.call(
    profile:,
    services: supply_params.require(:services),   # raises if absent
    coverage: supply_params.require(:coverage)    # raises if absent
  )
end
```

A `PATCH` with `coverage` and no `services` raises `ActionController::ParameterMissing`. That is
caught by `BaseController`'s `rescue_from` and surfaces as
`{"code": "validation_failed", "field_errors": {"services": ["é obrigatório"]}}` — a confusing error
for a request that never mentioned services.

### Why it matters

Low impact today, because `apps/web/app/components/dashboard/ProfileEditor.vue` always sends both.
But the API contract is now ambiguous: the guard says "either", the body says "both". Any other
consumer written against the contract hits a misleading error.

### How to fix it

Decide which contract you want and make both halves agree.

**Option A — both are required together (simplest, matches current behaviour).** Change the guard to
`if params[:services].present? && params[:coverage].present?` and mark both as required in the
`updateProfessionalProfile` request schema in `apps/contracts/openapi.yaml`. Document that supply is
replaced as a unit.

**Option B — each is independently updatable (better API).** Split
`ProfessionalProfileSupplyUpdater#call` so `services:` and `coverage:` are each optional, and only
replace the collection that was supplied. Note the validations interact: `validate_coverage!` rejects
"all Joinville plus specific neighbourhoods", so a partial update must re-validate against the stored
state, not just the incoming payload.

Recommendation: **Option A**. Supply is conceptually one edit, the frontend already treats it that
way, and Option B adds validation complexity for no current consumer.

### How to verify

A request spec sending only `coverage` receives the outcome the chosen option specifies — either a
clear `services is required` error (A) or a successful coverage-only update (B) — and the OpenAPI
contract test agrees.

---

## C12 — `ENV.fetch` at request time

**Severity:** Low
**Where:** `apps/api/app/controllers/api/v1/base_controller.rb:98`, `apps/api/app/services/professional_quote_sharer.rb:15`, and the same pattern in `PublicProfilePhotoImageUrl` / `PublicPortfolioImageUrl` / `MediaUploadAuthorizer`

### What is wrong

Configuration is read from the process environment on every request:

```ruby
# apps/api/app/controllers/api/v1/base_controller.rb:97
def valid_request_origin?
  request.headers["Origin"] == ENV.fetch("WEB_ORIGIN")
end
```

```ruby
# apps/api/app/services/professional_quote_sharer.rb:15
share_url = "#{ENV.fetch("WEB_ORIGIN").delete_suffix("/")}/orcamento/#{token}"
```

### Why it matters

Correctness is fine — `lib/berufe/environment.rb` lists `WEB_ORIGIN` in `COMMON_REQUIRED`, so a
missing value fails at boot, not at request time. The issues are stylistic and structural:

1. **Inconsistent with the project's own pattern.** This codebase already has a well-built config
   layer: `Rails.configuration.x.berufe.environment`, `.otp`, `.session_activity_write_interval_seconds`
   and `.public_interaction_cache` are all resolved once in initializers. `WEB_ORIGIN` and
   `API_PUBLIC_URL` are the exceptions.
2. **The value is normalized repeatedly.** `.delete_suffix("/")` appears in four separate files. If
   someone sets `WEB_ORIGIN` with a trailing slash, the origin comparison at
   `base_controller.rb:98` — which does _not_ strip it — fails while the URL builders succeed. That is
   a genuine latent bug: a trailing slash in configuration silently breaks every mutation with
   `request_not_allowed`.
3. **`ENV` is process-global mutable state**, which makes it awkward to stub in specs relative to
   `Rails.configuration.x`.

### How to fix it

1. Extend the existing initializer to resolve and normalize both URLs once:

   ```ruby
   # apps/api/config/initializers/berufe_environment.rb
   Rails.application.config.x.berufe.web_origin = ENV.fetch("WEB_ORIGIN").delete_suffix("/")
   Rails.application.config.x.berufe.api_public_url = ENV.fetch("API_PUBLIC_URL").delete_suffix("/")
   ```

2. Replace all call sites with `Rails.configuration.x.berufe.web_origin` /
   `.api_public_url`. That removes four duplicate `.delete_suffix("/")` calls and fixes the
   trailing-slash inconsistency in step 2 above as a side effect.
3. Add a boot-time validation in `Berufe::Environment.load!` that `WEB_ORIGIN` parses as an absolute
   `http`/`https` URI with no path, so a malformed value fails fast rather than silently rejecting
   every mutation.
4. `config/initializers/cors.rb` may keep its `ENV.fetch` — it runs once at boot and the middleware
   stack is built before `config.x` is a natural read.

### How to verify

`grep -rn 'ENV.fetch("WEB_ORIGIN")' apps/api/app` returns nothing. A request spec with a
trailing-slash `WEB_ORIGIN` still accepts a valid mutation.

---

## C13 — A public serializer filters private rows in Ruby

**Severity:** Low
**Where:** `apps/api/app/serializers/public_professional_profile_serializer.rb:79-97`

### What is wrong

The public portfolio is produced by loading **all** portfolio items and filtering in Ruby:

```ruby
# apps/api/app/serializers/public_professional_profile_serializer.rb:79
def public_portfolio
  profile.portfolio_items
    .select { |item| item.approved? && item.deleted_at.nil? && item.public_key.present? }
    .sort_by { |item| [-item.submitted_at.to_f, item.id] }
    .map { ... }
end
```

`PublicProfessionalProfileQuery` eager-loads `portfolio_items: :service` with no status filter, so
pending, rejected, hidden and soft-deleted items are all materialised in memory on a public request.

### Why it matters

The output is **correct** — nothing unapproved is serialized, and the filter is right. The concerns
are:

1. **Private rows enter a public code path.** Rejected items carry `rejection_reason`, which is
   explicitly private data (Feature Plan A3: _"Private; nullable"_). Having those objects in scope in
   the serializer that builds the public payload is one careless `map` away from a leak.
2. **A scope already exists.** `PortfolioItem.publicly_visible` (`active.where(status: "approved")`)
   is defined and used by `PublicPortfolioImagesController`. Not using it here means the "what is
   public" rule lives in two places.
3. **Wasted work** — up to 12 approved plus an unbounded number of rejected/hidden rows loaded per
   public profile render.

### How to fix it

1. Scope the eager load in the query rather than filtering in the serializer:

   ```ruby
   # apps/api/app/queries/public_professional_profile_query.rb
   .includes(:published_photo, :verification_requests, published_revision: {...})
   .preload(portfolio_items: :service)
   ```

   then replace the association access with an explicitly scoped one. The cleanest form is a dedicated
   association:

   ```ruby
   # apps/api/app/models/professional_profile.rb
   has_many :public_portfolio_items,
     -> { publicly_visible.where.not(public_key: nil).newest_first },
     class_name: "PortfolioItem",
     inverse_of: :professional_profile
   ```

   and eager-load `public_portfolio_items: :service` in the query.

2. The serializer then becomes `profile.public_portfolio_items.map { ... }` — no `select`, no
   `sort_by`, because the association scope already orders by `submitted_at DESC, id DESC`, which is
   exactly what story S027 requires (_"Approved items appear newest first, with ID as the
   deterministic tie-breaker"_).
3. Apply the same treatment to `PublicProfessionalCardSerializer#portfolioCount` — it can become
   `profile.public_portfolio_items.size` against the preloaded association.

### How to verify

`spec/serializers/public_professional_profile_serializer_spec.rb` passes unchanged. Add an assertion
that a profile with a rejected item never loads that row (via query instrumentation or by asserting
`profile.association(:public_portfolio_items).target` excludes it).

---

## C14 — Response headers set after `send_data`

**Severity:** Low
**Where:** `apps/api/app/controllers/api/v1/public_profile_photos_controller.rb:9-16`, `apps/api/app/controllers/api/v1/public_portfolio_images_controller.rb:15-22`

### What is wrong

Both image controllers render the body first, then set security headers:

```ruby
# apps/api/app/controllers/api/v1/public_profile_photos_controller.rb:9
send_data(
  body,
  type: photo.content_type,
  disposition: "inline",
  filename: "berufe-profile-photo-#{photo.id}.jpg"
)
response.set_header("Cache-Control", "public, max-age=0, must-revalidate")
response.set_header("X-Content-Type-Options", "nosniff")
```

The sibling controller that handles the _sensitive_ file does it correctly:

```ruby
# apps/api/app/controllers/api/v1/admin/verification_files_controller.rb:8
response.set_header("X-Content-Type-Options", "nosniff")
send_data(file.body, type: file.content_type, disposition: "inline", filename: file.filename)
```

### Why it matters

**It works today.** `send_data` assigns the response body and headers but does not commit the response;
Rack sends it only after the action returns, so the later `set_header` calls are applied.

But it reads as a bug to every reviewer, and it is fragile: switch to `send_data` with `stream: true`,
introduce `response.stream.write`, or add a Rack middleware that commits early, and `nosniff` silently
disappears from a route that serves user-uploaded bytes. `X-Content-Type-Options: nosniff` on a
user-upload endpoint is not decorative — it is what stops a browser from re-interpreting an image as
HTML. (The global `SecurityHeaders` middleware in `lib/security_headers.rb` also sets it on every
response, so there is defence in depth here; that is why this is Low and not higher.)

### How to fix it

Move both `set_header` calls above `send_data`, matching `Admin::VerificationFilesController`:

```ruby
def show
  photo = ProfessionalProfilePhoto.publicly_visible.find(params[:id])
  body = MediaStorage.build.read(scope: :public, key: photo.public_key)
  response.set_header("Cache-Control", "public, max-age=0, must-revalidate")
  response.set_header("X-Content-Type-Options", "nosniff")
  send_data(body, type: photo.content_type, disposition: "inline",
    filename: "berufe-profile-photo-#{photo.id}.jpg")
rescue Errno::ENOENT, Aws::S3::Errors::NoSuchKey
  raise ActiveRecord::RecordNotFound
end
```

Note that both routes disappear entirely in deployed environments once
`REVIEW_DOCS_MISMATCHES.md` D3 is implemented — but they remain the local-development path, so fix
them regardless.

### How to verify

A request spec asserting `X-Content-Type-Options: nosniff` and the expected `Cache-Control` on both
image responses.

---

## C15 — What to keep doing

**Severity:** Info

Recording these so a future refactor does not "clean up" something that is deliberate and correct.

**Database design**

- `apps/api/db/schema.rb` — ~90 `CHECK` constraints. Standouts: `quotes_consistent_totals`
  (server-calculated totals enforced in PostgreSQL), `quotes_consistent_share_state` (status,
  token hash and `shared_at` can only move together), `user_accounts_role_credentials` (structurally
  impossible to store a credential-less admin), `professional_daily_metrics_whatsapp_source_total`
  (the source counters must sum to the total), and request-id format constraints on every audit table.
- Partial unique indexes doing real work: `idx_revision_services_one_primary`
  (`WHERE is_primary`), and the pair on `professional_profile_service_areas` that closes the
  `NULL`-semantics hole story S020 called out by name.
- `on_delete: :cascade` used only where it is safe (`quote_items → quotes`), with
  `dependent: :restrict_with_exception` protecting every audit table from accidental deletion.

**Service layer**

- Constructor injection everywhere (`MediaUploadProcessor.new(inspector:)`,
  `PublicSearchEventRecorder.new(sanitizer:, token_issuer:)`), which is why the 121 specs can run
  without touching R2 or Infobip.
- `Data.define` result objects (`Result = Data.define(:quote, :share_url, :whatsapp_url)`) instead of
  hashes or multi-return arrays.
- A consistent typed-error convention: each service defines `Invalid` carrying `field_errors`, which
  the controller passes straight into the shared error envelope. This is why the controllers stay thin
  — exactly what Infrastructure §6 asks for.

**Security-adjacent craft** (detailed in `REVIEW_SECURITY.md` S11)

- `SessionSecurityDigest` / `OtpSecurityDigest` derive keys via `Rails.application.key_generator`
  rather than using raw `SECRET_KEY_BASE`, and HMAC rather than bare SHA-256, so a database dump does
  not yield usable tokens.
- `MediaUploadInspector` checks the magic bytes _before_ handing the buffer to libvips, and enforces
  the 25-megapixel limit on the lazily-loaded header _before_ encoding — the correct order for
  avoiding decompression bombs.
- `LocalDiskStorage#path_for` validates the scope, rejects absolute keys, `cleanpath`s, and then
  re-asserts the resolved path is under the scope root. That is a textbook traversal guard.
- `AdminPasswordAuthenticator::DUMMY_PASSWORD_DIGEST` equalises BCrypt timing for unknown emails.

**Frontend**

- `useState` for genuinely shared state, plain `shallowRef` for per-instance state — the distinction
  is applied consistently (C7 is the single exception).
- Every API call goes through `app/services/api/*.ts` against generated types; no component fetches
  directly. This is Infrastructure §7's rule, followed without exception.
- `routeRules` encode the caching and indexing policy declaratively, including the `no-store` +
  `noindex` + `no-referrer` triple on `/orcamento/**`.

**Tooling**

- CI runs Standard, Brakeman with `--exit-on-warn`, `zeitwerk:check`, RSpec with OpenAPI contract
  coverage, and `db:seed` verification — then the frontend's `api:generate` diff check, ESLint,
  Prettier, `nuxt typecheck`, Vitest and a production build. That is a genuinely strong gate.

---

## Suggested order of work

1. **C4** — get network I/O out of the database transaction. This is the one finding that can take
   the whole API down.
2. **C1** — bound the moderation queue's memory and query cost.
3. **C3** then **C2** — restructure the moderation subsystem. Doing C3 first makes C4's two-phase
   split natural and makes C1's source objects obvious.
4. **C7**, **C8** — close the two latent frontend hazards before someone builds on them.
5. **C10**, **C9** — small robustness fixes with clear tests.
6. **C6** — pairs with `REVIEW_DOCS_MISMATCHES.md` D4 and D5; do all three together.
7. **C5**, **C11**, **C12**, **C13**, **C14** — cleanups, any order.
