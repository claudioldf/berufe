<script setup lang="ts">
import { useToast } from "~/composables/useToast";

const { toast, clearToast } = useToast();

// The site-wide Organization/WebSite identity lives in the
// `app/plugins/schema-org.ts` plugin, not here: a component-level
// defineOrganization/defineWebSite call in this root component loses to
// nuxt-schema-org's own "defaults" plugin, which registers its own
// WebSite/WebPage nodes for the same @id before this component's setup()
// ever runs.
</script>

<template>
  <UApp>
    <AppNavigationFeedback />
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
    <DesignSystemToast :message="toast" @dismiss="clearToast" />
  </UApp>
</template>
