<script setup lang="ts">
import { ref, shallowRef } from 'vue'
import catalogsData from '../../../data/catalogs.json'
import { useMockupApp } from '~/composables/useMockupApp'

const { showToast } = useMockupApp()
const activeTab = shallowRef<'services' | 'neighborhoods'>('services')
const services = ref(catalogsData.services.map((item, index) => ({ ...item, active: index !== 7 })))
const neighborhoods = ref(catalogsData.neighborhoods.map((item) => ({ ...item, active: true })))

function toggleService(id: string) {
  services.value = services.value.map((item) => item.id === id ? { ...item, active: !item.active } : item)
  showToast({ title: 'Catálogo atualizado', description: 'Referências históricas foram preservadas.' })
}

function toggleNeighborhood(code: string) {
  neighborhoods.value = neighborhoods.value.map((item) => item.code === code ? { ...item, active: !item.active } : item)
  showToast({ title: 'Localização atualizada', description: 'A alteração já vale para novas seleções.' })
}
</script>

<template>
  <section class="catalog surface-card">
    <header><div><h2>Catálogo controlado</h2><p>A mesma lista alimenta o Finder e os perfis profissionais.</p></div><UButton color="primary" icon="i-lucide-plus">Adicionar entrada</UButton></header>
    <nav><button type="button" :class="{ active: activeTab === 'services' }" @click="activeTab = 'services'">Serviços <span>{{ services.length }}</span></button><button type="button" :class="{ active: activeTab === 'neighborhoods' }" @click="activeTab = 'neighborhoods'">Bairros <span>{{ neighborhoods.length }}</span></button></nav>
    <div class="catalog__table">
      <div class="catalog__head"><span>Ordem</span><span>Nome</span><span>Identificador</span><span>Status</span><span>Ações</span></div>
      <div v-for="(item, index) in (activeTab === 'services' ? services : neighborhoods)" :key="'id' in item ? item.id : item.code" class="catalog__row">
        <span class="catalog__order"><UIcon name="i-lucide-grip-vertical" /> {{ index + 1 }}</span>
        <span><strong>{{ item.name }}</strong><small v-if="'description' in item">{{ item.description }}</small></span>
        <code>{{ 'slug' in item ? item.slug : item.code }}</code>
        <button type="button" class="catalog__status" :class="{ inactive: !item.active }" @click="activeTab === 'services' ? toggleService('id' in item ? item.id : '') : toggleNeighborhood('code' in item ? item.code : '')"><i />{{ item.active ? 'Ativo' : 'Inativo' }}</button>
        <button type="button" class="catalog__edit"><UIcon name="i-lucide-pencil" /> Editar</button>
      </div>
    </div>
  </section>
</template>

<style scoped>
.catalog { overflow: hidden; }.catalog > header { display: flex; justify-content: space-between; align-items: center; gap: 20px; padding: 22px; }.catalog h2, .catalog p { margin: 0; }.catalog h2 { font-family: Georgia, serif; font-size: 1.5rem; }.catalog p { margin-top: 4px; color: var(--ink-soft); font-size: .86rem; }.catalog nav { display: flex; gap: 4px; padding: 0 22px; border-bottom: 1px solid var(--line); }.catalog nav button { padding: 10px 12px; border: 0; border-bottom: 2px solid transparent; background: transparent; color: var(--ink-soft); font-size: .86rem; font-weight: 850; cursor: pointer; }.catalog nav button.active { border-bottom-color: #397a69; color: #397a69; }.catalog nav span { margin-left: 4px; padding: 2px 5px; border-radius: 5px; background: #eeece6; font-size: .82rem; }.catalog__head, .catalog__row { display: grid; grid-template-columns: 70px 1.5fr 1fr 90px 75px; gap: 12px; align-items: center; padding: 11px 20px; }.catalog__head { background: #f0eee8; color: var(--ink-soft); font-size: .82rem; font-weight: 900; text-transform: uppercase; }.catalog__row { border-top: 1px solid var(--line); min-height: 66px; }.catalog__order { display: flex; align-items: center; gap: 5px; color: var(--ink-soft); font-size: .84rem; cursor: grab; }.catalog__row strong, .catalog__row small { display: block; }.catalog__row strong { font-size: .86rem; }.catalog__row small { overflow: hidden; max-width: 400px; margin-top: 3px; color: var(--ink-soft); font-size: .82rem; text-overflow: ellipsis; white-space: nowrap; }.catalog__row code { color: var(--ink-soft); font-size: .82rem; }.catalog__status, .catalog__edit { display: inline-flex; align-items: center; gap: 5px; border: 0; background: transparent; color: #31715f; font-size: .82rem; font-weight: 850; cursor: pointer; }.catalog__status i { width: 7px; height: 7px; border-radius: 99px; background: #4caf8e; }.catalog__status.inactive { color: #8a7772; }.catalog__status.inactive i { background: #a79792; }.catalog__edit { color: var(--ink-soft); }
@media (max-width: 700px) { .catalog__head { display: none; }.catalog__row { grid-template-columns: 34px 1fr auto; }.catalog__row code { display: none; }.catalog__edit { grid-column: 3; }.catalog > header { display: grid; } }
</style>
