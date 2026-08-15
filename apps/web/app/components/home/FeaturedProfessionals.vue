<script setup lang="ts">
import type { Professional } from "~/types";

defineProps<{ professionals: Professional[] }>();
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
            <img
              :src="professional.avatar"
              :alt="`Foto de ${professional.name}`"
              width="1024"
              height="1536"
              loading="lazy"
            />
            <span>{{ professional.primaryService }}</span>
          </div>
          <div class="featured-card__body">
            <div>
              <strong>{{ professional.name }}</strong>
              <small>
                <UIcon name="i-lucide-map-pin" />
                {{
                  professional.allJoinville
                    ? "Toda Joinville"
                    : professional.neighborhoods.slice(0, 2).join(" e ")
                }}
              </small>
            </div>
            <UIcon name="i-lucide-arrow-up-right" />
          </div>
          <div class="featured-card__proof">
            <span>
              <UIcon name="i-lucide-badge-check" /> Identidade verificada
            </span>
            <span>
              {{ professional.relationships.length }} relações profissionais
            </span>
          </div>
        </NuxtLink>
      </div>
    </DesignSystemContainer>
  </DesignSystemPageSection>
</template>
