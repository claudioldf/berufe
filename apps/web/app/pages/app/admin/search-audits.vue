<script setup lang="ts">
import SearchAudits from "~/components/admin/search-audits/SearchAudits.vue";

definePageMeta({ layout: "workspace" });

useSeoMeta({
  title: "Auditoria de buscas",
  robots: "noindex, nofollow",
});
</script>

<template>
  <AdminWorkspace
    title="Auditoria de buscas"
    description="Intenções, respostas do LLM, interpretação controlada e cobertura profissional dos últimos seis meses."
  >
    <SearchAudits />
  </AdminWorkspace>
</template>
