<template>
  <footer class="footer">
    <div class="footer__inner page-container">
      <div>
        <NuxtLink class="footer__brand" to="/">berufe<span>.</span></NuxtLink>
        <p>Confiança local para cuidar da sua casa.</p>
      </div>
      <div class="footer__links">
        <NuxtLink to="/encontrar">Encontrar profissional</NuxtLink>
        <NuxtLink to="/entrar">Criar meu perfil</NuxtLink>
        <a href="#">Privacidade</a>
        <a href="#">Termos</a>
      </div>
      <p class="footer__note">Protótipo interativo · Joinville, SC</p>
    </div>
  </footer>
</template>

<style scoped>
.footer { padding: 54px 0 30px; background: #102d28; color: white; }
.footer__inner { display: grid; grid-template-columns: 1fr auto; gap: 44px; align-items: start; }
.footer__brand { color: white; font-family: Georgia, serif; font-size: 2rem; font-weight: 700; letter-spacing: -.05em; text-decoration: none; }
.footer__brand span { color: var(--coral); }
.footer p { margin: 10px 0 0; color: rgba(255,255,255,.57); font-size: .86rem; }
.footer__links { display: grid; grid-template-columns: repeat(2, auto); gap: 14px 28px; }
.footer__links a { color: rgba(255,255,255,.74); font-size: .82rem; font-weight: 700; text-decoration: none; }
.footer__links a:hover { color: white; }
.footer__note { grid-column: 1 / -1; padding-top: 24px; border-top: 1px solid rgba(255,255,255,.1); }
@media (max-width: 660px) { .footer__inner { grid-template-columns: 1fr; } .footer__note { grid-column: auto; } }
</style>
