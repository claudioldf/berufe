<script setup lang="ts">
import { computed, reactive, shallowRef } from 'vue'
import type { Professional, Quote, QuoteItem } from '~/types'
import { useMockupApp } from '~/composables/useMockupApp'

const props = defineProps<{ initialQuote: Quote; professional: Professional }>()
const emit = defineEmits<{ shared: [] }>()
const { money, showToast } = useMockupApp()
const quote = reactive<Quote>({ ...props.initialQuote, items: props.initialQuote.items.map((item) => ({ ...item })) })
const previewOpen = shallowRef(false)
const shareOpen = shallowRef(false)
const isSaved = shallowRef(true)
const isShared = shallowRef(false)

const subtotal = computed(() => quote.items.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0))
const total = computed(() => Math.max(0, subtotal.value - quote.discount))

function addItem() {
  const nextId = Math.max(0, ...quote.items.map((item) => item.id)) + 1
  quote.items.push({ id: nextId, description: '', quantity: 1, unit: 'serviço', unitPrice: 0 })
  isSaved.value = false
}

function removeItem(id: number) {
  if (quote.items.length === 1) return
  quote.items = quote.items.filter((item) => item.id !== id)
  isSaved.value = false
}

function save() {
  isSaved.value = true
  showToast({ title: 'Rascunho salvo', description: `Orçamento #${quote.number} atualizado.` })
}

function shareQuote() {
  shareOpen.value = false
  isShared.value = true
  isSaved.value = true
  emit('shared')
}
</script>

<template>
  <div class="quote-builder">
    <div class="quote-builder__form">
      <section class="builder-card surface-card">
        <header><div><span>01</span><div><h2>Cliente e serviço</h2><p>Informações visíveis no link compartilhado.</p></div></div></header>
        <div class="builder-fields" @input="isSaved = false">
          <label><span>Nome do cliente</span><input v-model="quote.customerName" required maxlength="80"></label>
          <label><span>Válido até</span><input v-model="quote.validUntil" type="date"></label>
          <label class="builder-fields__full"><span>Descrição do serviço</span><input v-model="quote.serviceDescription" required maxlength="160"></label>
        </div>
      </section>

      <section class="builder-card surface-card">
        <header><div><span>02</span><div><h2>Itens do orçamento</h2><p>Os totais abaixo são uma prévia da interface.</p></div></div><UButton size="sm" color="neutral" variant="outline" icon="i-lucide-plus" @click="addItem">Adicionar item</UButton></header>
        <div class="quote-items">
          <div class="quote-item quote-item--head"><span>Descrição</span><span>Qtd.</span><span>Unidade</span><span>Valor unit.</span><span>Total</span><span /></div>
          <div v-for="(item, index) in quote.items" :key="item.id" class="quote-item" @input="isSaved = false">
            <label><span class="sr-only">Descrição</span><input v-model="item.description" :placeholder="`Item ${index + 1}`"></label>
            <label><span class="sr-only">Quantidade</span><input v-model.number="item.quantity" type="number" min="0.01" step="0.01"></label>
            <label><span class="sr-only">Unidade</span><select v-model="item.unit"><option>serviço</option><option>hora</option><option>ponto</option><option>m²</option><option>unidade</option></select></label>
            <label><span class="sr-only">Valor unitário</span><input v-model.number="item.unitPrice" type="number" min="0" step="0.01"></label>
            <strong>{{ money(item.quantity * item.unitPrice) }}</strong>
            <button type="button" aria-label="Remover item" :disabled="quote.items.length === 1" @click="removeItem(item.id)"><UIcon name="i-lucide-trash-2" /></button>
          </div>
        </div>
        <UButton class="quote-items__mobile-add" color="neutral" variant="outline" block icon="i-lucide-plus" @click="addItem">Adicionar item</UButton>
        <div class="builder-total">
          <div><span>Subtotal</span><strong>{{ money(subtotal) }}</strong></div>
          <label><span>Desconto</span><div><em>R$</em><input v-model.number="quote.discount" type="number" min="0" :max="subtotal" step="0.01" @input="isSaved = false"></div></label>
          <div><span>Total</span><strong>{{ money(total) }}</strong></div>
        </div>
      </section>

      <section class="builder-card surface-card">
        <header><div><span>03</span><div><h2>Observações</h2><p>Detalhes de prazo, materiais ou condições.</p></div></div></header>
        <label class="builder-notes"><span>Observações opcionais</span><textarea v-model="quote.notes" maxlength="700" @input="isSaved = false"></textarea></label>
      </section>

      <div class="quote-builder__savebar">
        <span><UIcon :name="isSaved ? 'i-lucide-cloud-check' : 'i-lucide-circle-dot'" /> {{ isSaved ? (isShared ? 'Compartilhado' : 'Rascunho salvo') : 'Alterações não salvas' }}</span>
        <div><UButton color="neutral" variant="outline" icon="i-lucide-eye" @click="previewOpen = true">Pré-visualizar</UButton><UButton color="primary" @click="save">Salvar rascunho</UButton><UButton color="secondary" icon="i-lucide-send" @click="shareOpen = true">Compartilhar</UButton></div>
      </div>
    </div>

    <aside class="quote-builder__preview"><div class="quote-builder__preview-label"><span>Prévia do cliente</span><em>Atualização instantânea</em></div><QuotesQuotePreview :quote="quote" :professional="professional" /></aside>

    <UModal v-model:open="previewOpen" title="Prévia do orçamento" description="Esta é a página que o cliente verá.">
      <template #body><QuotesQuotePreview :quote="quote" :professional="professional" customer-facing /></template>
    </UModal>

    <UModal v-model:open="shareOpen" title="Compartilhar orçamento" description="Ao compartilhar, o rascunho ganha um link seguro e muda para compartilhado.">
      <template #body>
        <div class="share-quote"><span><UIcon name="i-lucide-message-circle" /></span><div><strong>Enviar pelo WhatsApp</strong><p>A Berufe abre o aplicativo com uma mensagem e o link. Não enviamos nem lemos a conversa.</p></div></div>
        <div class="share-quote__link"><UIcon name="i-lucide-link" /><span>berufe.com.br/orcamento/••••••••1043</span></div>
      </template>
      <template #footer><UButton color="neutral" variant="ghost" @click="shareOpen = false">Cancelar</UButton><UButton color="primary" icon="i-lucide-message-circle" @click="shareQuote">Abrir WhatsApp</UButton></template>
    </UModal>
  </div>
</template>

<style scoped>
.quote-builder { display: grid; grid-template-columns: minmax(0, 1.25fr) minmax(330px, .75fr); gap: 24px; align-items: start; }.quote-builder__form { min-width: 0; display: grid; gap: 14px; }.builder-card { padding: 22px; }.builder-card > header { display: flex; justify-content: space-between; align-items: center; padding-bottom: 17px; margin-bottom: 18px; border-bottom: 1px solid var(--line); }.builder-card > header > div { display: flex; align-items: center; gap: 11px; }.builder-card > header > div > span { display: grid; place-items: center; width: 32px; height: 32px; border-radius: 9px; background: var(--mint); color: #397a69; font-family: Georgia, serif; font-size: .82rem; }.builder-card h2, .builder-card p { margin: 0; }.builder-card h2 { font-family: Georgia, serif; font-size: 1.25rem; }.builder-card p { margin-top: 3px; color: var(--ink-soft); font-size: .84rem; }.builder-fields { display: grid; grid-template-columns: 1fr .55fr; gap: 14px; }.builder-fields label, .builder-notes { display: grid; gap: 6px; }.builder-fields label > span, .builder-notes > span { color: var(--ink); font-size: .84rem; font-weight: 850; }.builder-fields input, .builder-notes textarea { width: 100%; padding: 10px 11px; border: 1px solid var(--line); border-radius: 9px; background: #fdfcf9; outline: none; font-size: .82rem; }.builder-fields__full { grid-column: 1 / -1; }.quote-items { overflow-x: auto; }.quote-item { display: grid; grid-template-columns: minmax(150px, 1.4fr) 64px 84px 95px 90px 30px; gap: 7px; align-items: center; min-width: 660px; padding: 8px 0; border-top: 1px solid var(--line); }.quote-item--head { border: 0; color: var(--ink-soft); font-size: .82rem; font-weight: 850; text-transform: uppercase; }.quote-item--head span:nth-child(n+2) { text-align: right; }.quote-item input, .quote-item select { width: 100%; padding: 8px; border: 1px solid var(--line); border-radius: 8px; background: #fdfcf9; font-size: .84rem; outline: none; }.quote-item strong { text-align: right; font-size: .84rem; }.quote-item button { display: grid; place-items: center; width: 27px; height: 27px; border: 0; border-radius: 7px; background: transparent; color: #a45245; cursor: pointer; }.quote-item button:disabled { opacity: .25; }.quote-items__mobile-add { display: none; }.builder-total { width: min(280px, 100%); margin: 18px 0 0 auto; }.builder-total > div, .builder-total > label { display: flex; justify-content: space-between; align-items: center; padding: 6px 0; color: var(--ink-soft); font-size: .84rem; }.builder-total > div:last-child { margin-top: 6px; padding-top: 12px; border-top: 2px solid var(--ink); color: var(--ink); font-size: .86rem; }.builder-total label > div { display: grid; grid-template-columns: auto 80px; align-items: center; border: 1px solid var(--line); border-radius: 8px; }.builder-total label em { padding-left: 8px; font-size: .82rem; font-style: normal; }.builder-total input { width: 80px; padding: 7px; border: 0; background: transparent; text-align: right; outline: none; font-size: .84rem; }.builder-notes textarea { min-height: 100px; resize: vertical; line-height: 1.5; }.quote-builder__savebar { position: sticky; z-index: 10; bottom: 12px; display: flex; justify-content: space-between; align-items: center; gap: 12px; padding: 11px 13px; border: 1px solid var(--line); border-radius: 14px; background: rgba(255,255,255,.96); box-shadow: var(--shadow-lg); }.quote-builder__savebar > span { display: flex; align-items: center; gap: 5px; color: var(--ink-soft); font-size: .82rem; }.quote-builder__savebar > div { display: flex; gap: 6px; }.quote-builder__preview { position: sticky; top: 20px; min-width: 0; }.quote-builder__preview-label { display: flex; justify-content: space-between; margin-bottom: 8px; color: var(--ink-soft); font-size: .82rem; font-weight: 800; text-transform: uppercase; }.quote-builder__preview-label em { color: #397a69; font-style: normal; text-transform: none; }.share-quote { display: flex; align-items: center; gap: 13px; padding: 16px; border-radius: 13px; background: #e9f5f1; }.share-quote > span { display: grid; place-items: center; width: 42px; height: 42px; border-radius: 12px; background: #397a69; color: white; font-size: 1.25rem; }.share-quote strong { font-size: .84rem; }.share-quote p { margin: 4px 0 0; color: var(--ink-soft); font-size: .84rem; line-height: 1.5; }.share-quote__link { display: flex; align-items: center; gap: 7px; margin-top: 12px; padding: 11px; border: 1px solid var(--line); border-radius: 10px; color: var(--ink-soft); font-size: .86rem; }
@media (max-width: 1000px) { .quote-builder { grid-template-columns: 1fr; }.quote-builder__preview { display: none; } } @media (max-width: 720px) { .builder-fields { grid-template-columns: 1fr; }.builder-fields__full { grid-column: auto; }.quote-builder__savebar { display: grid; }.quote-builder__savebar > div { flex-wrap: wrap; }.quote-builder__savebar > div > * { flex: 1; justify-content: center; }.builder-card { padding: 17px; } }
</style>
