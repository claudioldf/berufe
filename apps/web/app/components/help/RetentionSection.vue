<script setup lang="ts">
const emit = defineEmits<{ contact: [] }>();

const benefits = [
  {
    icon: "i-lucide-badge-dollar-sign",
    title: "Perfil grátis, sem pagar por contato",
    text: "Você não paga para aparecer nem por cada cliente que chama.",
  },
  {
    icon: "i-lucide-message-circle",
    title: "Clientes direto no seu WhatsApp",
    text: "Quem encontra seu perfil fala com você sem intermediários.",
  },
  {
    icon: "i-lucide-file-text",
    title: "Orçamentos e clientes organizados",
    text: "Monte orçamentos, envie por link e acompanhe quem aprovou.",
  },
  {
    icon: "i-lucide-star",
    title: "Recomendações que ficam no seu perfil",
    text: "Cada recomendação reforça a confiança de quem ainda não te conhece.",
  },
  {
    icon: "i-lucide-badge-check",
    title: "Selo de identidade verificada",
    text: "Mostre que existe uma pessoa real e confiável por trás do perfil.",
  },
];
</script>

<template>
  <section class="retention" aria-labelledby="retention-title">
    <h2 id="retention-title">Antes de ir embora, pense no que você leva</h2>
    <p>
      Se o motivo é uma dúvida, uma dificuldade ou algo que não funcionou como
      esperado, podemos ajudar. Veja o que sua conta já oferece hoje:
    </p>
    <ul class="retention__benefits">
      <li v-for="benefit in benefits" :key="benefit.title">
        <UIcon
          :name="benefit.icon"
          class="retention__icon"
          aria-hidden="true"
        />
        <div>
          <strong class="retention__title">{{ benefit.title }}</strong>
          <span class="retention__text">{{ benefit.text }}</span>
        </div>
      </li>
    </ul>
    <div class="retention__support">
      <p>Prefere conversar antes de decidir?</p>
      <UButton
        color="neutral"
        variant="outline"
        icon="i-lucide-life-buoy"
        @click="emit('contact')"
      >
        Falar com o suporte
      </UButton>
    </div>
  </section>
</template>

<style scoped lang="scss">
.retention {
  margin-top: 36px;
  padding: 24px;
  border: 1px solid var(--line);
  border-radius: var(--radius-lg, 18px);

  & h2 {
    margin: 0 0 10px;
    font-family: var(--font-display);
    font-size: 1.3rem;
  }

  & > p {
    margin: 0 0 18px;
    color: var(--ink-soft);
    line-height: 1.6;
  }

  &__benefits {
    display: grid;
    gap: 14px;
    margin: 0;
    padding: 0;
    list-style: none;

    & li {
      display: grid;
      grid-template-columns: auto 1fr;
      gap: 12px;
      align-items: start;
    }
  }

  &__icon {
    // Same height as the title's first line so the icon sits on it.
    width: 1.5rem;
    height: 1.5rem;
    color: var(--color-brand);
  }

  &__title,
  &__text {
    display: block;
  }

  &__title {
    line-height: 1.5rem;
  }

  &__text {
    color: var(--ink-soft);
    font-size: 0.92rem;
    line-height: 1.5;
  }

  &__support {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    margin-top: 22px;
    padding-top: 18px;
    border-top: 1px solid var(--line);

    & p {
      margin: 0;
      font-weight: 700;
    }

    @media (width <= 640px) {
      flex-direction: column;
      align-items: flex-start;
    }
  }
}
</style>
