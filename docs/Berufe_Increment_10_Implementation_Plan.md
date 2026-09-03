# Berufe — Increment 10 Implementation Plan

**Status:** in progress

**Updated:** September 3, 2026

**Scope:** S070–S071 — closed-price quotes with a private calculation, and a customer materials list

## Source precedence

This document records the approved implementation detail for S070 and S071, which extend Feature D1 (`Berufe_MVP_Feature_Plan.md`). Both stories are defined in `Berufe_MVP_Stories.md`, immediately after S059; this document records the decisions made while implementing them and takes precedence where it intentionally differs from the feature plan's general description, per `CLAUDE.md`.

**Story IDs used here:** S070–S071, the next free block after S069. Retired and never reused: `S038`–`S041`, `S044`–`S045`, `S048`.

## Product decisions

Some professionals — a painter, a builder — don't quote item by item. They tell the customer one number: "esse serviço sai por R$ 2.000." They still think in a breakdown to reach that number, but never show it. Separately, several of these trades need to tell the customer what to buy before the professional can start: cans of paint, sacks of joint compound, sheets of sandpaper. Neither need fits the existing always-itemized, always-priced `quote_item` model, so this increment makes four decisions:

1. **Pricing mode is per-quote, not per-professional.** `pricing_mode` is `itemized` (default, unchanged behavior) or `lump_sum`. The same professional can itemize one job and quote a closed price on the next; nothing is configured on the professional profile.
2. **The line items become an optional private calculator in `lump_sum` mode.** The professional can still build the same item list — description, quantity, unit, unit price — but its sum is never persisted on the quote and never leaves the owner-facing API response. The professional types the actual price into `lump_sum_amount`, which Rails uses as `total_amount` directly. This keeps S049's rule intact — Rails still owns every persisted total — while making clear that the item sum in this mode is a scratch calculation, not quote content.
3. **Customer visibility of the calculation is an explicit per-quote toggle, and it never includes money.** `items_visible_to_customer` controls whether the shared link shows the line items as a scope list (description and quantity only) under the closed price. The toggle has no effect in `itemized` mode, where items are already the customer-facing content. In `lump_sum` mode a visible item is structurally incapable of carrying a price: the token-authorized `SharedQuoteItem` schema makes `unit_price` and `line_total` nullable, and the serializer emits `null` for both rather than omitting the fields, so the frontend can render a scope row without a schema-level chance of a stray price slipping through.
4. **Materials are a new, permanently unpriced list, available in both pricing modes.** `quote_material` mirrors `quote_item`'s shape minus `unit_price` and `line_total`. It never contributes to `subtotal_amount`, `total_amount`, or the commercial summary (S050's awaiting-response / approved-this-month aggregates), and it renders in a visually distinct section of the quote so it cannot be misread as billed scope.

A consequence worth stating plainly: **the discount is unavailable in `lump_sum` mode.** A closed price already reflects whatever negotiation happened to reach it; a `Subtotal / Desconto / Total` block under a single typed number would misrepresent that number as derived rather than stated. Switching a quote to `lump_sum` forces `discount_amount` to zero; the field is hidden while in that mode.

The private calculation is not stored on the `quotes` row at all — it is computed from `quote_items.line_total` on read, the same way `subtotal_amount` was computed before this increment, and surfaced only through the owner-facing `items_amount` field. This is a deliberate storage choice, not an oversight: a persisted column is one query away from a serializer bug leaking it to a customer; a value that is never written to a column reachable by the shared code path cannot leak through it.

## Backend implementation

- `quotes` gains `pricing_mode` (string, default `itemized`), `lump_sum_amount` (nullable decimal(14,2)), `items_visible_to_customer` (boolean, default `true`), with check constraints mirroring the existing `quotes_*` family: pricing mode is known, `lump_sum_amount` is null outside `lump_sum`, and — outside `draft` — `lump_sum` quotes have a non-negative `lump_sum_amount` and a zero discount. The existing `quotes_consistent_totals` constraint (`total_amount = subtotal_amount - discount_amount`) is unchanged: `Quote#recalculate_totals` satisfies it in `lump_sum` mode by setting `subtotal_amount = lump_sum_amount` and `discount_amount = 0`, rather than by relaxing the constraint.
- New `quote_materials` table, `quote_item`'s shape minus `unit_price`/`line_total`: `description`, `quantity`, `unit`, `sort_order`, unique per quote, cascade-deleted with the quote.
- `Quote#recalculate_totals` branches on `pricing_mode`; item and material replacement on write follows the existing destroy-and-rebuild pattern (`ProfessionalQuoteWriter` already does this for `quote_items`).
- `Quote#items_amount` derives the private calculation for the owner serializer; it is never assigned to a column.
- The minimum item count for `has_valid_item_count` drops to zero when `draft? || lump_sum?` — items are optional once a lump sum is being quoted.

## HTTP contract

`ProfessionalQuoteWriteRequest`/`ProfessionalQuote` gain `pricing_mode`, `lump_sum_amount`, `items_visible_to_customer`, owner-only `items_amount`, and `materials`. `SharedQuote` gains `pricing_mode`, `items_visible_to_customer`, and `materials`, and its `items` array becomes optional (`minItems: 0`) — but it never gains `lump_sum_amount` or `items_amount`. That omission is itself part of the contract: a field that does not exist in the customer-facing schema cannot be serialized into a customer-facing response by mistake. `SharedQuoteItem.unit_price`/`line_total` become nullable for the same reason described in decision 3.

Regenerate the committed `apps/web/app/services/api/schema.d.ts` in the same commit as the contract change, per the repository's drift rule.

## Frontend implementation

- `useQuoteDraft` gains `itemsAmount`, `addMaterial`/`removeMaterial`, `setPricingMode` (zeroing the discount and seeding `lumpSumAmount` from the current item sum when switching to `lump_sum`), and a one-click action to apply that item sum to the price field.
- The line-items card gains a pricing-mode selector; in `lump_sum` its footer replaces the subtotal/discount/total block with the read-only internal calculation, the price field, and the visibility toggle.
- A new materials card, present in both modes, with no currency field anywhere in it.
- `QuotesQuotePreview` — shared by the builder sidebar, the preview modal, and `/orcamento/:token` — renders the closed price alone, or the closed price plus an unpriced scope list when the toggle is on, plus a materials section separated from the priced total in both modes.

## Verification and completion gate

Each story adds focused Rails model/service/request/contract tests and behavior-focused Vitest coverage before an atomic story commit, per the existing project convention. Required coverage for this increment specifically includes a regression test asserting that no `POST /api/v1/shared-quotes/resolve` response body — for a `lump_sum` quote with items visible or hidden — contains the private item sum or any non-null per-item price. The increment closes only after OpenAPI-generated types are current and the full backend and frontend gates (`bin/check`, `pnpm check`) pass.
