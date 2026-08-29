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
  modules: [
    "@nuxt/ui",
    "@nuxt/eslint",
    "@nuxtjs/seo",
    "@nuxt/content",
    "@nuxt/image",
  ],
  eslint: {
    config: {
      stylistic: false,
    },
  },
  site: {
    url: process.env.NUXT_PUBLIC_SITE_URL,
    name: "Berufe",
    description:
      "Encontre profissionais verificados para sua casa e seu dia a dia. Veja trabalhos e referências e fale direto pelo WhatsApp — sem pagar por contato.",
    defaultLocale: "pt-BR",
  },
  robots: {
    disallow: ["/app", "/orcamento", "/recomendacao", "/foundation"],
  },
  sitemap: {
    exclude: ["/app/**", "/orcamento/**", "/recomendacao/**", "/foundation"],
    sources: [
      "/api/__sitemap__/professionals",
      "/api/__sitemap__/listings",
      "/api/__sitemap__/para-profissionais",
    ],
  },
  linkChecker: {
    enabled: true,
    // Report only; a broken internal link should not fail CI while the
    // module is new. Revisit once the report is clean.
    failOnError: false,
  },
  image: {
    quality: 82,
    format: ["webp"],
  },
  content: {
    build: {
      markdown: {
        toc: { depth: 2 },
      },
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
        "lucide:brush-cleaning",
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
        "lucide:spray-can",
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
  experimental: {
    defaults: {
      nuxtLink: {
        // Catalog grids (services, guides, city hubs) render 25+ links on
        // one screen; the framework default prefetches every one of them as
        // soon as it's visible, firing a full SSR render per link. Prefetch
        // on hover/focus/touchstart instead — still instant for the link the
        // visitor actually intends to follow.
        prefetchOn: { visibility: false, interaction: true },
      },
    },
  },
  app: {
    head: {
      htmlAttrs: { lang: "pt-BR" },
      titleTemplate: "%s · Berufe",
      meta: [
        {
          name: "description",
          content:
            "Profissionais verificados para cuidar da sua casa e do seu dia a dia.",
        },
        { name: "theme-color", content: "#183c35" },
      ],
      link: [
        { rel: "icon", type: "image/svg+xml", href: "/favicon.svg" },
        { rel: "icon", type: "image/x-icon", href: "/favicon.ico" },
        { rel: "apple-touch-icon", href: "/apple-touch-icon.png" },
        { rel: "manifest", href: "/site.webmanifest" },
      ],
    },
  },
  routeRules: {
    "/**": { headers: browserSecurityHeaders },
    "/": { prerender: false },
    "/encontrar": { prerender: false },
    "/encontrar/**": { prerender: false, swr: 300 },
    "/profissionais/**": { prerender: false, swr: 300 },
    // The "/**" rules below don't match their own bare parent path, so each
    // needs an explicit entry or the index page never gets SWR caching.
    "/servicos": { prerender: false, swr: 300 },
    "/servicos/**": { prerender: false, swr: 300 },
    "/para-profissionais": { prerender: false, swr: 900 },
    "/para-profissionais/**": { prerender: false, swr: 900 },
    "/guias": { prerender: false, swr: 900 },
    "/guias/**": { prerender: false, swr: 900 },
    "/foundation": {
      prerender: false,
      headers: {
        ...browserSecurityHeaders,
        "x-robots-tag": "noindex, nofollow",
      },
    },
    "/app/**": {
      ssr: false,
      prerender: false,
      headers: {
        ...browserSecurityHeaders,
        "cache-control": "private, no-store",
        "x-robots-tag": "noindex, nofollow",
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
    "/recomendacao/**": {
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
