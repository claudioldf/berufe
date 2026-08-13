<template>
  <footer class="footer">
    <DesignSystemContainer class="footer__inner">
      <div>
        <DesignSystemBrand size="lg" />
        <p>Confiança para cuidar da sua casa.</p>
      </div>
      <div class="footer__links">
        <NuxtLink to="/encontrar">Encontrar profissional</NuxtLink>
        <NuxtLink to="/entrar">Criar meu perfil</NuxtLink>
        <NuxtLink to="/privacidade">Privacidade</NuxtLink>
        <NuxtLink to="/termos-de-uso">Termos</NuxtLink>
      </div>
      <p class="footer__note">Berufe · Joinville, SC</p>
    </DesignSystemContainer>
  </footer>
</template>

<style scoped>
.footer { padding: 54px 0 30px; background: #102d28; color: white; }
.footer__inner { display: grid; grid-template-columns: 1fr auto; gap: 44px; align-items: start; }
.footer p { margin: 10px 0 0; color: rgba(255,255,255,.57); font-size: .86rem; }
.footer__links { display: grid; grid-template-columns: repeat(2, auto); gap: 14px 28px; }
.footer__links a { color: rgba(255,255,255,.74); font-size: .82rem; font-weight: 700; text-decoration: none; }
.footer__links a:hover { color: white; }
.footer__note { grid-column: 1 / -1; padding-top: 24px; border-top: 1px solid rgba(255,255,255,.1); }
@media (max-width: 660px) { .footer__inner { grid-template-columns: 1fr; } .footer__note { grid-column: auto; } }
</style>
