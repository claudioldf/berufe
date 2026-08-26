<script setup lang="ts">
import { formatDateTime } from "~/utils/formatters";
import {
  searchAuditCityLabel,
  searchAuditOutcome,
  searchAuditOutcomeLabels,
  searchAuditServiceLabel,
  searchAuditStatusLabels,
} from "~/utils/searchAudit";
import type { SearchAuditItem, SearchAuditPage } from "~/types";

const props = defineProps<{
  items: SearchAuditItem[];
  meta: SearchAuditPage["meta"];
}>();

const emit = defineEmits<{
  changePage: [page: number];
  view: [item: SearchAuditItem];
}>();
</script>

<template>
  <section
    class="audit-list"
    aria-label="Prompts de busca dos últimos seis meses"
  >
    <div class="audit-list__heading">
      <p>
        <strong>{{ props.meta.totalCount }}</strong>
        {{
          props.meta.totalCount === 1
            ? "busca encontrada"
            : "buscas encontradas"
        }}
      </p>
      <span>O total de profissionais considera a consulta completa.</span>
    </div>

    <div class="audit-list__table-wrap">
      <table>
        <thead>
          <tr>
            <th scope="col">Busca</th>
            <th scope="col">Interpretação</th>
            <th scope="col">Localização</th>
            <th scope="col">Diagnóstico</th>
            <th scope="col" class="audit-list__numeric">Resultados</th>
            <th scope="col">Quando</th>
            <th scope="col"><span class="sr-only">Ações</span></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in props.items" :key="item.id">
            <td class="audit-list__prompt-cell">
              <p>{{ item.inputPrompt }}</p>
            </td>
            <td class="audit-list__interpretation">
              <strong>{{ searchAuditServiceLabel(item) }}</strong>
            </td>
            <td class="audit-list__location">
              {{ searchAuditCityLabel(item) }}
            </td>
            <td class="audit-list__diagnostic">
              <small>{{ searchAuditStatusLabels[item.status] }}</small>
              <span
                class="audit-list__outcome"
                :class="`audit-list__outcome--${searchAuditOutcome(item)}`"
              >
                {{ searchAuditOutcomeLabels[searchAuditOutcome(item)] }}
              </span>
            </td>
            <td class="audit-list__count audit-list__numeric">
              {{ item.resultCount }}
            </td>
            <td class="audit-list__date">
              <time :datetime="item.createdAt">{{
                formatDateTime(item.createdAt)
              }}</time>
            </td>
            <td class="audit-list__action">
              <UButton
                color="neutral"
                variant="outline"
                size="sm"
                label="Detalhes"
                @click="emit('view', item)"
              />
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <nav
      v-if="props.meta.totalPages > 1"
      class="audit-pagination"
      aria-label="Paginação da auditoria"
    >
      <UButton
        color="neutral"
        variant="outline"
        label="Anterior"
        :disabled="props.meta.page <= 1"
        @click="emit('changePage', props.meta.page - 1)"
      />
      <span>Página {{ props.meta.page }} de {{ props.meta.totalPages }}</span>
      <UButton
        color="neutral"
        variant="outline"
        label="Próxima"
        :disabled="props.meta.page >= props.meta.totalPages"
        @click="emit('changePage', props.meta.page + 1)"
      />
    </nav>
  </section>
</template>

<style scoped lang="scss">
.audit-list {
  overflow: hidden;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  background: var(--color-surface);
  box-shadow: var(--shadow-sm);

  &__heading {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    padding: 11px 14px;
    border-bottom: 1px solid var(--color-border);
    background: var(--color-surface-neutral);

    p,
    span {
      margin: 0;
      color: var(--color-text-muted);
      font-size: 0.74rem;
    }

    strong {
      color: var(--color-brand-strong);
      font-variant-numeric: tabular-nums;
    }
  }

  &__table-wrap {
    overflow-x: auto;
  }

  table {
    width: 100%;
    min-width: 980px;
    border-collapse: collapse;
    table-layout: fixed;
  }

  th,
  td {
    padding: 11px 12px;
    border-bottom: 1px solid var(--color-border);
    text-align: left;
    vertical-align: middle;
  }

  th {
    background: var(--color-surface);
    color: var(--color-text-muted);
    font-size: 0.68rem;
    font-weight: 850;
    letter-spacing: 0.025em;
    text-transform: uppercase;

    &:first-child {
      width: 26%;
    }

    &:nth-child(2) {
      width: 16%;
    }

    &:nth-child(3) {
      width: 15%;
    }

    &:nth-child(4) {
      width: 15%;
    }

    &:nth-child(5) {
      width: 9%;
    }

    &:nth-child(6) {
      width: 11%;
    }

    &:last-child {
      width: 8%;
    }
  }

  tbody tr {
    transition: background var(--motion-fast) ease;

    &:hover {
      background: var(--color-surface-hover);
    }

    &:last-child td {
      border-bottom: 0;
    }
  }

  &__prompt-cell p {
    display: -webkit-box;
    margin: 0;
    overflow: hidden;
    color: var(--color-brand-strong);
    font-size: 0.82rem;
    font-weight: 700;
    line-height: 1.35;
    overflow-wrap: anywhere;
    -webkit-box-orient: vertical;
    -webkit-line-clamp: 2;
  }

  &__interpretation {
    strong {
      display: block;
      overflow: hidden;
      color: var(--color-text);
      font-size: 0.78rem;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
  }

  &__location {
    overflow: hidden;
    color: var(--color-text-muted);
    font-size: 0.74rem;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  &__diagnostic small {
    display: block;
    margin: 0 0 4px;
    color: var(--color-text-subtle);
    font-size: 0.66rem;
  }

  &__outcome {
    display: inline-flex;
    padding: 4px 7px;
    border-radius: var(--radius-pill);
    background: var(--color-surface-muted);
    color: var(--color-text);
    font-size: 0.68rem;
    font-weight: 850;
    line-height: 1.1;

    &--zero_results,
    &--operational_issue {
      background: var(--color-danger-tint);
      color: var(--color-danger);
    }

    &--not_understood,
    &--thin_results {
      background: var(--color-warning-tint);
      color: #815107;
    }

    &--healthy {
      background: var(--color-success-tint);
      color: var(--color-success);
    }
  }

  &__numeric {
    text-align: right !important;
  }

  &__count {
    color: var(--color-brand-strong);
    font-size: 1rem;
    font-variant-numeric: tabular-nums;
    font-weight: 850;
  }

  &__date {
    color: var(--color-text-muted);
    font-size: 0.7rem;
    white-space: nowrap;
  }

  &__action {
    text-align: right;
  }
}

.audit-pagination {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  padding: 12px;
  border-top: 1px solid var(--color-border);

  span {
    color: var(--color-text-muted);
    font-size: 0.76rem;
    font-variant-numeric: tabular-nums;
    font-weight: 700;
  }
}

@media (width <= 650px) {
  .audit-list__heading {
    align-items: start;
    flex-direction: column;
    gap: 3px;
  }

  .audit-pagination {
    justify-content: space-between;
    gap: 8px;
  }
}
</style>
