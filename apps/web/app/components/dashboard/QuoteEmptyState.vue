<script setup lang="ts">
const benefits = [
  "Itens, quantidades e valores bem organizados",
  "Aprovação do cliente direto pelo link",
  "Histórico e andamento sempre à mão",
];

const visual = {
  icon: "i-lucide-file-check-2",
  title: "Orçamento",
  caption: "Pronto para o cliente",
  metaLabel: "Total",
  metaValue: "R$ 1.850",
  badge: "Pronto para enviar",
  badgeIcon: "i-lucide-send",
};
</script>

<template>
  <DesignSystemFeatureEmptyState
    eyebrow="Sua proposta, com cara profissional"
    title="Transforme pedidos em trabalhos fechados."
    description="Monte um orçamento claro em poucos minutos. O cliente recebe um link seguro para aprovar ou pedir ajustes, e você acompanha tudo pelo painel."
    :items="benefits"
    cta-label="Criar meu primeiro orçamento"
    cta-to="/app/professional/quotes/new"
    :visual="visual"
  />
</template>
