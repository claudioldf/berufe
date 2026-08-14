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
- `/entrar` → phone OTP and first-time registration
- `/painel` and `/painel/perfil` → readiness, profile sharing and editing, portfolio, identity verification, and existing-member relationships
- `/painel/orcamentos/novo` → editable itemized quote with customer preview and WhatsApp sharing
- `/orcamento/BERUFE-DEMO-1042` → private-token customer quote page with browser print
- `/admin` → the shared moderation queue for profiles, portfolios, identity requests, and accepted professional relationships
- `/admin/catalogo` → controlled services and Joinville neighborhoods for new profile and search selections (`/admin?view=catalogos` redirects here for compatibility)
- `/admin/relatorios` → privacy-safe MVP growth, discovery, utility, and moderation reporting

The quote token and customer data are synthetic. That route is prerendered only so this static prototype can be reviewed; the production implementation must serve tokenized quotes dynamically with `no-store` and `noindex`, as specified in the MVP stories.

All people, phone numbers, professional relationships, portfolio records, and newly generated profile/portfolio images in this prototype are synthetic. They demonstrate product behavior and must not be interpreted as real professionals, customers, work, credentials, or endorsements.

Generate a static build with `npm run generate`; the result is written to `.output/public`.
