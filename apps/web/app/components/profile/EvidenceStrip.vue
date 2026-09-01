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
      <div class="evidence-strip__verification">
        <span class="evidence-strip__icon" aria-hidden="true">
          <UIcon name="i-lucide-shield-check" />
        </span>
        <div class="evidence-strip__verification-content">
          <div class="evidence-strip__heading">
            <h2 id="evidence-strip-title">Verificações da Berufe</h2>
            <p>Dados conferidos para você contratar com mais confiança.</p>
          </div>
          <div
            class="evidence-strip__badges"
            aria-label="Verificações deste perfil"
          >
            <PublicEvidenceBadge
              v-for="item in evidence"
              :key="item.id"
              :evidence="item"
            />
          </div>
        </div>
      </div>
      <div class="evidence-strip__summary">
        <dl class="evidence-strip__outcomes" aria-label="Resumo do perfil">
          <div class="evidence-strip__metric">
            <dt>{{ summary.registeredServices }}</dt>
            <dd>serviços registrados</dd>
          </div>
          <div class="evidence-strip__metric">
            <dt>{{ summary.recommendations }}</dt>
            <dd>recomendações</dd>
          </div>
          <div class="evidence-strip__metric">
            <dt>{{ summary.workedTogetherProfessionals }}</dt>
            <dd>profissionais parceiros</dd>
          </div>
        </dl>
        <p
          v-if="summary.hiddenRecommendations > 0"
          class="evidence-strip__hidden-note"
        >
          <UIcon name="i-lucide-eye-off" aria-hidden="true" />
          <span>
            {{ summary.hiddenRecommendations }}
            {{
              summary.hiddenRecommendations === 1
                ? "recomendação ocultada"
                : "recomendações ocultadas"
            }}
            pelo profissional.
          </span>
        </p>
      </div>
    </DesignSystemContainer>
  </section>
</template>

<style scoped lang="scss">
.evidence-strip {
  border-bottom: 1px solid var(--line);
  background: linear-gradient(
    105deg,
    var(--color-surface) 35%,
    var(--color-brand-tint-subtle) 100%
  );

  &__inner {
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    align-items: center;
    gap: 40px;
    padding-block: 22px;
  }

  &__verification {
    display: grid;
    grid-template-columns: 48px minmax(0, 1fr);
    align-items: center;
    gap: 16px;
    min-width: 0;
  }

  &__icon {
    display: grid;
    place-items: center;
    width: 48px;
    height: 48px;
    border: 1px solid var(--color-brand-soft-strong);
    border-radius: 15px;
    background: var(--color-brand-soft);
    color: var(--color-brand);
    box-shadow: 0 8px 20px rgb(18 98 93 / 10%);
    font-size: 1.3rem;
  }

  &__verification-content {
    display: flex;
    align-items: center;
    gap: 20px;
    min-width: 0;
  }

  &__heading {
    flex: 0 1 230px;
  }

  &__heading h2,
  &__heading p {
    margin: 0;
  }

  &__heading h2 {
    color: var(--ink);
    font-size: 0.95rem;
    font-weight: 800;
    line-height: 1.3;
  }

  &__heading p {
    margin-top: 4px;
    color: var(--ink-soft);
    font-size: 0.82rem;
    line-height: 1.45;
  }

  &__badges {
    display: flex;
    flex-wrap: nowrap;
    gap: 8px;
    min-width: 0;
  }

  &__summary {
    overflow: hidden;
    border: 1px solid var(--color-border);
    border-radius: var(--radius-xl);
    background: rgb(255 255 255 / 74%);
    box-shadow: 0 10px 30px rgb(30 50 44 / 6%);
    backdrop-filter: blur(6px);
  }

  &__outcomes {
    display: grid;
    grid-template-columns: repeat(3, minmax(92px, 1fr));
    margin: 0;
    padding: 13px 8px;
  }

  &__metric {
    display: grid;
    align-content: center;
    justify-items: center;
    min-width: 0;
    padding-inline: 14px;
    text-align: center;
  }

  &__metric + &__metric {
    border-left: 1px solid var(--line);
  }

  &__metric dt {
    color: var(--color-brand);
    font-family: var(--font-display);
    font-size: 1.55rem;
    font-variant-numeric: tabular-nums;
    font-weight: 700;
    line-height: 1;
  }

  &__metric dd {
    margin: 5px 0 0;
    color: var(--ink-soft);
    font-size: 0.7rem;
    line-height: 1.25;
  }

  &__hidden-note {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    margin: 0;
    padding: 8px 12px;
    border-top: 1px solid var(--line);
    color: var(--ink-soft);
    font-size: 0.72rem;
    line-height: 1.35;
  }
}

@media (width <= 1160px) {
  .evidence-strip {
    &__inner {
      grid-template-columns: 1fr;
      gap: 18px;
    }

    &__verification-content {
      justify-content: space-between;
    }

    &__summary {
      width: 100%;
    }
  }
}

@media (width <= 680px) {
  .evidence-strip {
    background: var(--color-surface);

    &__inner {
      gap: 16px;
      padding-block: 18px;
    }

    &__verification {
      grid-template-columns: 42px minmax(0, 1fr);
      align-items: start;
      gap: 12px;
    }

    &__icon {
      width: 42px;
      height: 42px;
      border-radius: 13px;
      font-size: 1.15rem;
    }

    &__verification-content {
      display: grid;
      gap: 12px;
    }

    &__heading {
      flex-basis: auto;
    }

    &__badges {
      grid-column: 1 / -1;
      flex-wrap: wrap;
    }

    &__outcomes {
      grid-template-columns: repeat(3, minmax(0, 1fr));
      padding-inline: 2px;
    }

    &__metric {
      padding-inline: 6px;
    }

    &__metric dt {
      font-size: 1.4rem;
    }

    &__metric dd {
      font-size: 0.67rem;
    }

    &__hidden-note {
      align-items: flex-start;
      text-align: left;
    }
  }
}
</style>
