<script setup lang="ts">
import { professionalSignupPath } from "~/utils/professional-auth";
</script>

<template>
  <footer class="footer">
    <DesignSystemContainer class="footer__inner">
      <div>
        <DesignSystemBrand size="lg" />
        <p>Confiança para cuidar da sua casa.</p>
      </div>
      <div class="footer__links">
        <NuxtLink to="/encontrar">Encontrar profissional</NuxtLink>
        <NuxtLink :to="professionalSignupPath">Criar meu perfil</NuxtLink>
        <NuxtLink to="/privacidade">Privacidade</NuxtLink>
        <NuxtLink to="/termos-de-uso">Termos</NuxtLink>
      </div>
      <p class="footer__note">Berufe · Brasil</p>
    </DesignSystemContainer>
  </footer>
</template>

<style scoped lang="scss">
.footer {
  padding: 54px 0 30px;
  background: #102d28;
  color: white;
  &__inner {
    display: grid;
    grid-template-columns: 1fr auto;
    gap: 44px;
    align-items: start;
  }
  & p {
    margin: 10px 0 0;
    color: rgb(255 255 255 / 57%);
    font-size: 0.86rem;
  }
  &__links {
    display: grid;
    grid-template-columns: repeat(2, auto);
    gap: 14px 28px;
  }
  &__links a {
    color: rgb(255 255 255 / 74%);
    font-size: 0.82rem;
    font-weight: 700;
    text-decoration: none;
  }
  &__links a:hover {
    color: white;
  }
  &__note {
    grid-column: 1 / -1;
    padding-top: 24px;
    border-top: 1px solid rgb(255 255 255 / 10%);
  }
}
@media (width <= 660px) {
  .footer {
    &__inner {
      grid-template-columns: 1fr;
    }
    &__note {
      grid-column: auto;
    }
  }
}
</style>
