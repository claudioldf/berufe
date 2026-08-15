<script setup lang="ts">
import type { Service } from "~/types";

defineProps<{ services: Service[] }>();
</script>

<template>
  <DesignSystemPageSection class="categories">
    <DesignSystemContainer>
      <div class="section-heading">
        <div>
          <DesignSystemEyebrow
            >O que você precisa resolver?</DesignSystemEyebrow
          >
          <DesignSystemHeading>
            Serviços para cada<br />canto da casa.
          </DesignSystemHeading>
        </div>
        <DesignSystemSectionCopy>
          Escolha um serviço e veja profissionais que atendem sua região.
        </DesignSystemSectionCopy>
      </div>

      <div class="category-grid">
        <NuxtLink
          v-for="service in services"
          :key="service.id"
          class="category-card"
          :to="`/encontrar?servico=${service.slug}&bairro=all`"
        >
          <span class="category-card__icon"
            ><UIcon :name="service.icon"
          /></span>
          <span>
            <strong>{{ service.name }}</strong>
            <small>{{ service.description }}</small>
          </span>
          <UIcon name="i-lucide-arrow-up-right" />
        </NuxtLink>
      </div>
    </DesignSystemContainer>
  </DesignSystemPageSection>
</template>
