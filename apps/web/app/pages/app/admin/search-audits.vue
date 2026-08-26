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
    description="Prompts, respostas do LLM, interpretação controlada e alcance profissional dos últimos sete dias."
  >
    <SearchAudits />
  </AdminWorkspace>
</template>
