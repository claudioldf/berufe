<script setup lang="ts">
import { computed } from "vue";
import type { PublicProfessionalProfile } from "~/types";
import { formatCountLabel } from "~/utils/text";

const props = defineProps<{
  professional: PublicProfessionalProfile;
}>();
defineEmits<{
  viewPortfolio: [index: number];
}>();

const connectionCountLabel = computed(() =>
  formatCountLabel(
    props.professional.relationships.length,
    "conexão confirmada",
    "conexões confirmadas",
  ),
);
</script>

<template>
  <div class="profile-content__main">
    <section class="profile-section profile-about">
      <DesignSystemEyebrow>Sobre o trabalho</DesignSystemEyebrow>
      <h2>Experiência que dá<br />tranquilidade.</h2>
      <p>{{ professional.bio }}</p>
      <div class="profile-about__services">
        <div v-for="(service, index) in professional.services" :key="service">
          <span>
            <UIcon :name="index === 0 ? 'i-lucide-zap' : 'i-lucide-wrench'" />
          </span>
          <div>
            <strong>{{ service }}</strong>
            <small v-if="professional.serviceNotes[index]">
              {{ professional.serviceNotes[index] }}
            </small>
          </div>
          <em v-if="index === 0">Principal</em>
        </div>
      </div>
    </section>

    <section
      v-if="professional.portfolio.length"
      class="profile-section portfolio-section"
    >
      <div class="profile-section__heading">
        <div>
          <DesignSystemEyebrow>Portfólio aprovado</DesignSystemEyebrow>
          <h2>Trabalhos que falam.</h2>
        </div>
        <span>{{ professional.portfolio.length }} trabalhos</span>
      </div>
      <div class="portfolio-grid">
        <button
          v-for="(item, index) in professional.portfolio"
          :key="item.id"
          type="button"
          class="portfolio-item"
          @click="$emit('viewPortfolio', index)"
        >
          <img
            :src="item.image"
            :alt="item.title"
            width="1280"
            height="853"
            loading="lazy"
          />
          <span class="portfolio-item__meta">
            <strong>{{ item.title }}</strong>
            <small>{{ item.service }}</small>
          </span>
          <UIcon name="i-lucide-expand" class="portfolio-item__expand" />
        </button>
      </div>
    </section>

    <section
      v-if="professional.relationships.length"
      class="profile-section relationships-section"
    >
      <div class="profile-section__heading">
        <div>
          <DesignSystemEyebrow>Rede profissional</DesignSystemEyebrow>
          <h2>Confiança entre quem faz.</h2>
        </div>
        <span>{{ connectionCountLabel }}</span>
      </div>
      <div class="relationships-list">
        <article
          v-for="relationship in professional.relationships"
          :key="relationship.id"
        >
          <DesignSystemAvatar
            :name="relationship.professionalName"
            :src="relationship.avatar ?? undefined"
            size="lg"
            shape="rounded"
          />
          <div>
            <span class="relationship-type">
              <UIcon
                :name="
                  relationship.type === 'worked_together'
                    ? 'i-lucide-handshake'
                    : 'i-lucide-heart'
                "
              />
              {{
                relationship.type === "worked_together"
                  ? "Trabalharam juntos"
                  : relationship.direction === "incoming"
                    ? `Recomendado por ${relationship.professionalName}`
                    : `Recomendou ${relationship.professionalName}`
              }}
            </span>
            <p v-if="relationship.note">“{{ relationship.note }}”</p>
            <NuxtLink
              :to="buildPublicProfilePath(relationship.professionalSlug)"
            >
              {{ relationship.professionalName }}
              <UIcon name="i-lucide-arrow-up-right" />
            </NuxtLink>
          </div>
        </article>
      </div>
    </section>

    <section class="profile-disclaimer">
      <UIcon class="profile-disclaimer__icon" name="i-lucide-shield-alert" />
      <div>
        <strong>O que a verificação significa</strong>
        <p>
          A Berufe confere evidências específicas e modera o conteúdo público,
          mas não garante a execução, o preço ou o resultado de um serviço.
          Combine escopo e condições diretamente com o profissional.
        </p>
      </div>
    </section>
  </div>
</template>
