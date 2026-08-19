<script setup lang="ts">
import { computed, type DeepReadonly } from "vue";
import type { ReportPeriodData } from "~/types";
import { formatRate } from "~/utils/formatters";

const props = defineProps<{ report: DeepReadonly<ReportPeriodData> }>();

interface SummaryCard {
  key: string;
  label: string;
  value: string;
  detail: string;
  change: string;
  icon: string;
  tone: "forest" | "coral" | "gold" | "blue" | "purple";
  help: { meaning: string; goal: string; reading: string };
}

const cards = computed<SummaryCard[]>(() => [
  {
    key: "published",
    label: "Publicados no período",
    value: `${props.report.summary.published.value}`,
    detail: `${props.report.summary.published.currentStock}/${props.report.supply.targetMinimum} publicados agora`,
    change: props.report.summary.published.change,
    icon: "i-lucide-users-round",
    tone: "forest",
    help: {
      meaning:
        "Profissionais cujo perfil foi aprovado e ficou pesquisável no período selecionado.",
      goal: `Formar a rede fundadora de ${props.report.supply.targetMinimum}–${props.report.supply.targetMaximum} profissionais publicados, com oferta distribuída entre serviços e bairros.`,
      reading:
        "Leia junto do funil: muitos cadastros e poucas publicações indicam bloqueio em verificação, preenchimento ou moderação.",
    },
  },
  {
    key: "activated",
    label: "Perfis ativados",
    value: `${props.report.summary.activated.numerator}/${props.report.summary.activated.denominator}`,
    detail: `${formatRate(props.report.summary.activated.rate)} dos publicados`,
    change: props.report.summary.activated.change,
    icon: "i-lucide-badge-check",
    tone: "purple",
    help: {
      meaning:
        "Perfis publicados com identidade aprovada, pelo menos três trabalhos no portfólio e duas relações profissionais confirmadas.",
      goal: "Aumentar a parcela de publicados que cumpre todos os critérios de ativação, sem criar uma nota de confiança opaca.",
      reading:
        "O numerador mostra ativados e o denominador, publicados. Consulte Qualidade da oferta para saber qual critério falta.",
    },
  },
  {
    key: "coverage",
    label: "Buscas com resultado",
    value: `${props.report.summary.searchCoverage.numerator}/${props.report.summary.searchCoverage.denominator}`,
    detail: `${formatRate(props.report.summary.searchCoverage.rate)} de cobertura`,
    change: props.report.summary.searchCoverage.change,
    icon: "i-lucide-search-check",
    tone: "blue",
    help: {
      meaning:
        "Buscas válidas que retornaram ao menos um profissional no serviço e região procurados.",
      goal: "Cobrir as buscas válidas e usar casos recorrentes sem resultado para orientar recrutamento ou revisão do catálogo.",
      reading:
        "Uma taxa alta com poucas opções ainda pode ser frágil. Compare também com buscas que oferecem três ou mais profissionais.",
    },
  },
  {
    key: "handoffs",
    label: "Contatos iniciados",
    value: `${props.report.summary.handoffs.numerator}`,
    detail: `${formatRate(props.report.summary.handoffs.rate)} dos perfis abertos`,
    change: props.report.summary.handoffs.change,
    icon: "i-lucide-message-circle-more",
    tone: "coral",
    help: {
      meaning:
        "Cliques deduplicados para iniciar uma conversa no WhatsApp a partir de um perfil ou resultado de busca.",
      goal: "Fazer o volume crescer junto com buscas bem atendidas e perfis abertos, mostrando intenção de contato.",
      reading:
        "É uma oportunidade observável, não uma contratação. A Berufe não lê mensagens nem conhece o resultado da conversa.",
    },
  },
  {
    key: "returning",
    label: "Profissionais recorrentes",
    value: `${props.report.summary.returning.numerator}/${props.report.summary.returning.denominator}`,
    detail: `${formatRate(props.report.summary.returning.rate)} da base publicada`,
    change: props.report.summary.returning.change,
    icon: "i-lucide-refresh-cw",
    tone: "gold",
    help: {
      meaning:
        "Profissionais publicados que voltaram e realizaram uma ação útil, como atualizar o perfil, fortalecer a rede ou criar orçamento.",
      goal: "Elevar a recorrência semanal e a retenção W1/W4; login isolado não conta como valor gerado.",
      reading:
        "Use o total com as coortes de retenção. Em bases pequenas, n/N é mais confiável que variações percentuais.",
    },
  },
]);
</script>

<template>
  <section class="summary" aria-labelledby="growth-health-title">
    <div class="summary__heading">
      <div>
        <DesignSystemKicker>Placar de partida</DesignSystemKicker>
        <h2 id="growth-health-title">Saúde do crescimento</h2>
      </div>
      <p>Contagens e denominadores visíveis para uma base ainda pequena.</p>
    </div>

    <div class="summary__grid">
      <article
        v-for="card in cards"
        :key="card.key"
        :class="['summary-card', `summary-card--${card.tone}`]"
      >
        <div class="summary-card__top">
          <span class="summary-card__icon"><UIcon :name="card.icon" /></span>
          <span class="summary-card__label">{{ card.label }}</span>
          <AdminReportsMetricHelp :title="card.label" v-bind="card.help" />
        </div>
        <strong>{{ card.value }}</strong>
        <small>{{ card.detail }}</small>
        <p><UIcon name="i-lucide-move-up-right" />{{ card.change }}</p>
      </article>
    </div>
  </section>
</template>

<style scoped lang="scss">
.summary {
  display: grid;
  gap: 13px;
  &__heading {
    display: flex;
    align-items: end;
    justify-content: space-between;
    gap: 20px;
  }
  &__heading h2,
  &__heading p {
    margin: 0;
  }
  &__heading h2 {
    margin-top: 2px;
    font-family: var(--font-display);
    font-size: 1.55rem;
    font-weight: 500;
    letter-spacing: -0.025em;
  }
  &__heading > p {
    max-width: 390px;
    color: var(--ink-soft);
    font-size: var(--font-size-min);
    line-height: 1.5;
    text-align: right;
  }
  &__grid {
    display: grid;
    grid-template-columns: repeat(5, minmax(0, 1fr));
    gap: 9px;
  }
}
.summary-card {
  --card-accent: var(--color-brand);
  --card-soft: var(--color-brand-tint);
  min-width: 0;
  padding: 15px;
  border: 1px solid var(--line);
  border-radius: 16px;
  background: rgb(255 255 255 / 88%);
  box-shadow: 0 8px 24px rgb(30 50 44 / 4.5%);
  &--coral {
    --card-accent: #bd563f;
    --card-soft: var(--color-accent-tint);
  }
  &--gold {
    --card-accent: #927019;
    --card-soft: #fff5d9;
  }
  &--blue {
    --card-accent: #356e84;
    --card-soft: #e8f3f7;
  }
  &--purple {
    --card-accent: #705e93;
    --card-soft: #f0ecf7;
  }
  &__top {
    display: flex;
    align-items: center;
    gap: 8px;
    min-height: 34px;
  }
  &__icon {
    display: grid;
    flex: 0 0 auto;
    place-items: center;
    width: 30px;
    height: 30px;
    border-radius: 9px;
    background: var(--card-soft);
    color: var(--card-accent);
  }
  &__label {
    flex: 1;
    color: var(--ink-soft);
    font-size: var(--font-size-min);
    font-weight: 750;
    line-height: 1.25;
  }
  & > strong {
    display: block;
    margin-top: 13px;
    font-family: var(--font-display);
    font-size: 1.75rem;
    font-weight: 500;
    letter-spacing: -0.035em;
  }
  & > small {
    display: block;
    min-height: 31px;
    margin-top: 2px;
    color: var(--ink-soft);
    font-size: var(--font-size-min);
    line-height: 1.35;
  }
  & > p {
    display: flex;
    align-items: center;
    gap: 4px;
    margin: 10px 0 0;
    color: var(--card-accent);
    font-size: var(--font-size-min);
    font-weight: 850;
  }
}
@media (width <= 1020px) {
  .summary__grid {
    grid-template-columns: repeat(3, 1fr);
  }
}
@media (width <= 680px) {
  .summary__heading {
    align-items: start;
    flex-direction: column;
  }
  .summary__heading > p {
    text-align: left;
  }
  .summary__grid {
    grid-template-columns: 1fr 1fr;
  }
}
@media (width <= 430px) {
  .summary__grid {
    grid-template-columns: 1fr;
  }
}
</style>
