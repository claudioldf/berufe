<script setup lang="ts">
import { computed, onMounted, shallowRef } from "vue";
import { useShare } from "~/composables/useShare";
import { useToast } from "~/composables/useToast";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";
import {
  fetchPublicProfessionalProfile,
  recordPublicProfessionalProfileView,
} from "~/services/api/public-discovery";
import { hydrationOnlyCachedData } from "~/utils/asyncDataCache";
import { buildPublicProfileWhatsAppUrl } from "~/utils/publicProfiles";

interface SocialLink {
  platform: "instagram" | "youtube";
  label: string;
  icon: string;
  url: string;
}

const route = useRoute();
const client = useApiClient();
const runtimeConfig = useRuntimeConfig();
const { share } = useShare();
const { showToast } = useToast();
definePageMeta({ alias: "/be/:slug" });
const requestedSlug = computed(() =>
  String(
    Array.isArray(route.params.slug) ? route.params.slug[0] : route.params.slug,
  ),
);
const incomingInteractionToken = computed(() => {
  const value = route.query.contexto;
  return Array.isArray(value) ? value[0] : value;
});
const incomingRequestMessage = computed(() => {
  const value = route.query.pedido;
  return Array.isArray(value) ? value[0] : value;
});
const { data: profileResult, error: profileError } = await useAsyncData(
  `public-professional-profile-${requestedSlug.value}`,
  () =>
    fetchPublicProfessionalProfile(
      client,
      requestedSlug.value,
      incomingInteractionToken.value || undefined,
    ),
  {
    // Keep the server payload during hydration, then revalidate every client
    // navigation so an administrator suspension cannot reuse an older profile.
    getCachedData: hydrationOnlyCachedData,
  },
);
if (profileError.value || !profileResult.value) {
  const failure = profileError.value;
  const notFound =
    failure instanceof ApiRequestError && failure.code === "not_found";
  throw createError({
    statusCode: notFound ? 404 : 503,
    statusMessage: notFound
      ? "Profissional não encontrado"
      : "Perfil temporariamente indisponível.",
  });
}

const professional = computed(() => profileResult.value!.professional);
const activePortfolio = shallowRef(0);
const portfolioOpen = shallowRef(false);
const selectedPortfolio = computed(
  () => professional.value?.portfolio[activePortfolio.value],
);
const supportEmailUrl = computed(() => {
  const subject = encodeURIComponent(
    `Informação sobre o perfil ${professional.value.name}`,
  );
  return `mailto:suporte@berufe.com.br?subject=${subject}`;
});
const contactUrl = computed(() => {
  const profile = professional.value;
  return buildPublicProfileWhatsAppUrl({
    apiBaseUrl: runtimeConfig.public.apiBaseUrl,
    professionalId: profile.id,
    interactionToken: profileResult.value!.interactionToken,
    requestMessage: incomingRequestMessage.value || undefined,
  });
});
const resultsUrl = computed(() => {
  const expression = route.query.expressao;
  const encodedExpression = Array.isArray(expression)
    ? expression[0]
    : expression;
  if (!encodedExpression) return "/encontrar";

  return `/encontrar?${new URLSearchParams({ expressao: encodedExpression }).toString()}`;
});
const socialLinks = computed<SocialLink[]>(() => {
  const profile = professional.value;
  const links: SocialLink[] = [];
  if (profile.instagram) {
    links.push({
      platform: "instagram",
      label: "Instagram",
      icon: "i-lucide-instagram",
      url: profile.instagram,
    });
  }
  if (profile.youtube) {
    links.push({
      platform: "youtube",
      label: "YouTube",
      icon: "i-lucide-youtube",
      url: profile.youtube,
    });
  }
  return links;
});

const siteUrlRef = withSiteUrl("/");
const canonicalUrl = computed(
  () =>
    `${siteUrlRef.value.replace(/\/$/, "")}${buildPublicProfilePath(professional.value.slug)}`,
);
const professionalCity = computed(
  () => professional.value.coverage.city?.name ?? "sua cidade",
);
const professionalTitle = computed(() =>
  professional.value.primaryService
    ? `${professional.value.name} — ${professional.value.primaryService}`
    : `${professional.value.name} — profissional em ${professionalCity.value}`,
);
useSeoMeta({
  title: () => professionalTitle.value,
  description: () =>
    professional.value.headline ?? professional.value.bio ?? undefined,
  ogTitle: () => professionalTitle.value,
  ogDescription: () =>
    professional.value.headline ?? professional.value.bio ?? undefined,
  ogImage: () => professional.value.avatar ?? undefined,
  ogUrl: () => canonicalUrl.value,
  ogType: "profile",
  twitterCard: "summary_large_image",
  // External (unclaimed, referral-created) or evidence-thin profiles are
  // never indexed -- see PublicIndexability on the API side, which is the
  // single source of truth this reads from. Indexing follows from claiming
  // the profile, which is also the conversion mechanic.
  robots: () =>
    professional.value.indexable ? "index, follow" : "noindex, follow",
});
useHead(() => ({
  link: [{ rel: "canonical", href: canonicalUrl.value }],
}));
const breadcrumbItems = computed(() => {
  const city = professional.value.coverage.city;
  const items: Array<{ name: string; item: string }> = [
    { name: "Berufe", item: "/" },
  ];
  if (city) {
    items.push({
      name: city.name,
      item: `/encontrar/${city.stateAbbreviation.toLowerCase()}/${city.slug}`,
    });
  }
  items.push({ name: professional.value.name, item: canonicalUrl.value });
  return items;
});
useSchemaOrg([
  definePerson({
    // An explicit @id, distinct from the site's own Organization identity
    // (which also defaults to an "#identity" id) -- without this the two
    // nodes collide and merge into one incoherent node.
    "@id": `${canonicalUrl.value}#person`,
    name: professional.value.name,
    description:
      professional.value.headline ?? professional.value.bio ?? undefined,
    image: professional.value.avatar ?? undefined,
    jobTitle: professional.value.primaryService ?? undefined,
    knowsAbout: professional.value.services,
    address: {
      "@type": "PostalAddress",
      addressLocality: professionalCity.value,
      addressRegion: professional.value.coverage.city?.stateAbbreviation,
      addressCountry: "BR",
    },
  }),
  defineWebPage({
    "@type": "ProfilePage",
    name: () => professionalTitle.value,
    description: () =>
      professional.value.headline ?? professional.value.bio ?? undefined,
    mainEntity: { "@id": `${canonicalUrl.value}#person` },
  }),
  defineBreadcrumb({
    itemListElement: breadcrumbItems.value,
  }),
]);
defineOgImageSafely("BerufeProfessional", {
  name: professional.value.name,
  service: professional.value.primaryService ?? undefined,
  city: professionalCity.value,
});

onMounted(() => {
  void recordPublicProfessionalProfileView(
    client,
    professional.value.id,
    profileResult.value!.interactionToken,
  ).catch(() => undefined);
});

function announceContact() {
  showToast({
    title: "Abrindo o WhatsApp",
    description: "A conversa acontece diretamente com o profissional.",
  });
}

function openPortfolio(index: number) {
  activePortfolio.value = index;
  portfolioOpen.value = true;
}

async function shareProfile() {
  await share({
    title: `${professional.value.name} na Berufe`,
    text: professional.value.primaryService
      ? `Veja o perfil de ${professional.value.name}, ${professional.value.primaryService.toLocaleLowerCase("pt-BR")} em ${professionalCity.value}.`
      : `Veja o perfil profissional de ${professional.value.name} em ${professionalCity.value}.`,
    url: canonicalUrl.value,
  });
}
</script>

<template>
  <div v-if="professional" class="profile-page">
    <ProfileExternalProfile
      v-if="professional.profileType === 'external'"
      :professional="professional"
      :contact-url="contactUrl"
      :support-email-url="supportEmailUrl"
      @contact="announceContact"
      @share="shareProfile"
    />
    <template v-else>
      <ProfileHero
        :professional="professional"
        :social-links="socialLinks"
        :contact-url="contactUrl"
        :results-url="resultsUrl"
        @contact="announceContact"
        @share="shareProfile"
      />
      <ProfileEvidenceStrip
        :evidence="professional.evidence"
        :summary="professional.evidenceSummary"
      />

      <DesignSystemContainer class="profile-content">
        <ProfileDetails
          :professional="professional"
          :support-email-url="supportEmailUrl"
          @view-portfolio="openPortfolio"
        />
        <ProfileSidebar
          :professional="professional"
          :contact-url="contactUrl"
          @contact="announceContact"
        />
      </DesignSystemContainer>

      <ProfileCustomerRecommendations
        :recommendations="professional.customerRecommendations"
      />

      <ProfileMobileContact
        :professional="professional"
        :contact-url="contactUrl"
        @contact="announceContact"
      />
    </template>

    <UModal
      v-if="professional.profileType === 'self_service'"
      v-model:open="portfolioOpen"
      :title="selectedPortfolio?.title"
      :description="selectedPortfolio?.service"
      :ui="{ content: 'sm:max-w-3xl' }"
    >
      <template #body>
        <div v-if="selectedPortfolio" class="portfolio-modal">
          <img
            :src="selectedPortfolio.image"
            :alt="selectedPortfolio.title"
            width="1280"
            height="853"
          />
          <p v-if="selectedPortfolio.description">
            {{ selectedPortfolio.description }}
          </p>
        </div>
      </template>
    </UModal>
  </div>
</template>

<style scoped lang="scss">
:deep() {
  .profile-hero {
    padding: 30px 0 44px;
    background: var(--color-brand-strong);
    color: white;
    &__crumbs {
      display: flex;
      justify-content: space-between;
      margin-bottom: 42px;
    }
    &__crumbs a,
    &__crumbs button {
      display: flex;
      align-items: center;
      gap: 7px;
      border: 0;
      background: transparent;
      color: rgb(255 255 255 / 65%);
      font-size: 0.82rem;
      font-weight: 700;
      text-decoration: none;
      cursor: pointer;
    }
    &__grid {
      display: grid;
      grid-template-columns: 1fr 290px;
      gap: 60px;
      align-items: end;
    }
    &__identity {
      display: grid;
      grid-template-columns: 165px 1fr;
      gap: 28px;
      align-items: center;
    }
    &__service {
      margin: 0 0 7px;
      color: var(--color-brand-muted);
      font-size: 0.82rem;
      font-weight: 900;
      letter-spacing: 0.1em;
      text-transform: uppercase;
    }
    & h1 {
      margin: 0;
      font-family: var(--font-display);
      font-size: clamp(2.7rem, 5vw, 5rem);
      font-weight: 500;
      letter-spacing: -0.05em;
      line-height: 0.95;
    }
    &__headline {
      max-width: 580px;
      margin: 15px 0;
      color: rgb(255 255 255 / 68%);
      line-height: 1.55;
    }
    &__meta {
      display: flex;
      flex-wrap: wrap;
      gap: 16px;
      color: rgb(255 255 255 / 76%);
      font-size: 0.82rem;
      font-weight: 700;
    }
    &__meta span {
      display: inline-flex;
      align-items: center;
      gap: 5px;
    }
    &__socials {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin-top: 16px;
    }
    &__socials a {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 7px 10px;
      border: 1px solid rgb(255 255 255 / 16%);
      border-radius: 9px;
      background: rgb(255 255 255 / 7%);
      color: rgb(255 255 255 / 82%);
      font-size: 0.82rem;
      font-weight: 800;
      text-decoration: none;
      transition:
        background 0.15s ease,
        border-color 0.15s ease;
    }
    &__socials a:hover {
      border-color: rgb(255 255 255 / 30%);
      background: rgb(255 255 255 / 12%);
    }
    &__contact {
      padding: 18px;
      border: 1px solid rgb(255 255 255 / 13%);
      border-radius: 18px;
      background: rgb(255 255 255 / 7%);
    }
    &__contact p {
      margin: 0 0 12px;
      font-size: 0.86rem;
      font-weight: 800;
    }
    &__contact small {
      display: flex;
      justify-content: center;
      align-items: center;
      gap: 4px;
      margin-top: 10px;
      color: rgb(255 255 255 / 52%);
      font-size: 0.84rem;
    }
  }
  .evidence-strip {
    border-bottom: 1px solid var(--line);
    background: white;
    &__inner {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 22px;
      min-height: 100px;
    }
    &__inner > div {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    &__icon {
      display: grid;
      place-items: center;
      width: 42px;
      height: 42px;
      border-radius: 12px;
      background: var(--mint);
      color: var(--color-brand);
      font-size: 1.25rem;
    }
    & strong,
    & small {
      display: block;
    }
    & strong {
      font-size: 0.86rem;
    }
    & small {
      margin-top: 3px;
      color: var(--ink-soft);
      font-size: 0.86rem;
    }
    &__badges {
      justify-content: flex-end;
      flex-wrap: wrap;
    }
  }
  .profile-content {
    display: grid;
    grid-template-columns: minmax(0, 1fr) 280px;
    gap: 72px;
    padding-top: 70px;
    padding-bottom: 90px;
  }
  .profile-section {
    padding-bottom: 70px;
    margin-bottom: 70px;
    border-bottom: 1px solid var(--line);
    & h2 {
      margin: 0;
      font-family: var(--font-display);
      font-size: clamp(2.1rem, 4vw, 3.4rem);
      font-weight: 500;
      letter-spacing: -0.04em;
      line-height: 1.02;
    }
  }
  .profile-about {
    & > p:not(.eyebrow) {
      max-width: 700px;
      margin: 24px 0;
      color: var(--ink-soft);
      line-height: 1.78;
    }
    &__services {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 10px;
    }
    &__services > div {
      display: grid;
      grid-template-columns: auto 1fr auto;
      align-items: center;
      gap: 10px;
      padding: 14px;
      border: 1px solid var(--line);
      border-radius: 14px;
      background: white;
    }
    &__services > div > span {
      display: grid;
      place-items: center;
      width: 38px;
      height: 38px;
      border-radius: 10px;
      background: var(--mint);
      color: var(--color-brand);
    }
    &__services strong,
    &__services small {
      display: block;
    }
    &__services strong {
      font-size: 0.86rem;
    }
    &__services small {
      margin-top: 3px;
      color: var(--ink-soft);
      font-size: 0.86rem;
    }
    &__services em {
      padding: 4px 7px;
      border-radius: 6px;
      background: var(--color-accent-tint);
      color: #b34d39;
      font-size: 0.82rem;
      font-style: normal;
      font-weight: 900;
      text-transform: uppercase;
    }
  }
  .declaration-note {
    display: flex;
    align-items: flex-start;
    gap: 7px;
    margin-top: 14px;
    color: var(--ink-soft);
    font-size: 0.86rem;
    line-height: 1.5;
  }
  .declaration-note svg {
    flex: 0 0 auto;
    margin-top: 2px;
  }
  .profile-section {
    &__heading {
      display: flex;
      justify-content: space-between;
      align-items: end;
      gap: 20px;
      margin-bottom: 26px;
    }
    &__heading > span {
      color: var(--ink-soft);
      font-size: 0.86rem;
      font-weight: 800;
    }
  }
  .portfolio-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 12px;
  }
  .portfolio-item {
    position: relative;
    overflow: hidden;
    min-height: 260px;
    padding: 0;
    border: 0;
    border-radius: 18px;
    background: var(--mint);
    color: white;
    text-align: left;
    cursor: zoom-in;
    & img {
      position: absolute;
      inset: 0;
      width: 100%;
      height: 100%;
      object-fit: cover;
      transition: transform 0.3s ease;
    }
    &:hover img {
      transform: scale(1.03);
    }
    &::after {
      content: "";
      position: absolute;
      inset: 35% 0 0;
      background: linear-gradient(transparent, rgb(7 28 24 / 82%));
    }
    &__meta {
      position: absolute;
      z-index: 2;
      left: 17px;
      right: 45px;
      bottom: 16px;
    }
    & strong,
    & small {
      display: block;
    }
    & strong {
      font-family: var(--font-display);
      font-size: 1.18rem;
    }
    & small {
      margin-top: 3px;
      color: rgb(255 255 255 / 72%);
      font-size: 0.86rem;
    }
    &__expand {
      position: absolute;
      z-index: 2;
      right: 16px;
      bottom: 18px;
    }
  }
  .relationships-list {
    display: grid;
    gap: 10px;
  }
  .relationships-list article {
    display: grid;
    grid-template-columns: 74px 1fr;
    gap: 16px;
    padding: 18px;
    border-radius: 17px;
    background: var(--color-brand-tint-muted);
  }
  .relationship-type {
    display: flex;
    align-items: center;
    gap: 5px;
    color: var(--color-brand);
    font-size: 0.84rem;
    font-weight: 900;
    text-transform: uppercase;
  }
  .relationships-list p {
    margin: 8px 0;
    font-family: var(--font-display);
    font-size: 0.93rem;
    line-height: 1.45;
  }
  .relationships-list a {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    color: var(--ink);
    font-size: 0.86rem;
    font-weight: 800;
    text-decoration: none;
  }
  .relationships-empty {
    color: var(--ink-soft);
  }
  .relationship-request {
    margin-top: 16px;
  }
  .profile-disclaimer {
    display: flex;
    align-items: flex-start;
    gap: 14px;
    padding: 20px;
    border: 1px dashed #aacbbf;
    border-radius: 16px;
    background: #f2f8f6;
  }
  .profile-disclaimer__icon {
    flex: 0 0 1.35rem;
    width: 1.35rem;
    height: 1.35rem;
    margin-top: 1px;
    color: var(--color-brand);
  }
  .profile-disclaimer strong {
    font-size: 0.84rem;
  }
  .profile-disclaimer p {
    margin: 6px 0 0;
    color: var(--ink-soft);
    font-size: 0.86rem;
    line-height: 1.55;
  }
  .support-link {
    display: flex;
    align-items: center;
    gap: 5px;
    margin: 20px auto 0;
    width: fit-content;
    color: var(--ink-soft);
    font-size: 0.86rem;
    text-decoration: underline;
  }
  .profile-sidebar {
    position: sticky;
    top: 24px;
    align-self: start;
    &__card {
      padding: 20px;
    }
    &__card p {
      margin: 0 0 8px;
      color: var(--color-brand);
      font-size: 0.86rem;
      font-weight: 900;
      text-transform: uppercase;
    }
    &__card > strong {
      display: block;
      margin-bottom: 17px;
      font-family: var(--font-display);
      font-size: 1.2rem;
      line-height: 1.35;
    }
    &__card small {
      display: block;
      margin-top: 10px;
      color: var(--ink-soft);
      font-size: 0.84rem;
      text-align: center;
    }
    &__coverage {
      margin-top: 16px;
      padding: 18px;
      border-top: 1px solid var(--line);
    }
    &__coverage strong {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 0.82rem;
    }
    &__coverage p {
      color: var(--ink-soft);
      font-size: 0.82rem;
    }
    &__coverage div {
      display: flex;
      flex-wrap: wrap;
      gap: 5px;
      margin-top: 10px;
    }
    &__coverage div span {
      padding: 5px 7px;
      border-radius: 7px;
      background: var(--paper-strong);
      color: var(--ink-soft);
      font-size: 0.82rem;
    }
  }
  .mobile-contact {
    display: none;
  }
  .portfolio-modal img {
    width: 100%;
    max-height: 65vh;
    border-radius: 14px;
    object-fit: cover;
  }
  .portfolio-modal p {
    margin: 12px 0 0;
    color: var(--ink-soft);
    line-height: 1.6;
  }
  @media (width <= 900px) {
    .profile-hero {
      &__grid {
        grid-template-columns: 1fr;
      }
      &__contact {
        display: none;
      }
    }
    .profile-content {
      grid-template-columns: 1fr;
    }
    .profile-sidebar {
      display: none;
    }
    .mobile-contact {
      position: fixed;
      z-index: 35;
      left: 12px;
      right: 12px;
      bottom: 12px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 10px 10px 10px 14px;
      border: 1px solid rgb(255 255 255 / 15%);
      border-radius: 16px;
      background: var(--color-brand-strong);
      color: white;
      box-shadow: var(--shadow-lg);
    }
    .mobile-contact small,
    .mobile-contact strong {
      display: block;
    }
    .mobile-contact small {
      color: var(--color-brand-muted);
      font-size: 0.82rem;
      text-transform: uppercase;
    }
    .mobile-contact strong {
      margin-top: 2px;
      font-size: 0.84rem;
    }
  }
  @media (width <= 680px) {
    .profile-hero {
      &__identity {
        grid-template-columns: 90px 1fr;
        gap: 16px;
      }
      & h1 {
        font-size: 2.5rem;
      }
      &__headline {
        font-size: 0.86rem;
      }
      &__meta {
        display: grid;
        gap: 6px;
      }
    }
    .evidence-strip {
      &__inner {
        display: grid;
        padding-block: 18px;
      }
      &__badges {
        justify-content: flex-start;
      }
    }
    .profile-content {
      padding-top: 50px;
      gap: 0;
    }
    .portfolio-grid {
      grid-template-columns: 1fr;
    }
    .profile-about {
      &__services {
        grid-template-columns: 1fr;
      }
    }
    .profile-section {
      &__heading {
        display: grid;
      }
    }
    .relationships-list article {
      grid-template-columns: 54px 1fr;
    }
  }
}
</style>
