<script setup lang="ts">
import type {
  ExpressionSearchPayload,
  SearchLocation,
  SearchLocationSource,
} from "~/types";

withDefaults(
  defineProps<{
    location: SearchLocation;
    cities: SearchLocation[];
    locationSource: SearchLocationSource;
    loading?: boolean;
  }>(),
  { loading: false },
);

defineEmits<{
  search: [payload: ExpressionSearchPayload];
  locationChange: [location: SearchLocation];
}>();

// The illustration fills a ~560px column on desktop and the full width on a
// single-column layout (<= 980px); 600/900/1224 cover 1x-2x screens.
const heroArtWidths = [600, 900, 1224];
const heroArtSizes = "(max-width: 980px) 100vw, 560px";

function heroArtSrcset(format: "avif" | "webp") {
  return heroArtWidths
    .map((width) =>
      // The 1224px WebP is the original, unsuffixed file.
      width === 1224 && format === "webp"
        ? `/images/hero-home-care-illustration.webp ${width}w`
        : `/images/hero-home-care-illustration-${width}.${format} ${width}w`,
    )
    .join(", ");
}
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
          :loading="loading"
          @submit="$emit('search', $event)"
          @location-change="$emit('locationChange', $event)"
        />
      </div>

      <div class="hero__visual">
        <div class="hero__art-wrap">
          <!-- Above the fold and the LCP element: eager with high priority,
               but sized per viewport (AVIF first, WebP fallback). -->
          <picture class="hero__art-picture">
            <source
              type="image/avif"
              :srcset="heroArtSrcset('avif')"
              :sizes="heroArtSizes"
            />
            <source
              type="image/webp"
              :srcset="heroArtSrcset('webp')"
              :sizes="heroArtSizes"
            />
            <img
              class="hero__art"
              src="/images/hero-home-care-illustration.webp"
              alt="Ilustração de profissionais cuidando da pintura e da iluminação de uma casa"
              width="1224"
              height="1285"
              fetchpriority="high"
              decoding="async"
            />
          </picture>
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
