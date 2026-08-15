<script setup lang="ts">
definePageMeta({ layout: "workspace" });

useSeoMeta({
  title: "Visão do produto",
  robots: "noindex, nofollow",
});
</script>

<template>
  <AdminWorkspace
    title="Visão do produto"
    description="Sinais agregados para conduzir o crescimento inicial da rede."
  >
    <AdminReportsGrowthReports />
  </AdminWorkspace>
</template>
