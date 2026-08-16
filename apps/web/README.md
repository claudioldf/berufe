# Berufe web

Nuxt/Vue TypeScript application for the public, professional, and administrator
surfaces. Nuxt UI is the only component toolkit. Shared product decisions remain
in the root `docs/`; this file records frontend-specific commands and boundaries.

```bash
pnpm install --frozen-lockfile
pnpm api:generate
pnpm dev
```

`app/services/api/schema.d.ts` is generated from
`../contracts/openapi.yaml`. API requests go through the handwritten typed client
in `app/services/api/client.ts`; pages do not call Rails directly.

The `/foundation` route demonstrates the public layout, central visual tokens,
form validation, feedback states, and live Nuxt-to-Rails integration. Routes
under `/app` use the responsive workspace layout.

Run the local checks with:

```bash
pnpm check
```

The token-authorized quote route and authenticated routes are request-time only
and use private, no-store response rules. Prototype JSON and imagery are
synthetic fixtures until their owning product stories replace them with API
operations.
