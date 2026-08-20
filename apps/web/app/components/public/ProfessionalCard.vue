<script setup lang="ts">
import { computed } from "vue";
import type { PublicProfessionalCard } from "~/types";
import { isRecentPublicSnapshot } from "~/utils/publicProfiles";

const props = defineProps<{
  professional: PublicProfessionalCard;
  profileUrl: string;
  contactUrl: string;
}>();

const emit = defineEmits<{
  contact: [professional: PublicProfessionalCard];
}>();

const hasVerifiedIdentity = computed(() =>
  props.professional.verificationLabels.some(
    (label) => label.type === "identity",
  ),
);
const wasUpdatedRecently = computed(() =>
  isRecentPublicSnapshot(props.professional.publicSnapshotUpdatedAt),
);
const coverageLabel = computed(() => {
  if (props.professional.coverage.allJoinville) return "Atende toda Joinville";
  if (props.professional.coverage.neighborhoods.length) {
    return `Atende ${props.professional.coverage.neighborhoods
      .slice(0, 3)
      .map((neighborhood) => neighborhood.name)
      .join(", ")}`;
  }
  return "Joinville · área não informada";
});
</script>

<template>
  <article class="professional-card">
    <NuxtLink class="professional-card__media" :to="profileUrl">
      <DesignSystemAvatar
        class="professional-card__avatar"
        :name="professional.name"
        :src="professional.photoUrl ?? undefined"
        size="profile"
        shape="rounded"
        loading="lazy"
      />
      <span v-if="hasVerifiedIdentity" class="professional-card__verified">
        <UIcon name="i-lucide-badge-check" /> Verificado
      </span>
    </NuxtLink>

    <div class="professional-card__body">
      <div class="professional-card__topline">
        <span v-if="professional.profileType === 'external'"
          ><UIcon name="i-lucide-user-round-plus" /> Perfil por indicação</span
        >
        <span v-else-if="professional.matchingService"
          ><UIcon name="i-lucide-sparkles" />
          {{ professional.matchingService.name }}</span
        >
        <span v-if="wasUpdatedRecently">Atualizado recentemente</span>
      </div>
      <NuxtLink class="professional-card__name" :to="profileUrl">
        {{ professional.name }}
      </NuxtLink>
      <p v-if="professional.headline" class="professional-card__headline">
        {{ professional.headline }}
      </p>
      <p class="professional-card__coverage">
        <UIcon name="i-lucide-map-pin" />
        {{ coverageLabel }}
      </p>

      <div class="professional-card__evidence">
        <PublicEvidenceBadge
          v-for="evidence in professional.verificationLabels.slice(0, 2)"
          :key="evidence.type"
          :evidence="evidence"
          compact
        />
      </div>

      <div class="professional-card__proof">
        <span
          ><strong>{{ professional.portfolioCount }}</strong> trabalhos</span
        >
        <span
          ><strong>{{ professional.relationshipCount }}</strong> relações
          profissionais</span
        >
      </div>

      <div class="professional-card__actions">
        <UButton
          :to="profileUrl"
          color="neutral"
          variant="outline"
          label="Ver perfil"
          class="professional-card__profile-button"
        />
        <UButton
          color="primary"
          icon="i-lucide-message-circle"
          label="WhatsApp"
          :to="contactUrl"
          target="_blank"
          rel="noopener noreferrer"
          @click="emit('contact', professional)"
        />
      </div>
    </div>
  </article>
</template>

<style scoped lang="scss">
.professional-card {
  display: grid;
  grid-template-columns: 190px 1fr;
  overflow: hidden;
  border: 1px solid var(--line);
  border-radius: 22px;
  background: white;
  transition:
    transform 0.2s ease,
    box-shadow 0.2s ease;
  &:hover {
    transform: translateY(-2px);
    box-shadow: var(--shadow-sm);
  }
  &__media {
    position: relative;
    min-height: 270px;
    background: var(--mint);
  }
  &__avatar {
    width: 100%;
    height: 100%;
  }
  &__avatar :deep(.avatar__image),
  &__avatar :deep(.avatar__fallback) {
    border-radius: 0;
    font-size: 2.5rem;
  }
  &__verified {
    position: absolute;
    left: 12px;
    bottom: 12px;
    display: inline-flex;
    align-items: center;
    gap: 5px;
    padding: 7px 9px;
    border-radius: 10px;
    background: rgb(255 255 255 / 92%);
    color: #266253;
    font-size: 0.86rem;
    font-weight: 800;
    backdrop-filter: blur(8px);
  }
  &__body {
    padding: 22px 24px;
  }
  &__topline {
    display: flex;
    justify-content: space-between;
    gap: 14px;
    color: var(--color-brand);
    font-size: 0.86rem;
    font-weight: 800;
    letter-spacing: 0.05em;
    text-transform: uppercase;
  }
  &__topline span {
    display: inline-flex;
    align-items: center;
    gap: 5px;
  }
  &__topline span:last-child {
    color: #8a9995;
    font-weight: 700;
    letter-spacing: 0;
    text-transform: none;
  }
  &__name {
    display: block;
    margin-top: 8px;
    color: var(--ink);
    font-family: var(--font-display);
    font-size: 1.65rem;
    font-weight: 600;
    letter-spacing: -0.035em;
    text-decoration: none;
  }
  &__headline {
    margin: 7px 0;
    color: var(--ink-soft);
    font-size: 0.82rem;
    line-height: 1.5;
  }
  &__coverage {
    display: flex;
    align-items: center;
    gap: 6px;
    margin: 10px 0 0;
    color: var(--ink);
    font-size: 0.84rem;
    font-weight: 700;
  }
  &__evidence {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    margin-top: 16px;
  }
  &__proof {
    display: flex;
    gap: 18px;
    margin-top: 17px;
    color: var(--ink-soft);
    font-size: 0.86rem;
  }
  &__proof strong {
    color: var(--ink);
    font-size: 0.83rem;
  }
  &__actions {
    display: flex;
    gap: 9px;
    margin-top: 20px;
  }
  &__actions > * {
    justify-content: center;
  }
  &__profile-button {
    min-width: 120px;
  }
}

@media (width <= 620px) {
  .professional-card {
    grid-template-columns: 112px 1fr;
    &__media {
      min-height: 320px;
    }
    &__body {
      padding: 17px;
    }
    &__topline span:last-child,
    &__verified {
      display: none;
    }
    &__name {
      font-size: 1.35rem;
    }
    &__evidence {
      display: none;
    }
    &__proof {
      flex-wrap: wrap;
      gap: 6px 13px;
    }
    &__actions {
      flex-direction: column;
    }
  }
}
</style>
