<script setup lang="ts">
import { computed } from "vue";
import type { ReportPeriodData } from "~/types";

const props = defineProps<{ supply: ReportPeriodData["supply"] }>();

const maxStage = computed(() =>
  Math.max(...props.supply.funnel.map((stage) => stage.value), 1),
);
const funnel = computed(() =>
  props.supply.funnel.map((stage, index) => {
    const previous = props.supply.funnel[index - 1]?.value ?? stage.value;
    return {
      ...stage,
      width: Math.max(
        (stage.value / maxStage.value) * 100,
        stage.value ? 8 : 0,
      ),
      conversion: previous ? Math.round((stage.value / previous) * 100) : 0,
    };
  }),
);

function percent(value: number, total: number) {
  if (!total) return "—";
  return `${Math.round((value / total) * 100)}%`;
}
</script>

<template>
  <section class="supply-grid" aria-label="Oferta e ativação profissional">
    <DesignSystemSurfaceCard as="article" class="report-card">
      <header class="report-card__header">
        <div>
          <DesignSystemKicker>Oferta</DesignSystemKicker>
          <h2>Funil de profissionais</h2>
          <span>Onde a rede fundadora está perdendo força.</span>
        </div>
        <div class="report-card__actions">
          <div class="goal-chip">
            <UIcon name="i-lucide-goal" /> Meta {{ supply.targetMinimum }}–{{
              supply.targetMaximum
            }}
          </div>
          <AdminReportsMetricHelp
            title="Funil de profissionais"
            meaning="Mostra quantos profissionais avançaram do cadastro até publicação e ativação. Cada porcentagem compara a etapa com a anterior."
            :goal="`Chegar a ${supply.targetMinimum}–${supply.targetMaximum} profissionais publicados e reduzir o maior abandono entre etapas.`"
            reading="A primeira etapa é a base observável no produto. Quedas grandes apontam verificação, preenchimento, moderação ou evidências."
          />
        </div>
      </header>
      <div class="funnel">
        <div
          v-for="(stage, index) in funnel"
          :key="stage.key"
          class="funnel__row"
        >
          <div class="funnel__label">
            <span>{{ stage.label }}</span
            ><small v-if="stage.description">{{ stage.description }}</small>
          </div>
          <div class="funnel__track">
            <i :style="{ width: `${stage.width}%` }" />
          </div>
          <strong>{{ stage.value }}</strong>
          <em>{{ index > 0 ? `${stage.conversion}%` : "base" }}</em>
        </div>
      </div>
    </DesignSystemSurfaceCard>

    <DesignSystemSurfaceCard as="article" class="report-card">
      <header class="report-card__header">
        <div>
          <DesignSystemKicker>Credibilidade</DesignSystemKicker>
          <h2>Qualidade da oferta</h2>
          <span>Critérios transparentes, sem nota de confiança opaca.</span>
        </div>
        <AdminReportsMetricHelp
          title="Qualidade da oferta"
          meaning="Decompõe identidade aprovada, três ou mais trabalhos e duas ou mais relações confirmadas."
          goal="Fazer os profissionais publicados avançarem nos três critérios, mantendo cada evidência compreensível."
          reading="Cada linha usa a mesma base publicada. Perfil ativado conta somente quem cumpre os três critérios ao mesmo tempo."
        />
      </header>
      <div class="activation-list">
        <div
          v-for="metric in supply.activation"
          :key="metric.key"
          class="activation-item"
        >
          <span class="activation-item__icon"
            ><UIcon :name="metric.icon"
          /></span>
          <div>
            <div class="activation-item__title">
              <strong>{{ metric.label }}</strong
              ><b>{{ metric.value }}/{{ metric.total }}</b>
            </div>
            <div class="activation-item__track">
              <i :style="{ width: percent(metric.value, metric.total) }" />
            </div>
            <small
              >{{ metric.description }} ·
              {{ percent(metric.value, metric.total) }}</small
            >
          </div>
        </div>
      </div>
      <aside class="activation-note">
        <UIcon name="i-lucide-lightbulb" />
        <p>
          <strong>Ativação significa evidência real.</strong> Identidade
          aprovada, três trabalhos e duas relações confirmadas.
        </p>
      </aside>
    </DesignSystemSurfaceCard>
  </section>
</template>

<style scoped lang="scss">
.supply-grid {
  display: grid;
  grid-template-columns: 1.08fr 0.92fr;
  gap: 12px;
}
.report-card {
  padding: 20px;
  &__header {
    display: flex;
    align-items: start;
    justify-content: space-between;
    gap: 14px;
  }
  &__actions {
    display: flex;
    align-items: center;
    gap: 7px;
  }
  &__header h2,
  &__header span {
    margin: 0;
  }
  &__header h2 {
    margin-top: 2px;
    font-family: Georgia, serif;
    font-size: 1.35rem;
    font-weight: 500;
  }
  &__header span {
    display: block;
    margin-top: 4px;
    color: var(--ink-soft);
    font-size: var(--font-size-min);
  }
}
.goal-chip {
  display: flex;
  align-items: center;
  gap: 5px;
  padding: 7px 9px;
  border-radius: 9px;
  background: #e8f4f0;
  color: #397a69;
  font-size: var(--font-size-min);
  font-weight: 850;
  white-space: nowrap;
}
.funnel {
  display: grid;
  gap: 12px;
  margin-top: 23px;
  &__row {
    display: grid;
    grid-template-columns: 128px minmax(80px, 1fr) 28px 38px;
    align-items: center;
    gap: 8px;
  }
  &__label span,
  &__label small {
    display: block;
  }
  &__label span,
  &__row strong,
  &__row em,
  &__label small {
    font-size: var(--font-size-min);
  }
  &__label span {
    font-weight: 750;
  }
  &__label small {
    overflow: hidden;
    margin-top: 2px;
    color: var(--ink-soft);
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  &__track {
    height: 9px;
    overflow: hidden;
    border-radius: 99px;
    background: #e9e8e3;
  }
  &__track i {
    display: block;
    height: 100%;
    border-radius: inherit;
    background: linear-gradient(90deg, #397a69, #74aa9c);
  }
  &__row strong,
  &__row em {
    text-align: right;
  }
  &__row em {
    color: var(--ink-soft);
    font-style: normal;
  }
}
.activation-list {
  display: grid;
  gap: 15px;
  margin-top: 22px;
}
.activation-item {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 10px;
  align-items: start;
  &__icon {
    display: grid;
    place-items: center;
    width: 34px;
    height: 34px;
    border-radius: 10px;
    background: #f0eee8;
    color: #397a69;
  }
  &__title {
    display: flex;
    justify-content: space-between;
    gap: 10px;
  }
  &__title strong,
  &__title b,
  & small {
    font-size: var(--font-size-min);
  }
  &__track {
    height: 6px;
    margin-top: 7px;
    overflow: hidden;
    border-radius: 99px;
    background: #e9e8e3;
  }
  &__track i {
    display: block;
    height: 100%;
    border-radius: inherit;
    background: #397a69;
  }
  & small {
    display: block;
    margin-top: 4px;
    color: var(--ink-soft);
  }
}
.activation-note {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 8px;
  margin-top: 18px;
  padding: 11px;
  border-radius: 11px;
  background: #fff7de;
  color: #85661a;
}
.activation-note p {
  margin: 0;
  color: var(--ink-soft);
  font-size: var(--font-size-min);
  line-height: 1.45;
}
.activation-note strong {
  color: #85661a;
}
@media (max-width: 850px) {
  .supply-grid {
    grid-template-columns: 1fr;
  }
}
@media (max-width: 520px) {
  .funnel__row {
    grid-template-columns: 105px minmax(55px, 1fr) 24px;
  }
  .funnel__row em,
  .goal-chip {
    display: none;
  }
}
</style>
