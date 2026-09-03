<script setup lang="ts">
import { computed } from "vue";
import { useAdminImpersonation } from "~/composables/useAdminImpersonation";
import { useApplicationSession } from "~/composables/useApplicationSession";

const { account, session } = useApplicationSession();
const { isChanging, error, stop } = useAdminImpersonation();
const impersonatedDisplayName = computed(() =>
  session.value?.impersonating
    ? (account.value?.registrationDisplayName ?? "profissional")
    : null,
);
</script>

<template>
  <div class="workspace-layout">
    <a class="skip-link" href="#workspace-content">Pular para o conteúdo</a>
    <AppHeader />
    <AuthImpersonationBanner
      v-if="impersonatedDisplayName"
      :display-name="impersonatedDisplayName"
      :stopping="isChanging"
      :error="error"
      @stop="stop"
    />
    <main id="workspace-content" class="workspace-layout__main" tabindex="-1">
      <slot />
    </main>
  </div>
</template>

<style scoped lang="scss">
.workspace-layout {
  min-height: 100vh;
  background: var(--color-surface-canvas);

  &__main {
    min-width: 0;
  }
}
</style>
