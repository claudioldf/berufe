<script setup lang="ts">
import professionalsData from "@data/professionals.json";
import type { Professional } from "~/types";
import { useCatalogs } from "~/composables/useCatalogs";
import { useProfessionalSearch } from "~/composables/useProfessionalSearch";
import { useToast } from "~/composables/useToast";
import { buildWhatsAppUrl } from "~/utils/contact";

const { showToast } = useToast();
const { data: catalog, error: catalogError } = await useCatalogs();
if (catalogError.value || !catalog.value) {
  throw createError({
    statusCode: 503,
    statusMessage: "Catálogo temporariamente indisponível.",
  });
}
const services = catalog.value.services;
const neighborhoods = catalog.value.neighborhoods;
const professionals = professionalsData as Professional[];
const {
  serviceInput,
  neighborhoodInput,
  serviceQuery,
  neighborhoodCode,
  selectedService,
  selectedNeighborhood,
  results,
  relatedServices,
  submitSearch,
} = useProfessionalSearch({ services, neighborhoods, professionals });

useSeoMeta({
  title: () =>
    `${selectedService.value?.name ?? "Encontrar profissionais"} em Joinville`,
  description: () =>
    `Compare evidências e encontre ${selectedService.value?.name.toLocaleLowerCase("pt-BR") ?? "profissionais"} em Joinville.`,
});

function contactUrl(professional: Professional) {
  return buildWhatsAppUrl(
    professional.whatsapp,
    `Olá, ${professional.name}! Encontrei seu perfil na Berufe e gostaria de conversar sobre ${selectedService.value?.name ?? professional.primaryService}.`,
  );
}

function announceContact() {
  showToast({
    title: "Abrindo o WhatsApp",
    description: "O contato é direto com o profissional.",
  });
}
</script>

<template>
  <div class="finder">
    <section class="finder__masthead">
      <DesignSystemContainer class="finder__masthead-inner">
        <div class="finder__breadcrumbs">
          <NuxtLink to="/">Início</NuxtLink
          ><UIcon name="i-lucide-chevron-right" />
          <span>Encontrar profissional</span>
        </div>
        <DesignSystemEyebrow>Profissionais</DesignSystemEyebrow>
        <h1>
          <template v-if="selectedService">
            {{ selectedService.name }} <em>em Joinville</em>
          </template>
          <template v-else>Vamos tentar <em>de outro jeito</em></template>
        </h1>
        <p>
          {{
            selectedService?.description ??
            "Não encontramos esse termo no catálogo de serviços residenciais."
          }}
        </p>
        <PublicServiceSearch
          v-model:service="serviceInput"
          v-model:neighborhood="neighborhoodInput"
          :services="services"
          :neighborhoods="neighborhoods"
          compact
          @submit="submitSearch"
        />
      </DesignSystemContainer>
    </section>

    <DesignSystemPageSection class="finder__content">
      <DesignSystemContainer class="finder__layout">
        <aside class="finder__aside">
          <p>Filtros</p>
          <div class="filter-block">
            <strong>Serviço</strong>
            <span>{{ selectedService?.name ?? serviceQuery }}</span>
          </div>
          <div class="filter-block">
            <strong>Localização</strong>
            <span>{{ selectedNeighborhood?.name }}</span>
          </div>
          <div class="finder__explanation">
            <UIcon name="i-lucide-list-ordered" />
            <strong>Como ordenamos</strong>
            <p>
              Primeiro, consideramos a correspondência exata e o atendimento na
              região. Depois, avaliamos identidade verificada, portfólio e
              relações profissionais.
            </p>
            <span>Relevância e qualidade.</span>
          </div>
        </aside>

        <div class="finder__results">
          <div class="results-heading">
            <div>
              <strong
                >{{ results.length }}
                {{
                  results.length === 1
                    ? "profissional encontrado"
                    : "profissionais encontrados"
                }}</strong
              >
              <span v-if="selectedNeighborhood?.code !== 'all'"
                >Atendendo {{ selectedNeighborhood?.name }}</span
              >
              <span v-else>Em Joinville</span>
            </div>
            <span class="results-heading__order"
              ><UIcon name="i-lucide-info" /> Ordem por relevância</span
            >
          </div>

          <div v-if="results.length" class="results-list">
            <PublicProfessionalCard
              v-for="professional in results"
              :key="professional.id"
              :professional="professional"
              :matching-service="
                selectedService?.name ?? professional.primaryService
              "
              :contact-url="contactUrl(professional)"
              @contact="announceContact"
            />
          </div>

          <DesignSystemSurfaceCard v-else class="empty-results">
            <span class="empty-results__icon"
              ><UIcon name="i-lucide-search-x"
            /></span>
            <h2>Ainda não temos esse encaixe.</h2>
            <p>
              Tente mudar o bairro ou explore um serviço próximo. A Berufe não
              transforma sua busca em pedido de orçamento.
            </p>
            <div class="empty-results__suggestions">
              <NuxtLink
                v-for="service in relatedServices"
                :key="service.id"
                :to="`/encontrar?servico=${service.slug}&bairro=${neighborhoodCode}`"
              >
                <UIcon :name="service.icon" /> {{ service.name }}
              </NuxtLink>
            </div>
          </DesignSystemSurfaceCard>

          <div class="finder__principle">
            <UIcon name="i-lucide-heart-handshake" />
            <div>
              <strong>Você decide com quem falar.</strong>
              <p>Na Berufe, seu contato só chega a quem você escolher.</p>
            </div>
          </div>
        </div>
      </DesignSystemContainer>
    </DesignSystemPageSection>
  </div>
</template>

<style scoped lang="scss">
.finder {
  &__masthead {
    padding: 40px 0 44px;
    background: #dff1eb;
  }
  &__breadcrumbs {
    display: flex;
    align-items: center;
    gap: 5px;
    margin-bottom: 30px;
    color: var(--ink-soft);
    font-size: 0.82rem;
  }
  &__breadcrumbs a {
    color: inherit;
    text-decoration: none;
  }
  &__breadcrumbs svg {
    font-size: 0.86rem;
  }
  &__masthead h1 {
    margin: 0;
    font-family: var(--font-display);
    font-size: clamp(2.4rem, 5vw, 4.5rem);
    font-weight: 500;
    letter-spacing: -0.045em;
    line-height: 1;
  }
  &__masthead h1 em {
    color: var(--color-brand);
    font-weight: inherit;
  }
  &__masthead-inner > p:last-of-type {
    margin: 15px 0 26px;
    color: var(--ink-soft);
  }
  &__layout {
    display: grid;
    grid-template-columns: 230px 1fr;
    gap: 42px;
  }
  &__aside {
    position: sticky;
    top: 24px;
    align-self: start;
  }
  &__aside > p {
    margin: 0 0 14px;
    font-size: 0.82rem;
    font-weight: 900;
    letter-spacing: 0.1em;
    text-transform: uppercase;
  }
}
.filter-block {
  display: grid;
  gap: 5px;
  padding: 15px 0;
  border-top: 1px solid var(--line);
}
.filter-block strong {
  font-size: 0.82rem;
}
.filter-block span {
  color: var(--ink-soft);
  font-size: 0.84rem;
}
.finder {
  &__explanation {
    margin-top: 20px;
    padding: 18px;
    border-radius: 17px;
    background: var(--color-brand-tint-muted);
  }
  &__explanation > svg {
    margin-bottom: 11px;
    color: var(--color-brand);
    font-size: 1.3rem;
  }
  &__explanation strong {
    display: block;
    font-size: 0.84rem;
  }
  &__explanation p {
    margin: 7px 0 10px;
    color: var(--ink-soft);
    font-size: 0.86rem;
    line-height: 1.5;
  }
  &__explanation span {
    color: var(--color-brand);
    font-size: 0.86rem;
    font-weight: 800;
  }
}
.results-heading {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 18px;
  & strong,
  & span {
    display: block;
  }
  & strong {
    font-family: var(--font-display);
    font-size: 1.35rem;
  }
  & > div span {
    margin-top: 4px;
    color: var(--ink-soft);
    font-size: 0.82rem;
  }
  &__order {
    display: flex !important;
    align-items: center;
    gap: 5px;
    color: var(--color-brand);
    font-size: 0.86rem;
    font-weight: 800;
  }
}
.results-list {
  display: grid;
  gap: 14px;
}
.finder {
  &__results {
    min-width: 0;
  }
}
.empty-results {
  padding: 56px 30px;
  text-align: center;
  &__icon {
    display: grid;
    place-items: center;
    width: 58px;
    height: 58px;
    margin: 0 auto;
    border-radius: 18px;
    background: var(--mint);
    color: var(--color-brand);
    font-size: 1.5rem;
  }
  & h2 {
    margin: 18px 0 7px;
    font-family: var(--font-display);
    font-size: 2rem;
  }
  & p {
    max-width: 520px;
    margin: 0 auto;
    color: var(--ink-soft);
    font-size: 0.83rem;
    line-height: 1.6;
  }
  &__suggestions {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 8px;
    margin-top: 22px;
  }
  &__suggestions a {
    display: inline-flex;
    align-items: center;
    gap: 7px;
    padding: 9px 12px;
    border: 1px solid var(--line);
    border-radius: 11px;
    color: var(--ink);
    font-size: 0.84rem;
    font-weight: 800;
    text-decoration: none;
  }
}
.finder {
  &__principle {
    display: flex;
    align-items: center;
    gap: 13px;
    margin-top: 18px;
    padding: 17px;
    border: 1px dashed #aacbbf;
    border-radius: 16px;
    color: var(--color-brand);
  }
  &__principle > svg {
    font-size: 1.5rem;
  }
  &__principle strong {
    display: block;
    font-size: 0.86rem;
  }
  &__principle p {
    margin: 3px 0 0;
    color: var(--ink-soft);
    font-size: 0.82rem;
  }
}
@media (width <= 800px) {
  .finder {
    &__layout {
      grid-template-columns: 1fr;
    }
    &__aside {
      display: none;
    }
    &__content {
      padding-top: 42px;
    }
  }
}
@media (width <= 520px) {
  .results-heading {
    &__order {
      display: none !important;
    }
  }
}
</style>
