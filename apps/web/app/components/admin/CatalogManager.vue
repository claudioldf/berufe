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
  <DesignSystemSurfaceCard as="section" class="catalog">
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
  </DesignSystemSurfaceCard>
</template>

<style scoped lang="scss">
.catalog {
  overflow: hidden;
  & > header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 20px;
    padding: 22px;
  }
  & h2,
  & p {
    margin: 0;
  }
  & h2 {
    font-family: Georgia, serif;
    font-size: 1.5rem;
  }
  & p {
    margin-top: 4px;
    color: var(--ink-soft);
    font-size: 0.86rem;
  }
  & nav {
    display: flex;
    gap: 4px;
    padding: 0 22px;
    border-bottom: 1px solid var(--line);
  }
  & nav button {
    padding: 10px 12px;
    border: 0;
    border-bottom: 2px solid transparent;
    background: transparent;
    color: var(--ink-soft);
    font-size: 0.86rem;
    font-weight: 850;
    cursor: pointer;
  }
  & nav button.active {
    border-bottom-color: #397a69;
    color: #397a69;
  }
  & nav span {
    margin-left: 4px;
    padding: 2px 5px;
    border-radius: 5px;
    background: #eeece6;
    font-size: 0.82rem;
  }
  &__head,
  &__row {
    display: grid;
    grid-template-columns: 70px 1.5fr 1fr 90px 75px;
    gap: 12px;
    align-items: center;
    padding: 11px 20px;
  }
  &__head {
    background: #f0eee8;
    color: var(--ink-soft);
    font-size: 0.82rem;
    font-weight: 900;
    text-transform: uppercase;
  }
  &__row {
    border-top: 1px solid var(--line);
    min-height: 66px;
  }
  &__order {
    display: flex;
    align-items: center;
    gap: 5px;
    color: var(--ink-soft);
    font-size: 0.84rem;
    cursor: grab;
  }
  &__row strong,
  &__row small {
    display: block;
  }
  &__row strong {
    font-size: 0.86rem;
  }
  &__row small {
    overflow: hidden;
    max-width: 400px;
    margin-top: 3px;
    color: var(--ink-soft);
    font-size: 0.82rem;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  &__row code {
    color: var(--ink-soft);
    font-size: 0.82rem;
  }
  &__status,
  &__edit {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    border: 0;
    background: transparent;
    color: #31715f;
    font-size: 0.82rem;
    font-weight: 850;
    cursor: pointer;
  }
  &__status i {
    width: 7px;
    height: 7px;
    border-radius: 99px;
    background: #4caf8e;
  }
  &__status.inactive {
    color: #8a7772;
  }
  &__status.inactive i {
    background: #a79792;
  }
  &__edit {
    color: var(--ink-soft);
  }
}
@media (max-width: 700px) {
  .catalog {
    &__head {
      display: none;
    }
    &__row {
      grid-template-columns: 34px 1fr auto;
    }
    &__row code {
      display: none;
    }
    &__edit {
      grid-column: 3;
    }
    & > header {
      display: grid;
    }
  }
}
</style>
