<script setup lang="ts">
import type { PublicProfessionalProfile } from "~/types";

defineProps<{
  evidence: PublicProfessionalProfile["evidence"];
  summary: PublicProfessionalProfile["evidenceSummary"];
}>();
</script>

<template>
  <section class="evidence-strip" aria-labelledby="evidence-strip-title">
    <DesignSystemContainer class="evidence-strip__inner">
      <div>
        <span class="evidence-strip__icon"
          ><UIcon name="i-lucide-shield-check"
        /></span>
        <div>
          <strong id="evidence-strip-title"
            >Evidências conferidas pela Berufe</strong
          >
          <small>Cada selo representa uma verificação específica.</small>
        </div>
      </div>
      <div class="evidence-strip__badges">
        <PublicEvidenceBadge
          v-for="item in evidence"
          :key="item.id"
          :evidence="item"
        />
      </div>
      <dl class="evidence-strip__outcomes">
        <div>
          <dt>{{ summary.registeredServices }}</dt>
          <dd>serviços registrados</dd>
        </div>
        <div>
          <dt>{{ summary.recommendations }}</dt>
          <dd>recomendações</dd>
        </div>
        <div>
          <dt>{{ summary.workedTogetherProfessionals }}</dt>
          <dd>profissionais parceiros</dd>
        </div>
      </dl>
    </DesignSystemContainer>
    <DesignSystemContainer
      v-if="summary.hiddenRecommendations > 0"
      class="evidence-strip__hidden-note"
    >
      <UIcon name="i-lucide-eye-off" aria-hidden="true" />
      {{ summary.hiddenRecommendations }}
      {{
        summary.hiddenRecommendations === 1
          ? "recomendação ocultada"
          : "recomendações ocultadas"
      }}
      pelo profissional.
    </DesignSystemContainer>
  </section>
</template>

<style scoped lang="scss">
.evidence-strip__outcomes {
  display: flex;
  gap: 18px;
  margin: 0;
}

.evidence-strip__outcomes > div {
  min-width: 80px;
  text-align: center;
}

.evidence-strip__outcomes dt {
  color: var(--color-brand);
  font-family: var(--font-display);
  font-size: 1.35rem;
  font-weight: 700;
}

.evidence-strip__outcomes dd {
  margin: 1px 0 0;
  color: var(--ink-soft);
  font-size: 0.72rem;
}

.evidence-strip__hidden-note {
  display: flex;
  align-items: center;
  gap: 6px;
  margin: 6px 0 0;
  color: var(--ink-soft);
  font-size: 0.76rem;
}

@media (width <= 850px) {
  .evidence-strip__outcomes {
    width: 100%;
    justify-content: space-between;
  }
}
</style>
