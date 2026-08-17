# Berufe — Increment 2 Implementation Plan

**Status:** approved for implementation  
**Updated:** August 17, 2026  
**Scope:** S019–S031 — credible professional supply

## 1. Source-of-truth order

This document records the approved implementation detail for Increment 2. It is read together with, in priority order:

1. `Berufe_MVP_Feature_Plan.md` for product scope and user-facing behavior;
2. this Increment 2 implementation plan for the decisions made while reconciling that scope with the existing mockups;
3. `Berufe_MVP_Infrastructure_Architecture.md` for technical and operational constraints;
4. `Berufe_MVP_Stories.md` for story acceptance criteria and delivery status;
5. the existing `apps/web` mockups for the allowed pages, fields, and interaction surfaces.

The implementation must not add a field, page, route, or user-facing claim that is absent from the approved documents and mockups. Two small controls are explicitly approved because the MVP stories already require them: an optional profile-photo control in the identity section and an optional specialization note for each selected service. Any later divergence requires a recorded product decision in `docs/` before code changes.

## 2. Delivery order

Story IDs remain stable, but Increment 2 is implemented in dependency order:

`S019 → S020 → S021 → S025 → S026 → S027 → S029 → S022 → S023 → S024 → S028 → S030 → S031`

This order lets media, portfolio, and identity evidence exist before the initial profile is submitted, because the existing four-step onboarding requires one reviewable portfolio item and one reviewable identity request before its final action.

## 3. Approved workflow decisions

### Onboarding persistence and submission

- The four existing onboarding steps remain the only onboarding steps.
- Each step saves its own validated data immediately to Rails. The browser does not accumulate one final profile payload.
- The existing **Concluir onboarding** action performs only the final transition from `draft` to `pending_review` after Rails verifies the persisted checklist.
- Initial submission requires complete identity/contact data, at least one service with exactly one primary service, valid Joinville coverage, one reviewable portfolio item, and one reviewable identity-verification request.
- Profile photo and social profile links remain optional. All four existing steps are required for the current 100% onboarding completion presentation.

### Approved snapshot and later edits

- A professional profile has stable identity/workflow state and relational content revisions.
- The first approved revision becomes the public revision.
- When a published professional saves material profile, service, or coverage edits, Rails creates or updates one private working revision and submits it for review. The previously approved revision remains the complete public snapshot until the new revision is approved.
- Approval atomically swaps the public revision pointer. Rejection keeps the previous approved revision public and returns the rejected content to a private editable state with owner guidance.
- Public serializers never mix fields from approved and unreviewed revisions.
- Hide, restore, and account/profile suspension affect public eligibility immediately without destroying the approved snapshot.
- This decision intentionally brings the former V2-004 behavior into the launch MVP and supersedes earlier text that removed a published profile during material re-review.

### Services and coverage

- Services and areas belong to the working/approved profile revision so a public snapshot cannot be partially updated.
- At least one active catalog service and exactly one primary service are required.
- Each selected service may contain one optional specialization note of at most 120 characters.
- Coverage is either all Joinville or one or more active Joinville neighborhoods. Contradictory and duplicate records are rejected transactionally and by database indexes where possible.

### Media and evidence

- JPEG and PNG are the only accepted formats. Maximum declared and actual size is 10 MiB and maximum decoded image area is 25 megapixels.
- Upload authorization expires after 10 minutes.
- Production uses a private R2 quarantine upload; local development uses an authenticated Rails upload endpoint backed by the local storage adapter.
- Actual bytes and signature are inspected. libvips safely decodes, auto-orients, strips metadata, and re-encodes a new image. Quarantine originals are deleted immediately after successful processing and immediately on invalid input or terminal processing failure.
- A transient processing failure can retry the same upload record. Invalid content requires a new upload.
- A processed upload can be attached only once and only to the authorized owner and purpose.
- The optional profile photo produces one JPEG display image fitted inside 1024 × 1536 pixels. A replacement remains private until approval while the existing approved photo remains public.
- Portfolio management uses the existing form and list, permits at most 12 non-deleted items, uses soft deletion, and publishes approved items newest first with ID as the deterministic tie-breaker. Manual ordering remains out of scope.
- The launch identity-verification request accepts exactly one regenerated image. It does not collect document numbers or accept PDF, company, or certificate evidence.

### Moderation and restricted access

- One shared paginated moderation queue covers profile revisions, profile photos, portfolio items, and identity-verification requests.
- Results are oldest first and may be filtered by the existing type control, an approved status control beside it, and the existing search field.
- Approve and reject remain the primary review actions. The existing ellipsis action hosts hide or restore for previously approved content.
- Rejection and hide require a private reason. Every decision appends an immutable action with actor, target, action, reason/note, request ID, and timestamp.
- The existing **Abrir documento** action retrieves only the regenerated identity image through an authenticated, audited Rails response. It uses the exact image content type, `Cache-Control: no-store`, `X-Content-Type-Options: nosniff`, and a server-generated inline filename. The browser opens an object URL and revokes it after 60 seconds.
- Identity evidence is retained while pending and for 30 days after approval or rejection, then the private object is deleted by a retry-safe daily job. Decision, label, moderation, and access-audit metadata are retained. This is the implementation default and requires qualified Brazilian privacy/legal signoff before real-user intake.

## 4. Data and API contract

Rails is the authority for validation, state transitions, authorization, public eligibility, and moderation. Increment 2 adds relational profile revisions and revision-owned services/coverage, media uploads, profile photos, portfolio items, verification requests/files, moderation actions, and restricted-file access events.

The shared OpenAPI contract exposes these authenticated operations without adding Nuxt pages:

- `GET /api/v1/professional/workspace`
- `PATCH /api/v1/professional/profile`
- `POST /api/v1/professional/profile/submission`
- `POST /api/v1/professional/media-uploads`
- `PUT /api/v1/professional/media-uploads/{id}/content` for local storage only
- `POST /api/v1/professional/media-uploads/{id}/completion`
- `GET /api/v1/professional/media-uploads/{id}`
- `POST /api/v1/professional/media-uploads/{id}/retry`
- `PUT /api/v1/professional/profile/photo`
- `POST /api/v1/professional/portfolio-items`
- `DELETE /api/v1/professional/portfolio-items/{id}`
- `POST /api/v1/professional/verification-requests`
- `GET /api/v1/admin/moderation`
- `POST /api/v1/admin/moderation/{target_type}/{target_id}/decisions`
- `GET /api/v1/admin/verification-files/{id}/content`

The professional workspace response is the single authenticated projection used by onboarding, the profile editor, supply-related dashboard status/checklist content, portfolio management, and verification status. Public Finder/profile HTTP integration remains Increment 3; Increment 2 supplies a tested safe public projection without wiring the existing public mockup pages.

## 5. UI integration boundary

- Existing Nuxt pages remain thin and use typed API services/composables.
- No Pinia store is introduced for this server-owned workflow.
- Authenticated Increment 2 surfaces stop using fake profile, portfolio, verification, and moderation data once their corresponding story is delivered.
- Unrelated mock dashboard sections, including later quote and professional-relationship work, remain untouched until their increments.
- The current relationship example is not returned by the Increment 2 moderation API because accepted professional relationships belong to Increment 4.

## 6. Verification and launch gate for the increment

Each story includes Rails request/model/service/policy coverage and behavior-focused Vitest coverage where its Nuxt surface changes. The increment closes only after OpenAPI-generated types are current, the full Rails and Nuxt checks pass in Docker Compose, production builds succeed, browser flows are exercised through Codex Chrome at desktop and mobile viewports, relevant network requests are inspected, and the browser console has no unexplained errors.
