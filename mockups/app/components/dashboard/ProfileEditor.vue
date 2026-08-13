<script setup lang="ts">
import { reactive, shallowRef } from 'vue'
import catalogsData from '../../../data/catalogs.json'
import type { Professional, Service } from '~/types'

const props = defineProps<{ professional: Professional }>()
const emit = defineEmits<{ save: [] }>()
const services = catalogsData.services as Service[]
const neighborhoods = catalogsData.neighborhoods.filter((item) => item.code !== 'all')

const form = reactive({
  name: props.professional.name,
  headline: props.professional.headline,
  bio: props.professional.bio,
  yearsExperience: props.professional.yearsExperience,
  whatsapp: '(47) 99999-1111',
  selectedServices: [...props.professional.services],
  primaryService: props.professional.primaryService,
  allJoinville: props.professional.allJoinville,
  selectedNeighborhoods: [...props.professional.neighborhoods],
})
const saved = shallowRef(true)

function toggleService(name: string) {
  saved.value = false
  if (form.selectedServices.includes(name)) {
    if (form.selectedServices.length === 1) return
    form.selectedServices = form.selectedServices.filter((item) => item !== name)
    if (form.primaryService === name) form.primaryService = form.selectedServices[0] ?? ''
  } else {
    form.selectedServices.push(name)
  }
}

function toggleNeighborhood(name: string) {
  saved.value = false
  form.selectedNeighborhoods = form.selectedNeighborhoods.includes(name)
    ? form.selectedNeighborhoods.filter((item) => item !== name)
    : [...form.selectedNeighborhoods, name]
}

function save() {
  saved.value = true
  emit('save')
}
</script>

<template>
  <form class="profile-editor" @input="saved = false" @submit.prevent="save">
    <section class="editor-section">
      <header><div><span>01</span><div><h2>Identidade profissional</h2><p>Como clientes verão e entenderão seu trabalho.</p></div></div><em>Obrigatório</em></header>
      <div class="editor-grid">
        <DesignSystemFormField label="Nome de exibição"><input v-model="form.name" required maxlength="70"></DesignSystemFormField>
        <DesignSystemFormField label="WhatsApp profissional" hint="O número não aparece como texto público."><div class="phone-field"><em>+55</em><input v-model="form.whatsapp" required type="tel"></div></DesignSystemFormField>
        <DesignSystemFormField class="editor-grid__full" label="Frase de apresentação"><template #label>Frase de apresentação <em>{{ form.headline.length }}/120</em></template><input v-model="form.headline" required maxlength="120"></DesignSystemFormField>
        <DesignSystemFormField class="editor-grid__full" label="Conte um pouco sobre seu trabalho"><template #label>Conte um pouco sobre seu trabalho <em>{{ form.bio.length }}/500</em></template><textarea v-model="form.bio" required maxlength="500" /></DesignSystemFormField>
        <DesignSystemFormField label="Anos de experiência" hint="Será mostrado como “experiência declarada”."><input v-model.number="form.yearsExperience" type="number" min="0" max="70"></DesignSystemFormField>
      </div>
    </section>

    <section class="editor-section">
      <header><div><span>02</span><div><h2>Serviços</h2><p>Escolha no catálogo o que você realmente oferece.</p></div></div><em>1 principal</em></header>
      <div class="service-picker">
        <button
          v-for="service in services"
          :key="service.id"
          type="button"
          :class="{ selected: form.selectedServices.includes(service.name) }"
          @click="toggleService(service.name)"
        >
          <span><UIcon :name="service.icon" /></span>
          <strong>{{ service.name }}</strong>
          <UIcon :name="form.selectedServices.includes(service.name) ? 'i-lucide-circle-check' : 'i-lucide-circle-plus'" />
        </button>
      </div>
      <DesignSystemFormField class="primary-service" label="Serviço principal do perfil"><select v-model="form.primaryService"><option v-for="service in form.selectedServices" :key="service">{{ service }}</option></select></DesignSystemFormField>
    </section>

    <section class="editor-section">
      <header><div><span>03</span><div><h2>Área de atendimento</h2><p>O Finder usa essas escolhas para mostrar seu perfil.</p></div></div><em>Joinville</em></header>
      <label class="all-city">
        <input v-model="form.allJoinville" type="checkbox" @change="saved = false">
        <span><strong>Atendo em toda Joinville</strong><small>Seu perfil poderá aparecer em buscas de qualquer bairro.</small></span>
        <UIcon name="i-lucide-map" />
      </label>
      <div v-if="!form.allJoinville" class="neighborhood-picker">
        <button v-for="item in neighborhoods" :key="item.code" type="button" :class="{ selected: form.selectedNeighborhoods.includes(item.name) }" @click="toggleNeighborhood(item.name)">
          <UIcon :name="form.selectedNeighborhoods.includes(item.name) ? 'i-lucide-check' : 'i-lucide-plus'" /> {{ item.name }}
        </button>
      </div>
    </section>

    <div class="editor-savebar">
      <span><UIcon :name="saved ? 'i-lucide-cloud-check' : 'i-lucide-circle-dot'" /> {{ saved ? 'Alterações salvas' : 'Há alterações não salvas' }}</span>
      <div><UButton type="button" color="neutral" variant="outline" to="/profissionais/marina-alves">Pré-visualizar</UButton><UButton type="submit" color="primary" :disabled="saved">Salvar alterações</UButton></div>
    </div>
  </form>
</template>

<style scoped>
.profile-editor { display: grid; gap: 18px; }.editor-section { padding: 26px; border: 1px solid var(--line); border-radius: 18px; background: white; }.editor-section header { display: flex; justify-content: space-between; align-items: start; padding-bottom: 20px; margin-bottom: 22px; border-bottom: 1px solid var(--line); }.editor-section header > div { display: flex; align-items: center; gap: 12px; }.editor-section header > div > span { display: grid; place-items: center; width: 34px; height: 34px; border-radius: 10px; background: var(--mint); color: #397a69; font-family: Georgia, serif; font-size: .84rem; }.editor-section h2, .editor-section p { margin: 0; }.editor-section h2 { font-family: Georgia, serif; font-size: 1.35rem; }.editor-section p { margin-top: 3px; color: var(--ink-soft); font-size: .86rem; }.editor-section header > em { padding: 5px 7px; border-radius: 7px; background: #efeee9; color: var(--ink-soft); font-size: .82rem; font-style: normal; font-weight: 900; text-transform: uppercase; }.editor-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 18px; }.editor-grid__full { grid-column: 1 / -1; }.phone-field { display: grid; grid-template-columns: auto 1fr; border: 1px solid var(--line); border-radius: 10px; background: #fdfcf9; }.phone-field em { padding: 11px; border-right: 1px solid var(--line); color: var(--ink-soft); font-size: .82rem; font-style: normal; }.phone-field input { border: 0; }.service-picker { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }.service-picker button { display: grid; grid-template-columns: auto 1fr auto; align-items: center; gap: 8px; padding: 11px; border: 1px solid var(--line); border-radius: 11px; background: #fdfcf9; color: var(--ink); text-align: left; cursor: pointer; }.service-picker button.selected { border-color: #86b9a9; background: #ebf6f2; }.service-picker button > span { display: grid; place-items: center; width: 29px; height: 29px; border-radius: 8px; background: var(--paper-strong); color: #397a69; }.service-picker strong { font-size: .86rem; }.service-picker button > svg { color: #82928d; }.service-picker button.selected > svg { color: #397a69; }.primary-service { max-width: 320px; margin-top: 18px; }.all-city { display: grid; grid-template-columns: auto 1fr auto; align-items: center; gap: 11px; padding: 15px; border: 1px solid #9ec8bb; border-radius: 13px; background: #edf7f3; cursor: pointer; }.all-city input { width: 17px; height: 17px; accent-color: #397a69; }.all-city strong, .all-city small { display: block; }.all-city strong { font-size: .82rem; }.all-city small { margin-top: 3px; color: var(--ink-soft); font-size: .84rem; }.all-city > svg { color: #397a69; font-size: 1.3rem; }.neighborhood-picker { display: flex; flex-wrap: wrap; gap: 7px; margin-top: 16px; }.neighborhood-picker button { display: flex; align-items: center; gap: 5px; padding: 8px 10px; border: 1px solid var(--line); border-radius: 9px; background: white; color: var(--ink); font-size: .86rem; cursor: pointer; }.neighborhood-picker button.selected { border-color: #9ec8bb; background: var(--mint); color: #2d695a; }.editor-savebar { position: sticky; z-index: 20; bottom: 14px; display: flex; justify-content: space-between; align-items: center; gap: 15px; padding: 12px 14px; border: 1px solid var(--line); border-radius: 15px; background: rgba(255,255,255,.95); box-shadow: var(--shadow-lg); backdrop-filter: blur(14px); }.editor-savebar > span { display: flex; align-items: center; gap: 6px; color: var(--ink-soft); font-size: .86rem; font-weight: 700; }.editor-savebar > div { display: flex; gap: 8px; }
@media (max-width: 750px) { .editor-grid, .service-picker { grid-template-columns: 1fr; }.editor-grid__full { grid-column: auto; }.editor-savebar { display: grid; }.editor-savebar > div { justify-content: stretch; }.editor-savebar > div > * { flex: 1; justify-content: center; } }
</style>
