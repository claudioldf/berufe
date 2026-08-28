<script setup lang="ts">
import { computed, shallowRef } from "vue";
import type { SearchLocation, Service } from "~/types";
import { encodeSearchExpression } from "~/utils/searchExpression";
import {
  fallbackSearchLocation,
  searchLocationPath,
} from "~/utils/searchLocation";

const INITIAL_VISIBLE_SERVICES = 8;
const props = defineProps<{
  services: Service[];
  location?: SearchLocation;
}>();
const expanded = shallowRef(false);
const hasAdditionalServices = computed(
  () => props.services.length > INITIAL_VISIBLE_SERVICES,
);
const visibleServices = computed(() =>
  expanded.value
    ? props.services
    : props.services.slice(0, INITIAL_VISIBLE_SERVICES),
);

function searchUrl(service: Service) {
  return {
    path: searchLocationPath(props.location ?? fallbackSearchLocation),
    query: { expressao: encodeSearchExpression(service.name) },
  };
}
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
            Serviços para sua casa<br />e seu dia a dia.
          </DesignSystemHeading>
        </div>
      </div>

      <div id="home-service-categories" class="category-grid">
        <NuxtLink
          v-for="service in visibleServices"
          :key="service.id"
          class="category-card"
          :to="searchUrl(service)"
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
      <button
        v-if="hasAdditionalServices"
        type="button"
        class="categories__toggle"
        aria-controls="home-service-categories"
        :aria-expanded="expanded"
        @click="expanded = !expanded"
      >
        <span>{{ expanded ? "Mostrar menos" : "Ver todos os serviços" }}</span>
        <UIcon
          name="i-lucide-chevron-down"
          class="categories__toggle-icon"
          :class="{ 'categories__toggle-icon--expanded': expanded }"
        />
      </button>
    </DesignSystemContainer>
  </DesignSystemPageSection>
</template>

<style scoped lang="scss">
.categories {
  &__toggle {
    display: flex;
    align-items: center;
    gap: 6px;
    margin: 26px auto 0;
    padding: 8px 10px;
    border: 0;
    background: transparent;
    color: var(--color-brand);
    font-size: 0.88rem;
    font-weight: 850;
    cursor: pointer;
  }

  &__toggle:hover {
    color: var(--color-brand-strong);
  }

  &__toggle-icon {
    transition: transform var(--motion-fast) ease;
  }

  &__toggle-icon--expanded {
    transform: rotate(180deg);
  }
}
</style>
