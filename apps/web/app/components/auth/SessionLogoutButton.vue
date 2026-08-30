<script setup lang="ts">
import { useApplicationSession } from "~/composables/useApplicationSession";
import { useAppRole } from "~/composables/useAppRole";
import { useToast } from "~/composables/useToast";

const { isEnding, logout } = useApplicationSession();
const { setRole } = useAppRole();
const { showToast } = useToast();

async function signOut() {
  try {
    await logout();
    setRole("visitor");
    await navigateTo("/app/professional/login", { replace: true });
  } catch {
    showToast({
      title: "Não foi possível sair",
      description: "Tente novamente em instantes.",
    });
  }
}
</script>

<template>
  <button
    class="session-logout"
    type="button"
    :disabled="isEnding"
    @click="signOut"
  >
    <UIcon name="i-lucide-log-out" />
    <span>{{ isEnding ? "Saindo…" : "Sair" }}</span>
  </button>
</template>

<style scoped lang="scss">
.session-logout {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 7px;
  min-height: 42px;
  padding: 8px 10px;
  border: 1px solid rgb(255 255 255 / 24%);
  border-radius: 10px;
  background: rgb(255 255 255 / 8%);
  color: inherit;
  font: inherit;
  font-size: 0.82rem;
  font-weight: 800;
  cursor: pointer;
}

.session-logout:hover,
.session-logout:focus-visible {
  background: rgb(255 255 255 / 16%);
}

.session-logout:disabled {
  cursor: wait;
  opacity: 0.55;
}
</style>
