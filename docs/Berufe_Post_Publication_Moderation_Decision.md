# Moderation scope decision

**Status:** Approved and implemented

**Date:** 2026-08-31

**Supersedes:** all profile-field, profile-photo, and portfolio-item moderation behavior in earlier feature, story, reporting, and infrastructure plans.

## Outcome

The moderation queue is restricted to identity verification. Profile information, profile photos, portfolio items, and professional relationships have no moderation status or decision lifecycle.

An administrator can still unpublish or restore an entire professional profile from the professional directory. These profile-level operations reuse the immutable `moderation_actions` audit table but are not queue items.

## Identity verification

- A professional submits one regenerated private JPEG/PNG identity document and a claimed birthdate.
- The queue lists only `verification_request` targets, oldest first, with status/search filters.
- The document is opened through the dedicated authenticated verification-file endpoint. Access remains audited and storage keys never reach Nuxt.
- Approval requires explicit confirmation that the document identity and birthdate match the profile.
- Rejection requires a 10–500 character reason visible to the professional; an optional administrator note remains private.
- Only an approved request produces the public “Identidade verificada” label.
- Changing the private birthdate expires pending or approved identity verification and begins the evidence-retention cleanup window.

## Self-managed profile content

- First publication changes a complete self-service profile directly from `draft` to `published`.
- Published profile edits update the working/public revision immediately.
- A processed profile-photo attachment becomes the single current photo immediately. Replacing or removing it soft-deletes the old photo.
- Active portfolio items are created and updated immediately and are ordered newest first. Deletion is soft deletion.
- Sanitized profile and portfolio images remain in private object storage and are streamed through stable Rails public routes that check parent-profile and record eligibility.
- Public and owner APIs expose no moderation state for revisions, photos, or portfolio items.

## Whole-profile unpublication

- The action lives on the administrator professional directory.
- Unpublishing requires a user-visible reason between 10 and 500 characters and transitions `published` to `suspended`.
- A suspended profile is removed immediately from public pages, discovery, media access, and search.
- The latest `hidden` audit reason appears in a banner on the professional dashboard, and the professional receives a notification. The profile editor remains available without a duplicate suspension banner.
- Restoring transitions `suspended` back to `published`, appends a `restored` action, and sends a restoration notification.

## Audit constraints

`moderation_actions` accepts only these target/action combinations:

| Target                 | Allowed actions        |
| ---------------------- | ---------------------- |
| `verification_request` | `approved`, `rejected` |
| `professional_profile` | `hidden`, `restored`   |

Rejection and hiding require the user-visible reason. Request ID, administrator, target, action, timestamps, and the optional private note remain immutable audit data.

## Reporting

Moderation queue age, review duration, rejection, and approval metrics use identity requests only. Whole-profile `hidden` and `restored` actions are reported separately as profile operations. Portfolio activity remains a supply/evidence metric, not a moderation metric.
