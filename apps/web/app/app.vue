<script setup lang="ts">
import { useToast } from "~/composables/useToast";

const { toast, clearToast } = useToast();
</script>

<template>
  <UApp>
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
    <DesignSystemToast :message="toast" @dismiss="clearToast" />
  </UApp>
</template>
