<script setup lang="ts">
import { computed } from 'vue'
import professionalsData from '../../../data/professionals.json'
import type { Professional } from '~/types'
import { useMockupApp } from '~/composables/useMockupApp'

const route = useRoute()
const router = useRouter()
const { showToast } = useMockupApp()
const professional = (professionalsData as Professional[])[0]!
const tabs = [
  { id: 'dados', label: 'Dados do perfil', icon: 'i-lucide-user-round' },
  { id: 'portfolio', label: 'Portfólio', icon: 'i-lucide-images' },
  { id: 'verificacoes', label: 'Verificações', icon: 'i-lucide-shield-check' },
]
const activeTab = computed(() => tabs.some((tab) => tab.id === route.query.tab) ? String(route.query.tab) : 'dados')

useSeoMeta({ title: 'Editar perfil profissional' })

async function selectTab(id: string) {
  await router.replace({ query: id === 'dados' ? {} : { tab: id } })
}
</script>

<template>
  <div class="profile-workspace">
    <section class="workspace-heading">
      <div class="page-container workspace-heading__inner">
        <div><NuxtLink to="/painel"><UIcon name="i-lucide-arrow-left" /> Painel</NuxtLink><h1>Meu perfil</h1><p>Organize as informações e evidências que clientes verão.</p></div>
        <span><i /> Publicado</span>
      </div>
    </section>
    <div class="page-container profile-workspace__content">
      <nav class="workspace-tabs" aria-label="Seções do perfil">
        <button v-for="tab in tabs" :key="tab.id" type="button" :class="{ active: activeTab === tab.id }" @click="selectTab(tab.id)"><UIcon :name="tab.icon" />{{ tab.label }}<span v-if="tab.id === 'portfolio'">{{ professional.portfolio.length }}</span></button>
      </nav>
      <DashboardProfileEditor v-if="activeTab === 'dados'" :professional="professional" @save="showToast({ title: 'Perfil atualizado', description: 'As alterações foram salvas neste protótipo.' })" />
      <DashboardPortfolioManager v-else-if="activeTab === 'portfolio'" :items="professional.portfolio" @added="showToast({ title: 'Trabalho enviado', description: 'Ele aparecerá no perfil depois da análise.' })" />
      <DashboardVerificationPanel v-else :evidence="professional.evidence" @submitted="showToast({ title: 'Verificação enviada', description: 'A equipe Berufe fará a conferência manual.' })" />
    </div>
  </div>
</template>

<style scoped>
.profile-workspace { min-height: 100vh; padding-bottom: 80px; background: #f3f1eb; }.workspace-heading { padding: 34px 0 38px; background: #17352f; color: white; }.workspace-heading__inner { display: flex; justify-content: space-between; align-items: end; }.workspace-heading a { display: flex; align-items: center; gap: 5px; margin-bottom: 20px; color: rgba(255,255,255,.58); font-size: .78rem; font-weight: 700; text-decoration: none; }.workspace-heading h1 { margin: 0; font-family: Georgia, serif; font-size: 2.7rem; font-weight: 500; letter-spacing: -.04em; }.workspace-heading p { margin: 7px 0 0; color: rgba(255,255,255,.59); font-size: .75rem; }.workspace-heading__inner > span { display: flex; align-items: center; gap: 6px; padding: 7px 10px; border: 1px solid rgba(255,255,255,.16); border-radius: 9px; color: #b7dfd3; font-size: .75rem; font-weight: 850; }.workspace-heading__inner > span i { width: 7px; height: 7px; border-radius: 99px; background: #7fd0b7; }.profile-workspace__content { display: grid; grid-template-columns: 190px minmax(0, 1fr); gap: 28px; padding-top: 26px; }.workspace-tabs { position: sticky; top: 20px; align-self: start; display: grid; gap: 4px; }.workspace-tabs button { display: flex; align-items: center; gap: 8px; width: 100%; padding: 11px 12px; border: 0; border-radius: 10px; background: transparent; color: var(--ink-soft); font-size: .78rem; font-weight: 800; text-align: left; cursor: pointer; }.workspace-tabs button.active { background: white; color: #397a69; box-shadow: 0 5px 15px rgba(23,53,47,.06); }.workspace-tabs button span { margin-left: auto; padding: 3px 6px; border-radius: 6px; background: var(--paper-strong); font-size: .72rem; }
@media (max-width: 760px) { .profile-workspace__content { grid-template-columns: 1fr; }.workspace-tabs { position: static; display: flex; overflow-x: auto; }.workspace-tabs button { width: auto; white-space: nowrap; }.workspace-heading__inner > span { display: none; } }
</style>
