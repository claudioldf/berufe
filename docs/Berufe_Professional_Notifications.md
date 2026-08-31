# Professional notifications

Professional notifications are a private, persisted activity inbox for active registered professionals. Rails owns event selection, recipient eligibility, copy, destination resolution, idempotency, ordering, and read state. Customer-entered messages, moderation reasons, phone numbers, e-mail addresses, names, and other domain payloads are never copied into a notification.

## Event coverage

The inbox covers these server events:

- whole-profile hiding and restoration by an administrator;
- identity-verification approval and rejection;
- professional relationship request, acceptance, and decline;
- quote change request, approval, and decline;
- customer confirmation or issue report for service completion;
- publication of a customer recommendation.

Event producers create their notification inside the same database transaction as the domain change. A stable event-derived `idempotency_key` and a unique database index prevent duplicate delivery. Unregistered external profiles do not receive inbox records.

## API and browser behavior

The owner-scoped endpoints are:

- `GET /api/v1/professional/notifications` for unread, newest-first cursor pages;
- `PATCH /api/v1/professional/notifications/{id}/read` for an irreversible idempotent read;
- `PATCH /api/v1/professional/notifications/read-all` for records present at the operation cutoff.

Responses include the exact remaining unread count and use `Cache-Control: no-store`. Cursor values are signed and opaque. Mutations require the exact configured browser origin.

The Nuxt header exposes a modal popover with keyboard/outside-click dismissal, individual and bulk read actions, cursor loading, and immediate navigation. It refreshes on workspace load, while the document is visible every 60 seconds, when the tab becomes visible again, and when the popover opens. Polling pauses while hidden. Logout and account changes synchronously clear all shared notification state; failed requests retain the last confirmed server state.

## Destination resolution

Notifications persist semantic `route_params` rather than browser paths. Quote and service-completion events keep only the related resource UUID; events with a fixed workspace destination keep an empty object. Database and model constraints require the exact parameter shape for each notification type.

Rails resolves the response's existing `route` field when the notification is read. This keeps stored records independent of future frontend route changes. Recommendation notifications also use the recipient's current public profile slug, falling back to the professional profile workspace when no public profile is available. `route_params` is an internal persistence detail and is not exposed by the API.

## Privacy and erasure

Notification titles and descriptions are static server copy and are filtered from parameter logs defensively. Routing parameters contain only internal resource UUIDs and never customer-entered content. Records are private to the recipient and are deleted with the professional account by the LGPD erasure job and the database cascade. No notification record is retained in the pseudonymous legal/audit set.
