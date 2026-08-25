<script setup lang="ts">
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
    <AdminSearchAuditsSearchAudits />
  </AdminWorkspace>
</template>
