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

const title = "Encontre profissionais perto de você";
const description =
  "Encontre profissionais para sua casa e seu dia a dia. Veja trabalhos e referências e fale diretamente pelo WhatsApp.";
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
      min-height: 590px;
      isolation: isolate;
    }
    &__visual::before {
      position: absolute;
      z-index: -2;
      inset: 34px 8px 28px 48px;
      border: 1px solid rgb(255 255 255 / 72%);
      border-radius: 36% 64% 45% 55% / 52% 38% 62% 48%;
      background:
        radial-gradient(
          circle at 82% 17%,
          rgb(233 126 105 / 22%) 0 9%,
          transparent 9.5%
        ),
        linear-gradient(145deg, #d9eee7 4%, #eef5e9 50%, #f5e4d7 100%);
      box-shadow: 0 30px 70px rgb(21 64 53 / 14%);
      content: "";
      transform: rotate(1.5deg);
    }
    &__visual::after {
      position: absolute;
      z-index: -1;
      right: 18px;
      bottom: 56px;
      width: 94px;
      height: 94px;
      border: 2px solid rgb(20 87 67 / 15%);
      border-radius: 50%;
      content: "";
    }
    &__art-wrap {
      position: absolute;
      z-index: 1;
      inset: -12px -26px -4px 0;
      display: grid;
      place-items: center;
    }
    &__art {
      width: 100%;
      height: 100%;
      object-fit: contain;
      filter: drop-shadow(0 22px 20px rgb(21 64 53 / 16%));
    }
    &__profile-chip {
      position: absolute;
      z-index: 3;
      left: -4px;
      bottom: 38px;
      display: grid;
      grid-template-columns: auto 1fr auto;
      align-items: center;
      gap: 10px;
      width: 276px;
      padding: 12px;
      border: 1px solid rgb(255 255 255 / 74%);
      border-radius: 18px;
      background: rgb(255 255 255 / 90%);
      box-shadow: var(--shadow-sm);
      backdrop-filter: blur(16px);
    }
    &__chip-icon {
      display: grid;
      width: 38px;
      height: 38px;
      place-items: center;
      border-radius: 12px;
      background: var(--mint);
      color: var(--color-brand);
      font-size: 1.1rem;
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
      font-size: 1.1rem;
    }
    &__trust-chip {
      position: absolute;
      z-index: 3;
      top: 42px;
      right: -14px;
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 12px 15px 12px 12px;
      border-radius: 18px;
      background: var(--coral);
      color: white;
      box-shadow: var(--shadow-sm);
    }
    &__trust-chip .hero__chip-icon {
      background: rgb(255 255 255 / 18%);
      color: white;
    }
    &__trust-chip strong,
    &__trust-chip small {
      display: block;
    }
    &__trust-chip strong {
      font-size: 0.9rem;
      line-height: 1.2;
    }
    &__trust-chip small {
      margin-top: 3px;
      color: rgb(255 255 255 / 86%);
      font-size: 0.78rem;
      font-weight: 700;
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
        min-height: 560px;
        max-width: 620px;
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
        min-height: 500px;
      }
      &__art-wrap {
        inset: -4px -10px 0 4px;
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
        min-height: 420px;
      }
      &__visual::before {
        inset: 30px 4px 32px 18px;
      }
      &__visual::after {
        right: 0;
        bottom: 52px;
        width: 68px;
        height: 68px;
      }
      &__art-wrap {
        inset: 12px -5px 30px 0;
      }
      &__profile-chip {
        bottom: 8px;
        width: 236px;
        padding: 10px;
      }
      &__trust-chip {
        top: 18px;
        padding: 10px 12px 10px 10px;
      }
      &__chip-icon {
        width: 34px;
        height: 34px;
      }
    }
  }
}
</style>
