<script setup lang="ts">
import { shallowRef } from 'vue'
import type { PortfolioItem } from '~/types'

defineProps<{ items: PortfolioItem[] }>()
const emit = defineEmits<{ added: [] }>()
const uploadOpen = shallowRef(false)
const title = shallowRef('')
</script>

<template>
  <div class="portfolio-manager">
    <section class="portfolio-manager__intro surface-card">
      <div><p class="eyebrow">Seu trabalho na prática</p><h2>Portfólio</h2><p>Adicione até 12 trabalhos. Novos itens entram em análise antes de aparecer no perfil público.</p></div>
      <UButton color="primary" icon="i-lucide-image-plus" @click="uploadOpen = true">Adicionar trabalho</UButton>
    </section>
    <div class="portfolio-manager__grid">
      <article v-for="(item, index) in items" :key="item.id">
        <img :src="item.image" :alt="item.title">
        <div><span><strong>{{ item.title }}</strong><small>{{ item.service }}</small></span><em>Aprovado</em></div>
        <button type="button" aria-label="Opções"><UIcon name="i-lucide-ellipsis" /></button>
        <span class="portfolio-manager__order"><UIcon name="i-lucide-grip-vertical" /> {{ index + 1 }}</span>
      </article>
      <button v-if="items.length < 12" class="portfolio-manager__add" type="button" @click="uploadOpen = true"><UIcon name="i-lucide-plus" /><strong>Adicionar trabalho</strong><small>{{ items.length }} de 12 publicados</small></button>
    </div>
    <UModal v-model:open="uploadOpen" title="Adicionar trabalho" description="A imagem ficará privada até a aprovação.">
      <template #body>
        <form id="portfolio-upload" class="portfolio-upload" @submit.prevent="uploadOpen = false; emit('added')">
          <label class="portfolio-upload__drop"><UIcon name="i-lucide-cloud-upload" /><strong>Arraste uma foto ou selecione do dispositivo</strong><small>JPG, PNG ou WebP · até 8 MB</small><input type="file" accept="image/jpeg,image/png,image/webp"></label>
          <label>Título do trabalho<input v-model="title" required maxlength="80" placeholder="Ex.: Iluminação da cozinha"></label>
          <label>Serviço<select required><option>Eletricista</option><option>Marido de aluguel</option></select></label>
          <label>Descrição opcional<textarea maxlength="300" placeholder="Explique brevemente o que foi feito..."></textarea></label>
        </form>
      </template>
      <template #footer><UButton color="neutral" variant="ghost" @click="uploadOpen = false">Cancelar</UButton><UButton type="submit" form="portfolio-upload" color="primary" :disabled="!title">Enviar para análise</UButton></template>
    </UModal>
  </div>
</template>

<style scoped>
.portfolio-manager { display: grid; gap: 18px; }.portfolio-manager__intro { display: flex; justify-content: space-between; align-items: end; gap: 30px; padding: 26px; }.portfolio-manager__intro h2 { margin: 0; font-family: Georgia, serif; font-size: 2rem; }.portfolio-manager__intro p:last-child { max-width: 580px; margin: 7px 0 0; color: var(--ink-soft); font-size: .82rem; line-height: 1.5; }.portfolio-manager__grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; }.portfolio-manager__grid article { position: relative; overflow: hidden; border: 1px solid var(--line); border-radius: 16px; background: white; }.portfolio-manager__grid article > img { width: 100%; height: 190px; object-fit: cover; }.portfolio-manager__grid article > div { display: flex; justify-content: space-between; gap: 8px; padding: 13px; }.portfolio-manager__grid strong, .portfolio-manager__grid small { display: block; }.portfolio-manager__grid strong { font-size: .82rem; }.portfolio-manager__grid small { margin-top: 3px; color: var(--ink-soft); font-size: .82rem; }.portfolio-manager__grid em { align-self: start; padding: 4px 6px; border-radius: 6px; background: #e5f3ee; color: #2e6f5e; font-size: .82rem; font-style: normal; font-weight: 900; }.portfolio-manager__grid article > button { position: absolute; top: 9px; right: 9px; display: grid; place-items: center; width: 31px; height: 31px; border: 0; border-radius: 9px; background: rgba(255,255,255,.92); cursor: pointer; }.portfolio-manager__order { position: absolute; top: 9px; left: 9px; display: flex; align-items: center; gap: 3px; padding: 6px 7px; border-radius: 8px; background: rgba(23,53,47,.82); color: white; font-size: .82rem; }.portfolio-manager__add { min-height: 260px; display: grid; place-items: center; align-content: center; gap: 5px; border: 1px dashed #9ab9af; border-radius: 16px; background: transparent; color: #397a69; cursor: pointer; }.portfolio-manager__add > svg { margin-bottom: 5px; font-size: 1.5rem; }.portfolio-manager__add small { color: var(--ink-soft); }.portfolio-upload { display: grid; gap: 14px; }.portfolio-upload label { display: grid; gap: 6px; color: var(--ink); font-size: .86rem; font-weight: 800; }.portfolio-upload input, .portfolio-upload select, .portfolio-upload textarea { padding: 10px 11px; border: 1px solid var(--line); border-radius: 9px; outline: 0; }.portfolio-upload textarea { min-height: 90px; }.portfolio-upload__drop { position: relative; place-items: center; padding: 30px; border: 1px dashed #8eb6aa; border-radius: 13px; background: #eff7f4; text-align: center; cursor: pointer; }.portfolio-upload__drop svg { color: #397a69; font-size: 1.8rem; }.portfolio-upload__drop small { color: var(--ink-soft); }.portfolio-upload__drop input { position: absolute; inset: 0; opacity: 0; cursor: pointer; }
@media (max-width: 780px) { .portfolio-manager__grid { grid-template-columns: repeat(2, 1fr); }.portfolio-manager__intro { display: grid; } } @media (max-width: 500px) { .portfolio-manager__grid { grid-template-columns: 1fr; } }
</style>
