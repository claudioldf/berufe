<script setup lang="ts">
import { professionalSignupPath } from "~/utils/professional-auth";
</script>

<template>
  <section id="para-profissionais" class="professional-cta">
    <DesignSystemContainer class="professional-cta__inner">
      <div>
        <DesignSystemEyebrow>Você é profissional?</DesignSystemEyebrow>
        <DesignSystemHeading>
          Seu trabalho merece<br />uma identidade forte.
        </DesignSystemHeading>
      </div>
      <div>
        <p>
          Crie seu perfil, organize suas evidências e compartilhe sua página e
          orçamentos sem pagar por contatos.
        </p>
        <UButton
          :to="professionalSignupPath"
          color="secondary"
          trailing-icon="i-lucide-arrow-right"
        >
          Criar perfil grátis
        </UButton>
      </div>
    </DesignSystemContainer>
  </section>
</template>

<style scoped>
.professional-cta {
  scroll-margin-top: 1rem;
}
</style>
