<script setup lang="ts">
const benefits = [
  "Serviços aprovados organizados em um só lugar",
  "Acompanhamento da execução até a conclusão",
  "Confirmação do cliente por um link seguro",
];

const visual = {
  icon: "i-lucide-briefcase-business",
  title: "Serviço aprovado",
  caption: "Pronto para executar",
  metaLabel: "Andamento",
  metaValue: "Até a conclusão",
  badge: "Cliente aprovou",
  badgeIcon: "i-lucide-badge-check",
};
</script>

<template>
  <DesignSystemFeatureEmptyState
    class="service-empty-state"
    eyebrow="Do orçamento ao serviço concluído"
    title="Seu próximo serviço começa com uma proposta aprovada."
    description="Crie e envie um orçamento ao cliente. Assim que ele aprovar, o trabalho aparece aqui para você acompanhar a execução e confirmar a conclusão."
    :items="benefits"
    cta-label="Criar meu primeiro orçamento"
    cta-to="/app/professional/quotes/new"
    :visual="visual"
  />
</template>

<style scoped lang="scss">
@media (width <= 700px) {
  .service-empty-state :deep(.feature-empty__visual) {
    display: none;
  }
}
</style>
