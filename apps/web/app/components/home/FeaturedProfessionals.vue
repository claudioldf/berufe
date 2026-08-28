<script setup lang="ts">
import type { PublicProfessionalCard, SearchLocation } from "~/types";
import { formatCountLabel } from "~/utils/text";
import {
  fallbackSearchLocation,
  searchLocationPath,
} from "~/utils/searchLocation";

const props = defineProps<{
  professionals: PublicProfessionalCard[];
  location?: SearchLocation;
}>();

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
          :to="searchLocationPath(props.location ?? fallbackSearchLocation)"
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
            <span
              v-if="professional.primaryService"
              class="featured-card__service"
            >
              {{ professional.primaryService.name }}
            </span>
          </div>
          <div class="featured-card__body">
            <div>
              <strong>{{ professional.name }}</strong>
              <small>
                <UIcon name="i-lucide-map-pin" />
                {{
                  professional.coverage.wholeCity
                    ? `Toda ${professional.coverage.city?.name ?? "a cidade"}`
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
.featured {
  background: var(--color-surface-warm);

  &__grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
  }
}

.featured-card {
  overflow: hidden;
  border: 1px solid var(--line);
  border-radius: 22px;
  background: white;
  color: var(--ink);
  text-decoration: none;
  transition:
    transform 0.2s ease,
    box-shadow 0.2s ease;

  &:hover {
    transform: translateY(-4px);
    box-shadow: var(--shadow-sm);
  }

  &__image {
    position: relative;
    overflow: hidden;
    aspect-ratio: 4 / 5;
    background: var(--mint);
  }

  &__avatar {
    display: block;
    width: 100%;
    height: 100%;

    :deep(.avatar__image),
    :deep(.avatar__fallback) {
      width: 100%;
      height: 100%;
      border-radius: 0;
    }

    :deep(.avatar__image) {
      display: block;
      object-fit: cover;
      object-position: center top;
      transition: transform 0.4s ease;
    }

    :deep(.avatar__fallback) {
      font-size: 3rem;
    }
  }

  &:hover &__avatar :deep(.avatar__image) {
    transform: scale(1.03);
  }

  &__service {
    position: absolute;
    left: 14px;
    bottom: 14px;
    padding: 7px 10px;
    border-radius: 9px;
    background: white;
    font-size: 0.86rem;
    font-weight: 800;
  }

  &__body {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 17px 18px 12px;
  }

  &__body strong,
  &__body small {
    display: block;
  }

  &__body strong {
    font-family: var(--font-display);
    font-size: 1.2rem;
  }

  &__body small {
    display: flex;
    align-items: center;
    gap: 4px;
    margin-top: 5px;
    color: var(--ink-soft);
    font-size: 0.86rem;
  }

  &__proof {
    display: flex;
    justify-content: space-between;
    gap: 8px;
    padding: 12px 18px 16px;
    border-top: 1px solid var(--line);
    color: var(--ink-soft);
    font-size: 0.86rem;
    font-weight: 700;
  }

  &__proof span {
    display: flex;
    align-items: center;
    gap: 4px;
  }

  &__proof span:first-child {
    color: var(--color-brand);
  }
}

@media (width <= 760px) {
  .featured {
    &__grid {
      grid-template-columns: 1fr;
      justify-items: center;
    }
  }

  .featured-card {
    width: min(100%, 450px);
  }
}
</style>
