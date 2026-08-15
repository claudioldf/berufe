<script setup lang="ts">
useSeoMeta({
  title: "Catálogo",
  robots: "noindex, nofollow",
});
</script>

<template>
  <AdminWorkspace
    title="Catálogo"
    description="Gerencie os serviços e bairros disponíveis para novas seleções."
  >
    <AdminCatalogManager />
  </AdminWorkspace>
</template>
