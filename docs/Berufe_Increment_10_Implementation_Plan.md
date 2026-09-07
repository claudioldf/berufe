# Berufe — Increment 10 Implementation Plan

**Status:** implemented

**Updated:** September 6, 2026

## Source precedence

This increment extends the quote-to-service loop delivered through S049–S051
and refined by `Berufe_Increment_9_Implementation_Plan.md`. It adds S070, the
next free story identifier after S069. Where this document is silent, the
existing MVP feature plan, infrastructure decisions, and Increment 9 remain
authoritative.

## Product decisions

1. **An approved quote stays immutable.** Work discovered after approval is
   recorded as a numbered service adjustment, preserving the original scope,
   price, and acceptance evidence.
2. **One adjustment model covers the practical cases.** Its signed items may
   represent additional work, contractor-supplied material, reimbursement for
   material already paid by the contractor, or a customer credit. An
   adjustment may also contain no priced items when it only documents scope or
   schedule.
3. **Approval changes the agreed total; payment does not.** Drafts and pending
   adjustments stay outside the combined total. Customer approval of the exact
   revision adds its signed total, but never represents payment, settlement,
   an invoice, or a legal signature.
4. **The professional initiates; the customer decides.** The existing private
   quote bearer link is reused. The customer may approve, decline, or request a
   change without an account. A change request returns the same adjustment to
   the professional for a new revision and re-share.
5. **Already-incurred costs are disclosed, not silently assumed.** The
   professional may enter an incurred date, and both surfaces warn that the
   amount remains outside the combined total until approval.
6. **Receipts are optional and private.** A JPEG or PNG may be attached only to
   a material-reimbursement item. It passes through the existing regenerated
   image pipeline and is served only after both the quote token and the
   receipt-to-service relationship are verified. A missing receipt is stated
   plainly and does not block a decision.
7. **Closing a service does not erase an unresolved commercial question.** A
   professional may complete or cancel while an adjustment is unresolved only
   after explicit acknowledgment. No new adjustment may be created after the
   service closes, but an existing unresolved one may still be edited, shared,
   and decided.

## Story

### S070 — Keep post-approval scope and cost changes explicit

**Story:** As a professional, I want to document and agree changes discovered
while a service is underway so that extra work, materials, reimbursements, and
credits do not overwrite the approved quote or become an informal dispute.

**Acceptance criteria:**

- Only the service owner can create, edit, share, or cancel an adjustment. A
  new adjustment is allowed only while the service is `approved`.
- Adjustment numbers are sequential within a service and assigned under a
  service lock. The owner can save a draft, copy the private link, or open an
  explicit WhatsApp handoff; Berufe does not send or read the message.
- An adjustment has a title, optional explanation, optional schedule impact,
  optional incurred date, and at most 20 ordered items. Rails recalculates all
  signed line totals and the adjustment total; browser totals are previews.
- `additional_service`, `material_charge`, and `material_reimbursement` items
  are non-negative additions. `credit` items are stored as negative line
  totals. Approving a credit cannot make the complete service agreement
  negative.
- The customer page never exposes drafts. It shows the immutable original
  quote total, approved-adjustment total, combined agreed total, and the amount
  still awaiting a response.
- The customer's decision names the adjustment id and current lock revision.
  Approval requires an explicit review checkbox and snapshots the decision
  time, revision, and quote customer identity. Stale and terminal decisions
  are rejected, while an identical repeated decision is idempotent.
- A requested change requires a message and preserves an append-only history.
  Editing an awaiting or change-requested adjustment resets it to draft; the
  customer must receive and decide the new revision.
- Approved, declined, and cancelled adjustments are immutable. Only approved
  adjustments affect the combined total.
- Completion and cancellation require an explicit unresolved-adjustment
  acknowledgment when applicable. Existing unresolved adjustments remain
  actionable after closure; creating another one does not.
- Adjustment decisions create professional notifications and actionable
  dashboard items with direct links to the related service.
- Receipt uploads are optional, sanitized, privately stored, excluded from
  analytics and public URLs, retained while referenced, and erased with the
  professional account. A draft adjustment's receipt cannot be read through
  the customer bearer endpoint.
- The OpenAPI contract, generated Nuxt types, owner/public authorization,
  optimistic-locking, receipt privacy, retention, lifecycle, and signed-total
  behavior are covered by automated tests.

**Depends on:** S049–S051, S065–S068.

**Covers:** Extends Feature D1 and the delivered quote-to-service loop.

## Delivery notes

- `service_adjustment`, ordered `service_adjustment_item`, optional
  one-to-one `service_adjustment_receipt`, and append-only
  `service_adjustment_change_request` records are deleted with their service.
- The receipt record snapshots the regenerated object's private key, media
  type, byte size, and dimensions. Reads verify those values against the
  attached media upload before returning bytes with private, no-store and
  no-sniff headers.
- The existing quote token remains the single customer bearer credential. An
  adjustment share URL adds only an in-page fragment, which is never sent to
  Rails.
- The service detail lives at `services/[id]/index.vue`, rather than
  `services/[id].vue`, so Nuxt treats `services/[id]/adjustments/new` as a
  separate page instead of an unrendered nested child route.
- No settlement state, balance-due calculation, automatic reminder, tax
  document, invoice, or payment collection is introduced by this increment.

## Delivery order

1. Contract and persistence for signed, revisioned service adjustments.
2. Owner-scoped write/share/cancel services and customer decision/read paths.
3. Professional ledger/editor, customer agreement view, and completion guards.
4. Dashboard notifications/actions, retention, erasure, and legal copy.
5. Contract coverage, Rails/Nuxt tests, security scan, and production build.
