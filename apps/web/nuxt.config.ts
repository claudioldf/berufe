import { existsSync } from "node:fs";
import { fileURLToPath } from "node:url";

// Compose and CI supply the environment directly; a host-run `pnpm dev`, `pnpm
// build`, or `pnpm test` would otherwise see none of it, because the only
// `.env` lives at the repository root and Nuxt reads `.env` from this
// directory. Already-set variables win, so Compose and CI stay authoritative.
const repositoryEnvFile = fileURLToPath(new URL("../../.env", import.meta.url));
if (existsSync(repositoryEnvFile)) {
  process.loadEnvFile(repositoryEnvFile);
}

const browserSecurityHeaders = {
  "x-content-type-options": "nosniff",
  "x-frame-options": "DENY",
  "referrer-policy": "strict-origin-when-cross-origin",
};

export default defineNuxtConfig({
  compatibilityDate: "2026-08-01",
  devtools: { enabled: true },
  runtimeConfig: {
    apiInternalBaseUrl: process.env.NUXT_API_INTERNAL_BASE_URL,
    public: {
      apiBaseUrl: process.env.NUXT_PUBLIC_API_BASE_URL,
      bugsnagApiKey: process.env.NUXT_PUBLIC_BUGSNAG_API_KEY,
      releaseVersion: process.env.RAILWAY_GIT_COMMIT_SHA,
      siteUrl: process.env.NUXT_PUBLIC_SITE_URL,
    },
  },
  alias: {
    "@app": fileURLToPath(new URL("./app", import.meta.url)),
    "@components": fileURLToPath(new URL("./app/components", import.meta.url)),
    "@data": fileURLToPath(new URL("./data", import.meta.url)),
  },
  modules: ["@nuxt/ui", "@nuxt/eslint"],
  eslint: {
    config: {
      stylistic: false,
    },
  },
  colorMode: {
    preference: "light",
    fallback: "light",
  },
  icon: {
    serverBundle: {
      collections: ["lucide"],
    },
    clientBundle: {
      scan: true,
      icons: [
        "lucide:air-vent",
        "lucide:anvil",
        "lucide:armchair",
        "lucide:arrow-left",
        "lucide:arrow-right",
        "lucide:arrow-up-right",
        "lucide:badge-check",
        "lucide:baby",
        "lucide:brick-wall",
        "lucide:briefcase-business",
        "lucide:check",
        "lucide:check-circle-2",
        "lucide:chevron-down",
        "lucide:chevron-right",
        "lucide:circle",
        "lucide:circle-alert",
        "lucide:circle-check",
        "lucide:circle-dot",
        "lucide:circle-plus",
        "lucide:clock-3",
        "lucide:cloud-check",
        "lucide:cloud-upload",
        "lucide:drill",
        "lucide:droplets",
        "lucide:ellipsis",
        "lucide:expand",
        "lucide:eye",
        "lucide:file-check-2",
        "lucide:file-lock-2",
        "lucide:file-up",
        "lucide:fingerprint",
        "lucide:flame",
        "lucide:grid-2x2",
        "lucide:hammer",
        "lucide:handshake",
        "lucide:heart",
        "lucide:heart-handshake",
        "lucide:house",
        "lucide:id-card",
        "lucide:image",
        "lucide:image-plus",
        "lucide:images",
        "lucide:inbox",
        "lucide:info",
        "lucide:instagram",
        "lucide:key-round",
        "lucide:lamp-floor",
        "lucide:link",
        "lucide:link-2-off",
        "lucide:list-ordered",
        "lucide:lock-keyhole",
        "lucide:log-out",
        "lucide:mail",
        "lucide:map",
        "lucide:map-pin",
        "lucide:menu",
        "lucide:message-circle",
        "lucide:paint-roller",
        "lucide:paintbrush",
        "lucide:panels-top-left",
        "lucide:party-popper",
        "lucide:paw-print",
        "lucide:pencil",
        "lucide:pipette",
        "lucide:plus",
        "lucide:printer",
        "lucide:quote",
        "lucide:ruler",
        "lucide:scan-search",
        "lucide:search",
        "lucide:search-x",
        "lucide:send",
        "lucide:share-2",
        "lucide:shield-alert",
        "lucide:shield-check",
        "lucide:smartphone",
        "lucide:sparkles",
        "lucide:square-stack",
        "lucide:user-round",
        "lucide:trash-2",
        "lucide:trees",
        "lucide:wrench",
        "lucide:x",
        "lucide:youtube",
        "lucide:zap",
      ],
    },
  },
  css: ["~/assets/css/tailwind.css", "~/assets/scss/main.scss"],
  typescript: {
    strict: true,
    typeCheck: true,
  },
  app: {
    head: {
      htmlAttrs: { lang: "pt-BR" },
      titleTemplate: "%s · Berufe",
      meta: [
        {
          name: "description",
          content:
            "Profissionais verificados para cuidar da sua casa em Joinville.",
        },
        { name: "theme-color", content: "#183c35" },
      ],
    },
  },
  routeRules: {
    "/**": { headers: browserSecurityHeaders },
    "/": { prerender: false },
    "/encontrar": { prerender: false },
    "/profissionais/**": { prerender: false },
    "/foundation": { prerender: false },
    "/app/**": {
      ssr: false,
      prerender: false,
      headers: {
        ...browserSecurityHeaders,
        "cache-control": "private, no-store",
      },
    },
    "/orcamento/**": {
      prerender: false,
      headers: {
        ...browserSecurityHeaders,
        "cache-control": "private, no-store",
        "referrer-policy": "no-referrer",
        "x-robots-tag": "noindex, nofollow",
      },
    },
  },
});
