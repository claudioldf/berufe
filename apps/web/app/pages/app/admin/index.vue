<script setup lang="ts">
useSeoMeta({
  title: "Fila de moderação",
  robots: "noindex, nofollow",
});
definePageMeta({
  layout: "workspace",
  middleware: (to) => {
    if (to.query.view === "catalogos") {
      return navigateTo("/app/admin/catalog", { replace: true });
    }
    if (to.query.view === "relatorios") {
      return navigateTo("/app/admin/reports", { replace: true });
    }
  },
});
</script>

<template>
  <AdminWorkspace
    title="Fila de moderação"
    description="Analise perfis, portfólios, identidades e relações profissionais na ordem de chegada."
  >
    <AdminModerationQueue />
  </AdminWorkspace>
</template>
