<script setup lang="ts">
import type { Professional } from "~/types";

export interface ProfileSocialLink {
  platform: "instagram" | "youtube";
  label: string;
  icon: string;
  url: string;
}

defineProps<{
  professional: Professional;
  socialLinks: ProfileSocialLink[];
  contactUrl: string;
}>();
defineEmits<{ contact: []; share: [] }>();
</script>

<template>
  <section class="profile-hero">
    <DesignSystemContainer>
      <div class="profile-hero__crumbs">
        <NuxtLink
          :to="`/encontrar?servico=${professional.primaryServiceSlug}&bairro=all`"
        >
          <UIcon name="i-lucide-arrow-left" /> Voltar aos resultados
        </NuxtLink>
        <button type="button" @click="$emit('share')">
          <UIcon name="i-lucide-share-2" /> Compartilhar perfil
        </button>
      </div>
      <div class="profile-hero__grid">
        <div class="profile-hero__identity">
          <DesignSystemAvatar
            :name="professional.name"
            :src="professional.avatar"
            size="profile"
            shape="rounded"
            verified
          />
          <div>
            <p class="profile-hero__service">
              {{ professional.primaryService }}
            </p>
            <h1>{{ professional.name }}</h1>
            <p class="profile-hero__headline">{{ professional.headline }}</p>
            <div class="profile-hero__meta">
              <span>
                <UIcon name="i-lucide-map-pin" />
                {{
                  professional.allJoinville
                    ? "Atende toda Joinville"
                    : professional.neighborhoods.slice(0, 4).join(", ")
                }}
              </span>
              <span>
                <UIcon name="i-lucide-briefcase-business" />
                {{ professional.yearsExperience }} anos de experiência declarada
              </span>
            </div>
            <nav
              v-if="socialLinks.length"
              class="profile-hero__socials"
              aria-label="Redes sociais do profissional"
            >
              <a
                v-for="link in socialLinks"
                :key="link.platform"
                :href="link.url"
                target="_blank"
                rel="noopener noreferrer"
                :aria-label="`Abrir ${link.label} de ${professional.name} em uma nova aba`"
              >
                <UIcon :name="link.icon" />
                {{ link.label }}
                <UIcon name="i-lucide-arrow-up-right" />
              </a>
            </nav>
          </div>
        </div>
        <aside class="profile-hero__contact">
          <p>Fale diretamente com {{ professional.name.split(" ")[0] }}</p>
          <UButton
            color="primary"
            icon="i-lucide-message-circle"
            block
            :to="contactUrl"
            target="_blank"
            rel="noopener noreferrer"
            @click="$emit('contact')"
          >
            Conversar no WhatsApp
          </UButton>
          <small>
            <UIcon name="i-lucide-lock-keyhole" /> Sem cadastro e sem
            intermediários
          </small>
        </aside>
      </div>
    </DesignSystemContainer>
  </section>
</template>
