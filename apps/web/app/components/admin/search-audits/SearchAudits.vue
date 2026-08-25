<script setup lang="ts">
import { useAdminSearchAudits } from "~/composables/useAdminSearchAudits";

const { audits, isLoading, error, load, setPage } = useAdminSearchAudits();
</script>

<template>
  <div class="search-audits">
    <section class="search-audits__intro" aria-label="Resumo da auditoria">
      <div>
        <strong>{{ audits.meta.totalCount }}</strong>
        <span>prompts disponíveis</span>
      </div>
      <p>
        Entradas e saídas são mantidas por sete dias. O total de profissionais
        corresponde à consulta completa, antes da paginação dos resultados.
      </p>
    </section>

    <DesignSystemSurfaceCard
      v-if="isLoading && audits.items.length === 0"
      class="search-audits__state"
      role="status"
      aria-live="polite"
    >
      <UIcon name="i-lucide-loader-circle" aria-hidden="true" />
      <strong>Carregando a auditoria de buscas...</strong>
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
      <strong>Nenhum prompt foi registrado nos últimos sete dias.</strong>
    </DesignSystemSurfaceCard>

    <template v-else>
      <p v-if="error" class="search-audits__notice" role="alert">{{ error }}</p>
      <AdminSearchAuditsSearchAuditList
        :items="audits.items"
        :meta="audits.meta"
        @change-page="setPage"
      />
    </template>
  </div>
</template>

<style scoped lang="scss">
.search-audits {
  display: grid;
  gap: 18px;

  &__intro {
    display: grid;
    grid-template-columns: auto 1fr;
    align-items: center;
    gap: 18px;
    padding: 17px 20px;
    border: 1px solid rgb(24 48 43 / 10%);
    border-radius: 14px;
    background: rgb(255 255 255 / 68%);

    div {
      display: grid;
    }

    strong {
      color: var(--color-brand-strong);
      font-family: var(--font-display);
      font-size: 1.8rem;
      line-height: 1;
    }

    span,
    p {
      color: var(--color-text-muted);
      font-size: 0.8rem;
    }

    p {
      margin: 0;
      line-height: 1.5;
    }
  }

  &__state {
    display: flex;
    align-items: center;
    gap: 13px;
    min-height: 120px;
    padding: 24px;

    p {
      margin: 4px 0 0;
      color: var(--color-text-muted);
      font-size: 0.82rem;
    }

    .search-audits__retry {
      margin-left: auto;
    }
  }

  &__notice {
    margin: 0;
    padding: 10px 13px;
    border-radius: 9px;
    background: #fde8e5;
    color: #8b3028;
    font-size: 0.82rem;
  }
}

@media (width <= 650px) {
  .search-audits__intro {
    grid-template-columns: 1fr;
  }

  .search-audits__state {
    align-items: start;
    flex-wrap: wrap;

    .search-audits__retry {
      margin-left: 0;
    }
  }
}
</style>
