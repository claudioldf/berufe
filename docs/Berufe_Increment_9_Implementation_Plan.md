# Berufe — Increment 9 Implementation Plan

**Status:** implemented

**Updated:** August 31, 2026

## Source precedence

`Berufe_Product_Strategy_Recurrence_Notes-Reviewd.md` documents the quote-to-recommendation loop as delivered through Increments 4–5, but carries no `Sxxx` identifiers and was never back-filled into `Berufe_MVP_Stories.md`. This increment gives that flow its story identifiers (S065–S069) and records four decisions that intentionally diverge from that narrative document and from `Berufe_V2_Stories.md`. Where this document is silent, `Berufe_MVP_Feature_Plan.md` and `Berufe_MVP_Infrastructure_Architecture.md` remain authoritative, per `Berufe_Increments_4_5_Implementation_Plan.md` §1.

**Story IDs used here:** S065–S069, the next free block after S064. Retired and never reused: `S038`–`S041`, `S044`–`S045`, `S048`, `V2-008` (see `Berufe_V2_Stories.md`, retired 2026-08-31). Note for a future increment, out of scope here: `S059` is currently assigned to two unrelated stories (`Berufe_MVP_Stories.md` and `Berufe_Increment_8_Implementation_Plan.md`) and needs reconciliation.

## Product decisions

The professional-facing quote and service surfaces split one mental unit — "a job for a customer" — across four records and five screens, with no cross-links between them. Reaching the dashboard's action items required opening a detail page in every case, and the post-approval flow required the professional to manually chase two separate WhatsApp round-trips (a completion-confirmation ask, then — only if that landed — a recommendation invite). The second touch reliably didn't happen, so customer recommendations under-represented actual completed work.

This increment makes four decisions that diverge from previously recorded scope:

1. **Customer confirmation of service completion is removed.** `Berufe_Product_Strategy_Recurrence_Notes-Reviewd.md` §4 described a customer-confirms-or-reports-an-issue step reached through `/orcamento/:token`. That step is retired along with the `completion_requested` service-job status. The professional closes a job themselves; customer feedback is asked for afterward, through a dedicated link, per S067.
2. **A recommendation request may be delivered by WhatsApp, not only by email.** `Berufe_Product_Strategy_Recurrence_Notes-Reviewd.md` §5 states "access to the emailed bearer link is the proof used by this flow." A quote's customer phone number is required where email is optional (`Berufe_Product_Strategy_Recurrence_Notes-Reviewd.md` §2), so an email-only channel structurally excludes any customer who didn't leave an email. This increment accepts a professional-triggered `wa.me` deep link to the same bearer token as an equally valid delivery channel — the same pattern already approved for quote sharing (S051) and the WhatsApp decision in `Berufe_MVP_Infrastructure_Architecture.md` §11. It is **not** automated WhatsApp delivery: Berufe never sends the message itself. This adopts `V2-008`'s preserved delivery criterion (WhatsApp deep link with copy-link fallback, no automated send); the identifier is retired, not reused. It does **not** adopt `V2-009`'s SMS-verification submission model or `V2-010`'s admin moderation queue — the emailed/WhatsApp'd bearer link remains the only proof of identity, and publication stays immediate, matching `Berufe_Product_Strategy_Recurrence_Notes-Reviewd.md` §5's "no draft state."
3. **A professional may hide a published recommendation from their public profile.** New capability, not previously scoped anywhere. Because the founding operations team cannot review recommendation volume at growth scale the way the identity-verification queue is reviewed today, this is deliberately **self-serve and unmoderated** — no admin review step, no moderation-queue entry. `apps/api/db/migrate/20260830140000_restrict_moderation_to_identity_verification.rb` already narrowed `moderation_actions.target_type` to `verification_request` and `professional_profile` only, so routing recommendations through that queue would reverse in-flight work, not extend it. Unmoderated hiding is kept honest, not by review, but by disclosure: whenever a professional has hidden at least one recommendation, the public profile states the count ("N recomendações ocultadas pelo profissional"). This satisfies `Berufe_MVP_Feature_Plan.md`'s stated principles ("show specific evidence… clearly distinguish verified facts from professional declarations") without adding a queue.
4. **The public `completed_services` count changes meaning.** It never actually filtered by who confirmed completion, despite `Berufe_Product_Strategy_Recurrence_Notes-Reviewd.md` §4 claiming otherwise — Decision 1 makes that claim moot rather than fixing it, since there is no longer a customer-confirmed state to filter by. The count is relabeled to describe professional-declared completion rather than implying customer verification; the recommendation count is the verified signal on the profile.

## Stories

### S065 — Show a professional what to do next, not what changed

**Story:** As a professional, I want every quote and service that needs an action from me to appear as one actionable card on my dashboard, so that I don't have to open a list and then a detail page to find and take the next step.

**Acceptance criteria:**

- The dashboard's existing "Para resolver" / "Para acompanhar" activity inbox (previously relationships-only) also carries quote and service items, each with exactly one server-decided next action: share an unshared quote, nudge a silent shared quote, open the editor for a change-requested quote, mark an approved service done, or ask an unreached customer for a recommendation over WhatsApp.
- Each action item's primary control performs the action inline from the card — sharing, completing, or opening the WhatsApp handoff — without navigating to a detail page first.
- The inbox is not capped to a fixed recent-N slice; every open action item appears until it is resolved.
- `Serviços` is reachable from the professional header navigation, not only from a dashboard tile.
- A quote-approval notification opens the resulting service, not the now-locked quote editor.

**Depends on:** S047, S049–S051.
**Covers:** the delivered service loop, back-filled per this document's source-precedence note.

### S066 — Let the professional close a job in one tap

**Story:** As a professional, I want to mark a job done with a single action so that finishing work doesn't require chasing a customer's confirmation first.

**Acceptance criteria:**

- A service job's lifecycle is `approved → completed`, with `cancelled` reachable only from `approved`, matching today's cancellation guard — `completed` stays terminal. The customer-confirmation round trip (`completion_requested`, `completion_issue` as a _service-job_ status, and the professional's separate "ask for confirmation" action) is removed.
- The professional's completion action is the only completion action; there is no second, customer-triggered completion path on `/orcamento/:token`.
- The public profile's completed-services figure is presented as professional-declared, not customer-verified, consistent with Decision 4.

**Depends on:** S049–S051.

### S067 — Ask every completed job's customer for feedback, automatically

**Story:** As a professional, I want the customer to be asked for feedback as soon as I mark a job done, without me having to remember or manually request it, so that recommendations reflect the work I actually complete.

**Acceptance criteria:**

- Completing a service job creates one recommendation request for that job, regardless of whether the quote's customer snapshot has an email — the bearer token now serves both the email and WhatsApp delivery channels.
- When the quote has a customer email, delivery is automatic and scheduled with a short delay after completion, giving the professional a window to correct an accidental tap before the customer is contacted.
- The customer's link leads to a neutral question — "Como foi o serviço?" — with two branches: submit a public recommendation (unchanged from the existing flow: display name, text, confirmation the service occurred, publication consent, publishes immediately), or report privately that something is still outstanding. The private branch writes a message the professional can see and fires the existing service-completion-issue notification; it does not change the service job's status — `completed` stays terminal, so there is no new transition to model — and leaves no public trace.
- The private branch exists specifically so an unhappy customer is not limited to a public recommendation as their only outlet — this is what keeps immediate, unmoderated publication (Decision 2) acceptable.

**Depends on:** S066.

### S068 — Reach a customer without an email through WhatsApp

**Story:** As a professional whose customer has no email on file, I want to send the same recommendation request through WhatsApp, so that I'm not excluded from collecting recommendations just because a customer left their phone number and not their email.

**Acceptance criteria:**

- A completed job whose recommendation request has no email to deliver to, and hasn't yet been sent, surfaces in the S065 action inbox with a "pedir recomendação pelo WhatsApp" action.
- That action opens an explicit WhatsApp deep link to the quote's customer phone snapshot containing the same bearer link used for email delivery, with a copy-link fallback — the same pattern as S051, not an automated send.
- The professional can reopen and resend the WhatsApp link more than once, unlike the email channel where the token is no longer needed once delivered.
- The public recommendation card discloses which channel delivered the invitation ("Link enviado por e-mail" vs. its WhatsApp equivalent) rather than defaulting to an email claim for a recommendation that was never emailed.

**Depends on:** S067.

### S069 — Let a professional keep a specific recommendation off their public profile

**Story:** As a professional, I want to hide one published recommendation from my public profile without asking an administrator, so that a single unrepresentative comment doesn't require an operations review the team cannot staff at scale.

**Acceptance criteria:**

- The professional workspace has a recommendations area listing every recommendation received, each with a hide/unhide control that takes effect immediately with no review step.
- Hiding is recorded separately from a customer's own LGPD publication withdrawal; the two are never conflated, and a customer withdrawal never counts toward or displays as professional hiding.
- A hidden recommendation is excluded from the public recommendation list and from the public recommendation count.
- Whenever a professional profile has at least one hidden recommendation, the public profile discloses the count ("N recomendações ocultadas pelo profissional"). This disclosure is what makes unmoderated self-serve hiding acceptable under Decision 3 — a reader can always tell hiding occurred, even without seeing what was hidden.
- The professional sees this disclosure requirement before confirming their first hide, not only after.

**Depends on:** S067–S068.

## Delivery notes

- Destructive migrations remain acceptable pre-launch, per the precedent already set by `apps/api/db/migrate/20260830140000_restrict_moderation_to_identity_verification.rb`.
- `completion_issue_message` is renamed rather than dropped and re-added — it becomes the private-feedback column S067's issue branch writes to, since the underlying idea (a message describing what's outstanding) survives even though the status it was attached to does not.
- Not built in this increment: merging `/app/professional/quotes` and `/app/professional/services` into a single pipeline view. S065's inbox is expected to surface which stages professionals actually act on before that larger restructuring is attempted.

## Delivery order

1. `ServiceJob` lifecycle collapse (S066): migration, model, service-object and endpoint removal, contract update, customer-page simplification.
2. Automatic and WhatsApp recommendation delivery (S067–S068): schema additions, completion-time request creation, scheduled delivery, WhatsApp handoff endpoint, the two-branch feedback page.
3. Recommendation hiding and its public disclosure (S069): schema, owner-scoped endpoints, workspace tab, public serializer and component changes.
4. The action inbox (S065): query object, contract, serializer, notification-routing fix, frontend inbox and composable, header navigation entry.
5. Backend, contract, and frontend validation through Docker Compose (`bin/check`, `pnpm check`), plus the end-to-end walk described in the increment's verification plan.
