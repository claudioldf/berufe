<script setup lang="ts">
import type { PublicProfessionalCard } from "~/types";
import { formatCountLabel } from "~/utils/text";

defineProps<{ professionals: PublicProfessionalCard[] }>();

function connectionCountLabel(count: number) {
  return formatCountLabel(
    count,
    "conexão profissional",
    "conexões profissionais",
  );
}
</script>

<template>
  <DesignSystemPageSection class="featured">
    <DesignSystemContainer>
      <div class="section-heading section-heading--compact">
        <div>
          <DesignSystemEyebrow>Profissionais em destaque</DesignSystemEyebrow>
          <DesignSystemHeading
            >Gente boa, trabalho bem feito.</DesignSystemHeading
          >
        </div>
        <UButton
          to="/encontrar"
          variant="link"
          trailing-icon="i-lucide-arrow-right"
        >
          Explorar a rede
        </UButton>
      </div>
      <div class="featured__grid">
        <NuxtLink
          v-for="professional in professionals"
          :key="professional.id"
          class="featured-card"
          :to="`/profissionais/${professional.slug}`"
        >
          <div class="featured-card__image">
            <DesignSystemAvatar
              class="featured-card__avatar"
              :name="professional.name"
              :src="professional.photoUrl ?? undefined"
              size="profile"
              shape="rounded"
              loading="lazy"
            />
            <span v-if="professional.primaryService">
              {{ professional.primaryService.name }}
            </span>
          </div>
          <div class="featured-card__body">
            <div>
              <strong>{{ professional.name }}</strong>
              <small>
                <UIcon name="i-lucide-map-pin" />
                {{
                  professional.coverage.allJoinville
                    ? "Toda Joinville"
                    : professional.coverage.neighborhoods
                        .slice(0, 2)
                        .map((neighborhood) => neighborhood.name)
                        .join(" e ")
                }}
              </small>
            </div>
            <UIcon name="i-lucide-arrow-up-right" />
          </div>
          <div class="featured-card__proof">
            <span
              v-if="
                professional.verificationLabels.some(
                  (label) => label.type === 'identity',
                )
              "
            >
              <UIcon name="i-lucide-badge-check" /> Identidade verificada
            </span>
            <span>
              {{ connectionCountLabel(professional.relationshipCount) }}
            </span>
          </div>
        </NuxtLink>
      </div>
    </DesignSystemContainer>
  </DesignSystemPageSection>
</template>

<style scoped lang="scss">
.featured-card__avatar {
  width: 100%;
  height: 100%;

  :deep(.avatar__image),
  :deep(.avatar__fallback) {
    border-radius: 0;
  }

  :deep(.avatar__fallback) {
    font-size: 3rem;
  }
}
</style>
