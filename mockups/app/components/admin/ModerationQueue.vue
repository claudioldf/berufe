<script setup lang="ts">
import { computed, ref, shallowRef } from 'vue'
import moderationData from '../../../data/moderation.json'
import { useMockupApp } from '~/composables/useMockupApp'

interface QueueItem {
  id: string
  type: string
  title: string
  subtitle: string
  submittedAt: string
  age: string
  priority: string
  details: string
  preview: string
}

const { showToast } = useMockupApp()
const queue = ref<QueueItem[]>(moderationData.queue)
const selectedId = shallowRef(queue.value[0]?.id ?? '')
const typeFilter = shallowRef('Todos')
const rejectionOpen = shallowRef(false)
const rejectionReason = shallowRef('')
const types = computed(() => ['Todos', ...new Set(queue.value.map((item) => item.type))])
const filteredQueue = computed(() => typeFilter.value === 'Todos' ? queue.value : queue.value.filter((item) => item.type === typeFilter.value))
const selected = computed(() => queue.value.find((item) => item.id === selectedId.value) ?? filteredQueue.value[0])

function decide(action: 'approved' | 'rejected') {
  const item = selected.value
  if (!item) return
  queue.value = queue.value.filter((queueItem) => queueItem.id !== item.id)
  selectedId.value = queue.value[0]?.id ?? ''
  rejectionOpen.value = false
  rejectionReason.value = ''
  showToast({
    title: action === 'approved' ? 'Item aprovado' : 'Item rejeitado',
    description: `A decisão sobre “${item.title}” foi registrada na auditoria.`,
  })
}
</script>

<template>
  <div class="moderation">
    <div class="moderation__toolbar">
      <div class="moderation__filters">
        <button v-for="type in types" :key="type" type="button" :class="{ active: typeFilter === type }" @click="typeFilter = type">{{ type }}</button>
      </div>
      <label><UIcon name="i-lucide-search" /><input type="search" placeholder="Buscar na fila..."></label>
    </div>

    <div v-if="queue.length" class="moderation__workspace">
      <section class="moderation__list" aria-label="Fila de moderação">
        <button v-for="item in filteredQueue" :key="item.id" type="button" :class="{ active: selected?.id === item.id, priority: item.priority === 'high' }" @click="selectedId = item.id">
          <span class="moderation__type-icon"><UIcon :name="item.type === 'Perfil' ? 'i-lucide-user-round' : item.type === 'Verificação' ? 'i-lucide-shield-check' : item.type === 'Portfólio' ? 'i-lucide-image' : item.type === 'Recomendação' ? 'i-lucide-heart' : item.type === 'Relacionamento' ? 'i-lucide-handshake' : 'i-lucide-flag'" /></span>
          <span><em>{{ item.type }}</em><strong>{{ item.title }}</strong><small>{{ item.subtitle }}</small></span>
          <span class="moderation__age">{{ item.age }}</span>
        </button>
        <div v-if="!filteredQueue.length" class="moderation__filtered-empty">Nenhum item neste filtro.</div>
      </section>

      <section v-if="selected" class="moderation__review">
        <header><div><span>{{ selected.type }}</span><h2>{{ selected.title }}</h2><p>{{ selected.subtitle }}</p></div><button type="button" aria-label="Mais opções"><UIcon name="i-lucide-ellipsis" /></button></header>
        <div class="moderation__meta"><span><UIcon name="i-lucide-clock-3" /> Enviado {{ selected.submittedAt }}</span><span><UIcon name="i-lucide-fingerprint" /> {{ selected.id }}</span></div>
        <div class="moderation__review-block"><span>Contexto da análise</span><p>{{ selected.details }}</p></div>
        <div class="moderation__preview"><div><UIcon :name="selected.type === 'Verificação' ? 'i-lucide-file-lock-2' : 'i-lucide-scan-search'" /></div><span><small>Conteúdo enviado</small><p>{{ selected.preview }}</p></span></div>
        <div v-if="selected.type === 'Verificação'" class="moderation__private-warning"><UIcon name="i-lucide-lock-keyhole" /><span><strong>Acesso a arquivo restrito</strong><small>A abertura do documento será registrada com seu usuário, horário e solicitação.</small></span><UButton size="sm" color="neutral" variant="outline">Abrir documento</UButton></div>
        <label class="moderation__note"><span>Nota interna opcional</span><textarea maxlength="500" placeholder="Adicione contexto para a trilha de auditoria..."></textarea></label>
        <footer><UButton color="error" variant="outline" icon="i-lucide-x" @click="rejectionOpen = true">Rejeitar</UButton><UButton color="primary" icon="i-lucide-check" @click="decide('approved')">Aprovar e publicar</UButton></footer>
      </section>
    </div>

    <div v-else class="moderation__empty surface-card"><span><UIcon name="i-lucide-party-popper" /></span><h2>Fila em dia.</h2><p>Todos os itens pendentes foram analisados nesta sessão do protótipo.</p></div>

    <UModal v-model:open="rejectionOpen" title="Rejeitar conteúdo" description="A justificativa será privada e ficará visível ao profissional quando aplicável.">
      <template #body><label class="rejection-form"><span>Motivo da rejeição</span><textarea v-model="rejectionReason" required minlength="10" maxlength="500" placeholder="Explique o que precisa ser corrigido..."></textarea><small>{{ rejectionReason.length }}/500</small></label></template>
      <template #footer><UButton color="neutral" variant="ghost" @click="rejectionOpen = false">Cancelar</UButton><UButton color="error" :disabled="rejectionReason.length < 10" @click="decide('rejected')">Confirmar rejeição</UButton></template>
    </UModal>
  </div>
</template>

<style scoped>
.moderation { display: grid; gap: 14px; }.moderation__toolbar { display: flex; justify-content: space-between; align-items: center; gap: 20px; }.moderation__filters { display: flex; overflow-x: auto; gap: 5px; }.moderation__filters button { padding: 7px 10px; border: 1px solid var(--line); border-radius: 8px; background: white; color: var(--ink-soft); font-size: .58rem; font-weight: 800; white-space: nowrap; cursor: pointer; }.moderation__filters button.active { border-color: #397a69; background: #397a69; color: white; }.moderation__toolbar label { display: flex; align-items: center; gap: 7px; width: 220px; padding: 8px 10px; border: 1px solid var(--line); border-radius: 9px; background: white; color: var(--ink-soft); }.moderation__toolbar input { min-width: 0; width: 100%; border: 0; outline: 0; font-size: .63rem; }.moderation__workspace { display: grid; grid-template-columns: minmax(280px, .65fr) minmax(430px, 1.35fr); overflow: hidden; min-height: 610px; border: 1px solid var(--line); border-radius: 18px; background: white; }.moderation__list { overflow-y: auto; border-right: 1px solid var(--line); background: #f8f7f3; }.moderation__list > button { display: grid; grid-template-columns: auto 1fr auto; gap: 10px; width: 100%; padding: 15px 13px; border: 0; border-bottom: 1px solid var(--line); border-left: 3px solid transparent; background: transparent; color: var(--ink); text-align: left; cursor: pointer; }.moderation__list > button:hover { background: white; }.moderation__list > button.active { border-left-color: #397a69; background: white; }.moderation__list > button.priority { border-left-color: var(--coral); }.moderation__type-icon { display: grid; place-items: center; width: 34px; height: 34px; border-radius: 10px; background: var(--mint); color: #397a69; }.moderation__list em, .moderation__list strong, .moderation__list small { display: block; }.moderation__list em { color: #397a69; font-size: .5rem; font-style: normal; font-weight: 900; text-transform: uppercase; }.moderation__list strong { overflow: hidden; margin-top: 3px; font-size: .65rem; text-overflow: ellipsis; white-space: nowrap; }.moderation__list small { margin-top: 3px; color: var(--ink-soft); font-size: .55rem; }.moderation__age { color: var(--ink-soft); font-size: .5rem; }.moderation__filtered-empty { padding: 30px; color: var(--ink-soft); font-size: .68rem; text-align: center; }.moderation__review { display: flex; flex-direction: column; min-width: 0; padding: 24px; }.moderation__review > header { display: flex; justify-content: space-between; gap: 20px; }.moderation__review > header span { color: #397a69; font-size: .55rem; font-weight: 900; text-transform: uppercase; }.moderation__review > header h2 { margin: 4px 0 0; font-family: Georgia, serif; font-size: 1.65rem; }.moderation__review > header p { margin: 4px 0 0; color: var(--ink-soft); font-size: .63rem; }.moderation__review > header button { display: grid; place-items: center; width: 32px; height: 32px; border: 1px solid var(--line); border-radius: 9px; background: white; cursor: pointer; }.moderation__meta { display: flex; gap: 16px; padding: 14px 0; margin: 17px 0; border-block: 1px solid var(--line); color: var(--ink-soft); font-size: .56rem; }.moderation__meta span { display: flex; align-items: center; gap: 4px; }.moderation__review-block > span, .moderation__note > span { color: var(--ink-soft); font-size: .53rem; font-weight: 900; text-transform: uppercase; }.moderation__review-block p { margin: 5px 0 0; font-size: .68rem; line-height: 1.55; }.moderation__preview { display: grid; grid-template-columns: auto 1fr; gap: 12px; align-items: center; padding: 17px; margin-top: 16px; border: 1px solid var(--line); border-radius: 13px; background: #f8f7f3; }.moderation__preview > div { display: grid; place-items: center; width: 48px; height: 48px; border-radius: 12px; background: white; color: #397a69; font-size: 1.25rem; }.moderation__preview small { color: var(--ink-soft); font-size: .52rem; font-weight: 850; text-transform: uppercase; }.moderation__preview p { margin: 5px 0 0; font-family: Georgia, serif; font-size: .83rem; line-height: 1.4; }.moderation__private-warning { display: grid; grid-template-columns: auto 1fr auto; align-items: center; gap: 10px; padding: 13px; margin-top: 13px; border: 1px solid #eccf8c; border-radius: 11px; background: #fff9e8; color: #8c671b; }.moderation__private-warning strong, .moderation__private-warning small { display: block; }.moderation__private-warning strong { font-size: .62rem; }.moderation__private-warning small { margin-top: 2px; color: #8d7a50; font-size: .53rem; }.moderation__note { display: grid; gap: 6px; margin-top: 17px; }.moderation__note textarea { min-height: 75px; padding: 10px; border: 1px solid var(--line); border-radius: 9px; outline: none; font-size: .63rem; resize: vertical; }.moderation__review > footer { display: flex; justify-content: flex-end; gap: 7px; padding-top: 18px; margin-top: auto; border-top: 1px solid var(--line); }.moderation__empty { padding: 70px 30px; text-align: center; }.moderation__empty > span { display: grid; place-items: center; width: 60px; height: 60px; margin: auto; border-radius: 18px; background: var(--mint); color: #397a69; font-size: 1.5rem; }.moderation__empty h2 { margin: 15px 0 4px; font-family: Georgia, serif; font-size: 2rem; }.moderation__empty p { margin: 0; color: var(--ink-soft); font-size: .7rem; }.rejection-form { display: grid; gap: 7px; }.rejection-form > span { font-size: .67rem; font-weight: 850; }.rejection-form textarea { min-height: 130px; padding: 11px; border: 1px solid var(--line); border-radius: 10px; outline: none; resize: vertical; }.rejection-form small { justify-self: end; color: var(--ink-soft); font-size: .55rem; }
@media (max-width: 850px) { .moderation__workspace { grid-template-columns: 1fr; }.moderation__list { max-height: 320px; border-right: 0; border-bottom: 1px solid var(--line); }.moderation__toolbar { display: grid; }.moderation__toolbar label { width: 100%; } } @media (max-width: 550px) { .moderation__review { padding: 17px; }.moderation__review > footer { flex-wrap: wrap; }.moderation__private-warning { grid-template-columns: auto 1fr; }.moderation__private-warning > :last-child { grid-column: 2; } }
</style>
