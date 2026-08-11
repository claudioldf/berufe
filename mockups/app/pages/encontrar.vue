<script setup lang="ts">
import { computed } from 'vue'
import catalogsData from '../../data/catalogs.json'
import professionalsData from '../../data/professionals.json'
import type { Neighborhood, Professional, Service } from '~/types'
import { useMockupApp } from '~/composables/useMockupApp'

const route = useRoute()
const router = useRouter()
const { showToast } = useMockupApp()
const services = catalogsData.services as Service[]
const neighborhoods = catalogsData.neighborhoods as Neighborhood[]
const professionals = professionalsData as Professional[]

const serviceQuery = computed(() => String(route.query.servico ?? 'eletricista'))
const neighborhoodCode = computed(() => String(route.query.bairro ?? 'all'))

const selectedService = computed(() => {
  const normalized = serviceQuery.value.toLocaleLowerCase('pt-BR')
  return services.find((service) => service.slug === normalized)
    ?? services.find((service) => service.name.toLocaleLowerCase('pt-BR') === normalized)
    ?? services.find((service) => service.aliases.includes(normalized))
})

const selectedNeighborhood = computed(() => neighborhoods.find((item) => item.code === neighborhoodCode.value) ?? neighborhoods[0])

const results = computed(() => {
  if (!selectedService.value) return []
  const service = selectedService.value
  const neighborhood = selectedNeighborhood.value

  return professionals
    .filter((professional) => professional.services.includes(service.name))
    .filter((professional) => {
      return neighborhood?.code === 'all'
        || professional.allJoinville
        || professional.neighborhoods.includes(neighborhood?.name ?? '')
    })
    .toSorted((a, b) => {
      const score = (professional: Professional) => {
        let value = 0
        if (professional.primaryService === service.name) value += 100
        if (neighborhood?.code !== 'all' && professional.neighborhoods.includes(neighborhood?.name ?? '')) value += 50
        if (professional.evidence.some((item) => item.label === 'Identidade verificada')) value += 25
        if (professional.portfolio.length) value += 10
        value += professional.recommendations.length + professional.relationships.length
        return value
      }
      return score(b) - score(a) || b.updatedAt.localeCompare(a.updatedAt)
    })
})

const relatedServices = computed(() => {
  if (selectedService.value) {
    return services.filter((service) => service.category === selectedService.value?.category && service.id !== selectedService.value?.id).slice(0, 3)
  }
  return services.slice(0, 3)
})

useSeoMeta({
  title: () => `${selectedService.value?.name ?? 'Encontrar profissionais'} em Joinville`,
  description: () => `Compare evidências e encontre ${selectedService.value?.name.toLocaleLowerCase('pt-BR') ?? 'profissionais'} em Joinville.`,
})

async function search(payload: { service: string; neighborhood: string }) {
  const normalized = payload.service.toLocaleLowerCase('pt-BR')
  const service = services.find((item) => item.name.toLocaleLowerCase('pt-BR') === normalized)
    ?? services.find((item) => item.aliases.some((alias) => alias.includes(normalized) || normalized.includes(alias)))
  await router.push({
    path: '/encontrar',
    query: { servico: service?.slug ?? payload.service, bairro: payload.neighborhood },
  })
}

function contact(professional: Professional) {
  const text = encodeURIComponent(`Olá, ${professional.name}! Encontrei seu perfil na Berufe e gostaria de conversar sobre ${selectedService.value?.name ?? professional.primaryService}.`)
  showToast({ title: 'Abrindo o WhatsApp', description: 'O contato é direto com o profissional.' })
  if (import.meta.client) window.open(`https://wa.me/${professional.whatsapp}?text=${text}`, '_blank', 'noopener,noreferrer')
}
</script>

<template>
  <div class="finder">
    <section class="finder__masthead">
      <div class="page-container">
        <div class="finder__breadcrumbs">
          <NuxtLink to="/">Início</NuxtLink><UIcon name="i-lucide-chevron-right" />
          <span>Encontrar profissional</span>
        </div>
        <p class="eyebrow">Berufe Encontrar</p>
        <h1>
          <template v-if="selectedService">
            {{ selectedService.name }} <em>em Joinville</em>
          </template>
          <template v-else>Vamos tentar <em>de outro jeito</em></template>
        </h1>
        <p>{{ selectedService?.description ?? 'Não encontramos esse termo no catálogo de serviços residenciais.' }}</p>
        <PublicServiceSearch
          :key="`${serviceQuery}-${neighborhoodCode}`"
          :initial-service="selectedService?.name ?? serviceQuery"
          :initial-neighborhood="neighborhoodCode"
          compact
          @search="search"
        />
      </div>
    </section>

    <section class="finder__content page-section">
      <div class="page-container finder__layout">
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
            <p>Primeiro, a correspondência exata e o atendimento ao bairro. Depois, evidências verificadas, portfólio e recomendações.</p>
            <span>Nunca há posição paga.</span>
          </div>
        </aside>

        <div class="finder__results">
          <div class="results-heading">
            <div>
              <strong>{{ results.length }} {{ results.length === 1 ? 'profissional encontrado' : 'profissionais encontrados' }}</strong>
              <span v-if="selectedNeighborhood?.code !== 'all'">Atendendo {{ selectedNeighborhood?.name }}</span>
              <span v-else>Em Joinville</span>
            </div>
            <span class="results-heading__order"><UIcon name="i-lucide-info" /> Ordem transparente</span>
          </div>

          <div v-if="results.length" class="results-list">
            <PublicProfessionalCard
              v-for="professional in results"
              :key="professional.id"
              :professional="professional"
              :matching-service="selectedService?.name ?? professional.primaryService"
              @contact="contact"
            />
          </div>

          <div v-else class="empty-results surface-card">
            <span class="empty-results__icon"><UIcon name="i-lucide-search-x" /></span>
            <h2>Ainda não temos esse encaixe.</h2>
            <p>Tente mudar o bairro ou explore um serviço próximo. A Berufe não transforma sua busca em pedido de orçamento.</p>
            <div class="empty-results__suggestions">
              <NuxtLink
                v-for="service in relatedServices"
                :key="service.id"
                :to="`/encontrar?servico=${service.slug}&bairro=${neighborhoodCode}`"
              >
                <UIcon :name="service.icon" /> {{ service.name }}
              </NuxtLink>
            </div>
          </div>

          <div class="finder__principle">
            <UIcon name="i-lucide-heart-handshake" />
            <div><strong>Você escolhe com calma.</strong><p>A Berufe não vende seu contato nem envia seu pedido para vários profissionais.</p></div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.finder__masthead { padding: 40px 0 44px; background: #dff1eb; }
.finder__breadcrumbs { display: flex; align-items: center; gap: 5px; margin-bottom: 30px; color: var(--ink-soft); font-size: .7rem; }.finder__breadcrumbs a { color: inherit; text-decoration: none; }.finder__breadcrumbs svg { font-size: .8rem; }
.finder__masthead h1 { margin: 0; font-family: Georgia, serif; font-size: clamp(2.4rem, 5vw, 4.5rem); font-weight: 500; letter-spacing: -.045em; line-height: 1; }.finder__masthead h1 em { color: #397a69; font-weight: inherit; }.finder__masthead > .page-container > p:not(.eyebrow) { margin: 15px 0 26px; color: var(--ink-soft); }
.finder__layout { display: grid; grid-template-columns: 230px 1fr; gap: 42px; }
.finder__aside { position: sticky; top: 24px; align-self: start; }.finder__aside > p { margin: 0 0 14px; font-size: .72rem; font-weight: 900; letter-spacing: .1em; text-transform: uppercase; }
.filter-block { display: grid; gap: 5px; padding: 15px 0; border-top: 1px solid var(--line); }.filter-block strong { font-size: .72rem; }.filter-block span { color: var(--ink-soft); font-size: .76rem; }
.finder__explanation { margin-top: 20px; padding: 18px; border-radius: 17px; background: #e7f3ef; }.finder__explanation > svg { margin-bottom: 11px; color: #397a69; font-size: 1.3rem; }.finder__explanation strong { display: block; font-size: .76rem; }.finder__explanation p { margin: 7px 0 10px; color: var(--ink-soft); font-size: .68rem; line-height: 1.5; }.finder__explanation span { color: #397a69; font-size: .65rem; font-weight: 800; }
.results-heading { display: flex; justify-content: space-between; align-items: center; margin-bottom: 18px; }.results-heading strong, .results-heading span { display: block; }.results-heading strong { font-family: Georgia, serif; font-size: 1.35rem; }.results-heading > div span { margin-top: 4px; color: var(--ink-soft); font-size: .72rem; }.results-heading__order { display: flex !important; align-items: center; gap: 5px; color: #397a69; font-size: .69rem; font-weight: 800; }
.results-list { display: grid; gap: 14px; }.finder__results { min-width: 0; }
.empty-results { padding: 56px 30px; text-align: center; }.empty-results__icon { display: grid; place-items: center; width: 58px; height: 58px; margin: 0 auto; border-radius: 18px; background: var(--mint); color: #397a69; font-size: 1.5rem; }.empty-results h2 { margin: 18px 0 7px; font-family: Georgia, serif; font-size: 2rem; }.empty-results p { max-width: 520px; margin: 0 auto; color: var(--ink-soft); font-size: .83rem; line-height: 1.6; }.empty-results__suggestions { display: flex; flex-wrap: wrap; justify-content: center; gap: 8px; margin-top: 22px; }.empty-results__suggestions a { display: inline-flex; align-items: center; gap: 7px; padding: 9px 12px; border: 1px solid var(--line); border-radius: 11px; color: var(--ink); font-size: .75rem; font-weight: 800; text-decoration: none; }
.finder__principle { display: flex; align-items: center; gap: 13px; margin-top: 18px; padding: 17px; border: 1px dashed #aacbbf; border-radius: 16px; color: #397a69; }.finder__principle > svg { font-size: 1.5rem; }.finder__principle strong { display: block; font-size: .78rem; }.finder__principle p { margin: 3px 0 0; color: var(--ink-soft); font-size: .7rem; }
@media (max-width: 800px) { .finder__layout { grid-template-columns: 1fr; }.finder__aside { display: none; }.finder__content { padding-top: 42px; } }
@media (max-width: 520px) { .results-heading__order { display: none !important; } }
</style>
