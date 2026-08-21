# Berufe — Quote-to-Recommendation MVP

## 1. Outcome

The minimum recurrence loop is implemented in the current Rails and Nuxt
applications:

1. A professional creates a quote for a customer.
2. The customer approves, declines, or requests a change through the private
   quote link.
3. Approval creates one service record.
4. The professional finishes the work and sends a completion request through
   WhatsApp.
5. The customer confirms completion or reports a problem through the same
   private quote link.
6. If the approved quote has an email address, confirmed completion sends a
   personal recommendation link by email.
7. A submitted recommendation is published immediately and contributes to the
   professional's public evidence.

This closes the operational and reputation loop without adding payments,
booking, generic CRM features, automated WhatsApp delivery, PDFs, ratings, or
moderation.

## 2. Customer boundary

Customer and client mean the same entity in this product.

- Every customer belongs to exactly one `professional_profile`; customers are
  never shared between professionals.
- A quote requires customer name and Brazilian mobile/WhatsApp number. Email is
  optional.
- Typing at least two characters in the quote form searches only the signed-in
  professional's customers. Results are capped at ten.
- Selecting a result fills name, phone, and email and keeps the customer
  association on the quote.
- If the professional does not select an existing result, saving creates a new
  customer from the typed name, required phone, and optional email.
- The professional can search the lean customer directory, edit canonical
  contact details, review the customer's quote history, and start a prefilled
  quote. Customers are still created only through the quote flow.
- Updating an existing customer through a quote or the directory clears prior
  email verification when the normalized email changes.

The quote also stores name, phone, and email snapshots. Service execution,
WhatsApp handoff, and recommendation delivery use those snapshots so later
customer edits do not rewrite the historical agreement.

## 3. Quote lifecycle

```text
draft -> shared -> approved
                -> change_requested -> shared
                -> declined -> shared
```

- The existing opaque share token is reused when a changed or declined quote is
  shared again.
- Client decisions are token-authenticated and return the same generic not-found
  response for unavailable links.
- Approval requires acceptance of the displayed scope, amount, and validity.
- Change requests require a message; decline messages are optional.
- The client submits the quote revision they viewed. A stale revision cannot be
  approved.
- Approval is idempotent, locks commercial quote content, and creates exactly
  one `service_job` through a unique database constraint.
- The quote now also carries optional service address and scheduled date. The
  existing free-text description, line items, validity, discount, and notes
  remain the commercial scope for this MVP.

## 4. Service lifecycle

```text
approved -> completion_requested -> completed
                                -> completion_issue -> completion_requested
approved/completion_requested/completion_issue -> cancelled
```

- The professional dashboard and service pages show approved work and its
  current state.
- Requesting completion opens WhatsApp addressed directly to the quote's phone
  snapshot and includes the existing private quote link. Copying the link is the
  fallback.
- The customer may confirm or explain an outstanding issue.
- A professional may resolve an issue and request confirmation again.
- Only client-confirmed completion contributes to the completed-service public
  counter.

## 5. Recommendation lifecycle

- Confirmation creates at most one recommendation request per service when the
  quote email snapshot is present.
- The GoodJob worker sends the invitation through SMTP. Its job argument contains
  only the request UUID; the personal token is encrypted at rest until delivery
  and removed after successful delivery.
- Delivery is idempotent and retries transient SMTP/network failures.
- The recommendation bearer link is unavailable before successful email
  delivery, after submission, or after its 14-day expiry.
- No second email validation is needed: access to the emailed bearer link is the
  proof used by this flow.
- Submission requires a display name, recommendation text, confirmation that the
  service occurred, and consent to public publication.
- Recommendations publish immediately. There is no star rating, administrator
  moderation, or draft state in this MVP.
- The current customer record is marked email-verified only when its present email
  still matches the historical quote email. A newer email is never overwritten
  or incorrectly verified.

Public profiles now show completed services, customer recommendations, confirmed
worked-together relationships, and recommendation cards labeled "Link enviado
por e-mail".

## 6. Delivered surfaces

### Professional

- Customer autocomplete in the quote builder.
- Customer directory and detail pages with contact editing, quote history, and
  prefilled new-quote handoff.
- Quote decision states and optimistic revision handling.
- Recent services on the professional dashboard.
- Service list and detail pages with completion and cancellation actions.

### Customer

- Approve, decline, and request-change actions on `/orcamento/:token`.
- Completion confirmation and issue reporting on the same link.
- Recommendation form on `/recomendacao/:token`.

### API and operations

- Owner-scoped customer candidate and paginated directory endpoints, including
  canonical contact editing and per-customer quote history.
- Professional service list/detail/completion/cancellation endpoints.
- Token-authenticated quote decision and completion endpoints.
- Token-authenticated recommendation resolution and submission endpoints.
- OpenAPI definitions and generated TypeScript types for the complete surface.
- SMTP configuration is required for staging, integration, and production; the
  `default` GoodJob queue must be running.

## 7. Explicitly deferred

These are useful later but are not required to let professionals start using the
loop:

- Payment collection, receivables, installments, or payment-method tracking.
- Calendar booking and scheduling automation.
- Server-generated PDFs; browser printing remains available.
- Quote templates, typed labor/material reporting, and catalog attribution.
- Quote or service attachments and before/after job-photo authorization.
- Scope-change ledgers after approval; the MVP keeps the approved quote immutable.
- Customer merging, notes, tags, campaigns, reminders, or other generic CRM
  behavior beyond the lean customer directory.
- Automated WhatsApp messages or provider webhooks.
- Star ratings, recommendation moderation, replies, or abuse tooling beyond the
  existing bearer, origin, length, and consent controls.

## 8. MVP acceptance check

The loop is ready to expose to professionals when migrations are applied, the
API and worker are deployed from the same release, SMTP credentials are present,
and the following checks pass:

```bash
docker compose exec api bin/check
docker compose exec web pnpm check
```

The quote migration intentionally removes pre-feature quote rows because they
lack the now-required historical phone snapshot. This must be accepted for the
target data set before applying the migration outside disposable environments.
