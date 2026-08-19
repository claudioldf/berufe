# Berufe — Security Review

**Reviewed range:** `de50e94e03df58f5c22b575b34a0edebe2eb8dd4..e5a75a6` (41 commits, S001–S051)
**Scope:** `apps/api`, `apps/web`, `apps/contracts`, `compose.yaml`, CI, `.env.example`
**Baseline:** `docs/Berufe_MVP_Infrastructure_Architecture.md` §8 (authentication and authorization), §9 (data rules and visibility), §10 (file storage), §12 (minimum security baseline), §18 (launch gate)

---

## Read this first

Berufe handles Brazilian phone numbers, government identity documents, and private customer quote
data. Infrastructure §12 says the baseline exists _"because Berufe handles phone numbers and identity
evidence."_ This review is measured against that bar.

**The security foundations are sound.** Session handling, OTP storage, password handling, media
sanitisation and the public/private data split are all implemented carefully and, in several places,
better than the specification required. Section [S11](#s11--controls-verified-as-correctly-implemented)
lists 15 controls verified as correct, and it is deliberately as detailed as the findings — those
controls are the reason the findings below are limited in blast radius.

The 10 findings are concentrated in three themes:

1. **Quote share links** — the bearer-token design is derived rather than random and cannot be
   revoked (S1, S10).
2. **Login and provisioning gaps** — a suspended professional still gets a cookie (S2), and the admin
   seed carries a published default password behind the wrong environment guard (S3).
3. **Unthrottled public write paths** — anonymous endpoints that create rows and increment the metrics
   the business will use to make launch decisions (S4, S5, S6).

No finding here is a remote code execution, an authentication bypass, or an unauthenticated read of
private data. The authorization model holds.

### Severity meanings

| Severity       | Meaning                                                                                                                       |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **Critical**   | Exposes private data of many users, or compromises authentication, if a plausible precondition occurs. Fix before real users. |
| **High**       | Exposes private data of one user, defeats a specified control, or creates a credential risk. Fix before launch.               |
| **Medium**     | Weakens a control, corrupts data the business relies on, or creates an availability risk. Fix before or shortly after launch. |
| **Low / Info** | Hardening, or a verified-correct control recorded for the launch gate.                                                        |

---

## Summary

| ID                                                                                                    | Finding                                                                                     | Severity     | Primary file                                                                  |
| ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- | ------------ | ----------------------------------------------------------------------------- |
| [S1](#s1--quote-share-tokens-are-derived-from-the-quote-id-not-randomly-generated)                    | Quote share tokens are derived from the quote id, not randomly generated                    | **Critical** | `apps/api/app/services/quote_share_token.rb:11`                               |
| [S2](#s2--a-suspended-professional-can-still-complete-otp-login)                                      | A suspended professional can still complete OTP login                                       | **High**     | `apps/api/app/services/phone_otp_verifier.rb:30`                              |
| [S3](#s3--a-default-admin-password-is-published-in-the-repository-behind-the-wrong-environment-guard) | A default admin password is published in the repository, behind the wrong environment guard | **High**     | `apps/api/app/services/admin_seed.rb:5,10`                                    |
| [S4](#s4--anonymous-endpoints-write-rows-and-metrics-with-no-rate-limit)                              | Anonymous endpoints write rows and metrics with no rate limit                               | **High**     | `apps/api/config/routes.rb:10-12`                                             |
| [S5](#s5--interaction-deduplication-uses-a-per-process-in-memory-cache)                               | Interaction deduplication uses a per-process in-memory cache                                | Medium       | `apps/api/config/initializers/public_interaction_cache.rb:3`                  |
| [S6](#s6--a-get-request-mutates-state-and-skips-the-origin-check)                                     | A `GET` request mutates state and skips the origin check                                    | Medium       | `apps/api/app/controllers/api/v1/base_controller.rb:101`                      |
| [S7](#s7--ssr-forges-the-origin-header-that-is-the-csrf-control)                                      | SSR forges the `Origin` header that _is_ the CSRF control                                   | Medium       | `apps/web/app/services/api/client.ts:39`                                      |
| [S8](#s8--the-rails-upload-endpoint-stays-routed-in-r2-environments)                                  | The Rails upload endpoint stays routed in R2 environments                                   | Medium       | `apps/api/app/controllers/api/v1/professional/media_uploads_controller.rb:39` |
| [S9](#s9--the-goodjob-route-constraint-writes-to-the-database)                                        | The GoodJob route constraint writes to the database                                         | Medium       | `apps/api/app/constraints/admin_session_constraint.rb:7`                      |
| [S10](#s10--there-is-no-operational-response-to-a-leaked-quote-link)                                  | There is no operational response to a leaked quote link                                     | Medium       | —                                                                             |
| [S11](#s11--controls-verified-as-correctly-implemented)                                               | Controls verified as correctly implemented                                                  | Info         | —                                                                             |

---

## S1 — Quote share tokens are derived from the quote id, not randomly generated

**Severity:** Critical
**Where:** `apps/api/app/services/quote_share_token.rb:11-19`, `apps/api/app/services/professional_quote_sharer.rb:22-36`
**Related:** `REVIEW_DOCS_MISMATCHES.md` D2 (the same defect stated as a specification mismatch), S10 below

### What the code does

A quote's share token is a keyed hash of the quote's own primary key:

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

def self.signing_key
  @signing_key ||= Rails.application.key_generator.generate_key("berufe.quote_share_signing", 32)
end
```

`Rails.application.key_generator` derives from `SECRET_KEY_BASE`. So for a given deployment, the token
for quote `X` is a **pure function of `X` and `SECRET_KEY_BASE`**, and is identical every time it is
computed.

The stored value is a second, separately-keyed HMAC of the token
(`QuoteShareToken.digest`, using a different derived key) — that part is well done and is the reason
this is not worse.

### What the specification asked for

Story S050:

> First share **generates a high-entropy token**, stores only its hash, and atomically changes status
> from `draft` to `shared`.

Feature Plan D1 §3.5:

> First share atomically marks the quote shared, **creates a long unguessable bearer token** whose
> hash alone is stored […]

Infrastructure §9, data visibility table:

| Visibility     | Examples                                         | Rule                                                              |
| -------------- | ------------------------------------------------ | ----------------------------------------------------------------- |
| Bearer-private | One shared quote and its customer-facing details | Returned only to the owner/admin or **for the exact valid token** |

### Why this is Critical

The token is unguessable in isolation — an attacker without the key faces a 256-bit HMAC. The problem
is what happens to the **blast radius** when the key is involved.

1. **One secret compromise discloses every quote in the system.** `SECRET_KEY_BASE` leaking is a
   serious incident under any design, but normally it costs you sessions and signed cookies. Here it
   additionally yields a _token-minting oracle_: an attacker who obtains `SECRET_KEY_BASE` can compute
   the valid share link for **any** quote id, with no further access. Quote ids are UUIDv4 and not
   enumerable, but they are not secret — they appear in
   `Location: /api/v1/professional/quotes/<id>` headers, in `ProfessionalQuoteSerializer#as_json`,
   in browser history and in frontend state. With a randomly-generated token, the same key leak would
   expose nothing about quotes, because there would be no relationship between the id and the token.
2. **Environments that share a secret share live tokens.** If `SECRET_KEY_BASE` is ever copied from
   production into staging — a common mistake when someone is trying to reproduce a bug — a staging
   database restore gives real, working production quote links.
3. **Revocation is structurally impossible.** Re-issuing produces the identical value, and the
   sharer explicitly refuses any mismatch:

   ```ruby
   # apps/api/app/services/professional_quote_sharer.rb:30
   elsif quote.share_token_hash != token_digest
     raise Unavailable
   end
   ```

   `Quote::STATUSES` is `%w[draft shared]` with no path back, and nothing anywhere sets
   `share_token_hash` to `nil`. Yet Infrastructure §5 and story S050 both name **revoked** as a state
   the system must handle. A leaked link — forwarded to the wrong WhatsApp group, pasted into a public
   chat, left in a shared browser — exposes the customer's name, the itemised prices, the professional's
   notes and their public identity, permanently, with no lever to pull. See S10.

4. **Rotating `SECRET_KEY_BASE` silently breaks every live link.** Because `share_token_hash` was
   computed under the old key, every previously shared quote becomes unresolvable and un-re-sharable
   (the mismatch branch above raises `Unavailable`). Credential rotation is itself a §12 requirement:
   _"Immediate credential rotation after suspected exposure."_ Today, doing the right thing after an
   incident bricks the quote feature.

### How to fix it

Make the token a random secret, and add revocation. Do this as one change together with
`REVIEW_DOCS_MISMATCHES.md` D2.

**Step 1 — generate randomly.**

```ruby
# apps/api/app/services/quote_share_token.rb
class QuoteShareToken
  PREFIX = "bq_"
  ENCODED_BYTES_LENGTH = 43
  PATTERN = /\A#{PREFIX}[A-Za-z0-9_-]{#{ENCODED_BYTES_LENGTH}}\z/

  def self.issue
    "#{PREFIX}#{SecureRandom.urlsafe_base64(32, false)}"
  end

  def self.digest(token)
    OpenSSL::HMAC.hexdigest("SHA256", digest_key, token.to_s)
  end

  def self.valid?(token) = PATTERN.match?(token.to_s)

  def self.digest_key
    @digest_key ||= Rails.application.key_generator.generate_key("berufe.quote_share_digest", 32)
  end
  private_class_method :digest_key
end
```

`SecureRandom.urlsafe_base64(32, false)` yields exactly 43 characters, so `PATTERN` is unchanged.
Delete `self.matches?` and `self.signing_key` — both exist only to serve the derived scheme.

**Step 2 — remove the now-dead comparison in `SharedQuoteResolver`.**

```ruby
# apps/api/app/services/shared_quote_resolver.rb
raise NotFound unless QuoteShareToken.valid?(token)

quote = Quote.includes(:quote_items)
  .find_by(status: "shared", share_token_hash: QuoteShareToken.digest(token))
raise NotFound unless quote
```

The `QuoteShareToken.matches?(quote_id:, token:)` line goes away. Lookup by the keyed digest is
already a constant-time-equivalent operation at the database level and is the correct primitive.

**Step 3 — decide the re-share semantics, then implement one.** Currently
`ProfessionalQuoteSharer#call` recomputes the token on every share, which is how "share again" keeps
working. With random tokens the raw value is not recoverable from the digest, so choose:

- **(a) Rotate on every share.** Simplest and safest. Each share invalidates the previous link. This
  contradicts story S051 (_"Sharing a previously shared quote reuses the active token rather than
  exposing or persisting another raw token"_), so amend S051 if you pick this.
- **(b) Keep the raw token retrievable** by storing it encrypted alongside the digest, using the same
  pattern `OtpChallenge` already uses (`ActiveSupport::MessageEncryptor` with a
  `key_generator`-derived key). This preserves S051's behaviour at the cost of storing a recoverable
  secret at rest — acceptable here because it is encrypted with a key that is not in the database.

Recommendation: **(b)**, because it preserves specified behaviour and `OtpChallenge` proves the
pattern already works in this codebase. Add a `share_token_ciphertext` column and mirror
`OtpChallenge.encrypt` / `.decrypt`.

**Step 4 — add revocation.**

```ruby
# apps/api/config/routes.rb — inside resources :quotes
delete :share, on: :member
```

```ruby
# apps/api/app/services/professional_quote_revoker.rb
class ProfessionalQuoteRevoker
  def call(quote:)
    quote.with_lock do
      next quote if quote.draft?

      quote.update!(status: "draft", share_token_hash: nil, shared_at: nil)
    end
    quote.reload
  end
end
```

The existing `quotes_consistent_share_state` check constraint already guarantees these three columns
move together, so a partially-revoked row cannot be persisted. Authorize with the existing
`QuotePolicy#share?` (owner only). Add a "Revogar link" action with a confirmation dialog to
`apps/web/app/components/dashboard/QuoteBuilder.vue`, since it breaks a link the customer may hold.

**Step 5 — migrate existing tokens.** Any quote already `shared` in a real environment has a derived
token in circulation. Write a one-off task that, for each shared quote, issues a fresh random token
and notifies the owner that the old link stopped working. If no real quotes exist yet, note that in
the migration and skip it.

### How to verify

1. A spec asserting two quotes with known ids produce tokens with no computable relationship, and
   that sharing the same quote twice under scheme (a) yields different tokens.
2. A spec that revokes a shared quote and then asserts `POST /api/v1/shared-quotes/resolve` with the
   old token returns the generic `404` envelope containing no `customer_name`, no `total_amount` and
   no professional identity.
3. A spec that rotates the derived `signing_key` (by stubbing `key_generator`) and asserts previously
   shared quotes still resolve — proving the token no longer depends on the application secret.

---

## S2 — A suspended professional can still complete OTP login

**Severity:** High
**Where:** `apps/api/app/services/phone_otp_verifier.rb:25-36`

### What the code does

OTP verification finds-or-creates the account, checks its **role**, and issues a session — but never
checks its **status**:

```ruby
# apps/api/app/services/phone_otp_verifier.rb:25
UserAccount.insert_all(
  [{phone_e164:, role: "professional", status: "active", created_at: now, updated_at: now}],
  unique_by: :index_user_accounts_on_phone_e164
)
account = UserAccount.find_by!(phone_e164:)
raise Invalid unless account.professional?          # role checked

account.update!(last_login_at: now)
session, session_token = ApplicationSession.issue!(user_account: account, now:)
challenge.update!(consumed_at: now)
```

`account.active?` is never called. A suspended professional who completes an SMS challenge receives
`200 {"status": "verified"}` and a valid `__Host-berufe_session` cookie.

The sibling admin path does check:

```ruby
# apps/api/app/services/admin_password_authenticator.rb:20
raise Invalid unless account&.active? && password_matches
```

### What the specification requires

Infrastructure §8:

> **Suspending an account** or using the administrative revoke-all action **invalidates every
> application session for that account immediately.**

Story S015:

> Policy/request tests prove anonymous, owner, non-owner, admin, and **suspended-user** behaviour.

Story S013:

> **Suspension** and the admin revoke-all action invalidate every application session for the account
> immediately.

### Why it matters — and the precise limit of the impact

The suspended user **cannot actually do anything**, and it is worth being exact about why, so this is
neither under- nor over-stated. On the very next request, `ApplicationSessionAuthenticator` catches it:

```ruby
# apps/api/app/services/application_session_authenticator.rb:14
unless application_session.user_account.active?
  application_session.user_account.revoke_all_sessions!(now:)
  next
end
```

The session is revoked and the request is rejected with `authentication_required`. So this is **not**
an authentication bypass, and no private data is reachable.

What is wrong is the shape of the failure:

1. **The success response is a lie.** A suspended account is told `verified` and handed a credential.
   Infrastructure §8 requires suspension to invalidate access _immediately_; here it is invalidated
   one request later.
2. **A session row is created for a suspended account** on every login attempt, then immediately
   revoked — an unbounded write amplification available to any suspended user with a phone.
3. **It burns the OTP challenge and the rate-limit budget** for an account that will never be able to
   sign in, so the user gets a confusing loop: the code works, then the app immediately signs them out,
   with no message explaining why.
4. **`insert_all` bypasses validations and callbacks.** That is intentional and correct here (it is
   the concurrency-safe find-or-create), but it means the `UserAccount` model's own guards do not run —
   which is exactly why the explicit status check must be present in the service.
5. **It is asymmetric with the admin path**, and asymmetries are how the second reviewer misses the
   next bug.

### How to fix it

1. Add the status check next to the role check:

   ```ruby
   # apps/api/app/services/phone_otp_verifier.rb:30
   raise Invalid unless account.professional? && account.active?
   ```

   `PhoneOtpVerifier::Invalid` is already rendered by `OtpVerificationsController` as
   `422 invalid_otp` with the generic message _"Código inválido ou expirado."_ That is the correct
   response: Infrastructure §8 requires _"the same account-neutral response wherever account existence
   would otherwise be exposed"_, so a suspended account must not be distinguishable from a wrong code.

2. Move the check **before** `account.update!(last_login_at: now)` so a suspended account does not
   have its login timestamp updated.
3. Consider consuming the challenge even on this failure path, so a suspended user cannot retry the
   same code — currently `challenge.update!(consumed_at: now)` only runs on success. This is a
   judgement call: consuming on failure is safer, but also lets an attacker with a stolen challenge
   token burn a legitimate user's code. Given the challenge token is itself high-entropy and
   short-lived, leaving it unconsumed is defensible; document whichever you choose.
4. Audit for the same gap elsewhere: `grep -rn "ApplicationSession.issue!" apps/api/app` returns
   exactly two call sites (this one and `AdminPasswordAuthenticator`). Both must check `active?`.

### How to verify

A request spec that suspends a professional, completes a valid OTP challenge, and asserts the response
is `422` with code `invalid_otp`, that `Set-Cookie` is absent, and that
`ApplicationSession.where(user_account: account).count` did not increase.

---

## S3 — A default admin password is published in the repository, behind the wrong environment guard

**Severity:** High
**Where:** `apps/api/app/services/admin_seed.rb:4-5`, `:10`, `:19`; `.env.example:24-25`; `apps/api/db/seeds.rb`

### What the code does

```ruby
# apps/api/app/services/admin_seed.rb:4
class AdminSeed
  DEFAULT_EMAIL = "admin@berufe.com.br"
  DEFAULT_PASSWORD = "@Qwer1234"
  ...
  def call
    if Rails.env.production?
      Rails.logger.warn("Administrator seed skipped in production.")
      return
    end

    email = ENV["ADMIN_AUTH_EMAIL"].presence || DEFAULT_EMAIL
    ...
    password = ENV["ADMIN_AUTH_PASSWORD"].presence || DEFAULT_PASSWORD
```

and the same values appear in `.env.example`:

```
# Non-production administrator seed (the service refuses production execution)
ADMIN_AUTH_EMAIL=admin@berufe.com.br
ADMIN_AUTH_PASSWORD=@Qwer1234
```

`db/seeds.rb` calls it unconditionally:

```ruby
CatalogSeed.new.call
AdminSeed.new.call
PublicDiscoveryDemoSeed.new.call
```

### The problem: the guard uses the wrong environment axis

This project deliberately maintains **two** environment concepts:

- `Rails.env` — Rails' own (`development`, `test`, `production`).
- `Berufe::Environment#name` — the product's (`local`, `preview`, `staging`, `integration`,
  `production`, `test`), configured via `BERUFE_ENV` and validated at boot in
  `apps/api/lib/berufe/environment.rb`.

They are **independent**. `lib/berufe/environment.rb` only supplies `DEFAULTS` for `development` and
`test`; every other combination is caller-supplied. A staging deployment will almost certainly run
`RAILS_ENV=production` (you want eager loading, `force_ssl`, no dev middleware) with
`BERUFE_ENV=staging` — in which case the guard holds. But nothing in the repository _enforces_ that
pairing, and `BERUFE_ENV=staging` with `RAILS_ENV=staging` is a perfectly plausible configuration that
a reasonable operator might choose.

In that configuration, `Rails.env.production?` is false, the guard does not fire, and running
`db:seed` on an internet-reachable staging host provisions an admin account whose email and password
are **published in this Git repository**.

The neighbouring seed gets this exactly right:

```ruby
# apps/api/app/services/public_discovery_demo_seed.rb:6
ALLOWED_ENVIRONMENTS = %w[local test].freeze
...
unless environment_name.in?(ALLOWED_ENVIRONMENTS)
  logger.warn("Public discovery demo seed skipped outside local/test.")
  return
end
```

It uses `Rails.configuration.x.berufe.environment.name` and an **allowlist**. `AdminSeed` uses
`Rails.env` and a **denylist**. Allowlists fail closed; denylists fail open.

### Why it matters

An admin session on this system can: read every professional's private moderation notes, download
every uploaded **government identity document** through
`GET /api/v1/admin/verification-files/:id/content`, view every private profile photo and portfolio
image pre-approval, mutate the service and neighbourhood catalog, and — via
`QuotePolicy#show?`'s `active_admin?` branch — read any quote with its customer name and prices.
It also unlocks the GoodJob dashboard at `/admin/jobs`, which exposes job arguments.

Infrastructure §8 is specific about how admin accounts come into existence:

> Use a dedicated admin account with a unique normalized email and **strong password**. `AdminSeed`
> is the only application service allowed to create one […]
> Non-production `db:seed` idempotently creates the configured development admin account. **The seed
> service refuses production execution before reading credentials** and logs a warning.

The "refuses before reading credentials" ordering _is_ correctly implemented — the guard is above the
`ENV` reads. The defect is only which environment concept the guard consults.

### How to fix it

1. **Switch to the allowlist, matching `PublicDiscoveryDemoSeed`:**

   ```ruby
   class AdminSeed
     ALLOWED_ENVIRONMENTS = %w[local test].freeze
     OPERATOR_IDENTIFIER = "database-seed"
     REQUEST_ID = "admin-seed"

     def initialize(environment_name: Rails.configuration.x.berufe.environment.name,
                    logger: Rails.logger)
       @environment_name = environment_name
       @logger = logger
     end

     def call
       unless @environment_name.in?(ALLOWED_ENVIRONMENTS)
         @logger.warn("Administrator seed skipped outside local/test.")
         return
       end
       ...
   ```

   This also correctly excludes `preview`, `staging` and `integration`, which the current guard does
   not.

2. **Remove the hardcoded password constant.** Require the variable and fail loudly:

   ```ruby
   password = ENV.fetch("ADMIN_AUTH_PASSWORD") do
     raise "ADMIN_AUTH_PASSWORD is required to seed an administrator"
   end
   ```

   Keep `DEFAULT_EMAIL` if you like — an email is not a secret — but a password in version control is
   a credential in version control regardless of which environments consume it.

3. **Stop shipping the value in `.env.example`.** Infrastructure §7.1: _"Commit `.env.example` with
   names and safe defaults only; never commit real credentials."_ Replace with:

   ```
   ADMIN_AUTH_EMAIL=admin@berufe.local
   # Required to seed a local administrator. Choose your own; no default is provided.
   ADMIN_AUTH_PASSWORD=
   ```

4. **Rotate now if it was ever used anywhere reachable.** `@Qwer1234` must be treated as public. If
   any deployed environment has ever run `db:seed`, change that account's password and revoke its
   sessions (`UserAccount#revoke_all_sessions!` exists for this).

5. **Strengthen the password policy while you are here.** `UserAccount::ADMIN_PASSWORD_MINIMUM_LENGTH`
   is 8. For an account with this much authority, 12 is a more defensible floor, and it costs one
   constant.

6. **Add a guard test** so this cannot regress: a spec that calls `AdminSeed.new(environment_name:
"staging").call` and asserts no `UserAccount` was created. Parameterise it over every value in
   `Berufe::Environment::ENVIRONMENTS`.

### How to verify

`bundle exec rspec spec/services/admin_seed_spec.rb` proves the seed is a no-op for `preview`,
`staging`, `integration` and `production`, and raises rather than defaulting when
`ADMIN_AUTH_PASSWORD` is absent. `grep -rn "Qwer" .` returns nothing.

---

## S4 — Anonymous endpoints write rows and metrics with no rate limit

**Severity:** High
**Where:** `apps/api/config/routes.rb:10-12`, `apps/api/app/controllers/api/v1/public_professional_searches_controller.rb`, `.../public_professional_views_controller.rb`, `.../public_professional_whatsapp_controller.rb`

### What the code does

Three unauthenticated endpoints perform writes:

```ruby
# apps/api/config/routes.rb:10
post "public/professional-searches", to: "public_professional_searches#create"   # INSERT search_events
post "public/professionals/:id/views", to: "public_professional_views#create"     # UPDATE daily metrics
get  "public/professionals/:id/whatsapp", to: "public_professional_whatsapp#show" # UPDATE daily metrics
```

- `POST /public/professional-searches` inserts one `SearchEvent` row per call, unconditionally.
- `POST /public/professionals/:id/views` increments `professional_daily_metrics.profile_views` and
  flips `search_events.profile_opened`.
- `GET /public/professionals/:id/whatsapp` increments `whatsapp_clicks` plus the per-source counter
  and flips `search_events.whatsapp_handoff_occurred`.

There is no throttling on any of them. The project deliberately has no Rack::Attack (Infrastructure §4
defers it) and instead builds its own PostgreSQL-backed limiters — `OtpRequestCounter` and
`AdminLoginAttemptCounter` — but neither is applied to these routes.

### The two distinct problems

**(a) Unbounded row creation.** `SearchEvent` has no rate limit and no retention job. A script issuing
searches in a loop grows the table without bound. Infrastructure §15 specifies a _paid Render
PostgreSQL plan_, i.e. a fixed disk. This is a cheap availability attack and also inflates every
report query built on `search_events` (`REVIEW_DOCS_MISMATCHES.md` D1).

**(b) Metric integrity — the more serious one.** The interaction tokens are well designed but are
scoped differently for the two sources, and one of them is not bound to a professional:

```ruby
# apps/api/app/services/public_whatsapp_interaction_resolver.rb:48
def verify_token(profile:, source:, token:)
  context = if source == "search_result"
    search_tokens.verify(token)          # Context(search_event_id, service_id) — no professional
  else
    profile_tokens.verify(token)         # Context(..., professional_id, ...)
  end
  raise InvalidInteraction unless context
  raise InvalidInteraction if source == "public_profile" && context.professional_id != profile.id
  context
end
```

For `source: "public_profile"` the token is correctly bound to one professional. For
`source: "search_result"` it is not — deliberately, because one search legitimately renders many
result cards. The only remaining check is that the token's `service_id` is among the profile's
services.

So the attack is: `POST /public/professional-searches` once (free, anonymous), take the returned
`interaction.token`, and replay it against `GET /public/professionals/<id>/whatsapp?source=search_result`
for **every** published professional offering that service. Deduplication is keyed on
`(search_event_id, professional_id)`, so each pairing counts once — but generating a new search event
costs one request, so the counters can be driven arbitrarily high. The same applies to `profile_views`
via the profile interaction token, which is issued freely by `GET /public/professionals/:slug`.

`PublicInteractionUserAgent.countable?` filters obvious bots, but only from **counting**, and only by
`User-Agent` — a header the client controls entirely.

Feature Plan E3 states what these numbers are for:

> The MVP must learn whether it is building enough credible supply and whether discovery produces
> useful action.

and Feature Plan B4 explicitly requires the control that is missing:

> Apply basic **bot/rate filtering** so automated clicks do not inflate the dashboard.

A competitor, or a professional wanting to look successful, can make the launch decision data say
whatever they want.

### How to fix it

**Rate limiting (fixes a, mitigates b).** The pattern already exists in this codebase — copy it rather
than inventing something.

1. Add a `public_request_counters` table mirroring `otp_request_counters`: `scope_kind`,
   `subject_digest`, `window_started_at`, `request_count`, `expires_at`, with the same unique index and
   check constraints.
2. Add `PublicRequestRateLimiter`, modelled on `OtpRequestRateLimiter`, digesting the client IP with
   `SessionSecurityDigest` so no raw IP is stored (Infrastructure §12 forbids PII in logs; the same
   principle applies to counters).
3. Apply it as a `before_action` on the three controllers, with a generous window — e.g. 60 search
   creations and 300 interaction records per IP per hour. Return `429` with `Retry-After`, using the
   shared error envelope, exactly as `OtpChallengesController` already does.
4. Extend `AuthenticationRecordsCleanupJob` (already scheduled hourly in
   `config/initializers/good_job.rb`) to purge expired rows from the new table.

**Token binding (fixes b properly).**

5. Bind the search interaction token to the set of professionals it was issued for. In
   `PublicSearchEventRecorder`, the result set is already loaded (`result.professionals.load` runs in
   the controller before recording), so include the professional ids in the signed payload:

   ```ruby
   token_issuer.issue(
     search_event_id: event.id,
     service_id: service&.id,
     professional_ids: professionals.map(&:id)
   )
   ```

   Then in `PublicWhatsappInteractionResolver#verify_token`, for `source: "search_result"`, assert
   `profile.id.in?(context.professional_ids)`. This makes replay impossible beyond the cards the
   search actually returned — which is the honest definition of the metric.

   Note this interacts with pagination (`REVIEW_DOCS_MISMATCHES.md` D5): once results are paginated,
   the token should carry the ids from the page it was issued with, and a new token comes with each page.

**Retention (fixes a durably).**

6. Add a retention rule for `search_events` — Infrastructure §9 requires one anyway: _"Define
   retention/deletion rules for private and restricted fields before launch."_ Story S053's retention
   matrix names `anonymous search events` explicitly. A daily GoodJob deleting events older than the
   longest report window (since-launch, so consider aggregating into a daily rollup and deleting the
   raw rows) both bounds the table and satisfies S053.

### How to verify

1. A request spec asserting the 61st search from one IP within the window returns `429` with
   `Retry-After`, and that the 60th succeeded.
2. A request spec that obtains a search token for professional A and asserts that replaying it against
   professional B's whatsapp endpoint returns `422 validation_failed` and does **not** increment B's
   `whatsapp_clicks`.
3. A spec asserting `AuthenticationRecordsCleanupJob` (or the new job) removes expired public counters.

---

## S5 — Interaction deduplication uses a per-process in-memory cache

**Severity:** Medium
**Where:** `apps/api/config/initializers/public_interaction_cache.rb:3`, `apps/api/app/services/public_interaction_deduplicator.rb`

### What the code does

```ruby
# apps/api/config/initializers/public_interaction_cache.rb:3
Rails.application.config.x.berufe.public_interaction_cache = ActiveSupport::Cache::MemoryStore.new(
  size: 8.megabytes
)
```

```ruby
# apps/api/app/services/public_interaction_deduplicator.rb
def claim(scope:, interaction_id:, professional_id:)
  cache.write(key(...), true, expires_in: TTL, unless_exist: true)
end
```

`MemoryStore` lives inside a single Ruby process. `PublicProfileViewRecorder` and
`PublicWhatsappHandoffRecorder` both gate their metric increments on `claim` returning true.

### Why it matters

The `unless_exist: true` write is atomic **within one process**, which makes this correct for a single
Puma worker. It stops working the moment there is more than one:

- Puma in clustered mode (`WEB_CONCURRENCY > 1`) forks workers with independent memory.
- Render can run more than one API replica; Infrastructure §6 explicitly plans for it
  (_"Recalculate before adding replicas or threads"_).

With N processes, a duplicate tap has an ~1/N chance of landing on a different worker and being
counted again. There is no error and no log line — the metric simply becomes wrong, silently, the day
someone scales the service.

Additionally, `size: 8.megabytes` means the store evicts under pressure. An eviction inside the
10-minute TTL releases the claim early, so a legitimate repeat tap is counted twice.

Story S037 requires the control:

> **Basic short-lived deduplication** prevents obvious repeated browser taps from inflating counts
> without creating a permanent visitor table.

The design intent — no permanent visitor identity — is correctly honoured. Only the storage is wrong.

### How to fix it

The constraint from S037 is _"without creating a permanent visitor table"_. A short-lived table with a
TTL is not a permanent visitor table, and PostgreSQL is already the project's chosen coordination
substrate (Infrastructure §4: _"GoodJob is the only queue implementation. It uses the existing
PostgreSQL database, so no Redis […] is required"_). Follow the same reasoning.

1. Add `public_interaction_claims`: `claim_digest` (text, unique), `expires_at` (timestamptz), and an
   index on `expires_at`. Store only the SHA-256 digest that `PublicInteractionDeduplicator#key`
   already computes — no professional id, no interaction id, no visitor data in plaintext.
2. Rewrite `claim` as an atomic insert:

   ```ruby
   def claim(scope:, interaction_id:, professional_id:)
     PublicInteractionClaim.insert_all(
       [{claim_digest: key(...), expires_at: TTL.from_now}],
       unique_by: :index_public_interaction_claims_on_digest
     ).any?
   end
   ```

   `insert_all` with `unique_by` performs `ON CONFLICT DO NOTHING` and returns the inserted rows, so a
   duplicate returns an empty result — atomic across every process and replica. `release` becomes a
   `delete_by`.

3. Purge expired rows from the existing hourly `AuthenticationRecordsCleanupJob`, or add a dedicated
   cron entry beside the three already in `config/initializers/good_job.rb`.
4. Keep the `PublicInteractionDeduplicator` interface unchanged — every caller already injects it,
   so the two recorder specs need no restructuring.

**If you decide not to fix this before launch**, add a comment in the initializer and a note in the
deployment runbook stating that the API must run exactly one process, and treat scaling as a change
that requires this fix first. That is a defensible MVP choice — but it must be written down, because
nothing in the code says it today.

### How to verify

A spec that calls `claim` twice with identical arguments from two separate `PublicInteractionDeduplicator`
instances (simulating two processes) and asserts the second returns false. With the current
`MemoryStore` this passes only because the spec shares one process — so also assert the backing store
is not `ActiveSupport::Cache::MemoryStore`.

---

## S6 — A `GET` request mutates state and skips the origin check

**Severity:** Medium
**Where:** `apps/api/app/controllers/api/v1/base_controller.rb:8`, `:101`; `apps/api/config/routes.rb:12`; `apps/api/app/controllers/api/v1/public_professional_whatsapp_controller.rb`

### What the code does

The CSRF control is scoped to four HTTP verbs:

```ruby
# apps/api/app/controllers/api/v1/base_controller.rb:8
before_action :verify_request_origin!, if: :state_changing_request?
# :101
def state_changing_request?
  request.post? || request.put? || request.patch? || request.delete?
end
```

But one route changes state behind a `GET`:

```ruby
# apps/api/config/routes.rb:12
get "public/professionals/:id/whatsapp", to: "public_professional_whatsapp#show"
```

```ruby
# apps/api/app/controllers/api/v1/public_professional_whatsapp_controller.rb
if PublicInteractionUserAgent.countable?(request.user_agent)
  PublicWhatsappHandoffRecorder.new.call(profile:, interaction:)   # writes metrics + search_events
end
redirect_to redirect_url, allow_other_host: true, status: :found
```

So the origin check never runs on it, and the sibling `POST .../views` route is checked while the
`GET .../whatsapp` route is not — despite both writing the same table.

### Why it matters

The real-world impact is bounded, and it is worth being precise:

- The endpoint is **public**, so no session is involved and there is nothing to forge on a victim's
  behalf. This is not a classical CSRF.
- It requires a **valid signed interaction token**, so it cannot be triggered by a bare `<img>` tag.
- The redirect target is safe: `PublicWhatsappUrl.call` validates the phone against
  `UserAccount::BRAZILIAN_MOBILE_PATTERN` and builds the URL with `URI::HTTPS.build(host: "wa.me", ...)`,
  so `allow_other_host: true` cannot be turned into an open redirect. **This is correctly done.**

What remains is: a state-changing operation is reachable by any mechanism that issues a `GET` — link
prefetchers, browser speculative loading, corporate link scanners, WhatsApp's own link preview
fetcher. `PublicInteractionUserAgent` tries to filter these by `User-Agent`, which is a heuristic on
attacker-controlled input, not a control. It also means the endpoint sits outside the invariant
S014 established:

> **Every state-changing request**, authenticated or not, requires an exact valid origin.

An invariant with an undocumented exception is an invariant nobody can rely on.

### How to fix it

Separate the two concerns the endpoint currently conflates.

1. Add `POST /api/v1/public/professionals/:id/whatsapp-handoffs` that records the handoff and returns
   `204`, subject to the normal origin check — identical in shape to the existing
   `POST .../views` route.
2. Reduce `GET .../whatsapp` to a pure redirect with no writes, or drop it entirely: the frontend can
   build the `wa.me` URL itself from data the profile endpoint already returns. Note the deliberate
   design choice here — the phone number is _not_ in the public serializer (see S11), and the redirect
   exists precisely so the number never appears in JSON. Keep that property: have the `POST` return the
   `wa.me` URL in its response body, and let the client navigate.
3. Update `apps/web/app/utils/contact.ts` and the two components that use it
   (`public/ProfessionalCard.vue`, `profile/MobileContact.vue`) to call the `POST` and then navigate.
4. Once no `GET` mutates, add a spec asserting `state_changing_request?` covers every route that
   writes — or better, add an `after_action` in test mode that fails if a `GET` action produced any
   `INSERT`/`UPDATE`. That turns the invariant into something enforced rather than remembered.

### How to verify

A request spec asserting the new `POST` is refused with `request_not_allowed` when `Origin` is missing
or wrong, and that no `GET` route increments `professional_daily_metrics`.

---

## S7 — SSR forges the `Origin` header that _is_ the CSRF control

**Severity:** Medium
**Where:** `apps/web/app/services/api/client.ts:38-42`, `:64-66`
**Related:** `REVIEW_CODE.md` C8 (same finding, with the refactoring detail)

### What the code does

```ts
// apps/web/app/services/api/client.ts:38
if (options.origin && !["GET", "HEAD", "OPTIONS"].includes(request.method)) {
  request.headers.set("Origin", options.origin);
}
```

```ts
// :64
origin: import.meta.server && configuredSiteUrl
  ? new URL(configuredSiteUrl).origin
  : undefined,
```

Rails treats that header as the sole CSRF defence:

```ruby
# apps/api/app/controllers/api/v1/base_controller.rb:97
def valid_request_origin?
  request.headers["Origin"] == ENV.fetch("WEB_ORIGIN")
end
```

Story S014 states the security property this is supposed to have:

> the browser supplies the `Origin` header, **which page scripts cannot forge**.

### Why it matters

**This is not currently exploitable, and the reason is worth stating precisely.** Node's `fetch` has
no cookie jar, so `credentials: "include"` is inert on the server. SSR requests arrive at Rails
unauthenticated. A forged `Origin` on an unauthenticated request grants nothing.

The finding is about the **structure**, not today's behaviour. The control that protects every
authenticated mutation is now satisfiable by application code rather than only by the browser. The
moment someone forwards the incoming session cookie into an SSR call — the obvious thing to do when
server-rendering an authenticated page — the CSRF check becomes unconditionally true for that path,
silently, with no test failing.

`SameSite=Lax` on the session cookie is the complementary control and remains fully intact, so even in
that hypothetical the attack surface is narrow (same-site-but-different-origin callers, which is
exactly what §8 says the origin check exists to cover).

### How to fix it

1. Delete the `origin` option from `ApiClientOptions`, the header-setting branch, and the `origin:`
   argument in `useApiClient()`.
2. That breaks SSR resolution of the shared quote page, because
   `POST /api/v1/shared-quotes/resolve` is a `POST` and therefore origin-checked. Fix it on the Rails
   side, where it belongs — the operation is a public read that mutates nothing and is already
   protected by the bearer token:

   ```ruby
   # apps/api/app/controllers/api/v1/shared_quotes_controller.rb
   skip_before_action :verify_request_origin!, raise: false
   ```

   Add a comment explaining why: a CSRF control on an unauthenticated read has no meaning, and the
   token is the actual authorization.

3. If SSR ever needs to genuinely mutate, do **not** reinstate the forged header. Issue the internal
   Nuxt→Rails hop a server-only shared secret (`NUXT_API_INTERNAL_TOKEN`, never under
   `runtimeConfig.public`) and accept it in place of the origin check on that specific path.
4. Add a Vitest assertion that `createApiClient` never sets an `Origin` header, so the option cannot
   quietly return.

### How to verify

The existing S014 origin specs still pass; a new spec proves shared-quote resolution succeeds with no
`Origin` header while every professional and admin mutation still returns `request_not_allowed`
without one. `pnpm test` covers the client middleware change.

---

## S8 — The Rails upload endpoint stays routed in R2 environments

**Severity:** Medium
**Where:** `apps/api/config/routes.rb:30`, `apps/api/app/controllers/api/v1/professional/media_uploads_controller.rb:39`

### What the code does

`MediaUploadAuthorizer` chooses between two upload strategies based on the storage adapter:

```ruby
# apps/api/app/services/media_upload_authorizer.rb
if Rails.configuration.x.berufe.environment.media_storage_adapter == "r2"
  {strategy: "direct", method: "PUT", url: storage.presigned_put_url(...), headers:}
else
  {strategy: "rails", method: "PUT", url: ".../media-uploads/#{upload.id}/content", headers:}
end
```

But the `content` route is registered in **all** environments, and its handler buffers the whole body
in memory:

```ruby
# apps/api/app/controllers/api/v1/professional/media_uploads_controller.rb:39
body = request.body.read(MediaUpload::MAX_BYTE_SIZE + 1)   # up to 10 MiB, in RAM
```

### Why it matters

This is **surface reduction, not a hole** — and the distinction matters, so here is what is already
correct:

- `authenticate_application_session!` runs first.
- `set_upload` scopes to `@profile.media_uploads.find(...)`, so cross-tenant access is impossible.
- `authorize @upload, :update?` re-checks ownership through `MediaUploadPolicy#owns_profile?`.
- `MediaUploadReceiver` rejects content-type and byte-size mismatches before writing anything.
- The written object is a private quarantine key that must still survive `MediaUploadInspector`.

What remains is an availability concern. In production the endpoint should be unreachable by design,
yet an authenticated professional can `PUT` 10 MiB into a Puma thread's heap. With
`RAILS_MAX_THREADS=5`, five concurrent uploads pin 50 MiB and five of five threads for the duration of
the transfer — on a route that production never intends to use. Infrastructure §10 is explicit that
deployed environments upload directly:

> **In deployed environments the browser uploads directly to the private R2 bucket** without
> application cookies […] In local development it sends the same authorized body through the
> authenticated Rails local-upload endpoint using `API_PUBLIC_URL`.

### How to fix it

1. Constrain the route to the local adapter:

   ```ruby
   # apps/api/config/routes.rb
   resources :media_uploads, only: %i[create show], path: "media-uploads" do
     member do
       if Rails.configuration.x.berufe.environment.media_storage_adapter == "local"
         put :content
       end
       post :completion
       post :retry
     end
   end
   ```

   Routes are drawn at boot and the adapter is fixed per environment, so this is safe. If you prefer
   not to branch in `routes.rb`, use a route constraint object — `AdminSessionConstraint` is the
   in-repo precedent for that style.

2. Guard the action as well, so the two cannot drift:

   ```ruby
   def content
     raise ActionController::RoutingError, "not found" unless local_storage?
     ...
   ```

3. Apply the same treatment to `public/profile-photos/:id/image` and
   `public/portfolio-items/:id/image` once `REVIEW_DOCS_MISMATCHES.md` D3 moves public media to R2 —
   they have the identical property of being local-development-only paths that stay routed in
   production, with the added cost of streaming public images through Rails.
4. Consider streaming rather than buffering even in local development
   (`request.body` is an `IO`; write it to the storage adapter in chunks). Lower priority, since it is
   development-only once step 1 lands.

### How to verify

A request spec with the R2 adapter configured asserts `PUT /api/v1/professional/media-uploads/:id/content`
returns `404`, while the same spec with the local adapter succeeds.

---

## S9 — The GoodJob route constraint writes to the database

**Severity:** Medium
**Where:** `apps/api/app/constraints/admin_session_constraint.rb:7`, `apps/api/config/routes.rb`, `apps/api/app/services/application_session_authenticator.rb:17`

### What the code does

The GoodJob dashboard is mounted behind a route constraint that authenticates the session:

```ruby
# apps/api/config/routes.rb
constraints AdminSessionConstraint.new do
  mount GoodJob::Engine => "/admin/jobs"
end
```

```ruby
# apps/api/app/constraints/admin_session_constraint.rb:7
def matches?(request)
  session = ApplicationSessionAuthenticator.new.call(
    token: request.cookies[ApplicationSession::COOKIE_NAME]
  )
  return false unless session&.user_account&.admin?
  return false unless session.authentication_method == "password"
  ...
```

`ApplicationSessionAuthenticator#call` is not read-only:

```ruby
# apps/api/app/services/application_session_authenticator.rb:11
ApplicationSession.transaction do
  application_session = ApplicationSession.includes(:user_account).lock.find_by(token_digest:)
  next unless application_session&.active?(now:)
  unless application_session.user_account.active?
    application_session.user_account.revoke_all_sessions!(now:)   # UPDATE
    next
  end
  application_session.record_activity!(now:)                       # UPDATE (throttled)
  application_session
end
```

So every request to `/admin/jobs*` opens a transaction, takes a `SELECT … FOR UPDATE` row lock, and
potentially issues an `UPDATE` — during **route matching**, before any controller runs.

### Why it matters

The authorization itself is **correct and well done**: it requires an active session, the `admin`
role, _and_ the `password` authentication method, which is exactly what Infrastructure §15 asks for
(_"Protect the GoodJob dashboard with an active password-authenticated admin application session"_),
and a professional SMS session can never satisfy it.

The concerns are operational:

1. **Unauthenticated probing causes database work.** Anyone hitting `/admin/jobs` with a garbage
   cookie causes a digest computation and an indexed lookup. With a _valid_ cookie it causes a locking
   transaction. `ApplicationSessionAuthenticator` returns early when the token is blank, so a bare
   probe is cheap — but a probe replaying any captured cookie is not.
2. **Route matching should be side-effect free.** Rails may evaluate constraints more than once per
   request (during recognition and again during generation in some paths), and a constraint that
   writes is surprising to anyone reading `routes.rb`.
3. **`rescue ActiveRecord::ActiveRecordError → false`** means a database blip silently renders the
   dashboard "not found" rather than surfacing a 503. That is arguably the safe default, but it will
   confuse an operator during exactly the incident when they need the dashboard most.

### How to fix it

1. Split the authenticator into a read-only verification and a separate activity write:

   ```ruby
   class ApplicationSessionAuthenticator
     def verify(token:, now: Time.current)
       return if token.blank?
       session = ApplicationSession.includes(:user_account).find_by(token_digest: ApplicationSession.digest_token(token))
       return unless session&.active?(now:) && session.user_account.active?
       session
     end

     def call(token:, now: Time.current)
       # existing locking behaviour, used by BaseController
     end
   end
   ```

2. Use `verify` in `AdminSessionConstraint`. The dashboard does not need to extend the session's idle
   window on every asset request — and arguably should not, since an idle admin session extending
   itself from a background browser tab is the opposite of what a 30-minute idle expiry is for.
3. Keep the suspension check. In `verify`, a suspended account simply returns `nil` (deny) without the
   `revoke_all_sessions!` write; the next real API request through `call` performs the revocation.
4. Add rate limiting to `/admin/jobs` using the same counter table introduced in S4, so repeated
   probing is bounded.
5. Log denied dashboard attempts with the request id (and nothing else — no cookie, no token). Story
   S052 will want this for the operations runbook.

### How to verify

A request spec asserting that a `GET /admin/jobs` with a valid admin cookie does **not** change
`application_sessions.last_active_at`, while a normal API request still does. The existing
`spec/constraints/admin_session_constraint_spec.rb` authorization assertions must pass unchanged.

---

## S10 — There is no operational response to a leaked quote link

**Severity:** Medium
**Where:** system-level; follows from S1
**Related:** `REVIEW_DOCS_MISMATCHES.md` D2

### What is missing

Quote share links are, by design, _private-by-possession_ — Infrastructure §8:

> They search approved profiles, explicitly hand off to WhatsApp, and may view one shared quote
> through its unguessable bearer link. The link is **private-by-possession**, not a public listing or
> customer session.

Bearer-token designs are perfectly reasonable, but they carry one mandatory operational requirement:
**you must be able to invalidate a token.** Berufe cannot. There is no revoke endpoint, no admin
action, no `rake` task, and no manual database procedure documented anywhere — and because the token
is derived (S1), even a direct `UPDATE quotes SET share_token_hash = NULL` does not permanently help,
since the next share regenerates the identical value.

The specification assumes the capability exists. Infrastructure §5:

> Rails hashes the supplied token […] and returns the same generic not-found response for malformed,
> unknown, or **revoked** tokens.

Story S050:

> Malformed, invalid, **revoked**, or unknown tokens reveal no quote or customer details.

### Why it matters

Leaked links are the _expected_ failure mode of this design, not an exotic one. The link is delivered
over WhatsApp — a medium where forwarding is one tap, group chats are common, and message history
persists on devices the professional does not control. What leaks is the customer's name, the itemised
prices, the professional's private notes, and the professional's public identity. When it happens, the
support answer today is "nothing can be done."

It also interacts with account lifecycle. `SharedQuoteResolver` re-checks
`ProfessionalProfile.publicly_eligible`, so suspending a professional **does** immediately break their
quote links — that part is correctly handled and is worth noting as a mitigating control. But there is
no way to break a single link without suspending the whole professional.

### How to fix it

1. Implement S1 (random tokens) and its step 4 (the revoke endpoint). That is the technical
   prerequisite.
2. Expose it to the professional: a "Revogar link" action in
   `apps/web/app/components/dashboard/QuoteBuilder.vue`, with a confirmation dialog explaining that
   the customer's existing link will stop working.
3. Give operations a break-glass path: an admin-only revoke, or a documented `rails runner` snippet in
   the operations runbook. Story S053 requires exactly this kind of documented procedure:

   > Operations can correct, suspend, and delete an account/profile through a documented manual
   > procedure.

4. Add quote share tokens to the retention matrix S053 mandates — it already names _"quotes and their
   customer data/share tokens"_ as an entry that must exist. Decide and document: how long does a
   shared link stay live with no expiry at all? The Feature Plan is explicit that `valid_until` is a
   commercial date and **not** token expiry (D1 §3: _"the commercial validity date is not token
   expiry"_), so an unbounded lifetime is currently the specified behaviour — but that should be a
   recorded decision, not an omission.

### How to verify

A professional can revoke a link from the dashboard; the revoked link returns the generic `404`; the
runbook contains the break-glass procedure; and S053's retention matrix has a row for share tokens.

---

## S11 — Controls verified as correctly implemented

**Severity:** Info

These were reviewed against Infrastructure §8, §9, §10 and §12 and found correct. They are recorded
here so the launch gate in §18 has evidence, and so a future refactor does not remove something
load-bearing.

### Session management (§8, §12)

- **Cookie configuration is exactly right.** `ApplicationSession::COOKIE_NAME` is
  `__Host-berufe_session`, and `BaseController#set_application_session_cookie` sets `secure: true`,
  `httponly: true`, `same_site: :lax`, `path: "/"` with no `Domain`. Those are precisely the
  conditions the `__Host-` prefix requires, so a browser rejects the cookie if any of them is ever
  dropped — the naming choice is itself an enforcement mechanism.
- **Raw tokens are never stored.** `ApplicationSession.digest_token` uses
  `SessionSecurityDigest`, an **HMAC** keyed from `Rails.application.key_generator`, not a bare
  SHA-256. A database dump therefore does not yield usable session tokens, because the key lives in
  the environment. The same pattern is applied to OTP counters and admin login counters.
- **Expiry is enforced in two dimensions and in the database.** `active?` checks `revoked_at`, idle
  and absolute expiry; `SESSION_DURATIONS` matches §8 exactly (professional 7d/30d, admin 30min/12h);
  and five `CHECK` constraints on `application_sessions` make an inconsistent row unstorable
  (`idle_expires_at <= absolute_expires_at`, `absolute_expires_at > authenticated_at`, and so on).
- **`record_activity!` is throttled** by `SESSION_ACTIVITY_WRITE_INTERVAL_SECONDS` (default 300) and
  correctly clamps the extended idle expiry to the absolute expiry with
  `[now + idle, absolute_expires_at].min` — so activity can never push a session past its absolute
  limit.
- **Suspension revokes immediately.** `UserAccount#suspend!` wraps the status change and
  `revoke_all_sessions!` in `with_lock`, and `ApplicationSessionAuthenticator` independently revokes
  on any request from a non-active account (this is what limits S2's impact).
- **`authentication_method_matches_role`** makes it impossible to persist an admin session created by
  SMS or a professional session created by password — a model validation _and_ a database check
  constraint.

### OTP and admin authentication (§8)

- **OTP values are never stored.** `OtpChallenge` persists only a digest of the browser token plus
  the phone and Infobip reference **encrypted** with `ActiveSupport::MessageEncryptor` using a
  purpose-scoped derived key. Decryption happens only server-side, and the challenge is consumed
  atomically inside a locking transaction.
- **The browser token is separate from the record id.** `OtpChallenge.issue!` returns a
  `SecureRandom.urlsafe_base64(32)` value stored only as a digest — the record's UUID is never the
  credential. This is exactly what Feature Plan A1's schema note asks for.
- **Rate limiting is real and database-backed.** `OtpRequestRateLimiter` enforces a resend cooldown
  plus daily per-phone and per-IP allowances using locked counter rows, digesting both subjects so no
  raw phone or IP is stored. Counters are incremented **before** the provider call, so failed sends
  still count. `Retry-After` is returned on every rate-limit response.
- **Timing attacks on admin login are addressed.** `AdminPasswordAuthenticator::DUMMY_PASSWORD_DIGEST`
  is a constant BCrypt hash used when no account matches, so an unknown email costs the same as a
  wrong password. Failures are generic (`invalid_credentials`), and
  `AdminLoginRateLimiter` throttles by both email and IP in 15-minute windows with digested subjects.
- **Admins cannot be created through the API.** There is no admin-creation endpoint; `AdminSeed` is
  the only path, and `AdminAccessEvent` records provisioning as an append-only audit row with a
  request-id format constraint. (S3 addresses the guard on that seed, not the design.)
- **Account-neutral responses.** OTP challenge and verification return identical outcomes whether or
  not an account exists, as §8 requires.

### Authorization and data visibility (§8, §9)

- **Pundit policies are explicit and scoped.** `QuotePolicy::Scope` returns `scope.none` for inactive
  users and joins on `professional_profiles.user_account_id` for professionals; controllers use
  `policy_scope(Quote).find(...)` so a non-owner gets `404`, not `403` — no existence disclosure.
- **Public scopes fail closed and compose.** `ProfessionalProfile.publicly_eligible` requires
  `profile_status = 'published'`, `user_accounts.status = 'active'` **and**
  `professional_profile_revisions.status = 'approved'`. Critically, both media scopes merge it:
  `ProfessionalProfilePhoto.publicly_visible` and the `PublicPortfolioImagesController` query both
  join through to the profile — so suspending an account instantly removes its images from public
  access, not just its profile JSON. §13's _"Hiding or suspending a profile must remove it from public
  API responses immediately"_ is genuinely satisfied.
- **The phone number is deliberately kept out of public JSON.** `PublicProfessionalProfileSerializer`
  and `PublicProfessionalCardSerializer` expose no `whatsapp_e164`; contact happens through the
  redirect endpoint. That matches Feature Plan B3's exclusion of _"Public phone number displayed as
  raw text"_ and is a thoughtful design decision, not an accident.
- **The revision model prevents mixed public snapshots.** `published_revision` and `working_revision`
  are separate pointers with `revision_pointers_belong_to_profile` validation, so a pending edit can
  never leak into a public serializer — §9's _"Public serializers never mix approved and unreviewed
  fields."_
- **Private review data stays private.** `rejection_reason` and `review_note` appear only in the
  owner's workspace serializer and the admin queue, never in a public serializer.

### Media handling (§10)

- **Signature checking precedes decoding.** `MediaUploadInspector#content_type_from_signature`
  inspects magic bytes and requires them to match the declared type before the buffer reaches libvips.
  Browser MIME types and extensions are never trusted, exactly as §10 requires.
- **Decompression bombs are handled in the right order.** `Vips::Image.new_from_buffer(..., access:
:sequential, fail_on: :error)` is lazy, so the `width * height > MAX_PIXELS` check runs against the
  header _before_ any full decode or re-encode. Multi-frame images are rejected via `n-pages`.
- **Metadata is stripped and the image is re-encoded**, not passed through: `jpegsave_buffer(strip:
true)` / `pngsave_buffer(strip: true)`, with `autorot` normalising orientation. Client filenames are
  never persisted or used in storage keys — keys are `quarantine/<profile_id>/<uuid>` and
  `sanitized/<profile_id>/<upload_id>.<ext>`.
- **Quarantine originals are deleted** after successful processing and on terminal failure, and
  `MediaUploadAuthorizationCleanupJob` runs every 10 minutes, matching §10.
- **Path traversal is properly blocked.** `LocalDiskStorage#path_for` validates the scope against an
  allowlist, rejects empty and absolute keys, `cleanpath`s, and then re-asserts the result is under the
  scope root — belt and braces.
- **Verification evidence is tightly controlled.** `VerificationFileReader` re-validates that the
  stored record still matches its `media_upload` (key, content type, byte size, dimensions) before
  reading, and refuses if the upload is not `attached` or the file is soft-deleted. Every read writes a
  `VerificationFileAccessEvent` with actor, request id and timestamp. The response sets an exact image
  content type, `nosniff`, `Cache-Control: no-store` (via `prevent_caching` on
  `ModerationBaseController`), `Content-Disposition: inline`, and a **server-generated** filename —
  the uploaded name is never reflected. `VerificationFileRetentionCleanupJob` implements the 30-day
  post-decision deletion, and the frontend revokes the temporary object URL after 60 seconds
  (`useModerationQueue.ts:219`), which is precisely what story S031 specified.

### Transport, headers and logging (§12)

- **`SecurityHeaders` middleware** (`lib/security_headers.rb`) is inserted at position 0 and sets
  `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY` and `Referrer-Policy: no-referrer` on
  every response, including errors.
- **Nuxt mirrors it** via `routeRules`, and adds `cache-control: private, no-store` on `/app/**` plus
  the full `no-store` + `noindex, nofollow` + `no-referrer` triple on `/orcamento/**`. Both `/app/**`
  and `/orcamento/**` set `prerender: false`, so token-authorized pages never enter static generation —
  §12 and §18 satisfied.
- **The shared quote API response matches**: `SharedQuotesController#protect_bearer_response` sets
  `Cache-Control: private, no-store`, `Referrer-Policy: no-referrer` and
  `X-Robots-Tag: noindex, nofollow`, and the token travels in the **request body**, not the URL, so it
  never lands in an API access log.
- **Production forces TLS** (`config.force_ssl = true`, `config.assume_ssl = true`) and logs are
  tagged with the request id.
- **Parameter filtering covers the right things**: `passw, email, phone, code, pin, secret, token,
challenge, _key, crypt, salt, certificate, otp, ssn, cvv, cvc` — partial matching, so
  `challenge_token` and `share_token` are both caught.
- **Request ids are validated, not trusted.** `RequestIdSanitizer` drops any inbound
  `X-Request-Id` that fails `/\A[A-Za-z0-9._-]{1,100}\z/` before `ActionDispatch::RequestId` sees it,
  and the frontend client applies the identical regex. This is header-injection defence done properly,
  and it is enforced again by `CHECK` constraints on every audit table.
- **CORS is exact-origin with no wildcard.** `config/initializers/cors.rb` allows a single
  `WEB_ORIGIN` with `credentials: true` and a minimal header allowlist. No Vercel preview pattern
  exists anywhere, as §14 requires.
- **The WhatsApp redirect cannot be an open redirect.** `PublicWhatsappUrl.call` validates the phone
  against the Brazilian mobile pattern and constructs the URL with
  `URI::HTTPS.build(host: "wa.me", ...)` — the host is a constant, so `allow_other_host: true` is safe.

### Secrets and environments (§7.1, §14)

- **Boot-time environment validation is thorough.** `Berufe::Environment.load!` refuses to start
  unless the adapter selection is legal for the environment (`preview` and `test` can only use `fake`
  SMS; `staging`/`integration`/`production` can only use `r2` storage), and it validates that
  `INFOBIP_CREDENTIAL_SCOPE` is `integration` for every non-production environment and that
  `INFOBIP_TEST_NUMBERS` contains a real allowlist. **Adapter selection never falls back at runtime**,
  which is exactly the property story S003 demanded.
- **`.env` and `apps/api/.env` are git-ignored** (verified with `git check-ignore`); no real
  credential is committed. S3 concerns a default password, which is a different problem.
- **`PublicDiscoveryDemoSeed` is correctly gated** to `local`/`test` via the Berufe environment name,
  so synthetic professionals cannot be published to a deployed environment.
- **Only `NUXT_PUBLIC_*` values reach the browser.** `nuxt.config.ts` keeps `apiInternalBaseUrl`
  outside the `public` block, so the internal API URL stays server-only.
- **CI enforces the security tooling**: Brakeman runs with `--exit-on-warn --exit-on-error`, alongside
  Standard, `zeitwerk:check`, RSpec with `openapi_first` contract validation, and a seed verification
  step.

---

## Recommended order of remediation

**Before accepting real users (Infrastructure §18 launch gate)**

1. **S1** — replace derived quote tokens with random ones and add revocation. Do it with
   `REVIEW_DOCS_MISMATCHES.md` D2 and S10 as a single change.
2. **S3** — fix the seed guard, remove the published default password, rotate if it was ever used.
3. **S2** — one-line status check on OTP verification.
4. **S4** — rate-limit the three anonymous write endpoints and bind the search interaction token.

**Before or shortly after launch**

5. **S5** — move interaction deduplication to PostgreSQL, or document the single-process constraint.
6. **S6**, **S7** — restore the "every state-changing request is origin-checked" invariant, in both
   directions.
7. **S8**, **S9** — reduce production attack surface and stop writing during route matching.

**Tracked separately**

8. Story S052 (Bugsnag with redaction callbacks) and story S053 (retention matrix, deletion
   procedures, Brazilian privacy review) are both launch-gate items in §18 and are not yet
   implemented. Neither is a defect in the reviewed code — both are unstarted Increment 7 work — but
   both are required before real-user intake, and S10 depends on S053's retention matrix.
