# Google Analytics 4 operations

## Scope

Berufe measures public-site audience and the visitor→lead funnel with Google Analytics 4
(property serving `www.berufe.com.br`, measurement ID `G-K8GG56FD41`). This document is the
event taxonomy and the property-level configuration that goes with it — see `privacidade.vue`
§6–8 for what is disclosed to visitors, and `Berufe_Reports_Stories.md` R013 for how this
differs from Berufe's own (GA-free) reporting pipeline.

## Architecture

- `app/plugins/analytics.client.ts` — loads gtag.js, gated on `NUXT_PUBLIC_GA_MEASUREMENT_ID`
  and off in dev. Sends `page_view` on every route change (`send_page_view: false` at config
  time, since GA4's own history-based auto page view fires before Nuxt updates the title and
  would leak the raw, un-redacted URL). Exposes `window.gtag` globally, matching Google's own
  snippet convention, so the rest of the app can send events without importing the plugin.
  **Calls `gtag('consent', 'default', {...})` before `config` — required.** Without an
  explicit default, gtag.js treats consent as "not configured" and silently drops every hit
  (confirmed via Tag Assistant: `Esta tag não enviou nenhum hit` / `O estado de consentimento
  padrão ainda não foi definido`, reproduced both from a real browser and from three direct
  Measurement Protocol hits sent via `curl` — this is not a browser/ad-blocker issue, gtag.js
  itself withholds collection with no default set). `analytics_storage` is granted (this site
  loads GA4 unconditionally, no cookie banner — see `privacidade.vue` §7); `ad_storage`,
  `ad_user_data`, and `ad_personalization` stay denied, matching Google Signals being off.
- `app/composables/useAnalyticsEvent.ts` — `trackEvent(name, params)`. A thin wrapper over
  `window.gtag`; a no-op wherever GA is disabled (dev, tests, SSR), so call sites never need
  their own guard.
- `app/utils/analytics.ts` — pure, tested helpers: `analyticsPagePath` (redacts a bearer token
  out of a page path before it becomes `page_path`) and `analyticsSearchTerm` (builds a
  `search_term` from controlled catalog values only, never the visitor's raw query).

## Event taxonomy

Only the core growth funnel — visitor search → profile view → WhatsApp contact → quote
opened → quote decision. Every param is either public listing data (already visible on the
page itself) or a controlled catalog value; see **Privacy constraints** below for what is
deliberately excluded.

| Event                    | Fires when                                  | Params                                                                                            | Source                                                                            |
| ------------------------ | ------------------------------------------- | ------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| `search`                 | A search resolves (free-text or structured) | `search_term` (matched service + resolved city, e.g. "Eletricista - Joinville"), `result_count`   | `useProfessionalSearch.ts`                                                        |
| `view_item`              | A professional's public profile page mounts | `item_id`, `item_category` (primary service), `city`                                              | `pages/profissionais/[slug].vue`                                                  |
| `generate_lead`          | Visitor opens WhatsApp for a professional   | `method: "whatsapp"`, `source: "public_profile" \| "search_result"`, `professional_id`, `service` | `pages/profissionais/[slug].vue`, `pages/encontrar/[state_code]/[city]/index.vue` |
| `share`                  | Visitor shares a professional's profile     | `method: "web_share" \| "clipboard"`, `content_type: "professional_profile"`, `item_id`           | `pages/profissionais/[slug].vue`                                                  |
| `quote_viewed`           | A customer opens a shared quote link        | `service` (professional's primary service)                                                        | `pages/orcamento/[token].vue`                                                     |
| `quote_approved`         | Customer approves a quote                   | `service`                                                                                         | `pages/orcamento/[token].vue`                                                     |
| `quote_declined`         | Customer declines a quote                   | `service`                                                                                         | `pages/orcamento/[token].vue`                                                     |
| `quote_change_requested` | Customer requests a change                  | `service`                                                                                         | `pages/orcamento/[token].vue`                                                     |

`generate_lead` and `quote_approved` are the two funnel outcomes that matter for growth
reporting and should be marked as Key Events once they start arriving (see **Property
configuration**).

Not yet instrumented (deferred, see the professional lifecycle scope that was not picked when
this was built): `sign_up` on phone verification, onboarding step/completion events, and
`quote_shared` when a professional shares a quote from the dashboard.

## Privacy constraints

Never sent to GA, by design:

- The visitor's raw free-text search query (retained separately, restricted-access, 6 months —
  see `privacidade.vue` §7). Only the matched catalog service name and resolved city travel to
  analytics.
- Any bearer token. `/orcamento/:token`, `/recomendacao/:token`, and
  `/exclusao-de-conta/:token` are redacted to a literal placeholder in `page_path` by
  `analyticsPagePath`, and no event on the quote page includes the token, per
  `LGPD_OPERATIONS.md`'s rule against tokens in analytics/monitoring metadata.
- Customer identity or contact info (name, phone, e-mail) and quote financial data (amounts,
  items, addresses). Quote events send only the professional's public service category.
- A GA4 `user_id` for logged-in professionals — evaluated and deliberately not implemented;
  the core funnel is anonymous visitors, and adding one would tie a persistent Google
  identifier to an internal account id beyond what the privacy policy discloses.

## Property configuration

Configured directly in the GA4 Admin UI (not code), account `Berufe` / property `552733988`,
web stream `https://www.berufe.com.br` (`15716679199`):

- **Google Signals: off**, and stays off. Required — it enables cross-device/ads-personalization
  linking via signed-in Google accounts, which would contradict the privacy policy's "não usa
  cookies publicitários" statement. "Coleta de dados fornecidos pelo usuário" (BETA, hashed
  customer data for Ads audiences) is off for the same reason.
- **Data retention (event/user-level, for Explore reports): 14 months** — GA4's maximum,
  chosen for year-over-year comparison; unrelated to the `_ga` cookie's own 2-year lifetime.
- **Enhanced measurement → Site search: off.** GA4's default recognized query params
  (`q,s,search,query,keyword`) include `q` — which is this site's actual search param, holding
  a reversible Base64URL encoding of the visitor's raw free-text query (see
  `encodeSearchExpression`/`decodeSearchExpression`). Left on, GA would have auto-captured
  exactly the raw text the custom `search` event above was built to keep out. Every other
  Enhanced Measurement default (scroll, outbound clicks, form interactions, video engagement,
  file downloads) stays on; automatic page-view tracking is off, since the plugin sends
  `page_view` explicitly.
- **Granular device/location data collection: off** — not needed on a web-only property;
  turned off to keep collection minimal.
- **Custom definitions**: `service`, `city`, `method`, `source`, `search_term`,
  `professional_id`, `item_id`, `item_category`, `content_type` registered as event-scoped
  custom dimensions, `result_count` as a custom metric (unit: Standard) — all pre-registered
  by parameter name (GA4 accepts this before the parameter has ever been sent) so they're
  queryable in Explore as soon as traffic starts.
- **Key events — not yet set.** GA4 only offers an event name for the Key Events star once it
  has actually been received at least once; this property has had zero traffic so far (nothing
  is deployed to production yet). **Once this ships and traffic flows**, go to Admin → Events,
  find `generate_lead` and `quote_approved` in "Eventos recentes", and star them.
