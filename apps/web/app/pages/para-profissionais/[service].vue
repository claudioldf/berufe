<script setup lang="ts">
import { fetchPublicServiceDemand } from "~/services/api/public-discovery";
import { useApiClient } from "~/services/api/client";
import { professionalSignupPath } from "~/utils/professional-auth";

const route = useRoute();
const client = useApiClient();
const serviceSlug = computed(() => String(route.params.service));

const catalogResult = await useCatalogs();
const service = computed(() =>
  catalogResult.data.value?.services.find(
    (candidate) => candidate.slug === serviceSlug.value,
  ),
);
if (!service.value) {
  throw createError({
    statusCode: 404,
    statusMessage: "Serviço não encontrado",
  });
}

const detectedLocation = useDetectedSearchLocation();
const { location, resolve: resolveLocation } = detectedLocation;
onMounted(() => {
  void resolveLocation();
});

const { data: demand } = await useAsyncData(
  () => `service-demand-${serviceSlug.value}-${location.value.cityCode}`,
  () =>
    fetchPublicServiceDemand(client, {
      serviceSlug: serviceSlug.value,
      stateSlug: location.value.stateSlug,
      citySlug: location.value.citySlug,
    }),
  { watch: [location] },
);

const serviceName = computed(() => service.value?.name ?? "");
const title = computed(
  () =>
    `Como conseguir clientes de ${serviceName.value.toLocaleLowerCase("pt-BR")}`,
);
const description = computed(
  () =>
    `Divulgação gratuita para ${serviceName.value.toLocaleLowerCase("pt-BR")}: portfólio, identidade confirmada e contato direto pelo WhatsApp, sem pagar por lead.`,
);
const siteUrl = withSiteUrl("/");
const canonicalUrl = computed(
  () => `${siteUrl.value.replace(/\/$/, "")}${route.path}`,
);

useSeoMeta({
  title: () => title.value,
  description: () => description.value,
  ogTitle: () => title.value,
  ogDescription: () => description.value,
  ogUrl: () => canonicalUrl.value,
  ogType: "website",
});
useHead(() => ({ link: [{ rel: "canonical", href: canonicalUrl.value }] }));
defineOgImageSafely("BerufeDefault", {
  title: () => title.value,
  description: () => description.value,
});
</script>

<template>
  <div v-if="service" class="service-pillar">
    <section class="service-pillar__masthead">
      <DesignSystemContainer class="service-pillar__masthead-inner">
        <DesignSystemEyebrow>Para {{ serviceName }}</DesignSystemEyebrow>
        <h1>
          Como conseguir clientes<br />
          de <em>{{ serviceName.toLocaleLowerCase("pt-BR") }}</em>
        </h1>
        <p>
          {{ service.description }} Um perfil gratuito com portfólio, identidade
          confirmada e referências de clientes reais é o que faz alguém escolher
          você em vez de outro profissional — sem pagar por lead nem comissão
          sobre o serviço.
        </p>
        <div v-if="demand?.released" class="service-pillar__demand">
          <UIcon name="i-lucide-scan-search" aria-hidden="true" />
          Nos últimos 30 dias,
          <strong
            >{{ demand.searches }}
            {{
              demand.searches === 1 ? "pessoa procurou" : "pessoas procuraram"
            }}</strong
          >
          {{ serviceName.toLocaleLowerCase("pt-BR") }} em {{ location.city }}.
        </div>
        <UButton
          :to="professionalSignupPath"
          color="primary"
          size="xl"
          trailing-icon="i-lucide-arrow-right"
        >
          Criar perfil grátis
        </UButton>
      </DesignSystemContainer>
    </section>

    <DesignSystemPageSection class="service-pillar__body">
      <DesignSystemContainer class="service-pillar__body-inner">
        <h2>
          O que funciona para {{ serviceName.toLocaleLowerCase("pt-BR") }}
        </h2>
        <ul>
          <li>
            <strong>Portfólio real.</strong> Fotos de antes e depois de serviços
            já concluídos — a prova mais direta de que você resolve o problema
            do cliente.
          </li>
          <li>
            <strong>Identidade confirmada.</strong> Reduz a hesitação de quem
            vai deixar um profissional desconhecido entrar em casa.
          </li>
          <li>
            <strong>Resposta rápida pelo WhatsApp.</strong> Clientes costumam
            falar com mais de um profissional ao mesmo tempo — quem responde
            primeiro geralmente sai na frente.
          </li>
          <li>
            <strong>Referências de clientes anteriores.</strong> Uma
            recomendação de quem já contratou vale mais do que qualquer texto de
            apresentação.
          </li>
        </ul>
        <p>
          Essas quatro coisas, reunidas em um único perfil, resolvem a pergunta
          que todo cliente faz antes de contratar: posso confiar nessa pessoa?
          Nenhuma delas exige pagar por anúncio ou por contato.
        </p>
      </DesignSystemContainer>
    </DesignSystemPageSection>

    <section class="service-pillar__final-cta">
      <DesignSystemContainer class="service-pillar__final-cta-inner">
        <h2>
          Crie seu perfil de {{ serviceName.toLocaleLowerCase("pt-BR") }}
          hoje.
        </h2>
        <UButton
          :to="professionalSignupPath"
          color="secondary"
          size="xl"
          trailing-icon="i-lucide-arrow-right"
        >
          Criar perfil grátis
        </UButton>
      </DesignSystemContainer>
    </section>
  </div>
</template>

<style scoped lang="scss">
.service-pillar {
  &__masthead {
    padding: 48px 0 44px;
    background: #dff1eb;
  }

  &__masthead-inner h1 {
    margin: 0;
    font-family: var(--font-display);
    font-size: clamp(2.2rem, 4.5vw, 3.6rem);
    font-weight: 500;
    letter-spacing: -0.04em;
    line-height: 1.1;
  }

  &__masthead-inner h1 em {
    color: var(--color-brand);
    font-weight: inherit;
    font-style: normal;
  }

  &__masthead-inner > p {
    max-width: 640px;
    margin: 18px 0 0;
    color: var(--ink-soft);
    line-height: 1.65;
  }

  &__demand {
    display: flex;
    align-items: center;
    gap: 9px;
    max-width: fit-content;
    margin: 22px 0;
    padding: 12px 16px;
    border-radius: 12px;
    background: white;
    color: var(--ink);
    font-size: 0.9rem;

    > svg {
      color: var(--color-brand);
      font-size: 1.1rem;
    }

    strong {
      color: var(--color-brand);
    }
  }

  &__masthead-inner .service-pillar__demand + :deep(a) {
    margin-top: 4px;
  }

  &__body-inner {
    max-width: 720px;
  }

  &__body-inner h2 {
    margin: 0 0 16px;
    font-family: var(--font-display);
    font-size: 1.6rem;
  }

  &__body-inner ul {
    display: grid;
    gap: 14px;
    margin: 0 0 20px;
    padding: 0;
    list-style: none;
  }

  &__body-inner li {
    padding: 16px 18px;
    border: 1px solid var(--line);
    border-radius: 14px;
    line-height: 1.6;
    color: var(--ink-soft);
  }

  &__body-inner li strong {
    color: var(--ink);
  }

  &__body-inner > p {
    color: var(--ink-soft);
    line-height: 1.65;
  }

  &__final-cta {
    padding: 56px 0;
    background: var(--color-brand-strong);
    color: white;
  }

  &__final-cta-inner {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 24px;
    flex-wrap: wrap;
  }

  &__final-cta-inner h2 {
    margin: 0;
    font-family: var(--font-display);
    font-size: 1.6rem;
    font-weight: 500;
  }
}
</style>
