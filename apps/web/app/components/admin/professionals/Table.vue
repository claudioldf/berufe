<script setup lang="ts">
import { formatDateTime } from "~/utils/formatters";
import type { AdminProfessionalItem, AdminProfessionalPage } from "~/types";

const props = defineProps<{
  items: AdminProfessionalItem[];
  meta: AdminProfessionalPage["meta"];
  isMutating: boolean;
}>();

const emit = defineEmits<{
  changePage: [page: number];
  publish: [item: AdminProfessionalItem];
  unpublish: [item: AdminProfessionalItem];
}>();

const profileStatusLabels: Record<string, string> = {
  draft: "Rascunho",
  published: "Publicado",
  suspended: "Suspenso",
};

function statusLabel(item: AdminProfessionalItem) {
  return item.profileStatus
    ? profileStatusLabels[item.profileStatus]
    : "Sem perfil";
}

function statusTone(item: AdminProfessionalItem) {
  if (item.profileStatus === "published") return "success";
  if (item.profileStatus === "suspended") return "danger";
  return "neutral";
}

function formatOrDash(value: string | null) {
  return value ? formatDateTime(value) : "—";
}

function actionDisabledReason(item: AdminProfessionalItem) {
  if (!item.profileStatus || item.profileStatus === "draft") {
    return "Perfil ainda não foi enviado para publicação.";
  }
  return "";
}
</script>

<template>
  <section class="professionals-list" aria-label="Profissionais cadastrados">
    <div class="professionals-list__heading">
      <p>
        <strong>{{ props.meta.totalCount }}</strong>
        {{
          props.meta.totalCount === 1
            ? "profissional encontrado"
            : "profissionais encontrados"
        }}
      </p>
    </div>

    <div class="professionals-list__table-wrap">
      <table>
        <thead>
          <tr>
            <th scope="col">Nome</th>
            <th scope="col">Telefone</th>
            <th scope="col">Identidade</th>
            <th scope="col" class="professionals-list__numeric">Portfólio</th>
            <th scope="col" class="professionals-list__numeric">Referências</th>
            <th scope="col" class="professionals-list__numeric">Clientes</th>
            <th scope="col" class="professionals-list__numeric">Orçamentos</th>
            <th scope="col">Cadastro</th>
            <th scope="col">Último acesso</th>
            <th scope="col" class="professionals-list__numeric">Acessos</th>
            <th scope="col">Cidade/UF</th>
            <th scope="col">Situação</th>
            <th scope="col"><span class="sr-only">Ações</span></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in props.items" :key="item.id">
            <td class="professionals-list__name-cell">
              <strong>{{ item.displayName ?? "—" }}</strong>
            </td>
            <td>
              <span class="professionals-list__contact">
                <DesignSystemStatusDot
                  :tone="item.phoneVerified ? 'success' : 'neutral'"
                />
                {{ item.phoneLast4 ? `•••• ${item.phoneLast4}` : "—" }}
              </span>
            </td>
            <td>
              <span class="professionals-list__contact">
                <DesignSystemStatusDot
                  :tone="item.identityVerified ? 'success' : 'neutral'"
                />
                {{ item.identityVerified ? "Verificada" : "Não verificada" }}
              </span>
            </td>
            <td class="professionals-list__numeric">
              {{ item.portfolioCount }}
            </td>
            <td class="professionals-list__numeric">
              {{ item.referenceCount }}
            </td>
            <td class="professionals-list__numeric">
              {{ item.customerCount }}
            </td>
            <td class="professionals-list__numeric">{{ item.quoteCount }}</td>
            <td class="professionals-list__date">
              {{ formatOrDash(item.registeredAt) }}
            </td>
            <td class="professionals-list__date">
              {{ formatOrDash(item.lastLoginAt) }}
            </td>
            <td class="professionals-list__numeric">{{ item.loginCount }}</td>
            <td class="professionals-list__location">
              {{ item.city ? `${item.city}/${item.state}` : "—" }}
            </td>
            <td>
              <span class="professionals-list__contact">
                <DesignSystemStatusDot :tone="statusTone(item)" />
                {{ statusLabel(item) }}
              </span>
            </td>
            <td class="professionals-list__action">
              <DesignSystemDisabledTooltip
                v-if="item.profileStatus === 'published'"
                :reason="
                  props.isMutating ? 'Aguarde a ação anterior terminar' : null
                "
              >
                <UButton
                  color="error"
                  variant="outline"
                  size="sm"
                  label="Despublicar"
                  :disabled="props.isMutating"
                  @click="emit('unpublish', item)"
                />
              </DesignSystemDisabledTooltip>
              <DesignSystemDisabledTooltip
                v-else-if="item.profileStatus === 'suspended'"
                :reason="
                  props.isMutating ? 'Aguarde a ação anterior terminar' : null
                "
              >
                <UButton
                  color="primary"
                  variant="outline"
                  size="sm"
                  label="Restaurar"
                  :disabled="props.isMutating"
                  @click="emit('publish', item)"
                />
              </DesignSystemDisabledTooltip>
              <DesignSystemDisabledTooltip
                v-else
                :reason="actionDisabledReason(item)"
              >
                <UButton
                  color="neutral"
                  variant="outline"
                  size="sm"
                  label="Publicar"
                  disabled
                />
              </DesignSystemDisabledTooltip>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <nav
      v-if="props.meta.totalPages > 1"
      class="professionals-pagination"
      aria-label="Paginação de profissionais"
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
.professionals-list {
  overflow: hidden;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  background: var(--color-surface);
  box-shadow: var(--shadow-sm);

  &__heading {
    padding: 11px 14px;
    border-bottom: 1px solid var(--color-border);
    background: var(--color-surface-neutral);

    p {
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
    min-width: 1280px;
    border-collapse: collapse;
  }

  th,
  td {
    padding: 10px 12px;
    border-bottom: 1px solid var(--color-border);
    text-align: left;
    vertical-align: middle;
    white-space: nowrap;
  }

  th {
    background: var(--color-surface);
    color: var(--color-text-muted);
    font-size: 0.66rem;
    font-weight: 850;
    letter-spacing: 0.025em;
    text-transform: uppercase;
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

  &__name-cell strong {
    color: var(--color-brand-strong);
    font-size: 0.82rem;
  }

  &__contact {
    display: inline-flex;
    align-items: center;
    gap: 7px;
    color: var(--color-text);
    font-size: 0.78rem;
  }

  &__numeric {
    color: var(--color-text);
    font-variant-numeric: tabular-nums;
    text-align: right;
  }

  &__date {
    color: var(--color-text-muted);
    font-size: 0.72rem;
  }

  &__location {
    color: var(--color-text-muted);
    font-size: 0.76rem;
  }

  &__action {
    text-align: right;
  }
}

.professionals-pagination {
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
</style>
