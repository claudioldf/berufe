# Post-publication moderation decision

**Status:** Approved for MVP implementation  
**Date:** 2026-08-19  
**Supersedes:** approval-gated publication text in Features A2, A3, and E1; S023–S024, S026, and S028; and the five-stage supply funnel in R003. Professional relationships are governed solely by recipient confirmation in Feature C1 and S043/S046.

## Outcome

Moderation is an audit and takedown workflow for profile content, profile photos, and portfolio items, not the normal publishing gate. Once a professional completes the minimum publication requirements, those targets become public immediately with a private pending-review state. Public pages do not expose review state or “unreviewed” badges.

Professional relationships are not moderation targets. They remain private while `pending`, become publicly eligible when the recipient sets them to `accepted`, and remain private when `declined`. Both endpoint profiles and accounts must remain public and active.

Admins still review every pending item. Approval marks the current item reviewed and removes it from the queue without changing its public visibility. Rejection removes inappropriate evidence immediately and uses the following deterministic fallback rules:

- profile revision: restore the last approved revision; without one, make the profile unavailable;
- profile photo: restore the last approved photo; without one, make the profile unavailable;
- portfolio item: remove the item from public results.

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

The same live-versus-approved-pointer model applies to profile photos. Portfolio records are individually removable, so they do not need fallback pointers. Relationship visibility is derived from recipient acceptance and party eligibility rather than a moderation pointer.

Public media is served through a stable Rails endpoint that checks current eligibility on every request. Pending media is read from private storage and returned with `no-store`; approved media may use the published object but must revalidate so rejection or hiding takes effect immediately. Storage keys are never exposed in public or owner JSON.

## Admin and reporting behavior

The moderation queue shows whether an item is currently public, whether a fallback exists, and for profile revisions the change set relative to the approved fallback. Its primary action is “Marcar como revisado”; rejection remains a takedown/rollback action with a required private reason.

The supply funnel is:

1. registered;
2. published;
3. identity verified within the published cohort;
4. activated.

Portfolio and identity verification remain trust-readiness criteria, but neither blocks first publication. Activation counts approved identity, approved portfolio evidence, and recipient-accepted public professional relationships; the relationship criterion represents mutual confirmation rather than admin review.

## Privacy and identity matching

Each identity request captures the profile birthdate used for that review. Admin approval requires explicit confirmation that the evidence matches the claimed identity. Changing birthdate expires any pending or approved identity verification, removes its public label, and starts the existing evidence-retention cleanup window.
