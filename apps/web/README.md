# Berufe interactive mockup

Static, interactive product prototype built with the approved frontend stack: Nuxt, Vue, TypeScript, and Nuxt UI. All backend-shaped data lives in `data/*.json`; there are no API calls.

```bash
npm install
npm run dev
```

Use the “Explorar como” switcher in the header to jump among the public, professional, and admin surfaces. The OTP code in the sign-in prototype is `123456`.

Main validation routes:

- `/` → service discovery and product positioning
- `/encontrar?servico=eletricista&bairro=america` → Finder filters and transparent results
- `/profissionais/marcos-alves` → complete public trust profile
- `/app/professional/login` → phone OTP and first-time registration
- `/app/professional` and `/app/professional/profile` → readiness, profile sharing and editing, portfolio, identity verification, and existing-member relationships
- `/app/professional/quotes/new` → editable itemized quote with customer preview and WhatsApp sharing
- `/orcamento/BERUFE-DEMO-1042` → private-token customer quote page with browser print
- `/app/admin` → the shared moderation queue for profiles, portfolios, identity requests, and accepted professional relationships
- `/app/admin/catalog` → controlled services and Joinville neighborhoods for new profile and search selections (`/app/admin?view=catalogos` redirects here for compatibility)
- `/app/admin/reports` → privacy-safe MVP growth, discovery, utility, and moderation reporting

The quote token and customer data are synthetic. That route is prerendered only so this static prototype can be reviewed; the production implementation must serve tokenized quotes dynamically with `no-store` and `noindex`, as specified in the MVP stories.

All people, phone numbers, professional relationships, portfolio records, and newly generated profile/portfolio images in this prototype are synthetic. They demonstrate product behavior and must not be interpreted as real professionals, customers, work, credentials, or endorsements.

Generate a static build with `npm run generate`; the result is written to `.output/public`.

## Architecture and quality gates

- Shared domain contracts live in `app/types`; pure formatting, catalog, quote, contact, and text logic lives in `app/utils`.
- Cross-root imports use the configured `@app`, `@components`, and `@data` aliases so route nesting does not affect import paths.
- Stateful workflows use focused composables (`useToast`, `useShare`, `useAppRole`, and feature-specific draft/search composables).
- Design-system primitives stay in `app/components/design-system`; page features are split into folders such as `home`, `profile`, `auth`, `dashboard/quote`, and `admin/moderation`.
- Search filters and report periods are URL-backed so views remain linkable and browser navigation behaves predictably.

Run the complete local quality gate with:

```bash
npm run check
```

Useful focused commands are `npm run lint`, `npm run stylelint`, `npm run typecheck`, `npm run test`, and `npm run test:e2e`. Playwright starts the Nuxt development server automatically.
