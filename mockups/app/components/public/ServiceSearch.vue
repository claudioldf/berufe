<script setup lang="ts">
import { computed, shallowRef } from 'vue'
import catalogsData from '../../../data/catalogs.json'
import type { Neighborhood, Service } from '~/types'

const props = withDefaults(defineProps<{
  initialService?: string
  initialNeighborhood?: string
  compact?: boolean
}>(), {
  initialService: '',
  initialNeighborhood: 'all',
  compact: false,
})

const emit = defineEmits<{
  search: [payload: { service: string; neighborhood: string }]
}>()

const services = catalogsData.services as Service[]
const neighborhoods = catalogsData.neighborhoods as Neighborhood[]
const query = shallowRef(props.initialService)
const neighborhood = shallowRef(props.initialNeighborhood)
const isFocused = shallowRef(false)

const suggestions = computed(() => {
  const normalized = query.value.trim().toLocaleLowerCase('pt-BR')
  if (!normalized) return services.slice(0, 6)
  return services
    .filter((service) => {
      return service.name.toLocaleLowerCase('pt-BR').includes(normalized)
        || service.aliases.some((alias) => alias.includes(normalized))
    })
    .slice(0, 6)
})

function chooseService(service: Service) {
  query.value = service.name
  isFocused.value = false
}

function submit() {
  if (!query.value.trim()) return
  emit('search', { service: query.value.trim(), neighborhood: neighborhood.value })
  isFocused.value = false
}
</script>

<template>
  <form class="service-search" :class="{ 'service-search--compact': compact }" @submit.prevent="submit">
    <div class="service-search__field service-search__field--service">
      <UIcon name="i-lucide-search" />
      <label>
        <span>Qual serviço você precisa?</span>
        <input
          v-model="query"
          type="search"
          autocomplete="off"
          placeholder="Ex.: eletricista, pintura..."
          @focus="isFocused = true"
          @blur="isFocused = false"
          @keydown.esc="isFocused = false"
        >
      </label>

      <div v-if="isFocused && suggestions.length" class="service-search__suggestions">
        <button
          v-for="service in suggestions"
          :key="service.id"
          type="button"
          @mousedown.prevent="chooseService(service)"
        >
          <span class="service-search__suggestion-icon"><UIcon :name="service.icon" /></span>
          <span><strong>{{ service.name }}</strong><small>{{ service.description }}</small></span>
          <UIcon name="i-lucide-arrow-up-right" />
        </button>
      </div>
    </div>

    <div class="service-search__divider" />

    <div class="service-search__field service-search__field--location">
      <UIcon name="i-lucide-map-pin" />
      <label>
        <span>Onde?</span>
        <select v-model="neighborhood">
          <option v-for="item in neighborhoods" :key="item.code" :value="item.code">
            {{ item.name }}
          </option>
        </select>
      </label>
      <UIcon name="i-lucide-chevron-down" class="service-search__chevron" />
    </div>

    <UButton type="submit" color="primary" class="service-search__button">
      <span>Encontrar</span>
      <UIcon name="i-lucide-arrow-right" />
    </UButton>
  </form>
</template>

<style scoped>
.service-search { position: relative; z-index: 10; display: grid; grid-template-columns: minmax(250px, 1.35fr) 1px minmax(190px, .8fr) auto; align-items: center; width: 100%; padding: 9px; border: 1px solid rgba(23,53,47,.14); border-radius: 18px; background: white; box-shadow: 0 20px 55px rgba(23,53,47,.13); }
.service-search__field { position: relative; display: grid; grid-template-columns: auto 1fr; align-items: center; gap: 11px; min-width: 0; padding: 4px 16px; }
.service-search__field > svg { color: #397a69; font-size: 1.15rem; }
.service-search__field label { display: grid; min-width: 0; }
.service-search__field label > span { color: var(--ink-soft); font-size: .64rem; font-weight: 800; letter-spacing: .07em; text-transform: uppercase; }
.service-search input, .service-search select { width: 100%; min-width: 0; padding: 4px 0 0; border: 0; outline: 0; background: transparent; color: var(--ink); font-size: .9rem; font-weight: 750; }
.service-search input::placeholder { color: #8a9995; font-weight: 600; }
.service-search select { appearance: none; cursor: pointer; }
.service-search__divider { width: 1px; height: 38px; background: var(--line); }
.service-search__chevron { position: absolute; right: 13px; color: var(--ink-soft) !important; pointer-events: none; }
.service-search__button { align-self: stretch; min-height: 52px; justify-content: center; padding-inline: 24px; border-radius: 13px; font-weight: 800; }
.service-search__suggestions { position: absolute; top: calc(100% + 17px); left: -10px; width: min(460px, calc(100vw - 56px)); overflow: hidden; padding: 7px; border: 1px solid var(--line); border-radius: 17px; background: white; box-shadow: var(--shadow-lg); }
.service-search__suggestions button { display: grid; grid-template-columns: auto 1fr auto; align-items: center; gap: 11px; width: 100%; padding: 10px; border: 0; border-radius: 12px; background: transparent; color: var(--ink); text-align: left; cursor: pointer; }
.service-search__suggestions button:hover { background: var(--paper); }
.service-search__suggestion-icon { display: grid; place-items: center; width: 36px; height: 36px; border-radius: 10px; background: var(--mint); color: #397a69; }
.service-search__suggestions strong, .service-search__suggestions small { display: block; }
.service-search__suggestions strong { font-size: .84rem; }
.service-search__suggestions small { overflow: hidden; margin-top: 2px; color: var(--ink-soft); font-size: .69rem; text-overflow: ellipsis; white-space: nowrap; }
.service-search__suggestions > button > svg { color: #789089; }
.service-search--compact { box-shadow: var(--shadow-sm); }

@media (max-width: 760px) {
  .service-search { grid-template-columns: 1fr; gap: 0; padding: 8px; }
  .service-search__divider { display: none; }
  .service-search__field { padding: 10px 12px; }
  .service-search__field--location { border-top: 1px solid var(--line); }
  .service-search__button { min-height: 48px; margin-top: 5px; }
  .service-search__suggestions { top: calc(100% + 8px); left: 0; }
}
</style>
