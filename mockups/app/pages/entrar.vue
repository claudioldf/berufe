<script setup lang="ts">
import { computed, shallowRef } from 'vue'
import { useMockupApp } from '~/composables/useMockupApp'

const router = useRouter()
const { activeRole, showToast } = useMockupApp()
const step = shallowRef<1 | 2 | 3>(1)
const phone = shallowRef('(47) 99999-1111')
const code = shallowRef('')
const name = shallowRef('Marina Alves')
const accepted = shallowRef(false)
const isLoading = shallowRef(false)
const error = shallowRef('')
const cooldown = shallowRef(0)

const cleanPhone = computed(() => phone.value.replace(/\D/g, ''))

useSeoMeta({ title: 'Entrar ou criar perfil' })

function simulateLoading(action: () => void) {
  isLoading.value = true
  window.setTimeout(() => {
    isLoading.value = false
    action()
  }, 650)
}

function requestCode() {
  error.value = ''
  if (cleanPhone.value.length < 10) {
    error.value = 'Digite um número brasileiro válido.'
    return
  }
  simulateLoading(() => {
    step.value = 2
    cooldown.value = 30
    const timer = window.setInterval(() => {
      cooldown.value -= 1
      if (cooldown.value <= 0) window.clearInterval(timer)
    }, 1000)
  })
}

function verifyCode() {
  error.value = ''
  if (code.value !== '123456') {
    error.value = 'Código inválido ou expirado. Neste protótipo, use 123456.'
    return
  }
  simulateLoading(() => { step.value = 3 })
}

async function register() {
  error.value = ''
  if (name.value.trim().length < 3) {
    error.value = 'Informe seu nome profissional.'
    return
  }
  if (!accepted.value) {
    error.value = 'Você precisa aceitar os termos e o aviso de privacidade.'
    return
  }
  activeRole.value = 'professional'
  showToast({ title: 'Perfil rascunho criado', description: 'Vamos completar sua presença na Berufe.' })
  await router.push('/painel')
}
</script>

<template>
  <div class="auth-page">
    <div class="auth-page__art">
      <div class="auth-page__art-content">
        <NuxtLink class="auth-page__brand" to="/">berufe<span>.</span></NuxtLink>
        <div>
          <span class="auth-page__quote-icon"><UIcon name="i-lucide-quote" /></span>
          <blockquote>“Meu trabalho já falava por mim. A Berufe ajudou mais gente a escutar.”</blockquote>
          <div class="auth-page__person">
            <img :src="'/images/photo-1500648767791-00dcc994a43e.jpg'" alt="">
            <span><strong>João Vitor Santos</strong><small>Pedreiro · membro fundador</small></span>
          </div>
        </div>
        <p><UIcon name="i-lucide-shield-check" /> Perfil básico e contato direto sempre gratuitos.</p>
      </div>
    </div>

    <main class="auth-page__main">
      <NuxtLink class="auth-page__back" to="/"><UIcon name="i-lucide-arrow-left" /> Voltar para o site</NuxtLink>

      <div class="auth-card">
        <div class="auth-progress">
          <span v-for="item in 3" :key="item" :class="{ active: item <= step }" />
        </div>

        <section v-if="step === 1">
          <p class="eyebrow">Acesso profissional</p>
          <h1>Entre com seu<br>telefone.</h1>
          <p class="auth-card__lead">Você receberá um código por SMS. Sem senha para lembrar.</p>
          <form @submit.prevent="requestCode">
            <label class="auth-field">
              <span>Celular com DDD</span>
              <div><span>🇧🇷 +55</span><input v-model="phone" type="tel" inputmode="tel" autocomplete="tel" autofocus></div>
            </label>
            <p v-if="error" class="auth-error"><UIcon name="i-lucide-circle-alert" /> {{ error }}</p>
            <UButton type="submit" color="primary" block :loading="isLoading" trailing-icon="i-lucide-arrow-right">Receber código</UButton>
          </form>
          <p class="auth-card__fineprint">Ao continuar, você confirma que este número é seu. Aplicamos limites de segurança e nunca informamos se uma conta já existe.</p>
        </section>

        <section v-else-if="step === 2">
          <button class="auth-card__step-back" type="button" @click="step = 1"><UIcon name="i-lucide-arrow-left" /> Alterar número</button>
          <p class="eyebrow">Confirme seu telefone</p>
          <h1>Digite o código<br>que enviamos.</h1>
          <p class="auth-card__lead">SMS enviado para <strong>+55 {{ phone }}</strong>. Para testar, use <strong>123456</strong>.</p>
          <form @submit.prevent="verifyCode">
            <label class="auth-field">
              <span>Código de 6 dígitos</span>
              <input v-model="code" class="auth-code" type="text" inputmode="numeric" maxlength="6" autocomplete="one-time-code" autofocus placeholder="000000">
            </label>
            <p v-if="error" class="auth-error"><UIcon name="i-lucide-circle-alert" /> {{ error }}</p>
            <UButton type="submit" color="primary" block :loading="isLoading">Confirmar e continuar</UButton>
            <button class="resend" type="button" :disabled="cooldown > 0" @click="requestCode">
              {{ cooldown > 0 ? `Reenviar código em ${cooldown}s` : 'Reenviar código' }}
            </button>
          </form>
        </section>

        <section v-else>
          <div class="auth-card__success"><UIcon name="i-lucide-check" /></div>
          <p class="eyebrow">Telefone confirmado</p>
          <h1>Como você quer<br>ser encontrado?</h1>
          <p class="auth-card__lead">Este será o nome principal do seu perfil. Você poderá completar as outras informações depois.</p>
          <form @submit.prevent="register">
            <label class="auth-field">
              <span>Seu nome profissional</span>
              <input v-model="name" type="text" autocomplete="name" maxlength="70">
            </label>
            <label class="auth-check">
              <input v-model="accepted" type="checkbox">
              <span>Li e aceito os <a href="#">Termos de Uso</a> e o <a href="#">Aviso de Privacidade</a> vigentes.</span>
            </label>
            <p v-if="error" class="auth-error"><UIcon name="i-lucide-circle-alert" /> {{ error }}</p>
            <UButton type="submit" color="primary" block trailing-icon="i-lucide-arrow-right">Criar meu perfil</UButton>
          </form>
        </section>
      </div>
    </main>
  </div>
</template>

<style scoped>
.auth-page { min-height: calc(100vh - 76px); display: grid; grid-template-columns: .9fr 1.1fr; background: #fffdfa; }.auth-page__art { position: relative; min-height: 720px; padding: 44px; background: linear-gradient(180deg, rgba(14,45,39,.2), rgba(14,45,39,.9)), url('/images/photo-1503387762-592deb58ef4e.jpg') center/cover; color: white; }.auth-page__art-content { position: relative; z-index: 2; display: flex; flex-direction: column; justify-content: space-between; height: 100%; max-width: 490px; }.auth-page__brand { color: white; font-family: Georgia, serif; font-size: 1.8rem; font-weight: 700; letter-spacing: -.05em; text-decoration: none; }.auth-page__brand span { color: var(--coral); }.auth-page__quote-icon { color: var(--coral); font-size: 2rem; }.auth-page blockquote { margin: 14px 0 22px; font-family: Georgia, serif; font-size: clamp(2rem, 4vw, 3.6rem); letter-spacing: -.04em; line-height: 1.05; }.auth-page__person { display: flex; align-items: center; gap: 10px; }.auth-page__person img { width: 42px; height: 42px; border: 2px solid rgba(255,255,255,.5); border-radius: 99px; object-fit: cover; }.auth-page__person strong, .auth-page__person small { display: block; }.auth-page__person strong { font-size: .75rem; }.auth-page__person small { margin-top: 3px; color: rgba(255,255,255,.6); font-size: .75rem; }.auth-page__art-content > p { display: flex; align-items: center; gap: 7px; color: rgba(255,255,255,.7); font-size: .78rem; font-weight: 700; }
.auth-page__main { position: relative; display: grid; place-items: center; padding: 75px 50px; }.auth-page__back { position: absolute; top: 28px; right: 36px; display: flex; align-items: center; gap: 6px; color: var(--ink-soft); font-size: .78rem; font-weight: 700; text-decoration: none; }.auth-card { width: min(100%, 480px); }.auth-progress { display: grid; grid-template-columns: repeat(3, 1fr); gap: 5px; margin-bottom: 54px; }.auth-progress span { height: 3px; border-radius: 99px; background: #d9d9d3; }.auth-progress span.active { background: #397a69; }.auth-card h1 { margin: 0; font-family: Georgia, serif; font-size: clamp(2.6rem, 5vw, 4.2rem); font-weight: 500; letter-spacing: -.05em; line-height: .98; }.auth-card__lead { margin: 18px 0 28px; color: var(--ink-soft); font-size: .85rem; line-height: 1.65; }.auth-card form { display: grid; gap: 15px; }.auth-field { display: grid; gap: 7px; }.auth-field > span { color: var(--ink); font-size: .78rem; font-weight: 850; }.auth-field > div { display: grid; grid-template-columns: auto 1fr; align-items: center; overflow: hidden; border: 1px solid var(--line); border-radius: 12px; background: white; }.auth-field > div > span { padding: 14px; border-right: 1px solid var(--line); color: var(--ink-soft); font-size: .78rem; }.auth-field input { width: 100%; padding: 14px; border: 1px solid var(--line); border-radius: 12px; outline: 0; background: white; color: var(--ink); font-weight: 750; }.auth-field > div input { border: 0; }.auth-field input:focus, .auth-field > div:focus-within { border-color: #397a69; box-shadow: 0 0 0 3px rgba(57,122,105,.12); }.auth-card__fineprint { margin: 14px 0 0; color: #88958f; font-size: .75rem; line-height: 1.55; }.auth-error { display: flex; align-items: center; gap: 6px; margin: 0; color: #b33b31; font-size: .78rem; font-weight: 700; }.auth-code { font-size: 1.8rem !important; letter-spacing: .35em; text-align: center; }.resend { justify-self: center; border: 0; background: transparent; color: #397a69; font-size: .78rem; font-weight: 800; cursor: pointer; }.resend:disabled { color: #88958f; cursor: default; }.auth-card__step-back { display: flex; align-items: center; gap: 5px; margin-bottom: 25px; padding: 0; border: 0; background: transparent; color: var(--ink-soft); font-size: .78rem; cursor: pointer; }.auth-card__success { display: grid; place-items: center; width: 50px; height: 50px; margin-bottom: 20px; border-radius: 16px; background: var(--mint); color: #397a69; font-size: 1.35rem; }.auth-check { display: grid; grid-template-columns: auto 1fr; gap: 9px; color: var(--ink-soft); font-size: .78rem; line-height: 1.5; }.auth-check input { margin-top: 2px; accent-color: #397a69; }.auth-check a { color: #397a69; font-weight: 800; }
@media (max-width: 850px) { .auth-page { grid-template-columns: 1fr; }.auth-page__art { display: none; }.auth-page__main { min-height: 720px; padding: 90px 24px 60px; }.auth-page__back { top: 25px; left: 24px; right: auto; } }
</style>
