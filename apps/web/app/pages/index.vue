<script setup lang="ts">
import { computed, onMounted } from "vue";
import { useCatalogs } from "~/composables/useCatalogs";
import { useFeaturedProfessionals } from "~/composables/useFeaturedProfessionals";
import { useDetectedSearchLocation } from "~/composables/useDetectedSearchLocation";
import type { ExpressionSearchPayload, SearchLocation } from "~/types";
import { encodeSearchExpression } from "~/utils/searchExpression";
import { searchLocationPath } from "~/utils/searchLocation";

const router = useRouter();
const runtimeConfig = useRuntimeConfig();
const [catalogResult, featuredResult] = await Promise.all([
  useCatalogs(),
  useFeaturedProfessionals(),
]);
if (
  catalogResult.error.value ||
  !catalogResult.data.value ||
  featuredResult.error.value ||
  !featuredResult.data.value
) {
  throw createError({
    statusCode: 503,
    statusMessage: "Descoberta temporariamente indisponível.",
  });
}
const services = computed(() => catalogResult.data.value?.services ?? []);
const featured = computed(() => featuredResult.data.value ?? []);
const cities = computed(() => catalogResult.data.value?.cities ?? []);
const detectedLocation = useDetectedSearchLocation();
const {
  location,
  source: locationSource,
  resolve: resolveLocation,
  select: selectLocation,
} = detectedLocation;

onMounted(() => {
  void resolveLocation();
});

const title = "Profissionais de confiança em Joinville";
const description =
  "Encontre profissionais verificados para reformas e manutenção residencial em Joinville.";
const siteUrl = String(
  runtimeConfig.public.siteUrl || "http://localhost:3000",
).replace(/\/$/, "");
const canonicalUrl = `${siteUrl}/`;

useSeoMeta({
  title,
  description,
  ogTitle: title,
  ogDescription: description,
  ogUrl: canonicalUrl,
  ogType: "website",
  twitterCard: "summary_large_image",
});
useHead({ link: [{ rel: "canonical", href: canonicalUrl }] });

async function search(payload: ExpressionSearchPayload) {
  await router.push({
    path: searchLocationPath(location.value),
    query: { expressao: encodeSearchExpression(payload.expression) },
  });
}

function changeLocation(nextLocation: SearchLocation) {
  selectLocation(nextLocation);
}
</script>

<template>
  <div>
    <HomeHero
      :location="location"
      :cities="cities"
      :location-source="locationSource"
      @search="search"
      @location-change="changeLocation"
    />

    <HomeCategories :services="services" :location="location" />

    <HomeTrust />

    <HomeFeaturedProfessionals
      v-if="featured.length > 0"
      :professionals="featured"
      :location="location"
    />
    <HomeProfessionalCta />
  </div>
</template>

<style scoped lang="scss">
:deep() {
  .hero {
    position: relative;
    padding: 76px 0 100px;
    background: var(--color-surface-page-light);
    &__inner {
      position: relative;
      display: grid;
      grid-template-columns: 1.08fr 0.92fr;
      align-items: center;
      gap: 70px;
    }
    &__copy {
      position: relative;
      z-index: 3;
    }
    & .display-title em {
      color: var(--color-brand);
      font-weight: inherit;
    }
    &__lead {
      max-width: 590px;
      margin: 28px 0 32px;
      color: var(--ink-soft);
      font-size: 1.05rem;
      line-height: 1.7;
    }
    &__visual {
      position: relative;
      min-height: 550px;
    }
    &__photo-wrap {
      position: absolute;
      inset: 0 0 24px 44px;
      overflow: hidden;
      border-radius: 180px 180px 28px 28px;
      background: #bdded3;
      box-shadow: var(--shadow-lg);
    }
    &__photo-wrap img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
    &__profile-chip {
      position: absolute;
      left: -4px;
      bottom: 52px;
      display: grid;
      grid-template-columns: auto 1fr auto;
      align-items: center;
      gap: 10px;
      width: 260px;
      padding: 11px;
      border: 1px solid rgb(255 255 255 / 50%);
      border-radius: 16px;
      background: rgb(255 255 255 / 92%);
      box-shadow: var(--shadow-sm);
      backdrop-filter: blur(12px);
    }
    &__profile-chip strong,
    &__profile-chip small {
      display: block;
    }
    &__profile-chip strong {
      font-size: 0.86rem;
    }
    &__profile-chip small {
      margin-top: 3px;
      color: var(--ink-soft);
      font-size: 0.86rem;
    }
    &__profile-chip > svg {
      color: var(--color-brand);
      font-size: 1.2rem;
    }
    &__trust-chip {
      position: absolute;
      top: 45px;
      right: -24px;
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 15px 17px;
      border-radius: 16px;
      background: var(--coral);
      color: white;
      box-shadow: var(--shadow-sm);
    }
    &__trust-chip strong {
      font-family: var(--font-display);
      font-size: 1.55rem;
    }
    &__trust-chip span {
      font-size: 0.84rem;
      font-weight: 800;
      line-height: 1.25;
    }
    &__shapes {
      position: absolute;
      inset: 0;
      overflow: hidden;
      pointer-events: none;
    }
    &__shape {
      position: absolute;
      border-radius: 999px;
      background: var(--mint);
      opacity: 0.65;
    }
    &__shape--one {
      width: 300px;
      height: 300px;
      top: -180px;
      left: 45%;
    }
    &__shape--two {
      width: 170px;
      height: 170px;
      right: -80px;
      bottom: 20px;
    }
  }
  .section-heading {
    display: flex;
    justify-content: space-between;
    align-items: end;
    gap: 40px;
    margin-bottom: 40px;
    & .section-copy {
      max-width: 360px;
      margin: 0;
    }
    &--compact {
      align-items: center;
    }
  }
  .category-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 12px;
  }
  .category-card {
    display: grid;
    grid-template-columns: auto 1fr auto;
    align-items: center;
    gap: 12px;
    min-height: 132px;
    padding: 20px;
    border: 1px solid var(--line);
    border-radius: 18px;
    background: rgb(255 255 255 / 58%);
    color: var(--ink);
    text-decoration: none;
    transition: 0.2s ease;
    &:hover {
      transform: translateY(-3px);
      border-color: #97c6b7;
      background: white;
      box-shadow: var(--shadow-sm);
    }
    &__icon {
      display: grid;
      place-items: center;
      width: 43px;
      height: 43px;
      border-radius: 13px;
      background: var(--mint);
      color: var(--color-brand);
      font-size: 1.2rem;
    }
    & strong,
    & small {
      display: block;
    }
    & strong {
      font-size: 0.85rem;
    }
    & small {
      display: -webkit-box;
      overflow: hidden;
      margin-top: 5px;
      color: var(--ink-soft);
      font-size: 0.86rem;
      line-height: 1.35;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
    }
    & > svg {
      align-self: start;
      color: #789089;
    }
  }
  .trust {
    background: var(--color-brand-strong);
    color: white;
    &__grid {
      display: grid;
      grid-template-columns: 0.95fr 1.05fr;
      gap: 90px;
      align-items: center;
    }
    &__visual {
      position: relative;
      min-height: 550px;
    }
    &__photo {
      position: absolute;
      inset: 0 30px 30px 0;
      overflow: hidden;
      border-radius: 26px 180px 26px 26px;
      background: #31594f;
    }
    &__photo img {
      width: 100%;
      height: 100%;
      object-fit: cover;
      opacity: 0.84;
    }
    &__label {
      position: absolute;
      right: 0;
      bottom: 0;
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 18px;
      border-radius: 16px;
      background: var(--color-surface-page);
      color: var(--ink);
      box-shadow: var(--shadow-lg);
    }
    &__label > svg {
      font-size: 1.7rem;
      color: var(--coral);
    }
    &__label strong,
    &__label small {
      display: block;
    }
    &__label strong {
      font-size: 0.86rem;
    }
    &__label small {
      margin-top: 3px;
      color: var(--ink-soft);
      font-size: 0.86rem;
    }
    & .section-copy {
      max-width: 590px;
      margin: 24px 0 32px;
      color: rgb(255 255 255 / 65%);
    }
    &__steps {
      display: grid;
      gap: 0;
      margin: 0;
      padding: 0;
      list-style: none;
    }
    &__steps li {
      display: grid;
      grid-template-columns: 50px 1fr;
      gap: 16px;
      padding: 18px 0;
      border-top: 1px solid rgb(255 255 255 / 12%);
    }
    &__steps li > span {
      color: var(--color-coral-400);
      font-family: var(--font-display);
      font-weight: 700;
      font-size: 0.92rem;
    }
    &__steps strong {
      font-size: 0.92rem;
    }
    &__steps p {
      margin: 5px 0 0;
      color: rgb(255 255 255 / 58%);
      font-size: 0.84rem;
      line-height: 1.5;
    }
  }
  .professional-cta {
    padding: 80px 0;
    background: var(--mint);
    &__inner {
      display: grid;
      grid-template-columns: 1fr 0.65fr;
      align-items: end;
      gap: 90px;
    }
    &__inner > div:last-child p {
      margin: 0 0 24px;
      color: var(--ink-soft);
      line-height: 1.7;
    }
  }

  @media (width <= 980px) {
    .hero {
      &__inner {
        grid-template-columns: 1fr;
      }
      &__copy {
        max-width: 720px;
      }
      &__visual {
        min-height: 450px;
        max-width: 600px;
        width: 100%;
        margin: 0 auto;
      }
    }
    .category-grid {
      grid-template-columns: repeat(2, 1fr);
    }
    .trust {
      &__grid {
        gap: 45px;
      }
    }
  }
  @media (width <= 760px) {
    .hero {
      padding: 54px 0 70px;
      &__inner {
        gap: 44px;
      }
      &__lead {
        margin-block: 22px;
      }
      &__visual {
        min-height: 390px;
      }
      &__photo-wrap {
        left: 20px;
      }
      &__trust-chip {
        right: 0;
      }
      &__profile-chip {
        left: 0;
      }
    }
    .section-heading {
      display: grid;
      gap: 16px;
    }
    .category-grid {
      grid-template-columns: 1fr;
    }
    .category-card {
      min-height: 100px;
    }
    .trust {
      &__grid {
        grid-template-columns: 1fr;
      }
      &__visual {
        min-height: 400px;
      }
    }
    .professional-cta {
      &__inner {
        grid-template-columns: 1fr;
        gap: 28px;
      }
    }
  }
  @media (width <= 470px) {
    .hero {
      &__visual {
        min-height: 340px;
      }
      &__profile-chip {
        width: 230px;
      }
      &__trust-chip {
        top: 25px;
      }
    }
  }
}
</style>
