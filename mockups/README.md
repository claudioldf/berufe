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
- `/profissionais/marina-alves` → complete public trust profile
- `/entrar` → phone OTP and first-time registration
- `/painel` and `/painel/perfil` → readiness, metrics, profile, portfolio, and verification
- `/painel/orcamentos/novo` → editable quote with live customer preview
- `/orcamento/BERUFE-DEMO-1042` → token-shaped customer quote page
- `/admin` → moderation; use the header for catalogs and aggregate reports

Generate a static build with `npm run generate`; the result is written to `.output/public`.
