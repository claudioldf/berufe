<script setup lang="ts">
import type { Professional } from '~/types'

defineProps<{
  professional: Professional
  matchingService: string
}>()

const emit = defineEmits<{
  contact: [professional: Professional]
}>()
</script>

<template>
  <article class="professional-card">
    <NuxtLink class="professional-card__media" :to="`/profissionais/${professional.slug}`">
      <img :src="professional.avatar" :alt="`Foto de ${professional.name}`">
      <span v-if="professional.evidence.some((item) => item.label.includes('Identidade'))" class="professional-card__verified">
        <UIcon name="i-lucide-badge-check" /> Verificada
      </span>
    </NuxtLink>

    <div class="professional-card__body">
      <div class="professional-card__topline">
        <span><UIcon name="i-lucide-sparkles" /> {{ matchingService }}</span>
        <span>Atualizado recentemente</span>
      </div>
      <NuxtLink class="professional-card__name" :to="`/profissionais/${professional.slug}`">
        {{ professional.name }}
      </NuxtLink>
      <p class="professional-card__headline">{{ professional.headline }}</p>
      <p class="professional-card__coverage">
        <UIcon name="i-lucide-map-pin" />
        {{ professional.allJoinville ? 'Atende toda Joinville' : `Atende ${professional.neighborhoods.slice(0, 3).join(', ')}` }}
      </p>

      <div class="professional-card__evidence">
        <PublicEvidenceBadge
          v-for="evidence in professional.evidence.slice(0, 2)"
          :key="evidence.id"
          :evidence="evidence"
          compact
        />
      </div>

      <div class="professional-card__proof">
        <span><strong>{{ professional.portfolio.length }}</strong> trabalhos</span>
        <span><strong>{{ professional.recommendations.length }}</strong> recomendações</span>
        <span><strong>{{ professional.relationships.length }}</strong> conexões</span>
      </div>

      <div class="professional-card__actions">
        <UButton
          :to="`/profissionais/${professional.slug}`"
          color="neutral"
          variant="outline"
          label="Ver perfil"
          class="professional-card__profile-button"
        />
        <UButton
          color="primary"
          icon="i-lucide-message-circle"
          label="WhatsApp"
          @click="emit('contact', professional)"
        />
      </div>
    </div>
  </article>
</template>

<style scoped>
.professional-card { display: grid; grid-template-columns: 190px 1fr; overflow: hidden; border: 1px solid var(--line); border-radius: 22px; background: white; transition: transform .2s ease, box-shadow .2s ease; }
.professional-card:hover { transform: translateY(-2px); box-shadow: var(--shadow-sm); }
.professional-card__media { position: relative; min-height: 270px; background: var(--mint); }
.professional-card__media img { width: 100%; height: 100%; object-fit: cover; }
.professional-card__verified { position: absolute; left: 12px; bottom: 12px; display: inline-flex; align-items: center; gap: 5px; padding: 7px 9px; border-radius: 10px; background: rgba(255,255,255,.92); color: #266253; font-size: .78rem; font-weight: 800; backdrop-filter: blur(8px); }
.professional-card__body { padding: 22px 24px; }
.professional-card__topline { display: flex; justify-content: space-between; gap: 14px; color: #397a69; font-size: .78rem; font-weight: 800; letter-spacing: .05em; text-transform: uppercase; }
.professional-card__topline span { display: inline-flex; align-items: center; gap: 5px; }
.professional-card__topline span:last-child { color: #8a9995; font-weight: 700; letter-spacing: 0; text-transform: none; }
.professional-card__name { display: block; margin-top: 8px; color: var(--ink); font-family: Georgia, serif; font-size: 1.65rem; font-weight: 600; letter-spacing: -.035em; text-decoration: none; }
.professional-card__headline { margin: 7px 0; color: var(--ink-soft); font-size: .82rem; line-height: 1.5; }
.professional-card__coverage { display: flex; align-items: center; gap: 6px; margin: 10px 0 0; color: var(--ink); font-size: .75rem; font-weight: 700; }
.professional-card__evidence { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 16px; }
.professional-card__proof { display: flex; gap: 18px; margin-top: 17px; color: var(--ink-soft); font-size: .78rem; }
.professional-card__proof strong { color: var(--ink); font-size: .83rem; }
.professional-card__actions { display: flex; gap: 9px; margin-top: 20px; }
.professional-card__actions > * { justify-content: center; }
.professional-card__profile-button { flex: 1; }

@media (max-width: 620px) {
  .professional-card { grid-template-columns: 112px 1fr; }
  .professional-card__media { min-height: 320px; }
  .professional-card__body { padding: 17px; }
  .professional-card__topline span:last-child, .professional-card__verified { display: none; }
  .professional-card__name { font-size: 1.35rem; }
  .professional-card__evidence { display: none; }
  .professional-card__proof { flex-wrap: wrap; gap: 6px 13px; }
  .professional-card__actions { flex-direction: column; }
}
</style>
