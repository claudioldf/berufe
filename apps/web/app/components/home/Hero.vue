<script setup lang="ts">
import { onMounted, shallowRef } from "vue";
import type {
  Neighborhood,
  Professional,
  Service,
  ServiceSearchPayload,
} from "~/types";

defineProps<{
  featuredProfessional?: Professional;
  services: Service[];
  neighborhoods: Neighborhood[];
}>();
defineEmits<{ search: [payload: ServiceSearchPayload] }>();

const heroImages = [
  {
    src: "/images/photo-1621905252507-b35492cc74b4.jpg",
    alt: "Profissional trabalhando em uma instalação residencial",
  },
  {
    src: "/images/hero-professional-painter.jpg",
    alt: "Pintora profissional trabalhando em uma parede residencial",
  },
  {
    src: "/images/hero-professional-plumber.jpg",
    alt: "Encanador profissional fazendo manutenção sob uma pia",
  },
] as const;

const heroImageStorageKey = "berufe.hero-image-index";
const activeHeroImage = shallowRef<(typeof heroImages)[number]>(heroImages[0]);

onMounted(() => {
  try {
    const storedImageIndex = Number.parseInt(
      window.localStorage.getItem(heroImageStorageKey) ?? "",
      10,
    );
    const nextImageIndex = Number.isInteger(storedImageIndex)
      ? (storedImageIndex + 1) % heroImages.length
      : 0;

    activeHeroImage.value = heroImages[nextImageIndex] ?? heroImages[0];
    window.localStorage.setItem(heroImageStorageKey, String(nextImageIndex));
  } catch {
    const fallbackImageIndex = Math.floor(Math.random() * heroImages.length);
    activeHeroImage.value = heroImages[fallbackImageIndex] ?? heroImages[0];
  }
});
</script>

<template>
  <section class="hero">
    <div class="hero__shapes" aria-hidden="true">
      <div class="hero__shape hero__shape--one" />
      <div class="hero__shape hero__shape--two" />
    </div>
    <DesignSystemContainer class="hero__inner">
      <div class="hero__copy">
        <DesignSystemEyebrow>Rede local de confiança</DesignSystemEyebrow>
        <DesignSystemHeading as="h1" variant="display">
          Sua casa em<br /><em>boas mãos.</em>
        </DesignSystemHeading>
        <p class="hero__lead">
          Encontre profissionais de reforma e manutenção com evidências claras,
          trabalhos reais e relações profissionais confirmadas.
        </p>
        <PublicServiceSearch
          :services="services"
          :neighborhoods="neighborhoods"
          @submit="$emit('search', $event)"
        />
      </div>

      <div class="hero__visual" aria-label="Exemplo de profissional da Berufe">
        <div class="hero__photo-wrap">
          <img
            :src="activeHeroImage.src"
            :alt="activeHeroImage.alt"
            width="1200"
            height="801"
            fetchpriority="high"
          />
        </div>
        <div class="hero__profile-chip">
          <DesignSystemAvatar
            name="Marcos Alves"
            :src="featuredProfessional?.avatar"
            alt=""
            size="sm"
            shape="rounded"
          />
          <span>
            <strong>Marcos Alves</strong>
            <small>Eletricista · Joinville</small>
          </span>
          <UIcon name="i-lucide-badge-check" />
        </div>
        <div class="hero__trust-chip">
          <strong>+50.000</strong>
          <span>profissionais<br />ativos</span>
        </div>
      </div>
    </DesignSystemContainer>
  </section>
</template>
