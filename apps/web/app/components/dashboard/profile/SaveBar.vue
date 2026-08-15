<script setup lang="ts">
defineProps<{ saved: boolean }>();
</script>

<template>
  <div class="editor-savebar">
    <span>
      <UIcon :name="saved ? 'i-lucide-cloud-check' : 'i-lucide-circle-dot'" />
      {{ saved ? "Alterações salvas" : "Há alterações não salvas" }}
    </span>
    <div>
      <small
        >Os campos acima representam as informações públicas do perfil.</small
      >
      <UButton type="submit" color="primary" :disabled="saved">
        Salvar alterações
      </UButton>
    </div>
  </div>
</template>
