<script setup lang="ts">
import Professionals from "~/components/admin/professionals/Professionals.vue";

definePageMeta({ layout: "workspace" });

useSeoMeta({
  title: "Profissionais",
  robots: "noindex, nofollow",
});
</script>

<template>
  <AdminWorkspace
    title="Profissionais"
    description="Liste, filtre e gerencie a publicação de todos os profissionais cadastrados."
  >
    <Professionals />
  </AdminWorkspace>
</template>
