# Primary-service experience decision

**Status:** Approved for MVP implementation
**Date:** 2026-08-30
**Supersedes:** the always-visible “Serviço principal do perfil” control in the professional profile mockup and the explicit-choice interpretation of S020. It does not supersede the exactly-one-primary persistence invariant.

## Outcome

Every selected catalog entry is an ordinary professional service and participates equally in service search. One selection remains marked internally as `is_primary` only to provide a deterministic featured service when a surface needs one canonical professional label, including direct profile headers, SEO metadata, quotes, moderation summaries, and contact attribution without search context.

The first selected service becomes the featured service automatically. The professional is not asked to make a second choice while only one service is selected. When two or more services are selected, the form shows a presentation choice labeled “Serviço em destaque” with the explanation: “Escolha o serviço que aparece primeiro no seu perfil. Todos continuam disponíveis nas buscas.” The choice remains technically required while multiple services exist.

If the featured service is removed, the first remaining selected service becomes featured. Existing or malformed drafts without a valid featured selection are normalized to the first selected service before persistence. The API continues to send all selected services and exactly one `is_primary: true`; no database, OpenAPI, public read-model, ranking, or search behavior changes.

## Presentation rules

- The services section communicates that the professional may choose “1 ou mais” services.
- With no services, validation says “Escolha ao menos um serviço.”
- With one service, the featured-service selector is hidden and that service is assigned automatically.
- With multiple services, the selector is visible and lists only the selected services.
- All selected services remain eligible for matching and search display; featured status does not increase ranking.
