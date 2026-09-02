<script setup lang="ts">
import { computed, onMounted, shallowRef } from "vue";
import { useCatalogs } from "~/composables/useCatalogs";
import { useFeaturedProfessionals } from "~/composables/useFeaturedProfessionals";
import { useDetectedSearchLocation } from "~/composables/useDetectedSearchLocation";
import type { ExpressionSearchPayload, SearchLocation } from "~/types";
import {
  encodeSearchExpression,
  searchExpressionQuery,
} from "~/utils/searchExpression";
import { searchLocationPath } from "~/utils/searchLocation";

const router = useRouter();
const isSearchPending = shallowRef(false);
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
const canonicalUrl = withSiteUrl("/");

useSeoMeta({
  title,
  description,
  ogTitle: title,
  ogDescription: description,
  ogUrl: () => canonicalUrl.value,
  ogType: "website",
  twitterCard: "summary_large_image",
  robots: "index, follow",
});
useHead(() => ({ link: [{ rel: "canonical", href: canonicalUrl.value }] }));
defineOgImageSafely("BerufeDefault", { title, description });

async function search(payload: ExpressionSearchPayload) {
  if (isSearchPending.value) return;

  isSearchPending.value = true;
  try {
    await router.push({
      path: searchLocationPath(location.value),
      query: searchExpressionQuery(encodeSearchExpression(payload.expression)),
    });
  } finally {
    isSearchPending.value = false;
  }
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
      :loading="isSearchPending"
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
    position: relative;
    overflow: hidden;
    background:
      radial-gradient(
        circle at 6% 20%,
        rgb(84 151 130 / 28%) 0,
        transparent 29%
      ),
      radial-gradient(
        circle at 94% 82%,
        rgb(233 126 105 / 12%) 0,
        transparent 24%
      ),
      var(--color-brand-strong);
    color: white;
    &__grid {
      position: relative;
      z-index: 1;
      display: grid;
      grid-template-columns: minmax(360px, 0.9fr) minmax(0, 1.1fr);
      gap: clamp(64px, 8vw, 112px);
      align-items: center;
    }
    &__visual {
      position: relative;
      min-height: 590px;
      display: grid;
      place-items: center;
      isolation: isolate;
    }
    &__visual::before,
    &__visual::after {
      position: absolute;
      z-index: -2;
      border-radius: 50%;
      content: "";
    }
    &__visual::before {
      width: 470px;
      height: 470px;
      border: 1px solid rgb(255 255 255 / 10%);
      background: rgb(255 255 255 / 4%);
    }
    &__visual::after {
      top: 30px;
      left: 14px;
      width: 92px;
      height: 92px;
      border: 22px solid rgb(233 126 105 / 16%);
    }
    &__profile-card {
      position: relative;
      width: min(100%, 430px);
      padding: 24px;
      border: 1px solid rgb(255 255 255 / 75%);
      border-radius: 28px;
      background: #f8f5ee;
      color: var(--ink);
      box-shadow:
        18px 18px 0 #31594f,
        0 34px 80px rgb(0 25 20 / 38%);
      transform: rotate(-1.5deg);
    }
    &__profile-header {
      display: grid;
      grid-template-columns: auto minmax(0, 1fr);
      align-items: center;
      gap: 12px;
      padding-bottom: 20px;
      border-bottom: 1px solid var(--line);
    }
    &__profile-icon {
      display: grid;
      width: 48px;
      height: 48px;
      place-items: center;
      border-radius: 15px;
      background: var(--mint);
      color: var(--color-brand);
      font-size: 1.35rem;
    }
    &__profile-header small,
    &__profile-header h3 {
      display: block;
      margin: 0;
    }
    &__profile-header small {
      color: var(--ink-soft);
      font-size: 0.7rem;
      font-weight: 800;
      letter-spacing: 0.08em;
      text-transform: uppercase;
    }
    &__profile-header h3 {
      margin-top: 4px;
      font-family: var(--font-display);
      font-size: 1.2rem;
      line-height: 1.1;
      text-wrap: balance;
    }
    &__profile-highlights {
      display: grid;
      grid-template-columns: 1.12fr 0.88fr;
      gap: 10px;
      margin: 18px 0;
    }
    &__profile-highlights > div {
      display: flex;
      min-height: 122px;
      flex-direction: column;
      justify-content: space-between;
      padding: 16px;
      border-radius: 18px;
      background: var(--mint);
    }
    &__profile-highlights > div:last-child {
      background: #f1dfd2;
    }
    &__profile-highlights > div > span {
      display: grid;
      width: 34px;
      height: 34px;
      place-items: center;
      border-radius: 11px;
      background: rgb(255 255 255 / 62%);
      color: var(--color-brand);
      font-size: 1.05rem;
    }
    &__profile-highlights strong {
      max-width: 130px;
      font-size: 0.82rem;
      line-height: 1.3;
    }
    &__profile-details {
      display: grid;
      gap: 10px;
      margin: 0;
      padding: 0;
      list-style: none;
    }
    &__profile-details li {
      display: grid;
      grid-template-columns: auto minmax(0, 1fr);
      align-items: center;
      gap: 12px;
      padding: 13px;
      border: 1px solid var(--line);
      border-radius: 16px;
      background: rgb(255 255 255 / 72%);
    }
    &__profile-details li > span {
      display: grid;
      width: 38px;
      height: 38px;
      place-items: center;
      border-radius: 12px;
      background: white;
      color: var(--color-brand);
      box-shadow: 0 5px 14px rgb(20 87 67 / 8%);
      font-size: 1.05rem;
    }
    &__profile-details strong,
    &__profile-details small {
      display: block;
    }
    &__profile-details strong {
      font-size: 0.8rem;
    }
    &__profile-details small {
      margin-top: 3px;
      color: var(--ink-soft);
      font-size: 0.74rem;
      line-height: 1.4;
    }
    &__label {
      position: absolute;
      z-index: 2;
      right: -8px;
      bottom: 28px;
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 14px 16px 14px 14px;
      border: 1px solid rgb(20 87 67 / 10%);
      border-radius: 18px;
      background: white;
      color: var(--ink);
      box-shadow: var(--shadow-lg);
    }
    &__label > span:first-child {
      display: grid;
      width: 40px;
      height: 40px;
      place-items: center;
      border-radius: 13px;
      background: var(--mint);
      color: var(--color-brand);
      font-size: 1.2rem;
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
      max-width: 240px;
      color: var(--ink-soft);
      font-size: 0.76rem;
      line-height: 1.35;
    }
    & .section-title {
      max-width: 620px;
      text-wrap: balance;
    }
    & .section-copy {
      max-width: 590px;
      margin: 24px 0 32px;
      color: rgb(255 255 255 / 72%);
    }
    &__steps {
      display: grid;
      gap: 10px;
      margin: 0;
      padding: 0;
      list-style: none;
    }
    &__steps li {
      position: relative;
      display: grid;
      grid-template-columns: 46px minmax(0, 1fr);
      align-items: center;
      gap: 14px;
      overflow: hidden;
      padding: 16px 18px;
      border: 1px solid rgb(255 255 255 / 10%);
      border-radius: 18px;
      background: linear-gradient(
        105deg,
        rgb(255 255 255 / 7%),
        rgb(255 255 255 / 3%)
      );
      box-shadow: inset 0 1px 0 rgb(255 255 255 / 4%);
    }
    &__steps li::before {
      position: absolute;
      top: 18px;
      bottom: 18px;
      left: 0;
      width: 2px;
      border-radius: 999px;
      background: var(--coral);
      content: "";
      opacity: 0.72;
    }
    &__step-icon {
      display: grid;
      width: 44px;
      height: 44px;
      place-items: center;
      border: 1px solid rgb(167 215 200 / 14%);
      border-radius: 14px;
      background: rgb(216 240 231 / 9%);
      color: var(--color-brand-muted);
      font-size: 1.1rem;
    }
    &__steps li > div > strong {
      font-size: 0.92rem;
    }
    &__steps p {
      margin: 5px 0 0;
      color: rgb(255 255 255 / 62%);
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
        grid-template-columns: minmax(320px, 0.88fr) minmax(0, 1.12fr);
        gap: 48px;
      }
      &__profile-card {
        width: min(100%, 390px);
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
        gap: 54px;
      }
      &__visual {
        order: 2;
        min-height: 560px;
      }
      &__copy {
        order: 1;
      }
      &__profile-card {
        width: min(calc(100% - 18px), 430px);
      }
      &__label {
        right: max(0px, calc((100% - 430px) / 2));
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
    .trust {
      &__visual {
        display: flex;
        min-height: 0;
        flex-direction: column;
        justify-content: center;
        padding: 56px 0 24px;
      }
      &__visual::before {
        width: 380px;
        height: 380px;
      }
      &__profile-card {
        padding: 18px;
        transform: none;
      }
      &__profile-header {
        grid-template-columns: auto minmax(0, 1fr);
      }
      &__profile-highlights > div {
        min-height: 108px;
      }
      &__label {
        position: relative;
        right: auto;
        bottom: auto;
        width: calc(100% - 36px);
        align-self: flex-end;
        margin-top: -16px;
      }
      &__steps li {
        grid-template-columns: 42px minmax(0, 1fr);
        gap: 12px;
        padding: 15px 14px;
      }
      &__step-icon {
        width: 40px;
        height: 40px;
      }
    }
  }
}
</style>
