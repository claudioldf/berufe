<script setup lang="ts">
import type { PublicProfessionalProfile } from "~/types";

defineProps<{
  professional: PublicProfessionalProfile;
  contactUrl: string;
}>();
defineEmits<{ contact: [] }>();
</script>

<template>
  <div class="mobile-contact">
    <div>
      <small>{{ professional.primaryService }}</small>
      <strong>{{ professional.name }}</strong>
    </div>
    <UButton
      color="primary"
      icon="i-lucide-message-circle"
      :to="contactUrl"
      target="_blank"
      rel="noopener noreferrer"
      @click="$emit('contact')"
    >
      WhatsApp
    </UButton>
  </div>
</template>
