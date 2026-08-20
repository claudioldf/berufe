<script setup lang="ts">
defineEmits<{ review: [] }>();
</script>

<template>
  <DesignSystemSurfaceCard as="section" class="onboarding-success">
    <span><UIcon name="i-lucide-party-popper" /></span>
    <DesignSystemEyebrow>Perfil publicado</DesignSystemEyebrow>
    <h2>Seu perfil já pode ser encontrado.</h2>
    <p>
      As informações essenciais estão no ar. Agora você pode adicionar
      portfólio, relações profissionais e verificação para fortalecer a
      confiança.
    </p>
    <div>
      <UButton
        type="button"
        color="neutral"
        variant="ghost"
        @click="$emit('review')"
      >
        Revisar etapas
      </UButton>
      <UButton
        to="/app/professional"
        color="primary"
        trailing-icon="i-lucide-arrow-right"
      >
        Ir para o painel
      </UButton>
    </div>
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.onboarding-success {
  display: grid;
  min-height: 360px;
  padding: 38px;
  text-align: center;
  place-items: center;

  & > span {
    display: grid;
    place-items: center;
    width: 70px;
    height: 70px;
    margin-bottom: 18px;
    border-radius: 22px;
    background: var(--mint);
    color: var(--color-brand);
    font-size: 2rem;
  }
  & h2 {
    margin: 8px 0 0;
    font-family: var(--font-display);
    font-size: clamp(2rem, 5vw, 3.2rem);
    font-weight: 500;
    letter-spacing: -0.04em;
  }
  & p {
    max-width: 620px;
    margin: 13px 0 23px;
    color: var(--ink-soft);
    line-height: 1.6;
  }
  & > div {
    display: flex;
    gap: 8px;
  }
}

@media (width <= 650px) {
  .onboarding-success {
    padding: 28px 20px;
  }
  .onboarding-success > div {
    display: grid;
    width: 100%;
  }
}
</style>
