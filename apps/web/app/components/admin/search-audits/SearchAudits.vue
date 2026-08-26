<script setup lang="ts">
import { shallowRef } from "vue";
import { useAdminSearchAudits } from "~/composables/useAdminSearchAudits";
import type { SearchAuditItem } from "~/types";

const {
  audits,
  q,
  outcome,
  sort,
  isLoading,
  error,
  load,
  setPage,
  submitQuery,
  setOutcome,
  setSort,
  clearFilters,
} = useAdminSearchAudits();

const selectedAudit = shallowRef<SearchAuditItem | null>(null);
const detailsOpen = shallowRef(false);

function openDetails(item: SearchAuditItem) {
  selectedAudit.value = item;
  detailsOpen.value = true;
}
</script>

<template>
  <div class="search-audits" :aria-busy="isLoading">
    <AdminSearchAuditsSearchAuditOverview
      :summary="audits.summary"
      :q="q"
      :outcome="outcome"
      :sort="sort"
      :is-loading="isLoading"
      @search="submitQuery"
      @outcome="setOutcome"
      @sort="setSort"
      @clear="clearFilters"
    />

    <DesignSystemSurfaceCard
      v-if="isLoading && audits.items.length === 0"
      class="search-audits__state"
      role="status"
      aria-live="polite"
    >
      <UIcon name="i-lucide-loader-circle" aria-hidden="true" />
      <strong>Carregando a auditoria de buscas…</strong>
    </DesignSystemSurfaceCard>

    <DesignSystemSurfaceCard
      v-else-if="error && audits.items.length === 0"
      class="search-audits__state"
      role="alert"
    >
      <UIcon name="i-lucide-triangle-alert" aria-hidden="true" />
      <div>
        <strong>Não foi possível carregar a auditoria.</strong>
        <p>{{ error }}</p>
      </div>
      <UButton
        class="search-audits__retry"
        color="neutral"
        variant="outline"
        label="Tentar novamente"
        @click="load"
      />
    </DesignSystemSurfaceCard>

    <DesignSystemSurfaceCard
      v-else-if="audits.items.length === 0"
      class="search-audits__state"
    >
      <UIcon name="i-lucide-search-x" aria-hidden="true" />
      <div>
        <strong>
          {{
            q || outcome
              ? "Nenhuma busca corresponde aos filtros."
              : "Nenhum prompt foi registrado nos últimos seis meses."
          }}
        </strong>
        <p v-if="q || outcome">
          Revise a intenção pesquisada ou selecione outro resultado.
        </p>
      </div>
    </DesignSystemSurfaceCard>

    <template v-else>
      <p v-if="error" class="search-audits__notice" role="alert">{{ error }}</p>
      <AdminSearchAuditsSearchAuditList
        :items="audits.items"
        :meta="audits.meta"
        @change-page="setPage"
        @view="openDetails"
      />
    </template>

    <AdminSearchAuditsSearchAuditDetailsModal
      v-model:open="detailsOpen"
      :item="selectedAudit"
    />
  </div>
</template>

<style scoped lang="scss">
.search-audits {
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

    .search-audits__retry {
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
  .search-audits__state {
    align-items: start;
    flex-wrap: wrap;

    .search-audits__retry {
      margin-left: 0;
    }
  }
}
</style>
