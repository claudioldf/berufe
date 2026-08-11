<script setup lang="ts">
import catalogsData from '../../data/catalogs.json'
import professionalsData from '../../data/professionals.json'
import type { Professional, Service } from '~/types'

const router = useRouter()
const services = catalogsData.services as Service[]
const featured = (professionalsData as Professional[]).slice(0, 3)

useSeoMeta({
  title: 'Profissionais de confiança em Joinville',
  description: 'Encontre profissionais verificados para reformas e manutenção residencial em Joinville.',
})

function findService(query: string) {
  const normalized = query.toLocaleLowerCase('pt-BR')
  return services.find((service) => service.name.toLocaleLowerCase('pt-BR') === normalized)
    ?? services.find((service) => service.aliases.some((alias) => alias.includes(normalized) || normalized.includes(alias)))
}

async function search(payload: { service: string; neighborhood: string }) {
  const service = findService(payload.service)
  await router.push({
    path: '/encontrar',
    query: {
      servico: service?.slug ?? payload.service,
      bairro: payload.neighborhood,
    },
  })
}
</script>

<template>
  <div>
    <section class="hero">
      <div class="hero__shape hero__shape--one" />
      <div class="hero__shape hero__shape--two" />
      <div class="hero__inner page-container">
        <div class="hero__copy">
          <p class="eyebrow">Rede local de confiança</p>
          <h1 class="display-title">Sua casa em<br><em>boas mãos.</em></h1>
          <p class="hero__lead">
            Encontre profissionais de reforma e manutenção com evidências claras,
            trabalhos reais e recomendações confirmadas.
          </p>
          <PublicServiceSearch @search="search" />
          <p class="hero__promise">
            <UIcon name="i-lucide-shield-check" />
            Contato direto. Sem leilão de orçamento e sem venda de leads.
          </p>
        </div>

        <div class="hero__visual" aria-label="Exemplo de profissional da Berufe">
          <div class="hero__photo-wrap">
            <img
              src="https://images.unsplash.com/photo-1621905252507-b35492cc74b4?auto=format&fit=crop&w=1100&q=88"
              alt="Profissional trabalhando em uma instalação residencial"
            >
          </div>
          <div class="hero__profile-chip">
            <img :src="featured[0]?.avatar" alt="">
            <span><strong>Marina Alves</strong><small>Eletricista · Joinville</small></span>
            <UIcon name="i-lucide-badge-check" />
          </div>
          <div class="hero__trust-chip">
            <strong>+50</strong>
            <span>profissionais<br>da rede local</span>
          </div>
          <svg class="hero__scribble" viewBox="0 0 92 73" fill="none" aria-hidden="true">
            <path d="M5 68C19 25 51 9 86 7M86 7L74 4M86 7L80 19" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
        </div>
      </div>
    </section>

    <section class="categories page-section">
      <div class="page-container">
        <div class="section-heading">
          <div>
            <p class="eyebrow">O que você precisa resolver?</p>
            <h2 class="section-title">Serviços para cada<br>canto da casa.</h2>
          </div>
          <p class="section-copy">Escolha uma categoria e veja profissionais que atendem sua região.</p>
        </div>

        <div class="category-grid">
          <NuxtLink
            v-for="service in services.slice(0, 8)"
            :key="service.id"
            class="category-card"
            :to="`/encontrar?servico=${service.slug}&bairro=all`"
          >
            <span class="category-card__icon"><UIcon :name="service.icon" /></span>
            <span><strong>{{ service.name }}</strong><small>{{ service.description }}</small></span>
            <UIcon name="i-lucide-arrow-up-right" />
          </NuxtLink>
        </div>

        <div class="categories__all">
          <UButton to="/encontrar" color="neutral" variant="outline" trailing-icon="i-lucide-arrow-right">
            Ver todos os serviços
          </UButton>
        </div>
      </div>
    </section>

    <section id="como-funciona" class="trust page-section">
      <div class="page-container trust__grid">
        <div class="trust__visual">
          <div class="trust__photo">
            <img src="https://images.unsplash.com/photo-1503387762-592deb58ef4e?auto=format&fit=crop&w=950&q=86" alt="Profissionais em uma obra residencial">
          </div>
          <div class="trust__label">
            <UIcon name="i-lucide-scan-search" />
            <span><strong>Evidência, não promessa.</strong><small>Você vê o que foi conferido.</small></span>
          </div>
        </div>
        <div class="trust__copy">
          <p class="eyebrow">Confiança sem caixa-preta</p>
          <h2 class="section-title">Escolha pelo que<br>você pode ver.</h2>
          <p class="section-copy">
            Nada de nota misteriosa. A Berufe mostra cada sinal de confiança separadamente
            para você decidir com clareza.
          </p>
          <ol class="trust__steps">
            <li><span>01</span><div><strong>Busque pelo serviço</strong><p>Use nosso catálogo e escolha seu bairro em Joinville.</p></div></li>
            <li><span>02</span><div><strong>Compare evidências reais</strong><p>Veja verificações, portfólio, clientes e colaborações.</p></div></li>
            <li><span>03</span><div><strong>Converse diretamente</strong><p>Abra o WhatsApp do profissional escolhido. Sem intermediários.</p></div></li>
          </ol>
        </div>
      </div>
    </section>

    <section class="featured page-section">
      <div class="page-container">
        <div class="section-heading section-heading--compact">
          <div>
            <p class="eyebrow">Profissionais em destaque</p>
            <h2 class="section-title">Gente boa, trabalho bem feito.</h2>
          </div>
          <UButton to="/encontrar" variant="link" trailing-icon="i-lucide-arrow-right">Explorar a rede</UButton>
        </div>
        <div class="featured__grid">
          <NuxtLink
            v-for="professional in featured"
            :key="professional.id"
            class="featured-card"
            :to="`/profissionais/${professional.slug}`"
          >
            <div class="featured-card__image">
              <img :src="professional.avatar" :alt="`Foto de ${professional.name}`">
              <span>{{ professional.primaryService }}</span>
            </div>
            <div class="featured-card__body">
              <div><strong>{{ professional.name }}</strong><small><UIcon name="i-lucide-map-pin" /> {{ professional.allJoinville ? 'Toda Joinville' : professional.neighborhoods.slice(0, 2).join(' e ') }}</small></div>
              <UIcon name="i-lucide-arrow-up-right" />
            </div>
            <div class="featured-card__proof">
              <span><UIcon name="i-lucide-badge-check" /> Identidade verificada</span>
              <span>{{ professional.recommendations.length }} recomendações</span>
            </div>
          </NuxtLink>
        </div>
      </div>
    </section>

    <section class="professional-cta">
      <div class="page-container professional-cta__inner">
        <div>
          <p class="eyebrow">Você é profissional?</p>
          <h2 class="section-title">Seu trabalho merece<br>uma identidade forte.</h2>
        </div>
        <div>
          <p>Crie seu perfil, organize suas evidências e compartilhe orçamentos sem pagar por contatos.</p>
          <UButton to="/entrar" color="secondary" trailing-icon="i-lucide-arrow-right">Criar meu perfil gratuito</UButton>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.hero { position: relative; overflow: hidden; padding: 76px 0 100px; background: #f7f5ef; }
.hero__inner { position: relative; display: grid; grid-template-columns: 1.08fr .92fr; align-items: center; gap: 70px; }
.hero__copy { position: relative; z-index: 3; }
.hero .display-title em { color: #397a69; font-weight: inherit; }
.hero__lead { max-width: 590px; margin: 28px 0 32px; color: var(--ink-soft); font-size: 1.05rem; line-height: 1.7; }
.hero__promise { display: flex; align-items: center; gap: 8px; margin: 16px 0 0; color: var(--ink-soft); font-size: .72rem; font-weight: 700; }
.hero__promise svg { color: #397a69; }
.hero__visual { position: relative; min-height: 550px; }
.hero__photo-wrap { position: absolute; inset: 0 0 24px 44px; overflow: hidden; border-radius: 180px 180px 28px 28px; background: #bdded3; box-shadow: var(--shadow-lg); }
.hero__photo-wrap img { width: 100%; height: 100%; object-fit: cover; }
.hero__profile-chip { position: absolute; left: -4px; bottom: 52px; display: grid; grid-template-columns: auto 1fr auto; align-items: center; gap: 10px; width: 260px; padding: 11px; border: 1px solid rgba(255,255,255,.5); border-radius: 16px; background: rgba(255,255,255,.92); box-shadow: var(--shadow-sm); backdrop-filter: blur(12px); }
.hero__profile-chip img { width: 42px; height: 42px; border-radius: 12px; object-fit: cover; }
.hero__profile-chip strong, .hero__profile-chip small { display: block; }
.hero__profile-chip strong { font-size: .78rem; }
.hero__profile-chip small { margin-top: 3px; color: var(--ink-soft); font-size: .65rem; }
.hero__profile-chip > svg { color: #397a69; font-size: 1.2rem; }
.hero__trust-chip { position: absolute; top: 45px; right: -24px; display: flex; align-items: center; gap: 8px; padding: 15px 17px; border-radius: 16px; background: var(--coral); color: white; box-shadow: var(--shadow-sm); }
.hero__trust-chip strong { font-family: Georgia, serif; font-size: 1.55rem; }
.hero__trust-chip span { font-size: .64rem; font-weight: 800; line-height: 1.25; }
.hero__scribble { position: absolute; top: -18px; right: 7px; width: 74px; color: #397a69; transform: rotate(-5deg); }
.hero__shape { position: absolute; border-radius: 999px; background: var(--mint); opacity: .65; }
.hero__shape--one { width: 300px; height: 300px; top: -180px; left: 45%; }
.hero__shape--two { width: 170px; height: 170px; right: -80px; bottom: 20px; }
.section-heading { display: flex; justify-content: space-between; align-items: end; gap: 40px; margin-bottom: 40px; }
.section-heading .section-copy { max-width: 360px; margin: 0; }
.section-heading--compact { align-items: center; }
.category-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; }
.category-card { display: grid; grid-template-columns: auto 1fr auto; align-items: center; gap: 12px; min-height: 132px; padding: 20px; border: 1px solid var(--line); border-radius: 18px; background: rgba(255,255,255,.58); color: var(--ink); text-decoration: none; transition: .2s ease; }
.category-card:hover { transform: translateY(-3px); border-color: #97c6b7; background: white; box-shadow: var(--shadow-sm); }
.category-card__icon { display: grid; place-items: center; width: 43px; height: 43px; border-radius: 13px; background: var(--mint); color: #397a69; font-size: 1.2rem; }
.category-card strong, .category-card small { display: block; }
.category-card strong { font-size: .85rem; }
.category-card small { display: -webkit-box; overflow: hidden; margin-top: 5px; color: var(--ink-soft); font-size: .68rem; line-height: 1.35; -webkit-line-clamp: 2; -webkit-box-orient: vertical; }
.category-card > svg { align-self: start; color: #789089; }
.categories__all { display: flex; justify-content: center; margin-top: 28px; }
.trust { background: #17352f; color: white; }
.trust__grid { display: grid; grid-template-columns: .95fr 1.05fr; gap: 90px; align-items: center; }
.trust__visual { position: relative; min-height: 550px; }
.trust__photo { position: absolute; inset: 0 30px 30px 0; overflow: hidden; border-radius: 26px 180px 26px 26px; background: #31594f; }
.trust__photo img { width: 100%; height: 100%; object-fit: cover; opacity: .84; }
.trust__label { position: absolute; right: 0; bottom: 0; display: flex; align-items: center; gap: 12px; padding: 18px; border-radius: 16px; background: #f7f5ef; color: var(--ink); box-shadow: var(--shadow-lg); }
.trust__label > svg { font-size: 1.7rem; color: var(--coral); }
.trust__label strong, .trust__label small { display: block; }
.trust__label strong { font-size: .8rem; }.trust__label small { margin-top: 3px; color: var(--ink-soft); font-size: .68rem; }
.trust .eyebrow { color: #a8d8c9; }.trust .section-copy { max-width: 590px; margin: 24px 0 32px; color: rgba(255,255,255,.65); }
.trust__steps { display: grid; gap: 0; margin: 0; padding: 0; list-style: none; }
.trust__steps li { display: grid; grid-template-columns: 50px 1fr; gap: 16px; padding: 18px 0; border-top: 1px solid rgba(255,255,255,.12); }
.trust__steps li > span { color: var(--coral); font-family: Georgia, serif; font-size: .8rem; }
.trust__steps strong { font-size: .92rem; }.trust__steps p { margin: 5px 0 0; color: rgba(255,255,255,.58); font-size: .77rem; line-height: 1.5; }
.featured { background: #fffdfa; }
.featured__grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; }
.featured-card { overflow: hidden; border: 1px solid var(--line); border-radius: 22px; background: white; color: var(--ink); text-decoration: none; transition: transform .2s ease, box-shadow .2s ease; }
.featured-card:hover { transform: translateY(-4px); box-shadow: var(--shadow-sm); }
.featured-card__image { position: relative; height: 280px; overflow: hidden; background: var(--mint); }
.featured-card__image img { width: 100%; height: 100%; object-fit: cover; transition: transform .4s ease; }.featured-card:hover img { transform: scale(1.03); }
.featured-card__image span { position: absolute; left: 14px; bottom: 14px; padding: 7px 10px; border-radius: 9px; background: white; font-size: .67rem; font-weight: 800; }
.featured-card__body { display: flex; align-items: center; justify-content: space-between; padding: 17px 18px 12px; }
.featured-card__body strong, .featured-card__body small { display: block; }.featured-card__body strong { font-family: Georgia, serif; font-size: 1.2rem; }.featured-card__body small { display: flex; align-items: center; gap: 4px; margin-top: 5px; color: var(--ink-soft); font-size: .68rem; }
.featured-card__proof { display: flex; justify-content: space-between; gap: 8px; padding: 12px 18px 16px; border-top: 1px solid var(--line); color: var(--ink-soft); font-size: .65rem; font-weight: 700; }.featured-card__proof span { display: flex; align-items: center; gap: 4px; }.featured-card__proof span:first-child { color: #397a69; }
.professional-cta { padding: 80px 0; background: var(--mint); }
.professional-cta__inner { display: grid; grid-template-columns: 1fr .65fr; align-items: end; gap: 90px; }.professional-cta__inner > div:last-child p { margin: 0 0 24px; color: var(--ink-soft); line-height: 1.7; }

@media (max-width: 980px) {
  .hero__inner { grid-template-columns: 1fr; }.hero__copy { max-width: 720px; }.hero__visual { min-height: 450px; max-width: 600px; width: 100%; margin: 0 auto; }
  .category-grid { grid-template-columns: repeat(2, 1fr); }.trust__grid { gap: 45px; }.featured-card__image { height: 220px; }
}
@media (max-width: 760px) {
  .hero { padding: 54px 0 70px; }.hero__inner { gap: 44px; }.hero__lead { margin-block: 22px; }.hero__visual { min-height: 390px; }.hero__photo-wrap { left: 20px; }.hero__trust-chip { right: 0; }.hero__profile-chip { left: 0; }
  .section-heading { display: grid; gap: 16px; }.category-grid { grid-template-columns: 1fr; }.category-card { min-height: 100px; }
  .trust__grid { grid-template-columns: 1fr; }.trust__visual { min-height: 400px; }.featured__grid { grid-template-columns: 1fr; }.featured-card__image { height: 320px; }
  .professional-cta__inner { grid-template-columns: 1fr; gap: 28px; }
}
@media (max-width: 470px) { .hero__visual { min-height: 340px; }.hero__profile-chip { width: 230px; }.hero__trust-chip { top: 25px; }.featured-card__image { height: 270px; } }
</style>
