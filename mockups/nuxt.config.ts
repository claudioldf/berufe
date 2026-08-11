export default defineNuxtConfig({
  compatibilityDate: '2026-08-01',
  devtools: { enabled: true },
  modules: ['@nuxt/ui'],
  colorMode: {
    preference: 'light',
    fallback: 'light',
  },
  icon: {
    serverBundle: {
      collections: ['lucide'],
    },
    clientBundle: {
      scan: true,
      icons: [
        'lucide:armchair', 'lucide:award', 'lucide:badge-check', 'lucide:brick-wall',
        'lucide:briefcase-business', 'lucide:building-2', 'lucide:check-circle-2',
        'lucide:circle', 'lucide:circle-dot', 'lucide:circle-plus', 'lucide:clock-3',
        'lucide:cloud-check', 'lucide:cloud-upload', 'lucide:drill', 'lucide:expand',
        'lucide:file-check-2', 'lucide:file-lock-2', 'lucide:file-text', 'lucide:file-up',
        'lucide:fingerprint', 'lucide:flag', 'lucide:grid-2x2', 'lucide:hammer',
        'lucide:handshake', 'lucide:heart', 'lucide:heart-handshake', 'lucide:id-card',
        'lucide:image', 'lucide:image-plus', 'lucide:images', 'lucide:inbox',
        'lucide:lamp-floor', 'lucide:link', 'lucide:list-ordered', 'lucide:lock-keyhole',
        'lucide:map', 'lucide:map-pin', 'lucide:message-circle', 'lucide:paint-roller',
        'lucide:paintbrush', 'lucide:panels-top-left', 'lucide:party-popper',
        'lucide:pencil', 'lucide:pipette', 'lucide:printer', 'lucide:quote', 'lucide:ruler',
        'lucide:scan-search', 'lucide:search-x', 'lucide:send', 'lucide:share-2',
        'lucide:shield-alert', 'lucide:shield-check', 'lucide:smartphone',
        'lucide:sparkles', 'lucide:trash-2', 'lucide:trending-up', 'lucide:user-plus',
        'lucide:user-round', 'lucide:user-round-x', 'lucide:users', 'lucide:wrench',
        'lucide:zap',
      ],
    },
  },
  css: ['~/assets/css/main.css'],
  typescript: {
    strict: true,
    typeCheck: true,
  },
  app: {
    head: {
      htmlAttrs: { lang: 'pt-BR' },
      titleTemplate: '%s · Berufe',
      meta: [
        {
          name: 'description',
          content: 'Profissionais verificados para cuidar da sua casa em Joinville.',
        },
        { name: 'theme-color', content: '#183c35' },
      ],
    },
  },
  nitro: {
    prerender: {
      routes: [
        '/',
        '/encontrar',
        '/entrar',
        '/painel',
        '/painel/perfil',
        '/painel/orcamentos/novo',
        '/profissionais/marina-alves',
        '/profissionais/joao-vitor-santos',
        '/orcamento/BERUFE-DEMO-1042',
        '/admin',
      ],
    },
  },
})
