<script setup lang="ts">
import type { PublicProfessionalProfile } from "~/types";
import { formatTimestampDate } from "~/utils/formatters";

defineProps<{
  recommendations: PublicProfessionalProfile["customerRecommendations"];
}>();
</script>

<template>
  <section
    v-if="recommendations.length"
    class="profile-recommendations"
    aria-labelledby="customer-recommendations-title"
  >
    <DesignSystemContainer>
      <DesignSystemEyebrow>Experiências confirmadas</DesignSystemEyebrow>
      <h2 id="customer-recommendations-title">Recomendações de clientes.</h2>
      <div class="profile-recommendations__grid">
        <article
          v-for="recommendation in recommendations"
          :key="recommendation.id"
        >
          <UIcon name="i-lucide-quote" />
          <blockquote>{{ recommendation.text }}</blockquote>
          <footer>
            <span>
              <strong>{{ recommendation.displayName }}</strong>
              <small>{{ formatTimestampDate(recommendation.submittedAt) }}</small>
            </span>
            <em>
              <UIcon name="i-lucide-mail-check" />
              {{ recommendation.verificationLabel }}
            </em>
          </footer>
        </article>
      </div>
    </DesignSystemContainer>
  </section>
</template>

<style scoped lang="scss">
.profile-recommendations {
  padding: 52px 0;
  border-top: 1px solid var(--line);
  background: white;

  h2 {
    margin: 6px 0 22px;
    font-family: var(--font-display);
    font-size: 2rem;
    font-weight: 500;
  }

  &__grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 14px;
  }

  article {
    padding: 20px;
    border: 1px solid var(--line);
    border-radius: 16px;
    background: var(--color-surface-canvas);
  }

  article > svg {
    color: var(--color-brand);
  }

  blockquote {
    margin: 12px 0 18px;
    line-height: 1.6;
  }

  footer {
    display: flex;
    justify-content: space-between;
    align-items: end;
    gap: 14px;
  }

  footer strong,
  footer small {
    display: block;
  }

  footer small {
    margin-top: 2px;
    color: var(--ink-soft);
    font-size: 0.76rem;
  }

  footer em {
    display: flex;
    align-items: center;
    gap: 4px;
    color: var(--color-brand);
    font-size: 0.74rem;
    font-style: normal;
    font-weight: 800;
  }
}

@media (width <= 700px) {
  .profile-recommendations__grid {
    grid-template-columns: 1fr;
  }
}
</style>
