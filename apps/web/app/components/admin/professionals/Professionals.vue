<script setup lang="ts">
import { shallowRef } from "vue";
import { useAdminProfessionals } from "~/composables/useAdminProfessionals";
import type { AdminProfessionalItem } from "~/types";

const {
  professionals,
  q,
  phone,
  city,
  state,
  identityVerified,
  onboardingFinished,
  sort,
  isLoading,
  error,
  isMutating,
  mutationError,
  load,
  setPage,
  submitQuery,
  submitPhone,
  setCity,
  setState,
  setIdentityVerified,
  setOnboardingFinished,
  setSort,
  clearFilters,
  setPublication,
} = useAdminProfessionals();

const unpublishOpen = shallowRef(false);
const unpublishReason = shallowRef("");
const unpublishTarget = shallowRef<AdminProfessionalItem | null>(null);

function openUnpublish(item: AdminProfessionalItem) {
  unpublishTarget.value = item;
  unpublishReason.value = "";
  unpublishOpen.value = true;
}

async function confirmUnpublish() {
  const target = unpublishTarget.value;
  if (!target) return;

  try {
    await setPublication(target, false, unpublishReason.value.trim());
    unpublishOpen.value = false;
    unpublishTarget.value = null;
    unpublishReason.value = "";
  } catch {
    // The composable exposes the user-facing mutation error. Keep the dialog
    // and entered reason intact so the administrator can retry.
  }
}

async function publish(item: AdminProfessionalItem) {
  await setPublication(item, true).catch(() => undefined);
}
</script>

<template>
  <div class="professionals" :aria-busy="isLoading">
    <AdminProfessionalsToolbar
      :summary="professionals.summary"
      :q="q"
      :phone="phone"
      :city="city"
      :state="state"
      :identity-verified="identityVerified"
      :onboarding-finished="onboardingFinished"
      :sort="sort"
      :is-loading="isLoading"
      @search="submitQuery"
      @phone="submitPhone"
      @city="setCity"
      @state="setState"
      @identity-verified="setIdentityVerified"
      @onboarding-finished="setOnboardingFinished"
      @sort="setSort"
      @clear="clearFilters"
    />

    <p v-if="mutationError" class="professionals__notice" role="alert">
      {{ mutationError }}
    </p>

    <DesignSystemSurfaceCard
      v-if="isLoading && professionals.items.length === 0"
      class="professionals__state"
      role="status"
      aria-live="polite"
    >
      <UIcon name="i-lucide-loader-circle" aria-hidden="true" />
      <strong>Carregando profissionais…</strong>
    </DesignSystemSurfaceCard>

    <DesignSystemSurfaceCard
      v-else-if="error && professionals.items.length === 0"
      class="professionals__state"
      role="alert"
    >
      <UIcon name="i-lucide-triangle-alert" aria-hidden="true" />
      <div>
        <strong>Não foi possível carregar os profissionais.</strong>
        <p>{{ error }}</p>
      </div>
      <UButton
        class="professionals__retry"
        color="neutral"
        variant="outline"
        label="Tentar novamente"
        @click="load"
      />
    </DesignSystemSurfaceCard>

    <DesignSystemSurfaceCard
      v-else-if="professionals.items.length === 0"
      class="professionals__state"
    >
      <UIcon name="i-lucide-user-x" aria-hidden="true" />
      <div>
        <strong>Nenhum profissional corresponde aos filtros.</strong>
        <p>Revise a busca ou limpe os filtros aplicados.</p>
      </div>
    </DesignSystemSurfaceCard>

    <template v-else>
      <p v-if="error" class="professionals__notice" role="alert">{{ error }}</p>
      <AdminProfessionalsTable
        :items="professionals.items"
        :meta="professionals.meta"
        :is-mutating="isMutating"
        @change-page="setPage"
        @publish="publish"
        @unpublish="openUnpublish"
      />
    </template>

    <AdminProfessionalsUnpublishDialog
      v-model:open="unpublishOpen"
      v-model:reason="unpublishReason"
      :display-name="unpublishTarget?.displayName ?? null"
      :submitting="isMutating"
      @confirm="confirmUnpublish"
    />
  </div>
</template>

<style scoped lang="scss">
.professionals {
  display: grid;
  gap: 14px;

  &__state {
    display: flex;
    align-items: center;
    gap: 13px;
    min-height: 110px;
    padding: 22px;

    p {
      margin: 4px 0 0;
      color: var(--color-text-muted);
      font-size: 0.8rem;
    }

    .professionals__retry {
      margin-left: auto;
    }
  }

  &__notice {
    margin: 0;
    padding: 10px 13px;
    border-radius: var(--radius-md);
    background: var(--color-danger-tint);
    color: var(--color-danger);
    font-size: 0.8rem;
  }
}

@media (width <= 650px) {
  .professionals__state {
    align-items: start;
    flex-wrap: wrap;

    .professionals__retry {
      margin-left: 0;
    }
  }
}
</style>
