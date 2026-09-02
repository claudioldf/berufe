<script setup lang="ts">
import type { PublicProfessionalProfile } from "~/types";

defineProps<{
  professional: PublicProfessionalProfile;
  contactUrl: string;
  supportEmailUrl: string;
}>();
defineEmits<{ contact: [] }>();
</script>

<template>
  <aside class="profile-sidebar">
    <DesignSystemSurfaceCard class="profile-sidebar__card">
      <p>Pronto para conversar?</p>
      <strong>
        Explique o que você precisa diretamente para
        {{ professional.name.split(" ")[0] }}.
      </strong>
      <UButton
        color="primary"
        icon="i-lucide-message-circle"
        block
        :to="contactUrl"
        target="_blank"
        rel="noopener noreferrer"
        @click="$emit('contact')"
      >
        Chamar no WhatsApp
      </UButton>
      <small>A Berufe não lê nem armazena sua conversa.</small>
    </DesignSystemSurfaceCard>
    <div class="profile-sidebar__coverage">
      <strong><UIcon name="i-lucide-map" /> Área de atendimento</strong>
      <p v-if="professional.coverage.wholeCity">
        Toda {{ professional.coverage.city?.name ?? "a cidade" }}
      </p>
      <div v-else>
        <span
          v-for="neighborhood in professional.coverage.neighborhoods"
          :key="neighborhood.code"
        >
          {{ neighborhood.name }}
        </span>
      </div>
    </div>
    <a class="profile-sidebar__support" :href="supportEmailUrl">
      <UIcon
        class="profile-sidebar__support-icon"
        name="i-lucide-mail"
        aria-hidden="true"
      />
      <span class="profile-sidebar__support-text">
        Reportar um problema à Berufe
      </span>
    </a>
  </aside>
</template>
