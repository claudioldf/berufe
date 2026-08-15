<script setup lang="ts">
import type { Professional } from "~/types";

defineProps<{ professional: Professional; contactUrl: string }>();
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
      <p v-if="professional.allJoinville">Toda Joinville</p>
      <div v-else>
        <span
          v-for="neighborhood in professional.neighborhoods"
          :key="neighborhood"
        >
          {{ neighborhood }}
        </span>
      </div>
    </div>
  </aside>
</template>
