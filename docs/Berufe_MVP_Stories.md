# Berufe — MVP Implementation Stories

**Status:** implementation backlog  
**Updated:** August 11, 2026  
**Sources:** *Berufe — MVP Feature Plan* and *Berufe — Lean MVP Infrastructure and Architecture*

## 1. Purpose

This document turns the approved Berufe MVP scope and architecture into an incrementally ordered implementation backlog.

The order is dependency-driven: establish a reproducible monorepo, enable secure access, build credible professional supply, expose it through public discovery, add trust relationships, deliver recurring professional utility, and then complete the launch gate.

The backlog intentionally excludes MVP 2.0 ideas and every item explicitly deferred by the source documents.

## 2. How to use this backlog

- Implement stories in numeric order unless a story explicitly has no unfinished dependency.
- A story is complete only when its backend, frontend, tests, authorization, and relevant documentation are complete.
- Keep each story releasable. Do not leave public endpoints exposing pending, rejected, private, or restricted data.
- The Feature Plan is the product source of truth. The architecture may add implementation detail, but it must not replace a Feature Plan behavior, scope boundary, data rule, or user experience. Conflicts are resolved in favor of the Feature Plan.
- Story estimates should be added by the implementation team after the repository is running. This document does not invent estimates before velocity is known.

### Story format

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
- `standardrb`, Biome lint, Prettier check, Nuxt typecheck, Brakeman, and the affected test suites pass.
- The story does not add a deferred technology or feature without updating the approved scope first.

## 4. Increment 0 — Reproducible development foundation

**Increment outcome:** a developer can clone the monorepo and start the complete local stack with one command. Both applications build and have enforceable quality checks.

### S001 — Create the monorepo skeleton

**Story:** As a developer, I want the frontend and backend in one repository so that product changes can be delivered together.

**Acceptance criteria:**

- The root contains `backend/`, `frontend/`, `compose.yaml`, `.env.example`, and `README.md`.
- `backend/` is a Rails 8.1 API-only application and `frontend/` is a Nuxt/Vue TypeScript application.
- Ruby, Node, Rails, Nuxt, and package versions are pinned; dependency lockfiles are committed.
- The README contains only the commands needed to install, start, test, lint, format, and stop the project.

**Depends on:** none.  
**Covers:** Infrastructure §§2–3 and §7.1.

### S002 — Run the local stack through Docker Compose

**Story:** As a developer, I want one command to run Berufe locally so that environment setup is consistent.

**Acceptance criteria:**

- `docker compose up --build` starts `frontend`, `backend`, `worker`, and `db`.
- The backend and worker use the same backend image and environment definition.
- PostgreSQL has a health check and named development volume; dependent services wait for database readiness.
- Frontend and backend source changes reload without rebuilding the entire stack.
- The local stack does not require Redis, MinIO, a live authentication provider, R2, or production credentials.

**Depends on:** S001.  
**Covers:** Infrastructure §7.1.

### S003 — Establish environment configuration and safe local adapters

**Story:** As a developer, I want explicit and safe environment configuration so that local work cannot accidentally use production services.

**Acceptance criteria:**

- `.env.example` lists required variable names and safe development defaults without secrets.
- Rails validates required environment variables at boot for the selected environment.
- Development uses a local-disk storage adapter and a fake hosted-auth adapter by default.
- The selected production auth provider is documented and proven to support Brazilian SMS OTP, stable external account IDs, server-verifiable sessions, admin MFA, and verification-only phone challenges that do not create customer accounts.
- Production-only credentials remain server-side and cannot enter the Nuxt client bundle.
- Local, preview/staging, and production configuration are clearly separated.

**Depends on:** S002.  
**Covers:** Infrastructure §§4, 7.1, 12, and 14.

### S004 — Configure PostgreSQL and the database baseline

**Story:** As a backend developer, I want consistent database conventions so that later features begin with reliable data rules.

**Acceptance criteria:**

- Rails connects to the Compose PostgreSQL service and can create, migrate, seed, and reset development/test databases.
- Application tables default to UUID primary keys and UTC `timestamptz` timestamps.
- Money conventions use PostgreSQL `numeric` and Ruby `BigDecimal`.
- Migrations are the only supported mechanism for schema changes.
- A database readiness check is exposed through the Rails health endpoint without leaking configuration.

**Depends on:** S002.  
**Covers:** Infrastructure §§3 and 9.

### S005 — Configure GoodJob and the worker

**Story:** As an operator, I want retryable background work to run from PostgreSQL so that image processing, OTP delivery, and cleanup tasks do not block web requests.

**Acceptance criteria:**

- GoodJob is the Active Job adapter in development, preview/staging, and production; ordinary tests use the Rails test adapter unless they specifically exercise GoodJob.
- GoodJob runs in `external` execution mode outside tests, and the Compose `worker` starts it with `bundle exec good_job start` to process one `default` queue for image processing, OTP-delivery requests, and expired-token/file cleanup.
- GoodJob tables are created through committed Rails migrations in the existing PostgreSQL database.
- A harmless probe job can be enqueued, processed, failed, retried, and inspected.
- Jobs receive a request or correlation ID when originating from a web request.
- Job code is documented as retry-safe; no Redis or alternative queue is added.

**Depends on:** S004.  
**Covers:** Infrastructure §§3, 6, and 15.

### S006 — Establish API and frontend integration conventions

**Story:** As a frontend developer, I want one predictable API contract so that pages handle data and errors consistently.

**Acceptance criteria:**

- Rails routes are prefixed with `/api/v1` and return JSON.
- Successful and failed responses follow documented shapes; validation failures include stable error codes and field errors.
- Lists support deterministic ordering and pagination when needed.
- Nuxt has one typed API client that handles the API base URL, credentials, CSRF header, and normalized errors.
- A sample endpoint proves browser-to-Nuxt-to-Rails communication in Compose.

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
- Frontend scripts run Biome lint with its formatter disabled, Prettier formatting checks, Nuxt typecheck, and Vitest.
- ESLint and a direct RuboCop configuration are not installed.
- RSpec request-test and Vitest component-test examples pass in containers.
- Test data is synthetic and no test reaches a real provider.

**Depends on:** S002, S006, S007.  
**Covers:** Infrastructure §§13–14.

### S009 — Add continuous integration and build verification

**Story:** As a team, we want every proposed change checked automatically so that broken builds do not reach `main`.

**Acceptance criteria:**

- GitHub Actions builds both Dockerfiles and runs backend and frontend non-writing checks.
- Backend CI runs Standard, Brakeman, RSpec, and Rails boot/migration checks.
- Frontend CI runs Biome lint, Prettier check, Nuxt typecheck, Vitest, and the production build.
- An integration job can start the root Compose stack for changes crossing the API boundary.
- CI excludes secrets, generated files, lockfiles, and incompatible Rails YAML/ERB from repository formatting.

**Depends on:** S008.  
**Covers:** Infrastructure §§3 and 14.

## 5. Increment 1 — Access, roles, and controlled catalogs

**Increment outcome:** professionals and admins can securely access Berufe, and the product has the controlled service/location vocabulary needed by onboarding and Finder.

### S010 — Seed the service and Joinville catalogs

**Story:** As Berufe operations, I want an approved service and neighborhood catalog so that profiles and search use the same vocabulary.

**Acceptance criteria:**

- Migrations create `service_categories`, `services`, and `neighborhoods` with the constraints defined in Feature E2.
- Seed data contains only the approved residential renovation/maintenance categories, services, and Joinville neighborhoods.
- Seeds are idempotent and use stable slugs/codes plus deterministic `sort_order` values for every reorderable catalog, including neighborhoods.
- Public read endpoints return active entries in configured order.

**Depends on:** S004, S006.  
**Covers:** Feature E2.

### S011 — Request a phone OTP

**Story:** As a professional, I want to request a code using my Brazilian phone number so that I can access Berufe without a password.

**Acceptance criteria:**

- The login page accepts and normalizes Brazilian numbers to E.164.
- Rails applies a resend cooldown and conservative daily allowances by phone and IP using short-lived PostgreSQL digests/counters.
- Rails enqueues a retry-safe OTP-delivery request through a small hosted-auth adapter; local and test environments use a fake implementation.
- The hosted provider owns the OTP value and delivery result; Berufe stores only short-lived abuse-control digests/counters and a provider challenge reference when required.
- Responses do not reveal whether an account exists and do not log phone numbers, OTPs, or request bodies.
- The UI explains cooldown and provider-unavailable states without bypassing verification.

**Depends on:** S005, S006, S008.  
**Covers:** Feature A1; Infrastructure §§8 and 12.

### S012 — Verify the OTP and create a secure session

**Story:** As a professional, I want to submit the received code so that Berufe can create an authenticated browser session.

**Acceptance criteria:**

- Rails verifies the code through the hosted-auth adapter and never stores the OTP.
- A successful check validates the provider response, creates or finds the account by its unique `auth_provider_id`, and synchronizes the verified E.164 phone.
- The browser receives the provider-backed session in a secure, HTTP-only cookie with an explicit expiry; auth tokens are never stored in `localStorage` or persisted in Berufe's business tables.
- Invalid, expired, and provider-unavailable results use generic safe messages.
- The selected hosted passwordless provider is implemented for non-local environments behind the same small adapter.

**Depends on:** S011.  
**Covers:** Feature A1; Infrastructure §8.

### S013 — Restore, inspect, and end a session

**Story:** As an authenticated user, I want my session restored safely and to be able to sign out so that access works across normal browser navigation.

**Acceptance criteria:**

- Nuxt can request the current account/session summary without receiving the raw provider token.
- Rails validates the provider session and then applies the Berufe account status, role, and authorization policies.
- Logout clears the browser cookie and revokes the provider session when supported.
- Expired provider sessions and sessions for suspended Berufe accounts are rejected.
- Expired OTP counters and provider challenge references are purged by a retry-safe GoodJob job.
- Authenticated routes redirect cleanly to login while Rails remains the authorization authority.

**Depends on:** S012, S005.  
**Covers:** Feature A1; Infrastructure §§6 and 8.

### S014 — Protect browser sessions with CORS and CSRF controls

**Story:** As a user, I want authenticated changes protected against cross-site requests so that another site cannot act as me.

**Acceptance criteria:**

- CORS uses exact local, preview/staging, and production Nuxt origins and allows credentials only for them.
- State-changing cookie-authenticated requests require a CSRF token and valid origin.
- Nuxt obtains and sends the CSRF token through the shared API client.
- Security headers cover content type, framing, and referrer behavior.
- Request tests prove allowed-origin success and cross-origin rejection.

**Depends on:** S012.  
**Covers:** Infrastructure §§8 and 12.

### S015 — Add roles and record-level authorization

**Story:** As Berufe, I want explicit professional and admin authorization so that users can access only permitted records and actions.

**Acceptance criteria:**

- Accounts support `professional` and `admin` roles plus `active` and `suspended` states.
- Each account has the unique stable `auth_provider_id` and verified E.164 phone supplied by the hosted authentication provider; authentication credentials remain provider-owned.
- Pundit policies and scopes protect authenticated endpoints, owned records, admin actions, and approved public data.
- Public serializers exclude private and restricted fields by default.
- Policy/request tests prove anonymous, owner, non-owner, admin, and suspended-user behavior.
- Hiding or suspending public content removes it from public API responses immediately.

**Depends on:** S013.  
**Covers:** Features A1 and E1; Infrastructure §§6, 8–9, and 12.

### S016 — Complete professional registration and create a draft profile

**Story:** As a first-time professional, I want to provide my name and accept the terms so that I can begin building my profile.

**Acceptance criteria:**

- A first-time authenticated professional must enter a display name and accept the current terms/privacy notice.
- Rails records the accepted terms version, privacy-notice version, and acceptance time, then creates exactly one draft professional profile for the account.
- Returning professionals skip completed registration and enter the dashboard/setup flow.
- Customers do not receive general-purpose accounts.
- Registration works when initiated from a valid professional invitation without automatically publishing a relationship.

**Depends on:** S013, S015.  
**Covers:** Feature A1 and the invited-professional entry path in Feature C1.

### S017 — Secure admin access with MFA and audit context

**Story:** As a Berufe admin, I want stronger access protection so that sensitive moderation and verification work is not protected by phone login alone.

**Acceptance criteria:**

- Admin accounts are provisioned deliberately and cannot be created through professional registration.
- Admin login requires TOTP or an equivalent approved second factor through the hosted authentication provider.
- Admin routes require both a valid session and the admin role.
- Admin actions receive the acting admin ID and request ID for later audit records.
- There is no multi-level moderator permission system in the MVP.

**Depends on:** S012, S015.  
**Covers:** Feature E1; Infrastructure §8.

### S018 — Manage service and location catalogs

**Story:** As an admin, I want to rename, reorder, activate, and deactivate catalog entries so that Berufe can correct its controlled vocabulary without deleting history.

**Acceptance criteria:**

- Admin API and Nuxt forms support rename, reorder, activation, and deactivation for service categories, services, and neighborhoods; each reorderable table persists `sort_order`.
- Referenced entries cannot be hard-deleted.
- Only admins can mutate the catalog; policy tests prove professional and anonymous denial.
- Professionals and public search cannot select inactive entries for new records.

**Depends on:** S010, S015, S017.  
**Covers:** Feature E2.

## 6. Increment 2 — Credible professional supply

**Increment outcome:** founding professionals can create, submit, and receive approval for complete profiles, portfolio evidence, and verification labels. Approved profiles are safe to expose publicly.

### S019 — Edit professional identity and contact information

**Story:** As a professional, I want to edit my public identity and WhatsApp contact so that customers understand who I am and how to reach me.

**Acceptance criteria:**

- The profile form supports display name, headline, short biography, declared years of experience, and WhatsApp phone.
- The WhatsApp phone defaults to the confirmed account phone and is normalized to E.164.
- Field lengths and valid experience ranges are enforced in Rails and reflected as immediate form feedback.
- The professional can edit only their own draft or permitted published profile fields.
- Declared experience is labeled as declared, never verified.

**Depends on:** S016, S007.  
**Covers:** Feature A2.

### S020 — Select services and service areas

**Story:** As a professional, I want to select what I do and where I work so that I can appear in relevant searches.

**Acceptance criteria:**

- The form uses only active catalog services and Joinville neighborhoods.
- A professional must choose at least one service and exactly one primary service; that service is the singular main service shown on the public profile.
- The professional can select specific neighborhoods or “all Joinville” without creating contradictory records.
- Duplicate service and service-area records are prevented by database constraints. The all-city nullable area uses a partial unique index or `NULLS NOT DISTINCT`, so multiple “all Joinville” rows cannot bypass uniqueness through `NULL` semantics.
- Optional specialization notes are short and do not create new categories.

**Depends on:** S010, S019.  
**Covers:** Feature A2.

### S021 — Create a stable public slug and profile preview

**Story:** As a professional, I want to preview a stable public profile URL so that I know what customers will eventually see and can share the same address later.

**Acceptance criteria:**

- Rails assigns a unique, human-readable, stable `public_slug`.
- The professional can preview their own draft, including pending content, through an authenticated endpoint.
- The preview clearly marks declarations, pending evidence, and content that is not yet public.
- Anonymous requests cannot use the preview endpoint or infer private records.
- Later display-name changes do not silently break an already shared slug.

**Depends on:** S019, S020.  
**Covers:** Features A2 and B3.

### S022 — Submit a profile for moderation

**Story:** As a professional, I want to submit a sufficiently complete profile so that Berufe can review it for publication.

**Acceptance criteria:**

- A calculated checklist identifies missing required identity, service, and area data.
- Submission changes the profile from `draft` to `pending_review` in one transaction.
- Incomplete profiles cannot be submitted and receive field/actionable errors.
- A professional can see the current status but cannot publish their own profile.
- Editing material approved content creates a separate pending revision. The last approved snapshot remains public and unchanged until the revision is approved.

**Depends on:** S021.  
**Covers:** Features A2 and A6.

### S023 — Build the shared moderation queue and audit trail

**Story:** As an admin, I want one oldest-first queue for pending content so that the founding cohort can be reviewed consistently.

**Acceptance criteria:**

- The admin area lists pending profile content (including revisions and photos), portfolio items, client recommendations, accepted professional relationships, and verification requests oldest first, with simple type/status filters.
- The reviewer sees only fields and files required for the selected decision.
- Approve, reject, hide, and restore actions create immutable `moderation_actions` with actor, target, action, private reason, time, and request ID.
- Rejection and hide require a private reason.
- Pending, rejected, and hidden items never appear through public scopes.

**Depends on:** S017, S022.  
**Covers:** Feature E1.

### S024 — Approve and publish a professional profile

**Story:** As an admin, I want to approve or reject a submitted profile so that only suitable profiles become searchable.

**Acceptance criteria:**

- First approval publishes the profile atomically. Approval of a later revision atomically replaces the approved snapshot; rejection keeps the previous snapshot public and returns the rejected revision to an editable private state with a reason visible to its owner.
- Public serializers expose only approved profile, service, and coverage fields.
- Hide, suspend, and restore operations update public availability immediately.
- Professionals can see moderation status and rejection guidance in the authenticated UI.
- State-transition, policy, and serializer tests cover every allowed path.

**Depends on:** S023.  
**Covers:** Features A2 and E1.

### S025 — Configure local and R2 object storage

**Story:** As a professional, I want to upload permitted files without sending large file bodies through Rails so that media workflows are reliable.

**Acceptance criteria:**

- A small Rails-owned storage adapter uses local disk in development and separate public/private Cloudflare R2 buckets in deployed environments.
- Rails authorizes upload purpose, ownership, content type, and size before issuing a short-lived presigned upload.
- Pending media and verification evidence remain private.
- Approved feature records persist public URLs/keys as defined by Features A2–A4. A narrowly scoped pending-upload record holds temporary private keys for profile/portfolio media until approval; verification evidence uses `verification_file`.
- R2 credentials and permanent verification-file URLs never reach Nuxt.
- Provider adapter tests use fakes and do not contact R2.

**Depends on:** S003, S015.  
**Covers:** Features A2–A4; Infrastructure §§4 and 10.

### S026 — Upload and moderate the profile photo

**Story:** As a professional, I want to add a profile photo so that customers can recognize me while unsafe or unapproved images remain private.

**Acceptance criteria:**

- The profile accepts one supported image within the configured size limit.
- The image remains private until approved and replaces the public photo only after moderation.
- libvips creates the required display variant, re-encodes the image, and removes unnecessary metadata through a retry-safe job.
- Upload, processing, rejection, and replacement states are visible to the owner.
- A failed processing job is visible and retryable without duplicating records.

**Depends on:** S005, S023, S025.  
**Covers:** Features A2 and E1; Infrastructure §§6 and 10.

### S027 — Create and manage portfolio items

**Story:** As a professional, I want to add and order examples of completed work so that customers can see relevant evidence.

**Acceptance criteria:**

- A professional can upload an image, select one catalog service, add a short title/description, and submit the item.
- Rails enforces ownership and a maximum of 12 non-deleted items per professional.
- Approved items can be manually reordered with deterministic `sort_order` values.
- Images use the same private-upload, libvips-processing, and public-variant rules as profile photos.
- Pending or rejected items are visible to the owner but not anonymous users.

**Depends on:** S020, S025, S026.  
**Covers:** Feature A3.

### S028 — Moderate portfolio items

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

**Story:** As a professional, I want to request identity, company, or certificate verification so that Berufe can publish a precise evidence label.

**Acceptance criteria:**

- The professional selects one controlled verification type and uploads only its permitted private file type(s).
- Rails creates a pending `verification_request` and associated private file records.
- Document numbers are not collected unless a later approved operational requirement makes them essential.
- Only the owner can see request status; only admins can access the evidence through short-lived authorized access.
- The UI explains that verification is evidence checking, not a work guarantee.

**Depends on:** S025, S024.  
**Covers:** Feature A4.

### S030 — Review verification and publish precise labels

**Story:** As an admin, I want to approve or reject verification evidence so that customers can distinguish checked facts from declarations.

**Acceptance criteria:**

- Verification requests appear in the shared moderation queue.
- Approval records reviewer/time and selects a controlled public label; professionals cannot write their own labels.
- Rejection requires a private reason visible to the professional.
- Public APIs return only the label and verification date, never files, identifiers, or review notes.
- Phone confirmation is represented separately from manually reviewed identity/company/certificate evidence.

**Depends on:** S029, S023.  
**Covers:** Features A4 and E1.

### S031 — Protect and retain restricted files

**Story:** As Berufe operations, I want verification-file access and retention controlled so that identity evidence is not kept or exposed unnecessarily.

**Acceptance criteria:**

- Every admin access to verification evidence records actor, request, target, time, and action without logging the file contents or signed URL.
- A documented retention rule maps request states to deletion dates.
- A retry-safe cleanup job deletes eligible private objects and records `deleted_at`.
- Deleted evidence cannot be regenerated through an old URL.
- Tests prove anonymous, professional, non-reviewing path, and expired-link denial.

**Depends on:** S030, S005.  
**Covers:** Feature A4; Infrastructure §§9–10 and 12.

## 7. Increment 3 — Public discovery and direct contact

**Increment outcome:** customers can search Joinville services, compare transparent evidence, open an approved public profile, and contact one chosen professional through WhatsApp.

### S032 — Publish the public home and category routes

**Story:** As a customer, I want to choose a residential service from the home page so that I can begin a relevant search without understanding Berufe’s internal taxonomy.

**Acceptance criteria:**

- The server-rendered home page asks what service is needed and defaults location to Joinville.
- Suggestions use only active controlled services. The visitor may still submit an unmatched typed term so Berufe can record unmet demand without creating a lead.
- Stable category routes show the service name, a short explanation, and a path to results.
- Public pages include correct title, description, canonical URL, and share metadata.
- No free-form lead request, multi-city selector, map, or paid placement is present.

**Depends on:** S010, S007, S024.  
**Covers:** Feature B1.

### S033 — Search published professionals

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

**Story:** As Berufe product operations, I want aggregate search demand data so that I can identify missing supply without tracking customers.

**Acceptance criteria:**

- A search records selected service when available, normalized query, Joinville/neighborhood, result count, and time.
- Each anonymous search event can record whether at least one result profile was opened; it does not record a visitor or a list of every profile viewed.
- The event stores no customer account, phone number, name, free-form note, cookie identifier, or persistent visitor identity.
- Clearly malformed/sensitive input is not retained.
- Recording failure never blocks customer results.
- Admin/product access is aggregate-only for the MVP.
- Daily aggregate reporting exposes the total searches needed as the denominator for the search-to-profile-open success signal without exposing individual search rows.

**Depends on:** S033.  
**Covers:** Feature B1 and MVP success signals.

### S035 — Show transparent, deterministic results

**Story:** As a customer, I want each result to show relevant evidence and explainable ordering so that I can choose whom to inspect without trusting an opaque score.

**Acceptance criteria:**

- Each card shows photo, name, exact matching service, coverage, precise verification labels, and approved portfolio/recommendation/relationship counts.
- Ordering follows the approved sequence: exact service, neighborhood coverage, identity verification, portfolio evidence, recommendation/relationship evidence, then recent profile update.
- The API and UI display no numeric trust score, sponsored rank, availability, or price sort.
- Ordering is deterministic for equivalent records and covered by request/query tests.
- Pending, rejected, hidden, or suspended evidence contributes neither labels nor counts.
- Result-to-profile links carry the anonymous search-event context. The first profile open marks that search as having produced an open; later opens from the same search do not increase the search-level numerator.

**Depends on:** S033, S028, S030.  
**Covers:** Feature B2.

### S036 — Render the public professional profile

**Story:** As a customer, I want one mobile-first page containing all approved evidence so that I can decide whether to contact a professional.

**Acceptance criteria:**

- The stable slug route is server-rendered and contains identity/coverage, labels, services/declared experience, portfolio, client recommendations, and professional relationships in the approved order.
- The page distinguishes verified facts, declarations, recommendations, and collaborations.
- Only approved public serializers feed the route; unknown, draft, hidden, and suspended profiles return the correct non-public response.
- The page includes the verification-not-a-guarantee disclaimer and useful share metadata.
- Raw phone numbers are not presented as ordinary public text.

**Depends on:** S035.  
**Covers:** Feature B3.

### S037 — Open a direct WhatsApp conversation and count the handoff

**Story:** As a customer, I want to contact one selected professional through WhatsApp so that I can continue the conversation directly without a Berufe lead marketplace.

**Acceptance criteria:**

- Search results and the public profile offer a `wa.me` action with an encoded, short pt-BR message naming Berufe and the viewed service.
- Tapping records an anonymous daily aggregate for that professional with source `search_result` or `public_profile`, then opens WhatsApp.
- A copy-number or equivalent practical fallback is available when the deep link cannot open.
- Berufe does not proxy, store, or claim visibility into message content, delivery, negotiation, or hiring.
- Basic short-lived deduplication prevents obvious repeated browser taps from inflating counts without creating a permanent visitor table.

**Depends on:** S035, S036.  
**Covers:** Feature B4 and Feature A6 metrics; Infrastructure §11.

### S038 — Accept and triage content reports

**Story:** As a visitor, I want to report questionable public content so that Berufe operations can review it without creating a public dispute system.

**Acceptance criteria:**

- Public profiles expose a report form with controlled category, required length-limited explanation, and optional private contact.
- Reports can target profiles, portfolio items, client recommendations, or professional relationships.
- Valid reports enter the admin operations area with `open`, `resolved`, or `dismissed` status.
- Reporter contact and details are private and excluded from public APIs/logs.
- There are no public replies, appeals, or case-management workflows.

**Depends on:** S023, S036.  
**Covers:** Feature E1.

## 8. Increment 4 — Client and professional trust graph

**Increment outcome:** professionals can bring existing client trust and collaborator relationships into Berufe through controlled, confirmed, moderated flows.

### S039 — Create and share a client recommendation request

**Story:** As a professional, I want a one-time recommendation link so that a past client can confirm completed work without creating an account.

**Acceptance criteria:**

- The owner creates a request tied to their profile with an expiry and `open` status.
- Rails stores only a hash of a high-entropy token; the raw token is shown only in the generated share URL.
- The professional can open an explicit WhatsApp deep link containing the request URL, with copy-link fallback, and can revoke an open request.
- Expired, completed, revoked, malformed, and unknown tokens reveal no private data and cannot be submitted.
- Request creation does not send an automated WhatsApp message.

**Depends on:** S024, S014.  
**Covers:** Feature A5; Infrastructure §§8 and 11.

### S040 — Submit a phone-confirmed client recommendation

**Story:** As a past client, I want to confirm the service and submit a short recommendation so that my experience can support the professional’s profile.

**Acceptance criteria:**

- A valid request shows the professional and permits a display name, request-relevant service, approximate service period, short recommendation, and required service confirmation.
- The client requests and verifies a single-purpose phone challenge through the hosted-auth adapter without creating a `user_account`, reusable provider identity, or Berufe session.
- The challenge uses the same cooldown, daily allowance, generic-response, and no-OTP-storage rules as professional authentication.
- Rails stores a keyed one-way phone fingerprint for duplicate/abuse detection, not a public phone number.
- Submission atomically consumes the request and creates one pending recommendation.
- There are no stars, anonymous submissions, replies, exact service address, or imported reviews.

**Depends on:** S011, S039.  
**Covers:** Feature A5.

### S041 — Moderate and publish client recommendations

**Story:** As an admin, I want to review client recommendations so that only controlled social proof appears publicly.

**Acceptance criteria:**

- Pending recommendations appear in the shared moderation queue.
- Approval publishes display name, service, approximate period, text, and the phone-confirmed indication.
- Rejection/hiding records a private reason and removes public visibility/counts.
- Approved recommendations appear on the correct professional profile and increase its approved recommendation/confirmed-service count.
- Duplicate indicators assist manual review but do not automatically accuse or publicly label a client.

**Depends on:** S040, S023, S036.  
**Covers:** Features A5, B2, B3, and E1.

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

### S044 — Invite a professional who is not registered

**Story:** As a verified professional, I want to invite a trusted collaborator through a one-time link so that they can join Berufe and later confirm our relationship.

**Acceptance criteria:**

- The inviter provides only invitee first name and intended relationship type.
- Rails creates an expiring, revocable invitation and stores only the token hash.
- Sharing opens an explicit WhatsApp deep link containing the invitation URL, with copy-link fallback; Berufe sends no automated message.
- The invited person can begin registration from a valid token.
- Invalid, expired, accepted, or revoked tokens do not reveal inviter-private data or permit reuse.

**Depends on:** S039, S042, S016.  
**Covers:** Feature C1; Infrastructure §§8 and 11.

### S045 — Complete an invitation after profile approval

**Story:** As an invited professional, I want the intended relationship offered after my profile is approved so that joining does not automatically create public trust evidence.

**Acceptance criteria:**

- Registration retains the valid invitation association without storing the raw token.
- Profile approval creates or reveals the pending relationship to the invitee.
- The invitee must explicitly accept or decline it using the same rules as an existing member.
- Acceptance marks the invitation accepted and submits the confirmed relationship to the shared moderation queue; publication still requires admin approval.
- Expiry/revocation before completion prevents relationship creation.

**Depends on:** S024, S043, S044.  
**Covers:** Feature C1.

### S046 — Moderate and display professional trust relationships publicly

**Story:** As an admin and customer, I want accepted professional relationships reviewed before publication so that network evidence is controlled and transparent rather than anonymous.

**Acceptance criteria:**

- Accepted relationships enter the shared moderation queue, where an admin can approve, reject, hide, or restore them with the same audit rules as other moderated content.
- Public profiles show only recipient-accepted and admin-approved relationships with author/other professional, exact type, and approved context when present.
- Result cards count only recipient-accepted, admin-approved, visible relationships.
- Rejected, hidden, declined, pending, unreviewed, or suspended-party relationships are excluded immediately.
- No follower counts, feed, messaging, forum, job board, or generic social graph is added.
- Public relationship projections are covered by policy and serializer tests.

**Depends on:** S023, S043, S045, S036.  
**Covers:** Features C1, B2, and B3.

## 9. Increment 5 — Professional dashboard and quote utility

**Increment outcome:** professionals have a focused home screen and a practical reason to return: creating and sharing a simple quote.

### S047 — Show profile readiness and pending work

**Story:** As a professional, I want one dashboard showing what needs attention so that I can complete and maintain my Berufe presence.

**Acceptance criteria:**

- The dashboard calculates profile readiness from existing data without a checklist table.
- It shows profile/publication status, missing setup steps, pending moderation/verification, and pending relationship confirmations.
- Primary actions link to edit profile, add portfolio, request recommendation, invite collaborator, and create quote.
- Empty and rejected states explain the next permitted action.
- A professional sees only their own records.

**Depends on:** S022, S030, S039, S043.  
**Covers:** Feature A6.

### S048 — Show aggregate activity and share the profile

**Story:** As a professional, I want simple recent activity counts and an easy share action so that I can understand and promote my profile without visitor tracking.

**Acceptance criteria:**

- `professional_daily_metric` retains the Feature Plan totals (`profile_views`, `whatsapp_clicks`, and `quotes_shared`) and adds non-negative source counters for WhatsApp clicks from public profiles versus search results. Search events separately provide total searches and searches with at least one profile open.
- The dashboard shows 30-day totals for profile views, WhatsApp clicks, approved recommendations, confirmed relationships, and quotes shared.
- Public-profile views increment privacy-friendly aggregates with short-lived duplicate filtering.
- Product aggregates calculate search-to-profile-open as searches with at least one profile open divided by searches, and profile-to-WhatsApp-click as profile-originated WhatsApp handoffs divided by profile views; neither calculation uses a visitor identity.
- Profile sharing uses the Web Share API and falls back to copying the stable URL.
- No visitor identities, traffic-source reports, detailed charts, CRM, or notifications center are added.

**Depends on:** S037, S041, S046, S047.  
**Covers:** Feature A6 and MVP success signals.

### S049 — Create and edit a draft quote

**Story:** As a professional, I want to create a simple itemized quote so that I can use Berufe in my real customer workflow.

**Acceptance criteria:**

- The owner can create/edit a draft with customer name, short service description, ordered line items, optional discount, validity date, and notes.
- Quantities are greater than zero; unit prices are non-negative; discount cannot exceed subtotal.
- Rails recalculates every line total, subtotal, and total with `BigDecimal`; client calculations are preview-only.
- Quote numbers are sequential per professional and concurrency-safe.
- Draft customer/quote data is private to the owner and admins only when operationally required; after sharing, the customer-facing projection is additionally available only to a bearer of the valid quote token.

**Depends on:** S015, S047.  
**Covers:** Feature D1; Infrastructure §9.

### S050 — Preview and share a secure quote link

**Story:** As a professional, I want to preview and share an unguessable quote link so that a customer can view it without an account.

**Acceptance criteria:**

- The owner previews the quote in a mobile customer-facing layout before sharing.
- First share generates a high-entropy token, stores only its hash, and atomically changes status from `draft` to `shared`.
- A valid link shows the quote and approved professional public identity/labels; it does not expose private profile fields.
- Invalid or unknown tokens reveal no quote/customer details.
- The token remains valid while the quote is `shared`; quote validity (`valid_until`) describes the commercial offer and is not a share-token expiry.
- Token-authorized quote responses use `no-store`/`noindex` behavior and are never included in shared caches or search indexes.
- The customer can use browser print; Berufe does not generate a PDF, acceptance, signature, invoice, or payment flow.

**Depends on:** S049, S030.  
**Covers:** Feature D1.

### S051 — Share the quote through WhatsApp and record the event

**Story:** As a professional, I want to share a quote through my device so that the customer receives the secure link using my normal WhatsApp workflow.

**Acceptance criteria:**

- Share opens an explicit WhatsApp deep link with a short message and quote URL, with copy-link fallback.
- Tapping the WhatsApp share action increments `quotes_shared` in the professional’s daily aggregate; Berufe does not claim delivery.
- Berufe does not send, read, or track a WhatsApp message or claim the quote was accepted/paid.
- Quote status remains only `draft` or `shared`.

**Depends on:** S048, S050.  
**Covers:** Features D1 and A6; Infrastructure §11.

## 10. Increment 6 — Production readiness and launch

**Increment outcome:** the release candidate meets the architecture launch gate and can safely onboard the founding 30–50 professionals.

### S052 — Add structured, privacy-safe operational logs

**Story:** As an operator, I want actionable platform logs so that MVP failures can be diagnosed without a centralized error tracker.

**Acceptance criteria:**

- Rails and Nuxt logs include request IDs; Rails propagates them into GoodJob jobs.
- Logs exclude phone numbers, OTPs, provider-session/raw share tokens, request bodies, verification files, signed URLs, and quote customer details.
- Health endpoints distinguish web and worker/database readiness without leaking secrets.
- Operators can identify failed logins, jobs, uploads, and old moderation work through platform tools.
- Sentry or another centralized error tracker is not introduced.

**Depends on:** S005, S013, S025.  
**Covers:** Infrastructure §§12 and 15.

### S053 — Define privacy, terms, retention, and user-data operations

**Story:** As Berufe operations, I want documented and executable privacy rules so that real-user data is collected and retained only as needed.

**Acceptance criteria:**

- The production terms and privacy notice are versioned and linked at registration and public-page locations where appropriate.
- A retention matrix covers provider-session/challenge references, OTP counters, anonymous search events and aggregates, pending uploads, invitation/recommendation tokens, reports, quotes, moderation data, and verification files.
- Operations can correct, suspend, and delete an account/profile through a documented manual procedure.
- Deletion handles public data, private data, storage objects, and required audit retention explicitly.
- Qualified Brazilian privacy/legal review is recorded as a launch dependency, not implemented as application automation.

**Depends on:** S016, S031, S038, S051.  
**Covers:** Infrastructure §§9, 12, 15, and 18.

### S054 — Configure preview/staging and production deployments

**Story:** As a team, we want repeatable separate deployments so that release candidates can be verified without production data.

**Acceptance criteria:**

- Nuxt deploys to Vercel and Rails plus the GoodJob worker deploy from the same backend image to Render.
- Render PostgreSQL is the only production application database; Nuxt cannot connect to it directly.
- Preview/staging uses synthetic data and separate database, R2, and hosted-auth-provider configuration from production.
- Migrations run as an explicit release step before dependent code.
- Deployment failure preserves the last working version or has a documented forward-fix path.

**Depends on:** S009, S052.  
**Covers:** Infrastructure §§3–4, 7.1, 14–15.

### S055 — Implement the five release-critical end-to-end flows

**Story:** As a team, we want browser tests for the essential value loop so that a release cannot silently break Berufe’s MVP promise.

**Acceptance criteria:**

- Playwright covers: professional OTP login/profile submission; admin profile/evidence approval; public search/profile/WhatsApp handoff; recommendation or relationship confirmation plus its moderation; and quote creation/share link.
- Tests use fake OTP/provider behavior and synthetic files/data.
- Chromium mobile paths run for release-critical changes; focused WebKit and keyboard smoke checks run before production release.
- Tests assert user-visible behavior rather than implementation details or snapshot-only output.
- A failed critical flow blocks release.

**Depends on:** S017, S030, S037, S041, S046, S051, S054.  
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
- Named owners exist for deployments, database access, authentication-provider spend, R2 private access, moderation, and privacy requests.
- Failed-job inspection/retry, profile suspension, credential rotation, and disabling a broken flow are documented and rehearsed at least once where safe.
- The service/location seed is reviewed for the Joinville launch and the founding cohort onboarding process is ready.
- All five Playwright flows pass against the release candidate and no critical security/privacy defect remains open.

**Depends on:** S018, S031, S052, S053, S055, S056.  
**Covers:** Infrastructure §§15 and 18; all MVP features.

## 11. Increment summary

| Increment | Stories | Demonstrable result |
| --- | --- | --- |
| 0. Foundation | S001–S009 | The four-service monorepo runs locally and passes CI. |
| 1. Access and catalogs | S010–S018 | Professionals/admins can access the product; controlled catalogs are ready. |
| 2. Credible supply | S019–S031 | Professionals can be profiled, reviewed, verified, and published safely. |
| 3. Discovery | S032–S038 | Customers can find, inspect, contact, and report public professionals. |
| 4. Trust graph | S039–S046 | Approved client and professional trust evidence appears publicly. |
| 5. Recurring utility | S047–S051 | Professionals have a dashboard and can create/share quotes. |
| 6. Launch | S052–S057 | Operations, privacy, recovery, deployment, and critical flows meet the launch gate. |

## 12. Feature coverage matrix

| Feature | Primary stories |
| --- | --- |
| A1 — Professional account and onboarding | S011–S016 |
| A2 — Profile, services, and service area | S019–S024 |
| A3 — Portfolio | S025–S028 |
| A4 — Verification and public evidence labels | S029–S031 |
| A5 — Client recommendation request | S039–S041 |
| A6 — Dashboard and profile sharing | S037, S043, S047–S048, S051 |
| B1 — Public home, categories, and search | S032–S034 |
| B2 — Transparent result list | S035 |
| B3 — Public professional profile | S036, S041, S046 |
| B4 — Direct WhatsApp contact | S037 |
| C1 — Professional invitation and relationships | S042–S046 |
| D1 — Quote generator and share link | S049–S051 |
| E1 — Verification and moderation queue | S017, S023–S024, S026, S028, S030, S038, S041, S046 |
| E2 — Service and location catalog | S010, S018 |

## 13. Not stories in this MVP

Do not add backlog items for microservices, Redis, external search, graph/vector databases, automated WhatsApp messaging, CAPTCHA, Rack::Attack, Sentry, payments, booking, internal chat, maps, native apps, multi-city support, feeds, CRM, PDF generation, analytics providers, or any other MVP 2.0 enhancement unless the approved scope changes.

This backlog is complete when S057 passes. Product usage after launch should determine which evidence-triggered MVP 2.0 stories are created next.
