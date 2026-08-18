# Berufe — MVP Implementation Stories

**Status:** implementation backlog
**Updated:** August 17, 2026
**Sources:** _Berufe — MVP Feature Plan_ and _Berufe — Lean MVP Infrastructure and Architecture_

## 1. Purpose

This document turns the approved Berufe MVP scope and architecture into an incrementally ordered implementation backlog.

The order is dependency-driven: establish a reproducible monorepo, enable secure access, build credible professional supply, expose it through public discovery, add existing-member trust relationships and a focused professional dashboard, and then complete the launch gate. Increment 2 uses the approved dependency order recorded in `Berufe_Increment_2_Implementation_Plan.md` while retaining stable story IDs.

The backlog intentionally excludes V2 work. Story IDs removed during the August 2026 scope review are not reused; their original behavior and acceptance criteria are preserved in `Berufe_V2_Stories.md`.

## 2. How to use this backlog

- Implement stories in numeric order unless an approved increment plan records a dependency-driven order. Increment 2 uses `S019 → S020 → S021 → S025 → S026 → S027 → S029 → S022 → S023 → S024 → S028 → S030 → S031`.
- A story is complete only when its backend, frontend, tests, authorization, and relevant documentation are complete.
- Keep each story releasable. Do not leave public endpoints exposing pending, rejected, private, or restricted data.
- The Feature Plan is the product source of truth. The architecture may add implementation detail, but it must not replace a Feature Plan behavior, scope boundary, data rule, or user experience. Conflicts are resolved in favor of the Feature Plan.
- Story estimates should be added by the implementation team after the repository is running. This document does not invent estimates before velocity is known.

### Story format

- **Status:** `DONE`, `WIP`, or `PENDING`; change it only when the repository state changes.
- **Story:** the user or operator outcome.
- **Acceptance criteria:** observable conditions required for completion.
- **Depends on:** prerequisite story IDs.
- **Covers:** source feature or infrastructure requirement.

## 3. Definition of done for every story

Apply these rules whenever they are relevant to the story:

- Rails authorizes every mutation and exposes only allowlisted fields through serializers.
- Database rules use migrations, foreign keys, indexes, constraints, UUID primary keys, and UTC timestamps.
- User-facing copy is in Brazilian Portuguese; code, API fields, and database names are in English.
- Nuxt uses TypeScript strict mode, Composition API, `<script setup>`, Nuxt UI, and the shared typed API client.
- Loading, empty, success, validation, and failure states are usable on a mobile viewport.
- New Rails behavior has the appropriate RSpec coverage; important Vue behavior has Vitest coverage.
- External providers are accessed through small adapters and are faked in automated tests.
- Sensitive values are not logged, returned through public APIs, or stored in browser storage.
- `standardrb`, Nuxt ESLint, Prettier check, Nuxt typecheck, Brakeman, and the affected test suites pass.
- Every API change updates `apps/contracts/openapi.yaml`, regenerated Nuxt types, Rails contract tests, and the typed frontend consumer in the same story.
- The story does not add a deferred technology or feature without updating the approved scope first.

## 4. Increment 0 — Reproducible development foundation

**Increment outcome:** a developer can clone the monorepo and start the complete local stack with one command. Both applications build and have enforceable quality checks.

### S001 — Create the monorepo skeleton

**Story:** As a developer, I want the frontend and backend in one repository so that product changes can be delivered together.

**Acceptance criteria:**

- The root contains `apps/api/`, `apps/web/`, `apps/contracts/openapi.yaml`, `compose.yaml`, `.env.example`, `README.md`, and `docs/`.
- `apps/api/` is a Rails 8.1 API-only application and `apps/web/` is the Nuxt/Vue TypeScript application; there is no pnpm workspace or separate API-client package.
- `apps/web/` uses pnpm and commits `pnpm-lock.yaml`; obsolete Node lockfiles are removed when the foundation is created.
- Ruby, Node, Rails, Nuxt, and package versions are pinned; dependency lockfiles are committed.
- The README contains only the commands needed to install, start, test, lint, format, and stop the project.

**Depends on:** none.
**Covers:** Infrastructure §§2–3 and §7.1.

### S002 — Run the local stack through Docker Compose

**Story:** As a developer, I want one command to run Berufe locally so that environment setup is consistent.

**Acceptance criteria:**

- `docker compose up --build` starts `web`, `api`, `worker`, and `db`.
- The API and worker use the same backend image and environment definition.
- PostgreSQL has a health check and named development volume; dependent services wait for database readiness.
- Nuxt and Rails source changes reload without rebuilding the entire stack, and the team records that hot reload is comfortable on its supported development machines before retaining the four-service setup.
- The local stack does not require Redis, MinIO, live Infobip delivery, R2, or production credentials.

**Depends on:** S001.
**Covers:** Infrastructure §7.1.

### S003 — Establish environment configuration and safe local adapters

**Story:** As a developer, I want explicit and safe environment configuration so that local work cannot accidentally use production services.

**Acceptance criteria:**

- `.env.example` lists required variable names and safe development defaults without secrets.
- Rails validates required environment variables at boot for the selected environment.
- Development uses local-disk storage and selects the fake SMS-OTP adapter by default. A developer may explicitly select a restricted Infobip profile with allowlisted test numbers through `.env`; adapter selection never falls back at runtime.
- Production SMS OTP uses Infobip's 2FA API through a purpose-specific adapter. The integration documents application/message-template identifiers, Brazilian sender-registration prerequisites, API-key ownership, delivery limits, challenge verification, and provider-failure behavior.
- Production credentials are dedicated to Berufe. Stable staging and integration use a separate restricted Infobip application/profile and allowlisted test numbers. Local development uses that restricted profile only when explicitly selected; pull-request previews use the fake adapter and receive no provider credentials.
- Infobip is not Berufe's account, session, authorization, or administrator-password provider.
- Production-only credentials remain server-side and cannot enter the Nuxt client bundle.
- Local, pull-request preview, stable staging, and production configuration are clearly separated.

**Depends on:** S002.
**Covers:** Infrastructure §§4, 7.1, 12, and 14.

### S004 — Configure PostgreSQL and the database baseline

**Story:** As a backend developer, I want consistent database conventions so that later features begin with reliable data rules.

**Acceptance criteria:**

- Rails connects to the Compose PostgreSQL service and can create, migrate, seed, and reset development/test databases.
- Application tables default to UUID primary keys and UTC `timestamptz` timestamps.
- Migrations are the only supported mechanism for schema changes.
- A database readiness check is exposed through the Rails health endpoint without leaking configuration.

**Depends on:** S002.
**Covers:** Infrastructure §§3 and 9.

### S005 — Configure GoodJob and the worker

**Story:** As an operator, I want retryable noninteractive background work to run from PostgreSQL so that image processing and maintenance do not block web requests.

**Acceptance criteria:**

- GoodJob is the Active Job adapter in development, stable staging, and production; ordinary tests use the Rails test adapter unless they specifically exercise GoodJob.
- GoodJob runs in `external` execution mode outside tests, and the Compose `worker` starts it with `bundle exec good_job start` to process one `default` queue for image sanitization/processing, expired counter/token/file/session cleanup, aggregate maintenance, and nonurgent provider reconciliation. Interactive OTP initiation is explicitly excluded.
- The API uses `RAILS_MAX_THREADS=5` and `DB_POOL=5`; the worker uses `GOOD_JOB_MAX_THREADS=2` and `DB_POOL=5`. Deployment documentation uses `(API replicas × API pool) + (worker replicas × worker pool) + migration/admin allowance`, reserves 15 connections for one API/worker replica plus administration, selects a plan with at least 20 available connections, and recalculates before scaling.
- GoodJob tables are created through committed Rails migrations in the existing PostgreSQL database.
- A harmless probe job can be enqueued, processed, failed, retried, and inspected.
- The worker exposes GoodJob's HTTP running/started/connected probes; the dashboard is mounted only behind an active password-authenticated admin session.
- Jobs receive a request or correlation ID when originating from a web request.
- Job code is documented as retry-safe; no Redis or alternative queue is added.

**Depends on:** S004.
**Covers:** Infrastructure §§3, 6, and 15.

### S006 — Establish API and frontend integration conventions

**Story:** As a frontend developer, I want one predictable API contract so that pages handle data and errors consistently.

**Acceptance criteria:**

- `apps/contracts/openapi.yaml` is a valid OpenAPI 3.1.0 document and the source of truth for all `/api/v1` product operations.
- Successful and failed JSON responses follow the contract; the shared error envelope contains `code`, safe `message`, optional `field_errors` as field-name-to-message-array entries, and string `request_id`.
- Lists support deterministic ordering and pagination when needed.
- The contract declares the Rails application-session cookie security requirement and the exact-origin rule for authenticated mutations.
- `apps/web` provides `api:generate` using `openapi-typescript ../contracts/openapi.yaml -o app/services/api/schema.d.ts`; the generated file is committed.
- `app/services/api/client.ts` uses `openapi-fetch` to handle the API base URL, credentials, and typed operations; `errors.ts` normalizes the shared error envelope.
- Rails request specs use `openapi_first` against the same file to validate important requests/responses and report operation/status coverage.
- A sample endpoint proves browser-to-Nuxt-to-Rails communication and contract validation in Compose.

**Depends on:** S003, S004.
**Covers:** Infrastructure §5 and §§6–7.

### S007 — Configure the UI foundation

**Story:** As a product developer, I want a small shared visual foundation so that MVP screens are consistent and accessible.

**Acceptance criteria:**

- Nuxt UI is installed and is the only component toolkit.
- Berufe colors, typography, spacing, and component defaults are configured centrally.
- A base public layout and authenticated layout work on mobile and desktop.
- A small page demonstrates form controls, validation feedback, buttons, navigation, loading, empty, and error states.
- No second component library, standalone design-system package, or Storybook is added.

**Depends on:** S001.
**Covers:** Infrastructure §§3, 7, and 13.

### S008 — Enforce code quality and automated tests

**Story:** As a team, we want automatic quality checks so that the monorepo remains safe to change.

**Acceptance criteria:**

- Backend scripts run Standard Ruby, Brakeman, and RSpec.
- Frontend scripts run Nuxt's supported ESLint integration, Prettier formatting checks, Nuxt typecheck, and Vitest. ESLint formatting rules are disabled and Prettier is the only formatter.
- Biome and a direct RuboCop configuration are not installed.
- RSpec request-test and Vitest component-test examples pass in containers.
- Test data is synthetic and no test reaches a real provider.

**Depends on:** S002, S006, S007.
**Covers:** Infrastructure §§13–14.

### S009 — Add continuous integration and build verification

**Story:** As a team, we want every proposed change checked automatically so that broken builds do not reach `master`.

**Acceptance criteria:**

- GitHub Actions builds both Dockerfiles and runs backend and frontend non-writing checks.
- Backend CI runs Standard, Brakeman, RSpec, and Rails boot/migration checks.
- Frontend CI runs `pnpm api:generate`, `git diff --exit-code app/services/api/schema.d.ts`, Nuxt ESLint, Prettier check, Nuxt typecheck, Vitest, and the production build from `apps/web`.
- Backend RSpec executes the OpenAPI contract checks and fails on undocumented important request/response variants or contract coverage regressions.
- An integration job can start the root Compose stack for changes crossing the API boundary.
- CI excludes secrets, generated files such as `schema.d.ts`, lockfiles, and incompatible Rails YAML/ERB from repository formatting.

**Depends on:** S008.
**Covers:** Infrastructure §§3 and 14.

## 5. Increment 1 — Access, roles, and controlled catalogs

**Status:** DONE

**Increment outcome:** professionals and admins can securely access Berufe, and the product has the controlled service/location vocabulary needed by onboarding and Finder.

### S010 — Seed the service and Joinville catalogs

**Status:** DONE

**Story:** As Berufe operations, I want an approved service and neighborhood catalog so that profiles and search use the same vocabulary.

**Acceptance criteria:**

- Migrations create `service_categories`, `services`, and `neighborhoods` with the constraints defined in Feature E2.
- Seed data using ./apps/web/data/catalogs.json. The `all` entry is a derived “Toda Joinville” selector and is not persisted as a neighborhood.
- Seeds are idempotent and use stable slugs/codes plus deterministic `sort_order` values for every reorderable catalog, including neighborhoods.
- Public read endpoints return active entries in configured order.

**Depends on:** S004, S006.
**Covers:** Feature E2.

### S011 — Request a phone OTP

**Status:** DONE

**Story:** As a professional, I want to request a code using my Brazilian phone number so that I can access Berufe without a password.

**Acceptance criteria:**

- The login page accepts and normalizes Brazilian numbers to E.164.
- Rails applies a resend cooldown and conservative daily allowances by phone and IP using short-lived PostgreSQL digests/counters.
- Rails synchronously starts the challenge through a small SMS-OTP adapter. Production uses Infobip; stable staging and integration use restricted Infobip with an explicit allowlist; local development selects fake or restricted Infobip through `.env`; automated tests and pull-request previews use fake delivery. No OTP-delivery job is enqueued.
- Infobip owns the OTP value and delivery result. Rails stores a short-lived `otp_challenge` that binds an encrypted normalized phone and encrypted Infobip challenge ID to a separate high-entropy browser token stored only as a digest; it also stores short-lived abuse-control digests/counters.
- The API contract defines accepted, invalid-phone, rate-limited, provider-unavailable, and delivery-rejected outcomes. Rate-limit responses include `Retry-After` and every failure uses the shared safe error envelope.
- Responses do not reveal whether an account exists and do not log phone numbers, OTPs, or request bodies.
- The UI immediately explains cooldown, delivery rejection, and provider-unavailable states without polling or bypassing verification.
- Request/contract tests cover accepted, malformed phone, cooldown/daily rate limit with `Retry-After`, delivery rejection, provider timeout/unavailability, and the invariant that no OTP-delivery job is enqueued.

**Depends on:** S005, S006, S008.
**Covers:** Feature A1; Infrastructure §§8 and 12.

### S012 — Verify the Infobip OTP and create a Rails application session

**Status:** DONE

**Story:** As a professional, I want to submit the received code so that Berufe can create an authenticated browser session.

**Acceptance criteria:**

- Rails verifies the code through the Infobip adapter and never stores the OTP.
- Verification requires the unexpired, unconsumed Rails challenge token, decrypts the bound Infobip reference/phone only server-side, and consumes the challenge atomically on success.
- A successful check validates the challenge result and creates or finds the Rails-owned professional account by its unique verified E.164 phone. SMS verification never creates or authenticates an admin account. The Rails UUID is the stable Berufe identity; an Infobip challenge ID is not an account identifier.
- Rails creates an `application_session` containing a unique token digest, account ID, `sms_otp` authentication method, authentication time, last activity, idle/absolute expiries, and nullable revocation time.
- The browser receives only the random application-session token in the host-only `__Host-berufe_session` cookie with `Secure`, `HttpOnly`, `SameSite=Lax`, and `Path=/`; no `Domain` is set.
- Infobip credentials and raw Rails challenge/session tokens never enter browser storage or application logs; no authentication material is stored in `localStorage`.
- Professional sessions use 7-day idle and 30-day absolute expiry; admin sessions use 30-minute idle and 12-hour absolute expiry. Last-activity persistence is throttled.
- Invalid, expired, and provider-unavailable results use generic safe messages.
- The Infobip 2FA implementation remains behind the same small adapter. Production always uses it, stable staging and integration use a restricted allowlisted configuration, local development may explicitly select it, and automated tests and pull-request previews use the fake implementation.
- Model/request tests cover token hashing, professional idle and absolute boundaries, throttled activity writes, refusal to authenticate admins by SMS, invalid/expired verification, and safe provider-unavailable behavior.

**Depends on:** S011.
**Covers:** Feature A1; Infrastructure §8.

### S013 — Restore, inspect, and end a session

**Status:** DONE

**Story:** As an authenticated user, I want my session restored safely and to be able to sign out so that access works across normal browser navigation.

**Acceptance criteria:**

- Nuxt can request the current account/session summary without receiving the raw stored session token or any provider token; the browser holds no authentication material of its own, since the host-only session cookie is `HttpOnly`.
- Rails authenticates each request locally from the application-session token digest, enforces idle/absolute expiry, and then applies account status, role, and authorization policies without contacting the provider.
- Logout revokes the current application session and clears the browser cookie. Suspension and the admin revoke-all action invalidate every application session for the account immediately.
- Existing Rails sessions continue through a provider outage until their own expiry or revocation; new challenge initiation/verification returns a safe `503`.
- Expired OTP counters, provider challenge references, and application sessions are purged by retry-safe GoodJob jobs according to the retention matrix.
- Authenticated routes redirect cleanly to login while Rails remains the authorization authority.
- Request tests cover current-session reads, idle/absolute expiry, logout of one session, revoke-all/suspension, and continued local authentication during provider outage.

**Depends on:** S012, S005.
**Covers:** Feature A1; Infrastructure §§6 and 8.

### S014 — Protect browser sessions with CORS and origin controls

**Status:** DONE

**Story:** As a user, I want authenticated changes protected against cross-site requests so that another site cannot act as me.

**Acceptance criteria:**

- Credentialed CORS uses only exact local, stable-staging, and production Nuxt origins; pull-request previews are absent and no Vercel wildcard is allowed.
- Every state-changing request, authenticated or not, requires an exact valid origin; a missing or non-matching `Origin` is refused before the action runs. `SameSite=Lax` on the session cookie is the complementary control, since the browser never attaches it to a cross-site mutation.
- Nuxt sends credentialed requests through the shared API client and holds no token of its own; the browser supplies the `Origin` header, which page scripts cannot forge.
- Security headers cover content type, framing, and referrer behavior.
- Request tests prove exact allowed-origin success; missing origins, malformed origins, Vercel preview origins, and all other cross-origin mutations are rejected on every mutating route, including OTP challenge and verification.

**Depends on:** S012.
**Covers:** Infrastructure §§8 and 12.

### S015 — Add roles and record-level authorization

**Status:** DONE

**Story:** As Berufe, I want explicit professional and admin authorization so that users can access only permitted records and actions.

**Acceptance criteria:**

- Accounts support `professional` and `admin` roles plus `active` and `suspended` states.
- Each account has a Rails UUID. Professional accounts have a unique verified E.164 phone, while administrator accounts use their unique normalized email; Infobip challenge IDs remain short-lived authentication metadata and are never treated as Berufe account identities.
- Pundit policies and scopes protect authenticated endpoints, owned records, admin actions, and approved public data.
- Public serializers exclude private and restricted fields by default.
- Policy/request tests prove anonymous, owner, non-owner, admin, and suspended-user behavior.
- Hiding or suspending public content removes it from public API responses immediately.

**Depends on:** S013.
**Covers:** Features A1 and E1; Infrastructure §§6, 8–9, and 12.

### S016 — Complete professional registration and create a draft profile

**Status:** DONE

**Story:** As a first-time professional, I want to provide my name and accept the terms so that I can begin building my profile.

**Acceptance criteria:**

- A first-time authenticated professional must enter a display name and accept the current terms/privacy notice.
- Rails records the accepted terms version, privacy-notice version, and acceptance time, then creates exactly one draft professional profile for the account.
- Returning professionals skip completed registration and enter the dashboard/setup flow.
- Customers do not receive general-purpose accounts.

**Depends on:** S013, S015.
**Covers:** Feature A1 and the invited-professional entry path in Feature C1.

### S017 — Secure admin access with password authentication and audit context

**Status:** DONE

**Story:** As a Berufe admin, I want stronger access protection so that sensitive moderation and verification work is not protected by phone login alone.

**Acceptance criteria:**

- Admin accounts are provisioned deliberately with a unique normalized email and strong password and cannot be created through professional registration or SMS login.
- `AdminSeed` is the only application service allowed to create an admin account; non-production `db:seed` calls it idempotently, while production execution is refused with a warning. There is no administrator-creation API or separate provisioning task.
- Admins authenticate through a dedicated email/password API endpoint and Nuxt route; professional login remains SMS-only.
- Rails stores only a BCrypt password digest, uses generic authentication failures and conservative database-backed throttling, and never logs or serializes credentials.
- Seed provisioning and manual password resets are audited operations; each creates an append-only event with the target admin, operator identifier, request ID, action, and time.
- Admin routes require the admin role, an unexpired 30-minute-idle/12-hour-absolute session, and the `password` authentication method.
- Admin actions receive the acting admin ID and request ID for later audit records.
- There is no multi-level moderator permission system in the MVP.

**Depends on:** S012, S015.
**Covers:** Feature E1; Infrastructure §8.

### S018 — Manage services and Joinville neighborhoods

**Status:** DONE

**Story:** As a Berufe administrator, I want to maintain the controlled catalog so that onboarding and Finder use an accurate vocabulary without requiring a deployment for routine changes.

**Acceptance criteria:**

- An active administrator with a password-authenticated session can list, add, rename, reorder, activate, and deactivate services and Joinville neighborhoods through typed OpenAPI operations and Nuxt forms.
- The neighborhood list exposes UF, city, and neighborhood columns and supports independent accent-insensitive free-text filters for all three fields; launch data remains limited to Joinville, SC.
- “Toda Joinville” is derived by Nuxt for professional/public selection and is not persisted or exposed through the private neighborhood-management endpoint.
- When creating a neighborhood, Nuxt suggests its stable code from the typed name using lowercase ASCII kebab case (`Santo Antônio` → `santo-antonio`); the administrator may adjust it before saving, after which it is immutable.
- A service always retains one controlled category assignment and an administrator may reassign it among the existing categories; service-category hierarchy changes and search-alias administration remain post-MVP.
- A new service inherits the selected category icon and starts with no search aliases; neither field is added to the administrator form.
- Stable service slugs and neighborhood codes cannot change after creation, and entries referenced by profiles, searches, evidence, or historical aggregates cannot be hard-deleted.
- Every mutation persists deterministic `sort_order`, records the acting administrator and request ID, and returns the shared error envelope for validation or conflict failures.
- Inactive entries remain available to historical serializers but cannot be selected for new professional records or public searches.
- Policy/request tests prove that professional and anonymous callers cannot read the private management endpoint or mutate the catalog; frontend tests cover opening and closing the populated edit modal, add, rename, reorder, status changes, neighborhood filters, validation, and error states.

**Depends on:** S010, S015, S017.
**Covers:** Feature E2; Infrastructure §§6, 9, and 14.

## 6. Increment 2 — Credible professional supply

**Status:** DONE

**Increment outcome:** founding professionals can create, submit, and receive approval for complete profiles, portfolio evidence, and verification labels. Approved profiles are safe to expose publicly.

**Approved implementation detail:** `Berufe_Increment_2_Implementation_Plan.md` resolves the Increment 2 workflow, mockup, API, retention, and delivery-order decisions and is normative for S019–S031.

### S019 — Edit professional identity and contact information

**Status:** DONE

**Story:** As a professional, I want to edit my public identity, WhatsApp contact, and optional social profile links so that customers understand who I am and where they can see more of my work.

**Acceptance criteria:**

- The profile form supports display name, headline, short biography, declared years of experience, WhatsApp phone, and independently optional Instagram and YouTube profile links.
- The WhatsApp phone defaults to the confirmed account phone and is normalized to E.164.
- Instagram accepts a bare or `@` handle and a direct Instagram profile URL; YouTube accepts a bare or `@` handle and a direct `youtube.com/@handle` channel URL. Rails stores canonical HTTPS profile URLs and removes copied query strings/fragments.
- Off-platform URLs, Instagram post/reel paths, and YouTube video, playlist, or legacy channel paths are rejected with field-level errors; an empty value remains valid.
- Field lengths and valid experience ranges are enforced in Rails and reflected as immediate form feedback.
- The professional can edit only their own draft or permitted published profile fields.
- Declared experience is labeled as declared, never verified.

**Depends on:** S016, S007.
**Covers:** Feature A2.

### S020 — Select services and service areas

**Status:** DONE

**Story:** As a professional, I want to select what I do and where I work so that I can appear in relevant searches.

**Acceptance criteria:**

- The form uses only active catalog services and Joinville neighborhoods.
- A professional must choose at least one service and exactly one primary service; that service is the singular main service shown on the public profile.
- The professional can select specific neighborhoods or “all Joinville” without creating contradictory records.
- Duplicate service and service-area records are prevented by database constraints. The all-city nullable area uses a partial unique index or `NULLS NOT DISTINCT`, so multiple “all Joinville” rows cannot bypass uniqueness through `NULL` semantics.
- Optional specialization notes are short and do not create new categories.

**Depends on:** S010, S019.
**Covers:** Feature A2.

### S021 — Create a stable public slug and inline profile representation

**Status:** DONE

**Story:** As a professional, I want a stable public profile URL and an inline representation of public fields so that I understand what customers will eventually see.

**Acceptance criteria:**

- Rails assigns a unique, human-readable, stable `public_slug`.
- The authenticated editor presents the draft's public fields and clearly marks declarations, pending evidence, and content that is not yet public without adding a separate preview route or API operation.
- Anonymous requests cannot infer draft or pending records.
- Later display-name changes do not silently break an already shared slug.

**Depends on:** S019, S020.
**Covers:** Features A2 and B3.

### S022 — Submit a profile for moderation

**Status:** DONE

**Story:** As a professional, I want to submit a sufficiently complete profile so that Berufe can review it for publication.

**Acceptance criteria:**

- A calculated checklist identifies missing required identity, service, and area data.
- Submission changes the profile from `draft` to `pending_review` in one transaction.
- Incomplete profiles cannot be submitted and receive field/actionable errors.
- A professional can see the current status but cannot publish their own profile.
- Submission validates the already-persisted four-step onboarding state, including one reviewable portfolio item and one reviewable identity request; the final action does not resend an accumulated browser payload.
- Editing material published content creates or updates one private pending revision while the previous approved revision remains the complete public snapshot. Approval swaps the public revision atomically; rejection leaves the previous snapshot public and returns the rejected revision to an editable private state.

**Depends on:** S021.
**Covers:** Features A2 and A6.

### S023 — Build the shared moderation queue and audit trail

**Status:** DONE

**Story:** As an admin, I want one oldest-first queue for pending content so that the founding cohort can be reviewed consistently.

**Acceptance criteria:**

- The admin area lists profile revisions/photos, portfolio items, and identity-verification requests oldest first, with pagination plus type/status/search filters. Accepted professional relationships join this queue in Increment 4.
- The reviewer sees only fields and files required for the selected decision.
- The existing review preview loads regenerated profile-photo and portfolio images through authenticated, no-store Rails responses with an immutable admin access record; storage keys and permanent private URLs never reach Nuxt.
- Approve, reject, hide, and restore actions create immutable `moderation_actions` with actor, target, action, private reason, time, and request ID.
- Rejection and hide require a private reason.
- Pending, rejected, and hidden items never appear through public scopes.

**Depends on:** S017, S022.
**Covers:** Feature E1.

### S024 — Approve and publish a professional profile

**Status:** DONE

**Story:** As an admin, I want to approve or reject a submitted profile so that only suitable profiles become searchable.

**Acceptance criteria:**

- Approval publishes the first revision or atomically replaces the public revision pointer. Rejection returns the reviewed revision to an editable private state with a reason visible to its owner while any previous approved revision remains public.
- Public serializers expose only approved profile, service, and coverage fields.
- Hide, suspend, and restore operations update public availability immediately.
- Professionals can see moderation status and rejection guidance in the authenticated UI.
- State-transition, policy, and serializer tests cover every allowed path.

**Depends on:** S023.
**Covers:** Features A2 and E1.

### S025 — Configure local and R2 object storage

**Status:** DONE

**Story:** As a professional, I want to upload permitted files without sending large file bodies through Rails so that media workflows are reliable.

**Acceptance criteria:**

- A small Rails-owned storage adapter uses an authenticated Rails upload endpoint backed by local disk in development and separate public/private Cloudflare R2 buckets in deployed environments.
- Rails authorizes upload purpose, ownership, declared content type, and declared size before issuing a 10-minute upload authorization to a private quarantine key.
- After upload confirmation, a retry-safe job checks actual bytes and file signature, safely decodes with libvips, normalizes orientation, strips metadata, and re-encodes into a new private object. It deletes the quarantine original after processing; mismatched, oversized, or undecodable uploads are rejected and deleted without becoming reviewable.
- Pending media and verification evidence remain private, and a processing failure is rejected without exposing the object to an admin or the public.
- Approved feature records persist public URLs/keys as defined by Features A2–A4. A narrowly scoped pending-upload record holds temporary private keys for profile/portfolio media until approval; verification evidence uses `verification_file`.
- R2 credentials and permanent verification-file URLs never reach Nuxt.
- Provider adapter tests use fakes and do not contact R2.
- The generic sanitizer preserves the verified JPEG/PNG codec, never retains the client filename, and expires abandoned authorizations through GoodJob every 10 minutes. Purpose-specific stories create any stricter derived variants.

**Depends on:** S003, S015.
**Covers:** Features A2–A4; Infrastructure §§4 and 10.

### S026 — Upload and moderate the profile photo

**Status:** DONE

**Story:** As a professional, I want to add a profile photo so that customers can recognize me while unsafe or unapproved images remain private.

**Acceptance criteria:**

- The profile accepts one optional JPEG/PNG image no larger than 10 MiB or 25 megapixels and produces one metadata-free JPEG fitted within 1024 × 1536 pixels.
- The sanitized image remains private until approved and replaces the public photo only after moderation.
- libvips safely decodes, normalizes orientation, re-encodes, removes metadata, and creates the required display variant through a retry-safe job.
- Upload, processing, rejection, and replacement states are visible to the owner.
- A failed processing job is visible and retryable without duplicating records.

**Depends on:** S005, S023, S025.
**Covers:** Features A2 and E1; Infrastructure §§6 and 10.

### S027 — Create and manage portfolio items

**Status:** DONE

**Story:** As a professional, I want to add and manage examples of completed work so that customers can see relevant evidence.

**Acceptance criteria:**

- A professional can upload an image, select one catalog service, add a short title/description, and submit the item.
- Rails enforces ownership and a maximum of 12 non-deleted items per professional.
- Approved items appear newest first, with ID as the deterministic tie-breaker.
- Images use the same private-upload, libvips-processing, and public-variant rules as profile photos.
- Pending or rejected items are visible to the owner but not anonymous users.
- Deletion is soft deletion through the existing management action. Manual ordering is not exposed; public ordering remains newest first.

**Depends on:** S020, S025, S026.
**Covers:** Feature A3.

### S028 — Moderate portfolio items

**Status:** DONE

**Story:** As an admin, I want to approve, reject, hide, and restore portfolio items so that public portfolios contain reviewed evidence only.

**Acceptance criteria:**

- Portfolio items appear in the shared moderation queue.
- Approval makes the optimized variant public and preserves its service association and order.
- Rejection or hiding removes public access and records the reason without exposing it publicly.
- The owner sees item status and rejection guidance.
- Public portfolio queries return approved items only.

**Depends on:** S027.
**Covers:** Features A3 and E1.

### S029 — Submit private verification evidence

**Status:** DONE

**Story:** As a professional, I want to request identity verification so that Berufe can publish a precise evidence label.

**Acceptance criteria:**

- The professional requests the launch `identity` verification type and uploads only JPEG or PNG evidence no larger than 10 MiB or 25 megapixels.
- Rails creates at most one pending `identity` `verification_request` for the professional and associates exactly one private regenerated image.
- The evidence becomes reviewable only after signature inspection, byte/dimension limits, safe decoding, orientation normalization, metadata stripping, and re-encoding into a new private object succeed. Extensions and browser MIME types are never trusted.
- PDFs and other retained documents are rejected; malware scanning is deferred while those formats remain out of scope.
- Document numbers are not collected unless a later approved operational requirement makes them essential.
- Only the owner can see request status; only admins can retrieve the regenerated evidence through authenticated, audited access without a permanent URL.
- The UI explains that verification is evidence checking, not a work guarantee.

**Depends on:** S025, S024.
**Covers:** Feature A4.

### S030 — Review verification and publish precise labels

**Status:** DONE

**Story:** As an admin, I want to approve or reject verification evidence so that customers can distinguish checked facts from declarations.

**Acceptance criteria:**

- Verification requests appear in the shared moderation queue.
- Approval records reviewer/time and publishes the controlled “Identity verified” label; professionals cannot write their own labels.
- Rejection requires a private reason visible to the professional.
- Public APIs return only the label and verification date, never files, identifiers, or review notes.
- Phone confirmation is represented separately from manually reviewed identity evidence. Company/certificate verification types are not accepted by the MVP API.

**Depends on:** S029, S023.
**Covers:** Features A4 and E1.

### S031 — Protect and retain restricted files

**Status:** DONE

**Story:** As Berufe operations, I want verification-file access and retention controlled so that identity evidence is not kept or exposed unnecessarily.

**Acceptance criteria:**

- Every admin access to verification evidence records actor, request, target, time, and action without logging the file contents or signed URL.
- Admins can access only regenerated evidence through short-lived authorization with the exact image content type, `X-Content-Type-Options: nosniff`, `Cache-Control: no-store`, and `Content-Disposition: inline` using a server-generated filename; the uploaded filename is never reflected.
- Identity evidence is retained while pending and for 30 days after approval or rejection; decision, label, moderation, and access-audit metadata remain after file deletion. Qualified Brazilian privacy/legal signoff is required before real-user intake.
- A retry-safe cleanup job deletes eligible private objects and records `deleted_at`.
- Deleted evidence cannot be regenerated through an old URL. The browser revokes the temporary object URL used by the existing admin document action after 60 seconds.
- Tests prove anonymous, professional, non-reviewing path, quarantined/failed object, content-signature mismatch, oversized/dimension-limit, and expired-link denial.

**Depends on:** S030, S005.
**Covers:** Feature A4; Infrastructure §§9–10 and 12.

## 7. Increment 3 — Public discovery and direct contact

**Increment outcome:** customers can search Joinville services, compare transparent evidence, open an approved public profile, and contact one chosen professional through WhatsApp.

### S032 — Publish the public home and search entry

**Status:** DONE

**Story:** As a customer, I want to choose a residential service from the home page so that I can begin a relevant search without understanding Berufe’s internal taxonomy.

**Acceptance criteria:**

- The server-rendered home page asks what service is needed and defaults location to Joinville.
- Suggestions use only active controlled services. The visitor may still submit an unmatched typed term so Berufe can record unmet demand without creating a lead.
- Public pages include correct title, description, canonical URL, and share metadata.
- Results URLs preserve selected service/neighborhood state. No dedicated category landing page, free-form lead request, multi-city selector, map, or paid placement is present.

**Depends on:** S010, S007, S024.
**Covers:** Feature B1.

### S033 — Search published professionals

**Status:** DONE

**Story:** As a customer, I want to filter professionals by service and neighborhood so that results match what I need and where I live.

**Acceptance criteria:**

- When an active service is selected or a known spelling variation resolves to one, the public API returns only published professionals offering that service and serving the selected neighborhood or all Joinville.
- A selected/resolved service is required to return professionals; an unmatched term returns no professionals plus safe related-service suggestions. Neighborhood is the only optional profile filter.
- Indexed PostgreSQL queries meet the agreed small-catalog response target without an external search engine.
- Common known spelling variations are normalized in application code.
- No-result responses suggest a related active service or changing the neighborhood; they never create a lead.

**Depends on:** S024, S032.
**Covers:** Feature B1.

### S034 — Record privacy-friendly search aggregates

**Status:** DONE

**Story:** As Berufe product operations, I want aggregate search demand data so that I can identify missing supply without tracking customers.

**Acceptance criteria:**

- A search records selected service when available, normalized query, Joinville/neighborhood, result count, and time.
- Each anonymous search event can record whether at least one result profile was opened; it does not record a visitor or a list of every profile viewed.
- The event stores no customer account, phone number, name, free-form note, cookie identifier, or persistent visitor identity.
- Clearly malformed/sensitive input is not retained.
- Recording failure never blocks customer results.
- Admin/product access is aggregate-only for the MVP.
- Daily aggregate data retains the total searches needed as the denominator for the search-to-profile-open success signal and supplies the administrator growth report defined by R001–R014.

**Depends on:** S033.
**Covers:** Feature B1 and MVP success signals.

### S035 — Show transparent, deterministic results

**Status:** DONE

**Story:** As a customer, I want each result to show relevant evidence and explainable ordering so that I can choose whom to inspect without trusting an opaque score.

**Acceptance criteria:**

- Each card shows photo, name, exact matching service, coverage, precise verification labels, and approved portfolio/relationship counts.
- Ordering follows the approved sequence: exact service, neighborhood coverage, identity verification, portfolio evidence, professional-relationship evidence, then recent profile update.
- The API and UI display no numeric trust score, sponsored rank, availability, or price sort.
- Ordering is deterministic for equivalent records and covered by request/query tests.
- Pending, rejected, hidden, or suspended evidence contributes neither labels nor counts.
- Result-to-profile links carry the anonymous search-event context. The first profile open marks that search as having produced an open; later opens from the same search do not increase the search-level numerator.

**Depends on:** S033, S028, S030.
**Covers:** Feature B2.

### S036 — Render the public professional profile

**Status:** DONE

**Story:** As a customer, I want one mobile-first page containing all approved evidence so that I can decide whether to contact a professional.

**Acceptance criteria:**

- The stable slug route is server-rendered and contains identity/coverage, optional Instagram/YouTube profile links, labels, services/declared experience, portfolio, and professional relationships in the approved order.
- The page distinguishes verified facts, declarations, recommendations, and collaborations.
- Only approved public serializers feed the route; unknown, draft, hidden, and suspended profiles return the correct non-public response.
- The page includes the verification-not-a-guarantee disclaimer and useful share metadata.
- Raw phone numbers are not presented as ordinary public text.
- Only present, approved social links are rendered; each is labeled for its platform, opens as a safe external link in a new tab, and no empty social-links container appears.
- A successful public-profile render increments the privacy-friendly daily profile-view aggregate with short-lived duplicate filtering; metric failure never blocks the page.

**Depends on:** S035.
**Covers:** Feature B3.

### S037 — Open a direct WhatsApp conversation and count the handoff

**Status:** DONE

**Story:** As a customer, I want to contact one selected professional through WhatsApp so that I can continue the conversation directly without a Berufe lead marketplace.

**Acceptance criteria:**

- Search results and the public profile offer a `wa.me` action with an encoded, short pt-BR message naming Berufe and the viewed service.
- Tapping records an anonymous daily aggregate for that professional with source `search_result` or `public_profile`, then opens WhatsApp.
- A copy-number or equivalent practical fallback is available when the deep link cannot open.
- Berufe does not proxy, store, or claim visibility into message content, delivery, negotiation, or hiring.
- Basic short-lived deduplication prevents obvious repeated browser taps from inflating counts without creating a permanent visitor table.
- Internal aggregates can calculate search-to-profile-open and public-profile-to-WhatsApp conversion without a visitor identity; no professional-facing analytics UI is added.

**Depends on:** S035, S036.
**Covers:** Feature B4 and Feature A6 metrics; Infrastructure §11.

Public profiles also show a visible Berufe support/report contact that routes to the documented manual operations process. The launch MVP does not persist a `content_report` record or expose an anonymous report API.

## 8. Increment 4 — Existing-member professional trust graph

**Increment outcome:** published professionals can represent recommendations and prior collaboration with other Berufe members through controlled, confirmed, moderated relationships.

### S042 — Initiate a relationship with an existing member

**Story:** As a verified professional, I want to recommend or record work with another published professional so that real professional trust can be represented.

**Acceptance criteria:**

- Only a professional with an approved `identity` verification can initiate a public relationship; phone confirmation, company verification, or certificate verification alone does not satisfy this gate.
- The initiator selects a published recipient, chooses `recommendation` or `worked_together`, and may add one short context note.
- Rails prevents self-relationships and duplicate initiator/recipient/type records.
- The new relationship is pending and not public.
- Search for recipients exposes published professional identity only.

**Depends on:** S030, S035.
**Covers:** Feature C1.

### S043 — Accept or decline a professional relationship

**Story:** As a recipient professional, I want to accept or decline a relationship so that nothing is made public without my confirmation.

**Acceptance criteria:**

- The recipient sees pending relationships on authenticated pages and can accept or decline each once.
- Only the recipient can respond; the initiator cannot accept for them.
- Acceptance records response time and submits the exact relationship type and optional context note to the shared moderation queue; it is not public yet.
- Declined relationships remain private and do not affect public counts.
- “Worked together” is never public without confirmation by both parties.

**Depends on:** S042.
**Covers:** Feature C1 and Feature A6 pending actions.

### S046 — Moderate and display professional trust relationships publicly

**Story:** As an admin and customer, I want accepted professional relationships reviewed before publication so that network evidence is controlled and transparent rather than anonymous.

**Acceptance criteria:**

- Accepted relationships enter the shared moderation queue, where an admin can approve, reject, hide, or restore them with the same audit rules as other moderated content.
- Public profiles show only recipient-accepted and admin-approved relationships with author/other professional, exact type, and approved context when present.
- Result cards count only recipient-accepted, admin-approved, visible relationships.
- Rejected, hidden, declined, pending, unreviewed, or suspended-party relationships are excluded immediately.
- No follower counts, feed, messaging, forum, job board, or generic social graph is added.
- Public relationship projections are covered by policy and serializer tests.

**Depends on:** S023, S043, S036.

**Covers:** Features C1, B2, and B3.

## 9. Increment 5 — Professional dashboard, profile sharing, and quote utility

**Increment outcome:** professionals have a focused home screen for completing and sharing their Berufe presence plus one practical customer workflow.

### S047 — Show profile readiness and pending work

**Story:** As a professional, I want one dashboard showing what needs attention so that I can complete and maintain my Berufe presence.

**Acceptance criteria:**

- The dashboard calculates profile readiness from existing data without a checklist table.
- It shows profile/publication status, missing setup steps, pending moderation/verification, and pending relationship confirmations.
- Primary actions link to edit profile, add portfolio, request identity verification, find an existing member for a relationship, and create a quote.
- Profile sharing uses the Web Share API and falls back to copying the stable public URL.
- Empty and rejected states explain the next permitted action.
- A professional sees only their own records.

**Depends on:** S022, S030, S043.

**Covers:** Feature A6.

### S049 — Create and edit a draft quote

**Story:** As a professional, I want to create a simple itemized quote so that I can use Berufe in a frequent customer workflow.

**Acceptance criteria:**

- The owner can create and edit a draft with customer name, short service description, ordered line items, optional discount, validity date, and length-limited notes.
- Quantities are greater than zero, unit prices are non-negative, and discount cannot exceed subtotal.
- Rails recalculates each line total, subtotal, discount, and total with `BigDecimal`; Nuxt calculations are preview-only and persisted client totals are never trusted.
- Quote numbers are sequential per professional and assigned concurrency-safely.
- Draft quote and customer data is private to the owner and available to admins only when operationally required.
- OpenAPI operations, generated Nuxt types, owner/admin policy tests, validation tests, and request contract tests ship with the feature.

**Data shape:** `quote` contains UUID `id`, owner `professional_id`, per-professional sequential `quote_number`, required `customer_name` and `service_description`, decimal `discount_amount` and server-calculated `total_amount`, optional `valid_until` and notes, `draft|shared` status, unique nullable `share_token_hash`, timestamps, and nullable `shared_at`. `quote_item` contains UUID `id`, `quote_id`, required description, positive decimal quantity, length-limited unit label, non-negative decimal unit price, server-calculated line total, and deterministic `sort_order`.

**Depends on:** S015, S047.
**Covers:** Feature D1; Infrastructure §9.

### S050 — Preview and share a secure quote link

**Story:** As a professional, I want to preview and share an unguessable quote link so that a customer can view it without an account.

**Acceptance criteria:**

- The owner can preview the current quote in the same mobile-first presentation used by the customer page.
- First share generates a high-entropy token, stores only its hash, and atomically changes status from `draft` to `shared`.
- A valid bearer link returns only the quote and approved professional public identity/labels; it never exposes private profile fields.
- Malformed, invalid, revoked, or unknown tokens reveal no quote or customer details.
- The token remains valid only while the quote is `shared`; `valid_until` describes the commercial offer and is not token expiry.
- Token-authorized API and Nuxt responses use `Cache-Control: private, no-store` and `noindex`, and never enter shared caches, static generation, logs, analytics payloads, or search indexes.
- The customer can use browser print. There is no server PDF, acceptance, signature, invoice, or payment flow.

**Depends on:** S030, S049.
**Covers:** Feature D1; Infrastructure §§9 and 14.

### S051 — Share a quote through WhatsApp and record the action

**Story:** As a professional, I want to share a quote through my device so that the customer receives the secure link through my normal WhatsApp workflow.

**Acceptance criteria:**

- The action opens an explicit WhatsApp deep link with a short message and quote URL, with copy-link fallback.
- The explicit share action increments `quotes_shared` in the professional's daily aggregate with the same privacy and non-negative counter rules as other MVP aggregates.
- Berufe does not send, read, or track a WhatsApp message and never claims delivery, acceptance, signature, payment, or completion.
- Sharing a previously shared quote reuses the active token rather than exposing or persisting another raw token.
- The initial lifecycle remains only `draft` or `shared`.

**Depends on:** S037, S050.
**Covers:** Features D1 and A6; Infrastructure §11.

## 10. Increment 6 — Privacy-safe administrator growth reporting

**Increment outcome:** an administrator can make founding-cohort supply, discovery, utility, and moderation decisions from trustworthy aggregate metrics without visitor tracking.

Implementation is specified by `Berufe_Reports_Stories.md` R001–R014. Those stories are part of the launch MVP and must ship as one coherent feature: admin authorization, time-zone-aware period semantics, aggregate-only Rails queries, OpenAPI operation and generated Nuxt types, the responsive report UI, formula/privacy tests, and honest empty or unavailable states.

The MVP report includes only implemented launch domains: professional supply and activation, anonymous aggregate search/discovery, meaningful professional activity and retention, existing-member relationships, simple quotes, and the shared moderation queue. It omits client recommendations, external invitations, persisted content reports, and professional-facing analytics until their V2 stories are separately approved.

**Depends on:** S017, S023–S024, S030, S034, S036–S037, S046, and S049–S051.

**Covers:** Feature E3; Infrastructure §§9, 12, and 14; Reports R001–R014.

## 11. Increment 7 — Production readiness and launch

**Increment outcome:** the release candidate meets the architecture launch gate and can safely onboard the founding 30–50 professionals.

### S052 — Add privacy-safe logs, health checks, and error alerts

**Story:** As an operator, I want correlated platform logs and exception alerts so that MVP failures across Vercel, Render, and GoodJob are visible without logging sensitive payloads.

**Acceptance criteria:**

- Rails and Nuxt accept inbound request IDs only when they match ASCII `[A-Za-z0-9._-]{1,100}` and otherwise generate a UUID; Nuxt forwards the accepted/generated value to Rails and Rails propagates it into GoodJob jobs and Bugsnag events.
- Logs and Bugsnag exclude cookies, authorization headers, request parameters/bodies, phone numbers, OTPs, raw Infobip/application-session/share tokens or challenge secrets, signed URLs, verification files, quote customer details, and job arguments.
- Separate Bugsnag projects capture Rails/Active Job/GoodJob exceptions and Nuxt browser/SSR exceptions. Production source maps are uploaded privately.
- Bugsnag is error-only: performance monitoring, distributed tracing, automatic session tracking, user/anonymous identification, and IP collection are disabled. Events include only release, environment, normalized route or job class, request ID, exception, and stack trace.
- Production unhandled exceptions, terminal job failures, and GoodJob executor/thread failures immediately notify the named operations owner.
- Health endpoints distinguish Rails readiness and GoodJob running/started/database-connected states without leaking secrets.
- Successful GoodJob records are retained for 14 days and reviewed discarded failures for 30 days; unresolved failures are not automatically deleted and cleanup runs daily.
- The GoodJob dashboard requires an active password-authenticated admin application session. The documented procedure covers inspection, retry, discard review, and escalation.
- Queue monitoring warns when the oldest runnable job exceeds five minutes and alerts critically at fifteen minutes; operators can also identify failed logins/uploads and old moderation work.
- Automated tests prove the redaction callbacks remove every prohibited field, and a production-like smoke event verifies delivery, project routing, release metadata, source-map resolution, and owner notification before launch.

**Depends on:** S005, S013, S025.
**Covers:** Infrastructure §§12 and 15.

### S053 — Define privacy, terms, retention, and user-data operations

**Story:** As Berufe operations, I want documented and executable privacy rules so that real-user data is collected and retained only as needed.

**Acceptance criteria:**

- The production terms and privacy notice are versioned and linked at registration and public-page locations where appropriate.
- A retention matrix covers application sessions, Infobip challenge references, OTP counters, GoodJob records, anonymous search events, daily professional/report aggregates, pending/quarantined uploads, moderation data, support/report correspondence, quotes and their customer data/share tokens, and verification files.
- Operations can correct, suspend, and delete an account/profile through a documented manual procedure.
- Deletion handles public data, private data, storage objects, and required audit retention explicitly.
- Qualified Brazilian privacy/legal review is recorded as a launch dependency, not implemented as application automation.

**Depends on:** S016, S031, S037.

**Covers:** Infrastructure §§9, 12, 15, and 18.

### S054 — Configure isolated staging, previews, and production deployments

**Story:** As a team, we want repeatable separate deployments so that release candidates can be verified without production data.

**Acceptance criteria:**

- Nuxt deploys to Vercel and Rails plus the GoodJob worker deploy from the same backend image to Render.
- Render PostgreSQL is the only production application database; Nuxt cannot connect to it directly.
- One stable staging Nuxt deployment connects to one stable staging Rails API/worker, PostgreSQL database, R2 configuration, and a restricted Infobip profile limited to allowlisted test numbers.
- Vercel pull-request previews are mock-only and receive neither a staging API URL nor staging credentials. Credentialed CORS excludes preview origins and contains no wildcard.
- Production Infobip credentials are absent from stable staging and previews. Any separately approved integration environment uses a restricted Infobip application/message profile and allowlisted test numbers.
- The Nuxt SSR execution location and Rails/PostgreSQL region are recorded. Rails and PostgreSQL run together in the closest practical Render region.
- Release-like tests from the target Brazilian region show public Rails API p95 ≤ 500 ms and public HTML TTFB p95 ≤ 1.5 seconds.
- A Rails timeout or outage renders a branded Nuxt `503`/retry state with a request ID. If either latency target fails, launch is blocked until the cause is fixed or a separate change adds 60-second public SWR plus invalidation on approval, hiding, restoration, and suspension.
- Authenticated, admin, restricted-file, and bearer-token quote responses are never placed in shared caches; quote pages are not statically generated.
- Migrations run as an explicit release step before dependent code.
- Deployment failure preserves the last working version or has a documented forward-fix path.

**Depends on:** S009, S052.
**Covers:** Infrastructure §§3–4, 7.1, 14–15.

### S055 — Implement the five release-critical end-to-end flows

**Story:** As a team, we want browser tests for the essential value loop so that a release cannot silently break Berufe’s MVP promise.

**Acceptance criteria:**

- Playwright covers: professional Infobip-adapter OTP login/profile submission; admin profile/evidence approval; public search/profile/WhatsApp handoff; existing-member professional relationship confirmation plus moderation; and draft quote creation, secure preview/share, valid customer view, invalid-token denial, and print behavior.
- Tests use fake OTP/provider behavior and synthetic files/data.
- Chromium mobile paths run for release-critical changes; focused WebKit and keyboard smoke checks run before production release.
- Tests assert user-visible behavior rather than implementation details or snapshot-only output.
- A failed critical flow blocks release.

**Depends on:** S017, S030, S037, S046, S051, S054.

**Covers:** Infrastructure §§14 and 18; complete MVP value loop.

### S056 — Verify database backups and restoration

**Story:** As an operator, I want a proven database recovery path so that an infrastructure failure does not turn into untested guesswork.

**Acceptance criteria:**

- Production uses a paid managed PostgreSQL plan with confirmed backup retention.
- A restore is completed into a non-production environment and documented with date, owner, duration, and validation result.
- Restored data is access-restricted and removed after the exercise according to the privacy procedure.
- Public media re-upload and private-evidence re-request are documented as the MVP storage-loss approach.
- No custom cross-provider backup system is added.

**Depends on:** S053, S054.
**Covers:** Infrastructure §§15 and 18.

### S057 — Complete the launch checklist and operating ownership

**Story:** As the product owner, I want one explicit launch decision so that real users are accepted only after security, recovery, moderation, and core flows are ready.

**Acceptance criteria:**

- Every item in Infrastructure §18 is checked with evidence or blocks launch.
- Named owners exist for deployments, database access, Infobip spend/sender registration, R2 private access, Bugsnag alerts, moderation, and privacy requests.
- Failed-job inspection/retry, profile suspension, credential rotation, and disabling a broken flow are documented and rehearsed at least once where safe.
- OpenAPI generation has a clean diff, Rails contract coverage including `getAdminGrowthReport` passes, report formula/privacy tests pass, GoodJob probes/queue-age alerts work, Bugsnag delivery/redaction is tested, and SSR latency/outage criteria have evidence.
- The service/location seed is reviewed for the Joinville launch and the founding cohort onboarding process is ready.
- Infobip's Brazilian sender registration is approved, the production 2FA application/message template is configured, spend limits/alerts have an owner, and one controlled production-like start/verify smoke check succeeds without exposing credentials or a real user's phone.
- All five Playwright flows pass against the release candidate and no critical security/privacy defect remains open.

**Depends on:** S010, S031, S052, S053, S055, S056, and R014.

**Covers:** Infrastructure §§15 and 18; all MVP features.

## 12. Increment summary

| Increment               | Stories         | Demonstrable result                                                                                            |
| ----------------------- | --------------- | -------------------------------------------------------------------------------------------------------------- |
| 0. Foundation           | S001–S009       | The four-service monorepo runs locally and passes CI.                                                          |
| 1. Access and catalogs  | S010–S018       | Professionals/admins can access the product; controlled catalogs are seeded and administratively maintainable. |
| 2. Credible supply      | S019–S031       | Professionals can be profiled, reviewed, verified, and published safely.                                       |
| 3. Discovery            | S032–S037       | Customers can find, inspect, and contact public professionals.                                                 |
| 4. Trust graph          | S042–S043, S046 | Approved existing-member trust evidence appears publicly.                                                      |
| 5. Dashboard and quotes | S047, S049–S051 | Professionals can maintain/share their profile and create/share simple quotes.                                 |
| 6. Admin reporting      | R001–R014       | Administrators can inspect aggregate MVP growth, utility, and moderation signals.                              |
| 7. Launch               | S052–S057       | Operations, privacy, recovery, deployment, and critical flows meet the launch gate.                            |

## 13. Feature coverage matrix

| Feature                                         | Primary stories                         |
| ----------------------------------------------- | --------------------------------------- |
| A1 — Professional account and onboarding        | S011–S016                               |
| A2 — Profile, services, and service area        | S019–S024                               |
| A3 — Portfolio                                  | S025–S028                               |
| A4 — Verification and public evidence labels    | S029–S031                               |
| A6 — Dashboard and profile sharing              | S043, S047                              |
| B1 — Public home and search                     | S032–S034                               |
| B2 — Transparent result list                    | S035                                    |
| B3 — Public professional profile                | S036, S046                              |
| B4 — Direct WhatsApp contact                    | S037                                    |
| C1 — Existing-member professional relationships | S042–S043, S046                         |
| D1 — Quote generator and secure share link      | S049–S051                               |
| E1 — Verification and moderation queue          | S017, S023–S024, S026, S028, S030, S046 |
| E2 — Service and location catalog               | S010, S018                              |
| E3 — Administrator growth report                | R001–R014                               |

## 14. Not stories in this MVP

Do not add backlog items for microservices, Redis, external search, graph/vector databases, automated WhatsApp messaging, CAPTCHA, Rack::Attack, Bugsnag performance monitoring/distributed tracing, payment systems, booking, internal chat, maps, native apps, multi-city support, feeds, CRM, server PDF generation or PDF verification uploads, analytics providers, or any item tracked in `Berufe_V2_Stories.md` unless the approved MVP scope changes.

This backlog is complete when S057 passes. Product usage after launch should determine which evidence-triggered MVP 2.0 stories are created next.
