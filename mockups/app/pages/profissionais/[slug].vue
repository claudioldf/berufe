<script setup lang="ts">
import { computed, shallowRef } from 'vue'
import professionalsData from '../../../data/professionals.json'
import type { Professional } from '~/types'
import { useMockupApp } from '~/composables/useMockupApp'

const route = useRoute()
const { share, showToast } = useMockupApp()
const professionals = professionalsData as Professional[]
const professional = computed(() => professionals.find((item) => item.slug === route.params.slug))
const reportOpen = shallowRef(false)
const reportReason = shallowRef('informacao-incorreta')
const reportDetails = shallowRef('')
const activePortfolio = shallowRef(0)
const portfolioOpen = shallowRef(false)
const selectedPortfolio = computed(() => professional.value?.portfolio[activePortfolio.value])

if (!professional.value) {
  throw createError({ statusCode: 404, statusMessage: 'Profissional não encontrado' })
}

useSeoMeta({
  title: () => `${professional.value?.name} — ${professional.value?.primaryService}`,
  description: () => professional.value?.headline,
})

function contact() {
  if (!professional.value) return
  const text = encodeURIComponent(`Olá, ${professional.value.name}! Encontrei seu perfil na Berufe e gostaria de conversar sobre ${professional.value.primaryService}.`)
  showToast({ title: 'Abrindo o WhatsApp', description: 'A conversa acontece diretamente com o profissional.' })
  if (import.meta.client) window.open(`https://wa.me/${professional.value.whatsapp}?text=${text}`, '_blank', 'noopener,noreferrer')
}

async function shareProfile() {
  if (!professional.value) return
  await share({
    title: `${professional.value.name} na Berufe`,
    text: `Veja o perfil de ${professional.value.name}, ${professional.value.primaryService.toLocaleLowerCase('pt-BR')} em Joinville.`,
    url: `https://berufe.com.br/profissionais/${professional.value.slug}`,
  })
}

function submitReport() {
  reportOpen.value = false
  reportDetails.value = ''
  showToast({ title: 'Relato recebido', description: 'A equipe Berufe fará uma análise privada.' })
}
</script>

<template>
  <div v-if="professional" class="profile-page">
    <section class="profile-hero">
      <div class="page-container">
        <div class="profile-hero__crumbs">
          <NuxtLink :to="`/encontrar?servico=${professional.primaryServiceSlug}&bairro=all`"><UIcon name="i-lucide-arrow-left" /> Voltar aos resultados</NuxtLink>
          <button type="button" @click="shareProfile"><UIcon name="i-lucide-share-2" /> Compartilhar perfil</button>
        </div>
        <div class="profile-hero__grid">
          <div class="profile-hero__identity">
            <div class="profile-hero__avatar">
              <img :src="professional.avatar" :alt="`Foto de ${professional.name}`">
              <span><UIcon name="i-lucide-badge-check" /></span>
            </div>
            <div>
              <p class="profile-hero__service">{{ professional.primaryService }}</p>
              <h1>{{ professional.name }}</h1>
              <p class="profile-hero__headline">{{ professional.headline }}</p>
              <div class="profile-hero__meta">
                <span><UIcon name="i-lucide-map-pin" /> {{ professional.allJoinville ? 'Atende toda Joinville' : professional.neighborhoods.slice(0, 4).join(', ') }}</span>
                <span><UIcon name="i-lucide-briefcase-business" /> {{ professional.yearsExperience }} anos de experiência declarada</span>
              </div>
            </div>
          </div>
          <aside class="profile-hero__contact">
            <p>Fale diretamente com {{ professional.name.split(' ')[0] }}</p>
            <UButton color="primary" icon="i-lucide-message-circle" block @click="contact">
              Conversar no WhatsApp
            </UButton>
            <small><UIcon name="i-lucide-lock-keyhole" /> Sem cadastro e sem intermediários</small>
          </aside>
        </div>
      </div>
    </section>

    <section class="evidence-strip">
      <div class="page-container evidence-strip__inner">
        <div>
          <span class="evidence-strip__icon"><UIcon name="i-lucide-shield-check" /></span>
          <div><strong>Evidências conferidas pela Berufe</strong><small>Cada selo representa uma verificação específica.</small></div>
        </div>
        <div class="evidence-strip__badges">
          <PublicEvidenceBadge v-for="item in professional.evidence" :key="item.id" :evidence="item" />
        </div>
      </div>
    </section>

    <div class="page-container profile-content">
      <main>
        <section class="profile-section profile-about">
          <p class="eyebrow">Sobre o trabalho</p>
          <h2>Experiência que dá<br>tranquilidade.</h2>
          <p>{{ professional.bio }}</p>
          <div class="profile-about__services">
            <div v-for="(service, index) in professional.services" :key="service">
              <span><UIcon :name="index === 0 ? 'i-lucide-zap' : 'i-lucide-wrench'" /></span>
              <div><strong>{{ service }}</strong><small>{{ professional.serviceNotes[index] ?? 'Serviço residencial' }}</small></div>
              <em v-if="index === 0">Principal</em>
            </div>
          </div>
          <div class="declaration-note"><UIcon name="i-lucide-info" /> Os anos de experiência são declarados pelo profissional e não representam uma verificação da Berufe.</div>
        </section>

        <section class="profile-section portfolio-section">
          <div class="profile-section__heading">
            <div><p class="eyebrow">Portfólio aprovado</p><h2>Trabalhos que falam.</h2></div>
            <span>{{ professional.portfolio.length }} trabalhos</span>
          </div>
          <div class="portfolio-grid">
            <button
              v-for="(item, index) in professional.portfolio"
              :key="item.id"
              type="button"
              class="portfolio-item"
              @click="activePortfolio = index; portfolioOpen = true"
            >
              <img :src="item.image" :alt="item.title">
              <span class="portfolio-item__meta"><strong>{{ item.title }}</strong><small>{{ item.service }}</small></span>
              <UIcon name="i-lucide-expand" class="portfolio-item__expand" />
            </button>
          </div>
        </section>

        <section class="profile-section recommendations-section">
          <div class="profile-section__heading">
            <div><p class="eyebrow">Clientes anteriores</p><h2>Recomendações confirmadas.</h2></div>
            <span>{{ professional.recommendations.length }} serviços confirmados</span>
          </div>
          <div class="recommendations-list">
            <article v-for="recommendation in professional.recommendations" :key="recommendation.id">
              <UIcon name="i-lucide-quote" class="recommendation__quote" />
              <p>{{ recommendation.text }}</p>
              <footer>
                <span class="recommendation__avatar">{{ recommendation.clientName.charAt(0) }}</span>
                <div><strong>{{ recommendation.clientName }}</strong><small>{{ recommendation.service }} · {{ recommendation.period }}</small></div>
                <span v-if="recommendation.phoneConfirmed" class="recommendation__confirmed"><UIcon name="i-lucide-smartphone" /> Telefone confirmado</span>
              </footer>
            </article>
          </div>
        </section>

        <section class="profile-section relationships-section">
          <div class="profile-section__heading">
            <div><p class="eyebrow">Rede profissional</p><h2>Confiança entre quem faz.</h2></div>
            <span>{{ professional.relationships.length }} conexões confirmadas</span>
          </div>
          <div v-if="professional.relationships.length" class="relationships-list">
            <article v-for="relationship in professional.relationships" :key="relationship.id">
              <img :src="relationship.avatar" :alt="`Foto de ${relationship.professionalName}`">
              <div>
                <span class="relationship-type"><UIcon :name="relationship.type === 'worked_together' ? 'i-lucide-handshake' : 'i-lucide-heart'" /> {{ relationship.type === 'worked_together' ? 'Trabalharam juntos' : 'Recomendação profissional' }}</span>
                <p>“{{ relationship.note }}”</p>
                <NuxtLink :to="`/profissionais/${relationship.professionalSlug}`">{{ relationship.professionalName }} <UIcon name="i-lucide-arrow-up-right" /></NuxtLink>
              </div>
            </article>
          </div>
          <p v-else class="relationships-empty">Este profissional ainda não possui relações públicas aprovadas.</p>
        </section>

        <section class="profile-disclaimer">
          <UIcon name="i-lucide-shield-alert" />
          <div><strong>O que a verificação significa</strong><p>A Berufe confere evidências específicas e modera o conteúdo público, mas não garante a execução, o preço ou o resultado de um serviço. Combine escopo e condições diretamente com o profissional.</p></div>
        </section>

        <button class="report-link" type="button" @click="reportOpen = true"><UIcon name="i-lucide-flag" /> Relatar informação neste perfil</button>
      </main>

      <aside class="profile-sidebar">
        <div class="profile-sidebar__card surface-card">
          <p>Pronto para conversar?</p>
          <strong>Explique o que você precisa diretamente para {{ professional.name.split(' ')[0] }}.</strong>
          <UButton color="primary" icon="i-lucide-message-circle" block @click="contact">Chamar no WhatsApp</UButton>
          <small>A Berufe não lê nem armazena sua conversa.</small>
        </div>
        <div class="profile-sidebar__coverage">
          <strong><UIcon name="i-lucide-map" /> Área de atendimento</strong>
          <p v-if="professional.allJoinville">Toda Joinville</p>
          <div v-else><span v-for="neighborhood in professional.neighborhoods" :key="neighborhood">{{ neighborhood }}</span></div>
        </div>
      </aside>
    </div>

    <div class="mobile-contact">
      <div><small>{{ professional.primaryService }}</small><strong>{{ professional.name }}</strong></div>
      <UButton color="primary" icon="i-lucide-message-circle" @click="contact">WhatsApp</UButton>
    </div>

    <UModal v-model:open="reportOpen" title="Relatar conteúdo" description="Seu relato será privado e analisado pela equipe Berufe.">
      <template #body>
        <form id="report-form" class="report-form" @submit.prevent="submitReport">
          <label>Motivo<select v-model="reportReason"><option value="informacao-incorreta">Informação incorreta</option><option value="conteudo-inadequado">Conteúdo inadequado</option><option value="perfil-falso">Suspeita de perfil falso</option><option value="outro">Outro motivo</option></select></label>
          <label>Conte o que aconteceu<textarea v-model="reportDetails" required minlength="10" maxlength="500" placeholder="Descreva de forma objetiva..."></textarea></label>
          <small>Não inclua documentos, senhas ou outros dados sensíveis.</small>
        </form>
      </template>
      <template #footer>
        <UButton color="neutral" variant="ghost" @click="reportOpen = false">Cancelar</UButton>
        <UButton type="submit" form="report-form" color="primary" :disabled="reportDetails.length < 10">Enviar relato</UButton>
      </template>
    </UModal>

    <UModal
      v-model:open="portfolioOpen"
      :title="selectedPortfolio?.title"
      :description="selectedPortfolio?.service"
      :ui="{ content: 'sm:max-w-3xl' }"
    >
      <template #body>
        <div v-if="selectedPortfolio" class="portfolio-modal">
          <img :src="selectedPortfolio.image" :alt="selectedPortfolio.title">
          <p>{{ selectedPortfolio.description }}</p>
        </div>
      </template>
    </UModal>
  </div>
</template>

<style scoped>
.profile-hero { padding: 30px 0 44px; background: #17352f; color: white; }.profile-hero__crumbs { display: flex; justify-content: space-between; margin-bottom: 42px; }.profile-hero__crumbs a, .profile-hero__crumbs button { display: flex; align-items: center; gap: 7px; border: 0; background: transparent; color: rgba(255,255,255,.65); font-size: .7rem; font-weight: 700; text-decoration: none; cursor: pointer; }.profile-hero__grid { display: grid; grid-template-columns: 1fr 290px; gap: 60px; align-items: end; }.profile-hero__identity { display: grid; grid-template-columns: 165px 1fr; gap: 28px; align-items: center; }.profile-hero__avatar { position: relative; width: 165px; height: 185px; }.profile-hero__avatar img { width: 100%; height: 100%; border-radius: 70px 70px 18px 18px; object-fit: cover; }.profile-hero__avatar span { position: absolute; right: -8px; bottom: 15px; display: grid; place-items: center; width: 38px; height: 38px; border: 4px solid #17352f; border-radius: 99px; background: var(--coral); font-size: 1.1rem; }.profile-hero__service { margin: 0 0 7px; color: #a7d7c8; font-size: .72rem; font-weight: 900; letter-spacing: .1em; text-transform: uppercase; }.profile-hero h1 { margin: 0; font-family: Georgia, serif; font-size: clamp(2.7rem, 5vw, 5rem); font-weight: 500; letter-spacing: -.05em; line-height: .95; }.profile-hero__headline { max-width: 580px; margin: 15px 0; color: rgba(255,255,255,.68); line-height: 1.55; }.profile-hero__meta { display: flex; flex-wrap: wrap; gap: 16px; color: rgba(255,255,255,.76); font-size: .7rem; font-weight: 700; }.profile-hero__meta span { display: inline-flex; align-items: center; gap: 5px; }.profile-hero__contact { padding: 18px; border: 1px solid rgba(255,255,255,.13); border-radius: 18px; background: rgba(255,255,255,.07); }.profile-hero__contact p { margin: 0 0 12px; font-size: .8rem; font-weight: 800; }.profile-hero__contact small { display: flex; justify-content: center; align-items: center; gap: 4px; margin-top: 10px; color: rgba(255,255,255,.52); font-size: .75rem; }
.evidence-strip { border-bottom: 1px solid var(--line); background: white; }.evidence-strip__inner { display: flex; justify-content: space-between; align-items: center; gap: 22px; min-height: 100px; }.evidence-strip__inner > div { display: flex; align-items: center; gap: 12px; }.evidence-strip__icon { display: grid; place-items: center; width: 42px; height: 42px; border-radius: 12px; background: var(--mint); color: #397a69; font-size: 1.25rem; }.evidence-strip strong, .evidence-strip small { display: block; }.evidence-strip strong { font-size: .78rem; }.evidence-strip small { margin-top: 3px; color: var(--ink-soft); font-size: .78rem; }.evidence-strip__badges { justify-content: flex-end; flex-wrap: wrap; }
.profile-content { display: grid; grid-template-columns: minmax(0, 1fr) 280px; gap: 72px; padding-top: 70px; padding-bottom: 90px; }.profile-section { padding-bottom: 70px; margin-bottom: 70px; border-bottom: 1px solid var(--line); }.profile-section h2 { margin: 0; font-family: Georgia, serif; font-size: clamp(2.1rem, 4vw, 3.4rem); font-weight: 500; letter-spacing: -.04em; line-height: 1.02; }.profile-about > p:not(.eyebrow) { max-width: 700px; margin: 24px 0; color: var(--ink-soft); line-height: 1.78; }.profile-about__services { display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px; }.profile-about__services > div { display: grid; grid-template-columns: auto 1fr auto; align-items: center; gap: 10px; padding: 14px; border: 1px solid var(--line); border-radius: 14px; background: white; }.profile-about__services > div > span { display: grid; place-items: center; width: 38px; height: 38px; border-radius: 10px; background: var(--mint); color: #397a69; }.profile-about__services strong, .profile-about__services small { display: block; }.profile-about__services strong { font-size: .78rem; }.profile-about__services small { margin-top: 3px; color: var(--ink-soft); font-size: .78rem; }.profile-about__services em { padding: 4px 7px; border-radius: 6px; background: #fff0ec; color: #b34d39; font-size: .72rem; font-style: normal; font-weight: 900; text-transform: uppercase; }.declaration-note { display: flex; align-items: flex-start; gap: 7px; margin-top: 14px; color: var(--ink-soft); font-size: .78rem; line-height: 1.5; }.declaration-note svg { flex: 0 0 auto; margin-top: 2px; }
.profile-section__heading { display: flex; justify-content: space-between; align-items: end; gap: 20px; margin-bottom: 26px; }.profile-section__heading > span { color: var(--ink-soft); font-size: .78rem; font-weight: 800; }.portfolio-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 12px; }.portfolio-item { position: relative; overflow: hidden; min-height: 260px; padding: 0; border: 0; border-radius: 18px; background: var(--mint); color: white; text-align: left; cursor: zoom-in; }.portfolio-item img { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; transition: transform .3s ease; }.portfolio-item:hover img { transform: scale(1.03); }.portfolio-item::after { content: ""; position: absolute; inset: 35% 0 0; background: linear-gradient(transparent, rgba(7,28,24,.82)); }.portfolio-item__meta { position: absolute; z-index: 2; left: 17px; right: 45px; bottom: 16px; }.portfolio-item strong, .portfolio-item small { display: block; }.portfolio-item strong { font-family: Georgia, serif; font-size: 1.18rem; }.portfolio-item small { margin-top: 3px; color: rgba(255,255,255,.72); font-size: .78rem; }.portfolio-item__expand { position: absolute; z-index: 2; right: 16px; bottom: 18px; }
.recommendations-list { display: grid; gap: 10px; }.recommendations-list article { position: relative; padding: 24px; border: 1px solid var(--line); border-radius: 17px; background: white; }.recommendation__quote { color: var(--coral); font-size: 1.35rem; }.recommendations-list article > p { margin: 12px 0 20px; color: var(--ink); font-family: Georgia, serif; font-size: 1.12rem; line-height: 1.55; }.recommendations-list footer { display: grid; grid-template-columns: auto 1fr auto; align-items: center; gap: 10px; }.recommendation__avatar { display: grid; place-items: center; width: 35px; height: 35px; border-radius: 99px; background: var(--mint); color: #397a69; font-weight: 900; }.recommendations-list footer strong, .recommendations-list footer small { display: block; }.recommendations-list footer strong { font-size: .72rem; }.recommendations-list footer small { margin-top: 2px; color: var(--ink-soft); font-size: .75rem; }.recommendation__confirmed { display: flex; align-items: center; gap: 4px; color: #397a69; font-size: .75rem; font-weight: 800; }
.relationships-list { display: grid; gap: 10px; }.relationships-list article { display: grid; grid-template-columns: 74px 1fr; gap: 16px; padding: 18px; border-radius: 17px; background: #e7f3ef; }.relationships-list img { width: 74px; height: 74px; border-radius: 16px; object-fit: cover; }.relationship-type { display: flex; align-items: center; gap: 5px; color: #397a69; font-size: .75rem; font-weight: 900; text-transform: uppercase; }.relationships-list p { margin: 8px 0; font-family: Georgia, serif; font-size: .93rem; line-height: 1.45; }.relationships-list a { display: inline-flex; align-items: center; gap: 4px; color: var(--ink); font-size: .78rem; font-weight: 800; text-decoration: none; }.relationships-empty { color: var(--ink-soft); }
.profile-disclaimer { display: flex; gap: 14px; padding: 20px; border: 1px dashed #aacbbf; border-radius: 16px; background: #f2f8f6; }.profile-disclaimer > svg { flex: 0 0 auto; color: #397a69; font-size: 1.35rem; }.profile-disclaimer strong { font-size: .75rem; }.profile-disclaimer p { margin: 6px 0 0; color: var(--ink-soft); font-size: .78rem; line-height: 1.55; }.report-link { display: flex; align-items: center; gap: 5px; margin: 20px auto 0; border: 0; background: transparent; color: var(--ink-soft); font-size: .78rem; text-decoration: underline; cursor: pointer; }
.profile-sidebar { position: sticky; top: 24px; align-self: start; }.profile-sidebar__card { padding: 20px; }.profile-sidebar__card p { margin: 0 0 8px; color: #397a69; font-size: .78rem; font-weight: 900; text-transform: uppercase; }.profile-sidebar__card > strong { display: block; margin-bottom: 17px; font-family: Georgia, serif; font-size: 1.2rem; line-height: 1.35; }.profile-sidebar__card small { display: block; margin-top: 10px; color: var(--ink-soft); font-size: .75rem; text-align: center; }.profile-sidebar__coverage { margin-top: 16px; padding: 18px; border-top: 1px solid var(--line); }.profile-sidebar__coverage strong { display: flex; align-items: center; gap: 6px; font-size: .72rem; }.profile-sidebar__coverage p { color: var(--ink-soft); font-size: .72rem; }.profile-sidebar__coverage div { display: flex; flex-wrap: wrap; gap: 5px; margin-top: 10px; }.profile-sidebar__coverage span { padding: 5px 7px; border-radius: 7px; background: var(--paper-strong); color: var(--ink-soft); font-size: .72rem; }.mobile-contact { display: none; }
.report-form { display: grid; gap: 16px; }.report-form label { display: grid; gap: 7px; color: var(--ink); font-size: .72rem; font-weight: 800; }.report-form select, .report-form textarea { width: 100%; padding: 11px 12px; border: 1px solid var(--line); border-radius: 10px; background: white; outline: none; }.report-form textarea { min-height: 120px; resize: vertical; }.report-form small { color: var(--ink-soft); font-size: .75rem; }
.portfolio-modal img { width: 100%; max-height: 65vh; border-radius: 14px; object-fit: cover; }.portfolio-modal p { margin: 12px 0 0; color: var(--ink-soft); line-height: 1.6; }
@media (max-width: 900px) { .profile-hero__grid { grid-template-columns: 1fr; }.profile-hero__contact { display: none; }.profile-content { grid-template-columns: 1fr; }.profile-sidebar { display: none; }.mobile-contact { position: fixed; z-index: 35; left: 12px; right: 12px; bottom: 12px; display: flex; justify-content: space-between; align-items: center; padding: 10px 10px 10px 14px; border: 1px solid rgba(255,255,255,.15); border-radius: 16px; background: #17352f; color: white; box-shadow: var(--shadow-lg); }.mobile-contact small, .mobile-contact strong { display: block; }.mobile-contact small { color: #a7d7c8; font-size: .72rem; text-transform: uppercase; }.mobile-contact strong { margin-top: 2px; font-size: .76rem; } }
@media (max-width: 680px) { .profile-hero__identity { grid-template-columns: 90px 1fr; gap: 16px; }.profile-hero__avatar { width: 90px; height: 108px; }.profile-hero__avatar span { right: -6px; width: 30px; height: 30px; }.profile-hero h1 { font-size: 2.5rem; }.profile-hero__headline { font-size: .8rem; }.profile-hero__meta { display: grid; gap: 6px; }.evidence-strip__inner { display: grid; padding-block: 18px; }.evidence-strip__badges { justify-content: flex-start; }.profile-content { padding-top: 50px; gap: 0; }.profile-about__services, .portfolio-grid { grid-template-columns: 1fr; }.profile-section__heading { display: grid; }.recommendations-list footer { grid-template-columns: auto 1fr; }.recommendation__confirmed { grid-column: 2; }.relationships-list article { grid-template-columns: 54px 1fr; }.relationships-list img { width: 54px; height: 54px; } }
</style>
