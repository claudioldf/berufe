<script setup lang="ts">
import { computed } from "vue";
import type { PublicProfessionalListing } from "~/types";

const props = defineProps<{
  listing: PublicProfessionalListing;
  stateSlug: string;
  citySlug: string;
  serviceSlug: string;
}>();

const cityName = computed(() => props.listing.location.city);
const serviceName = computed(() => props.listing.service.name);
</script>

<template>
  <DesignSystemPageSection class="professionals">
    <DesignSystemContainer>
      <div v-if="listing.professionals.length" class="professionals__grid">
        <NuxtLink
          v-for="professional in listing.professionals"
          :key="professional.id"
          :to="buildPublicProfilePath(professional.slug)"
          class="professional-card"
        >
          <DesignSystemAvatar
            :name="professional.name"
            :src="professional.photoUrl ?? undefined"
            size="lg"
            shape="rounded"
            loading="lazy"
          />
          <div class="professional-card__body">
            <strong>{{ professional.name }}</strong>
            <span v-if="professional.headline">{{
              professional.headline
            }}</span>
            <span class="professional-card__coverage">
              <UIcon name="i-lucide-map-pin" aria-hidden="true" />
              {{
                professional.coverage.wholeCity
                  ? `Toda ${professional.coverage.city?.name ?? cityName}`
                  : professional.coverage.neighborhoods
                      .slice(0, 2)
                      .map((neighborhood) => neighborhood.name)
                      .join(" e ") || cityName
              }}
            </span>
          </div>
          <UIcon name="i-lucide-arrow-up-right" aria-hidden="true" />
        </NuxtLink>
      </div>

      <DesignSystemSurfaceCard v-else class="professionals__empty">
        <h2>
          Ainda não temos
          {{ serviceName.toLocaleLowerCase("pt-BR") }} publicado em
          {{ cityName }}.
        </h2>
        <p>Seja o primeiro a aparecer para quem procura esse serviço.</p>
        <UButton
          :to="`/para-profissionais/${serviceSlug}`"
          color="primary"
          trailing-icon="i-lucide-arrow-right"
        >
          Criar perfil grátis
        </UButton>
      </DesignSystemSurfaceCard>

      <div v-if="listing.relatedServices.length" class="professionals__related">
        <span>Serviços relacionados:</span>
        <NuxtLink
          v-for="related in listing.relatedServices"
          :key="related.id"
          :to="`/encontrar/${stateSlug}/${citySlug}/${related.slug}`"
        >
          {{ related.name }}
        </NuxtLink>
      </div>
    </DesignSystemContainer>
  </DesignSystemPageSection>
</template>

<style scoped lang="scss">
.professionals {
  &__grid {
    display: grid;
    gap: 12px;
  }

  &__empty {
    padding: 40px;
    text-align: center;
  }

  &__empty h2 {
    margin: 0 0 8px;
    font-family: var(--font-display);
    font-size: 1.3rem;
  }

  &__empty p {
    margin: 0 0 20px;
    color: var(--ink-soft);
  }

  &__related {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 8px;
    margin-top: 24px;
    font-size: 0.86rem;
  }

  &__related span {
    color: var(--ink-soft);
    font-weight: 700;
  }

  &__related a {
    padding: 6px 12px;
    border: 1px solid var(--line);
    border-radius: 9px;
    color: var(--ink);
    font-weight: 700;
    text-decoration: none;
  }
}

.professional-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px;
  border: 1px solid var(--line);
  border-radius: 16px;
  color: inherit;
  text-decoration: none;
  transition: border-color 0.15s ease;

  &:hover {
    border-color: var(--color-brand);
  }

  &__body {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 3px;
    min-width: 0;
  }

  &__body strong {
    font-family: var(--font-display);
    font-size: 1.05rem;
  }

  &__body > span {
    color: var(--ink-soft);
    font-size: 0.86rem;
  }

  &__coverage {
    display: flex;
    align-items: center;
    gap: 4px;
  }

  > svg:last-child {
    flex-shrink: 0;
    color: var(--ink-soft);
  }
}
</style>
