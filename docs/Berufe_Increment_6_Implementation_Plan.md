# Berufe — Increment 6 Implementation Plan

**Status:** approved implementation source for Increment 6

**Updated:** August 18, 2026

## Source precedence

For Increment 6, this document records the approved decisions that refine `Berufe_Reports_Stories.md`. The reports stories remain authoritative where this document is silent. The existing components in `apps/web/app/components/admin/reports` are the source of truth for visible information architecture: implementation must not add pages, widgets, or fields that are not already represented there.

## Approved reporting decisions

- The discovery funnel contains five stages, ending in **Contato iniciado**, using the existing privacy-safe search handoff flag.
- Rails owns counts, denominators, rates, comparisons, period boundaries, and metric semantics. Nuxt formats the typed response.
- Summary publication and activation metrics are separate from the supply funnel and current quality stock.
- Supply funnel percentages compare each row with the previous row. Verification and submission are not strictly sequential, so a percentage can exceed the preceding row and the UI explains that limitation.
- The seven-day activity view uses the existing **Sem ação/Ativos** shape. Longer views use four complete local Monday–Sunday buckets.
- The contact scorecard intentionally counts all WhatsApp handoffs divided by all profile views, regardless of handoff source. A handoff is not a hiring outcome.
- A relationship is **respondida** when accepted or declined. The approved funnel stage counts recipient-accepted relationships whose two profiles remain publicly eligible; there is no admin review stage.
- Zero counts are `0`; rates with no denominator are `null` and render as `—`.
- Empty reports still render every existing widget. The launch-only replacement state is removed.
- The publication target remains 30–50 and is configuration-backed. The publication scorecard detail uses current public stock.
- Support-only aggregates remain API-only: matched-service `other_count`, zero/thin gap split, and moderation counts by target type.
- `PRODUCT_LAUNCH_DATE` is mandatory outside the fixed local/test defaults.
- Since-launch milestones are: published 5/10/20/30/50, activated 3/5/8/10/20, coverage 50/75/90/100%, contacts 1/5/10/25/50, and returning 1/3/5/10/20. The comparison reports the highest reached threshold or, when none is reached, the next milestone.
- Comparisons with a current or previous denominator below five are marked **direcional**.
- Repeat quote creators are labeled **2+ no período**.
- Active catalog gaps map to **Recrutar**. Inactive or unmatched catalog demand maps to **Avaliar catálogo**.

## Privacy and retention

- Anonymous raw search events remain server-only for 90 days. A retry-safe daily job aggregates complete local days and irreversibly removes their raw rows.
- Search daily rollups, professional daily metrics, and professional daily activities are retained for 730 days.
- When launch predates that horizon, `since_launch` starts at the oldest retained local date and is displayed as **Últimos 24 meses**. Every period-sensitive section uses that same effective start.
- Unmatched search terms are returned only as aggregates meeting the privacy threshold: at least two searches for seven days and at least three for longer periods.
- Report access logs contain only administrator ID, request ID, selected period, and timestamp.

## Delivery order

1. Publication timestamp, reporting configuration, rollup schema, and retention jobs.
2. Authorized aggregate Rails endpoint and OpenAPI contract.
3. Typed Nuxt API adapter and composable.
4. Existing report widgets switched from fixtures to API data.
5. Backend, contract, frontend, and build validation through Docker Compose.

R013 pulls report-specific retention into this increment. S053 remains responsible for the later cross-product retention matrix and legal review. Increment 6 does not introduce V2 domains or an additional release-critical Playwright flow.
