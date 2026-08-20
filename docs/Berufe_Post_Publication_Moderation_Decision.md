# Post-publication moderation decision

**Status:** Approved for MVP implementation  
**Date:** 2026-08-19  
**Supersedes:** approval-gated publication text in Features A2, A3, C1, and E1; S023–S024, S026, S028, S046; and the five-stage supply funnel in R003.

## Outcome

Moderation is an audit and takedown workflow, not the normal publishing gate. Once a professional completes the minimum publication requirements, new profile content, profile photos, portfolio items, and recipient-accepted professional relationships become public immediately with a private pending-review state. Public pages do not expose review state or “unreviewed” badges.

Admins still review every pending item. Approval marks the current item reviewed and removes it from the queue without changing its public visibility. Rejection removes inappropriate evidence immediately and uses the following deterministic fallback rules:

- profile revision: restore the last approved revision; without one, make the profile unavailable;
- profile photo: restore the last approved photo; without one, make the profile unavailable;
- portfolio item: remove the item from public results;
- professional relationship: remove the relationship from public results; a retry is a new request and requires a new recipient acceptance.

Identity evidence is the exception. Verification requests and evidence remain private until approved, and only an approved identity request can produce the public identity label.

## First publication

The final onboarding step publishes once the professional either submits optional identity evidence or explicitly chooses “Agora não”. Publication requires:

- display name;
- a successfully processed profile photo;
- a private birthdate;
- at least one active service with exactly one primary service;
- valid Joinville coverage;
- a confirmed account phone, used as the default WhatsApp number unless an override is supplied.

Headline, biography, declared experience, social links, portfolio, professional relationships, and identity verification are optional. Birthdate is never public. It is shown only where needed for owner account management and private identity matching.

## Revision and media behavior

After first publication, every material profile save creates an immutable pending revision and atomically makes it the current public revision. A newer save supersedes an older pending revision so a stale queue item cannot later replace current content. The last approved revision remains a rollback pointer, not the normal public pointer.

The same live-versus-approved-pointer model applies to profile photos. Portfolio and relationship records are individually removable, so they do not need fallback pointers.

Public media is served through a stable Rails endpoint that checks current eligibility on every request. Pending media is read from private storage and returned with `no-store`; approved media may use the published object but must revalidate so rejection or hiding takes effect immediately. Storage keys are never exposed in public or owner JSON.

## Admin and reporting behavior

The moderation queue shows whether an item is currently public, whether a fallback exists, and for profile revisions the change set relative to the approved fallback. Its primary action is “Marcar como revisado”; rejection remains a takedown/rollback action with a required private reason.

The supply funnel is:

1. registered;
2. published;
3. identity verified within the published cohort;
4. activated.

Portfolio and identity verification remain trust-readiness criteria, but neither blocks first publication. Activation continues to count approved identity, approved portfolio evidence, and public professional relationships so the quality metric remains reviewed evidence rather than merely visible pending content.

## Privacy and identity matching

Each identity request captures the profile birthdate used for that review. Admin approval requires explicit confirmation that the evidence matches the claimed identity. Changing birthdate expires any pending or approved identity verification, removes its public label, and starts the existing evidence-retention cleanup window.
