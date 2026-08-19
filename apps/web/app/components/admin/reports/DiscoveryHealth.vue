<script setup lang="ts">
import { computed, type DeepReadonly } from "vue";
import type { ReportPeriodData } from "~/types";
import { formatRate } from "~/utils/formatters";

const props = defineProps<{
  discovery: DeepReadonly<ReportPeriodData["discovery"]>;
}>();

const discoveryStages = computed(() => props.discovery.stages);
const maxDemand = computed(() =>
  Math.max(...props.discovery.demand.map((item) => item.value), 1),
);
</script>

<template>
  <section class="discovery" aria-labelledby="discovery-title">
    <header class="section-heading">
      <div>
        <DesignSystemKicker>Demanda e liquidez</DesignSystemKicker>
        <h2 id="discovery-title">Da busca ao interesse</h2>
      </div>
      <p>
        Contatos aparecem no placar como cliques agregados — nunca como
        contratação.
      </p>
    </header>

    <div class="discovery__grid">
      <DesignSystemSurfaceCard as="article" class="discovery-funnel">
        <header class="widget-heading">
          <div>
            <h3>Cobertura da jornada</h3>
            <p>Progressão desde a busca</p>
          </div>
          <AdminReportsMetricHelp
            title="Cobertura da jornada"
            meaning="Mostra quantas buscas tiveram resultado, variedade, abertura de perfil e contato iniciado. Cada etapa é comparada ao total de buscas."
            goal="Cobrir a demanda, oferecer escolha e despertar interesse em perfis confiáveis."
            reading="A maior queda indica o problema principal. Contato é um clique agregado para o WhatsApp, não uma contratação."
          />
        </header>
        <div
          v-for="(stage, index) in discoveryStages"
          :key="stage.key"
          class="discovery-stage"
        >
          <div class="discovery-stage__top">
            <span>{{ stage.label }}</span
            ><strong>{{ stage.numerator }}</strong>
          </div>
          <div class="discovery-stage__bar">
            <i :style="{ width: formatRate(stage.rate) }" />
          </div>
          <small>{{
            index > 0
              ? `${formatRate(stage.rate)} das buscas`
              : "base do período"
          }}</small>
        </div>
      </DesignSystemSurfaceCard>

      <DesignSystemSurfaceCard as="article" class="demand-card">
        <header>
          <div>
            <h3>Demanda por serviço</h3>
            <p>Buscas agregadas</p>
          </div>
          <div class="widget-actions">
            <UIcon name="i-lucide-chart-no-axes-column-increasing" />
            <AdminReportsMetricHelp
              title="Demanda por serviço"
              meaning="Ordena os serviços pelo número de buscas, sem identificar quem pesquisou."
              goal="Usar demanda real para priorizar recrutamento e cobertura territorial."
              reading="Volume não é conversão. Compare com cobertura, opções disponíveis e contatos iniciados."
            />
          </div>
        </header>
        <div class="demand-bars">
          <div v-for="item in discovery.demand" :key="item.label">
            <span>{{ item.label }}</span>
            <i
              ><b :style="{ width: `${(item.value / maxDemand) * 100}%` }"
            /></i>
            <strong>{{ item.value }}</strong>
          </div>
        </div>
      </DesignSystemSurfaceCard>

      <DesignSystemSurfaceCard as="article" class="gaps-card">
        <header>
          <div>
            <h3>Gaps que bloqueiam crescimento</h3>
            <p>Buscas agrupadas com pouca ou nenhuma oferta</p>
          </div>
          <div class="widget-actions">
            <span>Priorizar rede</span>
            <AdminReportsMetricHelp
              title="Gaps de oferta"
              meaning="Destaca grupos de serviço e região que atingiram o limiar de privacidade, mas têm zero ou poucos profissionais."
              goal="Eliminar primeiro gaps repetidos de serviços ativos e avaliar demandas fora do catálogo antes de ampliar o MVP."
              reading="Recrutar indica falta de profissionais no catálogo atual. Avaliar catálogo indica demanda ainda não assumida."
            />
          </div>
        </header>
        <div class="gaps-list">
          <div
            v-for="gap in discovery.gaps"
            :key="`${gap.service}-${gap.location}`"
          >
            <span
              :class="{
                'gaps-list__icon--catalog': gap.catalogStatus !== 'active',
              }"
              ><UIcon
                :name="
                  gap.catalogStatus !== 'active'
                    ? 'i-lucide-list-plus'
                    : 'i-lucide-map-pin'
                "
            /></span>
            <div>
              <strong>{{ gap.service }} · {{ gap.location }}</strong>
              <small
                >{{ gap.searches }} buscas · {{ gap.professionals }}
                {{
                  gap.professionals === 1 ? "profissional" : "profissionais"
                }}</small
              >
            </div>
            <em>{{
              gap.catalogStatus !== "active" ? "Avaliar catálogo" : "Recrutar"
            }}</em>
          </div>
        </div>
      </DesignSystemSurfaceCard>
    </div>
  </section>
</template>

<style scoped lang="scss">
.discovery {
  display: grid;
  gap: 13px;
  &__grid {
    display: grid;
    grid-template-columns: 0.9fr 1.1fr;
    gap: 12px;
  }
}
.section-heading {
  display: flex;
  align-items: end;
  justify-content: space-between;
  gap: 20px;
}
.section-heading h2,
.section-heading p {
  margin: 0;
}
.section-heading h2 {
  margin-top: 2px;
  font-family: var(--font-display);
  font-size: 1.55rem;
  font-weight: 500;
}
.section-heading > p {
  max-width: 420px;
  color: var(--ink-soft);
  font-size: var(--font-size-min);
  line-height: 1.5;
  text-align: right;
}
.discovery-funnel {
  display: grid;
  gap: 14px;
  padding: 20px;
}
.discovery-stage {
  &__top {
    display: flex;
    justify-content: space-between;
    gap: 10px;
  }
  &__top span,
  &__top strong,
  & small {
    font-size: var(--font-size-min);
  }
  &__bar {
    height: 8px;
    margin-top: 6px;
    overflow: hidden;
    border-radius: 99px;
    background: var(--color-surface-disabled);
  }
  &__bar i {
    display: block;
    height: 100%;
    border-radius: inherit;
    background: linear-gradient(90deg, #f8755d, #f4a18f);
  }
  & small {
    display: block;
    margin-top: 3px;
    color: var(--ink-soft);
  }
}
.demand-card,
.gaps-card {
  padding: 20px;
}
.demand-card header,
.gaps-card header,
.widget-heading,
.widget-actions {
  display: flex;
  justify-content: space-between;
  gap: 12px;
}
.demand-card h3,
.demand-card p,
.gaps-card h3,
.gaps-card p,
.widget-heading h3,
.widget-heading p {
  margin: 0;
}
.demand-card h3,
.gaps-card h3,
.widget-heading h3 {
  font-family: var(--font-display);
  font-size: 1.15rem;
  font-weight: 500;
}
.demand-card p,
.gaps-card p,
.widget-heading p {
  margin-top: 3px;
  color: var(--ink-soft);
  font-size: var(--font-size-min);
}
.widget-actions {
  align-items: center;
  justify-content: flex-end;
  gap: 8px;
}
.widget-actions > svg {
  color: var(--color-brand);
  font-size: 1.2rem;
}
.widget-actions > span {
  padding: 6px 8px;
  border-radius: 8px;
  background: var(--color-accent-tint);
  color: #a94734;
  font-size: var(--font-size-min);
  font-weight: 850;
}
.demand-bars {
  display: grid;
  gap: 13px;
  margin-top: 23px;
}
.demand-bars > div {
  display: grid;
  grid-template-columns: 110px 1fr 28px;
  align-items: center;
  gap: 8px;
}
.demand-bars span,
.demand-bars strong {
  font-size: var(--font-size-min);
}
.demand-bars i {
  height: 7px;
  overflow: hidden;
  border-radius: 99px;
  background: var(--color-surface-disabled);
}
.demand-bars b {
  display: block;
  height: 100%;
  border-radius: inherit;
  background: var(--color-brand);
}
.demand-bars strong {
  text-align: right;
}
.gaps-card {
  grid-column: 1 / -1;
}
.gaps-list {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 9px;
  margin-top: 17px;
  & > div {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 9px;
    padding: 12px;
    border-radius: 12px;
    background: var(--color-surface-neutral);
  }
  & > div > span {
    display: grid;
    place-items: center;
    width: 32px;
    height: 32px;
    border-radius: 9px;
    background: var(--color-accent-tint);
    color: #a94734;
  }
  & > div > &__icon--catalog {
    background: var(--color-warning-tint);
    color: #8a6918;
  }
  & strong,
  & small {
    display: block;
  }
  & strong,
  & small,
  & em {
    font-size: var(--font-size-min);
  }
  & strong {
    line-height: 1.35;
  }
  & small {
    margin-top: 3px;
    color: var(--ink-soft);
  }
  & em {
    grid-column: 2;
    color: var(--color-brand);
    font-style: normal;
    font-weight: 850;
  }
}
@media (width <= 800px) {
  .discovery__grid {
    grid-template-columns: 1fr;
  }
  .gaps-card {
    grid-column: auto;
  }
  .gaps-list {
    grid-template-columns: 1fr;
  }
}
@media (width <= 620px) {
  .section-heading {
    align-items: start;
    flex-direction: column;
  }
  .section-heading > p {
    text-align: left;
  }
}
</style>
