<script setup lang="ts">
import type {
  ExpressionSearchPayload,
  SearchLocation,
  SearchLocationSource,
} from "~/types";

defineProps<{
  location: SearchLocation;
  cities: SearchLocation[];
  locationSource: SearchLocationSource;
}>();

defineEmits<{
  search: [payload: ExpressionSearchPayload];
  locationChange: [location: SearchLocation];
}>();
</script>

<template>
  <section class="hero">
    <div class="hero__shapes" aria-hidden="true">
      <div class="hero__shape hero__shape--one" />
      <div class="hero__shape hero__shape--two" />
    </div>
    <DesignSystemContainer class="hero__inner">
      <div class="hero__copy">
        <DesignSystemEyebrow>Profissionais perto de você</DesignSystemEyebrow>
        <DesignSystemHeading as="h1" variant="display">
          Sua casa em<br /><em>boas mãos.</em>
        </DesignSystemHeading>
        <p class="hero__lead">
          Encontre profissionais para cuidar da sua casa e do seu dia a dia.
          Conheça o trabalho e as referências de cada profissional antes de
          escolher.
        </p>
        <PublicExpressionSearch
          :location="location"
          :cities="cities"
          :location-source="locationSource"
          @submit="$emit('search', $event)"
          @location-change="$emit('locationChange', $event)"
        />
      </div>

      <div class="hero__visual">
        <div class="hero__art-wrap">
          <img
            class="hero__art"
            src="/images/hero-home-care-illustration.webp"
            alt="Ilustração de profissionais cuidando da pintura e da iluminação de uma casa"
            width="1224"
            height="1285"
            fetchpriority="high"
            decoding="async"
          />
        </div>
        <div class="hero__profile-chip">
          <span class="hero__chip-icon" aria-hidden="true">
            <UIcon name="i-lucide-map-pin" />
          </span>
          <span>
            <strong>Profissionais em {{ location.city }}</strong>
            <small>Serviços para a casa e o dia a dia</small>
          </span>
          <UIcon name="i-lucide-arrow-up-right" aria-hidden="true" />
        </div>
        <div class="hero__trust-chip">
          <span class="hero__chip-icon" aria-hidden="true">
            <UIcon name="i-lucide-message-circle" />
          </span>
          <span>
            <strong>Contato direto</strong>{{ " " }}<small>pelo WhatsApp</small>
          </span>
        </div>
      </div>
    </DesignSystemContainer>
  </section>
</template>
