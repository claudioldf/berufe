<script setup lang="ts">
import { computed } from "vue";
import type { ProviderPagesCollectionItem } from "@nuxt/content";
import type { PublicServiceDemand, SearchLocation, Service } from "~/types";
import { professionalSignupPath } from "~/utils/professional-auth";

const props = defineProps<{
  service: Service;
  content: ProviderPagesCollectionItem | null;
  demand: PublicServiceDemand | null;
  location: SearchLocation;
}>();

const displayTitle = computed(
  () =>
    props.content?.title ??
    `Como conseguir clientes de ${props.service.name.toLocaleLowerCase("pt-BR")}`,
);
const displayDescription = computed(
  () =>
    props.content?.description ??
    `${props.service.description} Crie um perfil gratuito para mostrar seu trabalho e receber contatos diretos pelo WhatsApp.`,
);
</script>

<template>
  <div class="provider-editorial">
    <section class="provider-editorial__masthead">
      <DesignSystemContainer class="provider-editorial__masthead-inner">
        <DesignSystemEyebrow>Para {{ service.name }}</DesignSystemEyebrow>
        <h1>{{ displayTitle }}</h1>
        <p>{{ displayDescription }}</p>
        <div v-if="demand?.released" class="provider-editorial__demand">
          <UIcon name="i-lucide-scan-search" aria-hidden="true" />
          Nos últimos 30 dias,
          <strong>
            {{ demand.searches }}
            {{
              demand.searches === 1 ? "pessoa procurou" : "pessoas procuraram"
            }}
          </strong>
          {{ service.name.toLocaleLowerCase("pt-BR") }} em {{ location.city }}.
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

    <DesignSystemPageSection class="provider-editorial__content">
      <DesignSystemContainer class="provider-editorial__body">
        <ContentRenderer v-if="content" :value="content" />
        <template v-else>
          <h2>Mostre evidências do seu trabalho</h2>
          <p>
            Complete seu perfil com fotos, referências e uma descrição clara dos
            serviços que você realiza. A página permanece fora dos resultados de
            busca até receber conteúdo editorial próprio.
          </p>
        </template>
      </DesignSystemContainer>
    </DesignSystemPageSection>

    <section class="provider-editorial__final-cta">
      <DesignSystemContainer class="provider-editorial__final-cta-inner">
        <h2>
          Mostre seu trabalho como
          {{ service.name.toLocaleLowerCase("pt-BR") }}.
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
.provider-editorial {
  &__masthead {
    padding: 48px 0 44px;
    background: #dff1eb;
  }

  &__masthead-inner h1 {
    max-width: 780px;
    margin: 0;
    font-family: var(--font-display);
    font-size: clamp(2.2rem, 4.5vw, 3.6rem);
    font-weight: 500;
    letter-spacing: -0.04em;
    line-height: 1.1;
  }

  &__masthead-inner > p {
    max-width: 680px;
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
  }

  &__demand svg {
    color: var(--color-brand);
    font-size: 1.1rem;
  }

  &__demand strong {
    color: var(--color-brand);
  }

  &__masthead-inner > :deep(a) {
    margin-top: 22px;
  }

  &__demand + :deep(a) {
    margin-top: 4px;
  }

  &__body {
    max-width: 760px;
  }

  &__body :deep(h2) {
    margin: 36px 0 14px;
    font-family: var(--font-display);
    font-size: 1.5rem;
  }

  &__body :deep(p) {
    margin: 0 0 16px;
    color: var(--ink-soft);
    line-height: 1.72;
  }

  &__body :deep(ul) {
    margin: 0 0 18px;
    padding-left: 22px;
    color: var(--ink-soft);
    line-height: 1.7;
  }

  &__body :deep(strong) {
    color: var(--ink);
  }

  &__final-cta {
    padding: 56px 0;
    background: var(--color-brand-strong);
    color: white;
  }

  &__final-cta-inner {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 24px;
  }

  &__final-cta-inner h2 {
    margin: 0;
    font-family: var(--font-display);
    font-size: 1.6rem;
    font-weight: 500;
  }
}
</style>
