<script setup lang="ts">
import { formatDateTime } from "~/utils/formatters";
import type { SearchAuditItem, SearchAuditPage } from "~/types";

const props = defineProps<{
  items: SearchAuditItem[];
  meta: SearchAuditPage["meta"];
}>();

const emit = defineEmits<{
  changePage: [page: number];
}>();

const statusLabels: Record<SearchAuditItem["status"], string> = {
  processing: "Processando",
  completed: "Concluída",
  application_rate_limited: "Limite da aplicação",
  provider_rate_limited: "Limite do provedor",
  provider_unavailable: "Provedor indisponível",
  response_rejected: "Resposta rejeitada",
  search_failed: "Busca indisponível",
};

function serviceLabel(item: SearchAuditItem) {
  const services = item.parsedResponse?.services.map((service) => service.name);
  return services?.length ? services.join(", ") : "Não identificado";
}

function locationLabel(item: SearchAuditItem) {
  const locations = item.parsedResponse?.locations.map((location) => {
    const neighborhood = location.neighborhood
      ? `${location.neighborhood.name}, `
      : "";
    return `${neighborhood}${location.city} - ${location.stateCode}`;
  });
  return locations?.length ? [...new Set(locations)].join(" · ") : "—";
}

function rawResponseLabel(item: SearchAuditItem) {
  if (item.rawLlmResponse) return item.rawLlmResponse;
  if (item.status === "application_rate_limited") {
    return "Rejeitada antes do envio ao LLM.";
  }
  return "Nenhuma resposta bruta foi recebida.";
}

function parsedResponseLabel(item: SearchAuditItem) {
  return item.parsedResponse
    ? JSON.stringify(item.parsedResponse, null, 2)
    : "Nenhuma resposta interpretada.";
}
</script>

<template>
  <section
    class="audit-list"
    aria-label="Prompts de busca dos últimos sete dias"
  >
    <article v-for="item in props.items" :key="item.id" class="audit-card">
      <header class="audit-card__header">
        <div>
          <span class="audit-card__time">{{
            formatDateTime(item.createdAt)
          }}</span>
          <h2 class="audit-card__prompt">{{ item.inputPrompt }}</h2>
        </div>
        <span
          class="audit-card__status"
          :class="`audit-card__status--${item.status}`"
        >
          {{ statusLabels[item.status] }}
        </span>
      </header>

      <dl class="audit-card__summary">
        <div>
          <dt>Serviço</dt>
          <dd>{{ serviceLabel(item) }}</dd>
        </div>
        <div>
          <dt>Localização</dt>
          <dd>{{ locationLabel(item) }}</dd>
        </div>
        <div>
          <dt>Profissionais encontrados</dt>
          <dd class="audit-card__count">{{ item.resultCount }}</dd>
        </div>
      </dl>

      <div class="audit-card__message">
        <span>Mensagem normalizada para contato</span>
        <p>{{ item.parsedResponse?.normalizedRequest ?? "—" }}</p>
      </div>

      <details class="audit-card__details">
        <summary>Resposta bruta do LLM</summary>
        <pre>{{ rawResponseLabel(item) }}</pre>
      </details>

      <details class="audit-card__details">
        <summary>Resposta interpretada</summary>
        <pre>{{ parsedResponseLabel(item) }}</pre>
      </details>

      <footer class="audit-card__metadata">
        <span>Origem: {{ item.responseSource ?? "—" }}</span>
        <span>Adaptador: {{ item.adapter ?? "—" }}</span>
        <span>Modelo: {{ item.model ?? "—" }}</span>
        <span v-if="item.providerRequestId">
          Requisição: {{ item.providerRequestId }}
        </span>
      </footer>
    </article>

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
  display: grid;
  gap: 16px;
}

.audit-card {
  overflow: hidden;
  border: 1px solid rgb(24 48 43 / 10%);
  border-radius: 16px;
  background: white;
  box-shadow: 0 8px 30px rgb(24 48 43 / 5%);

  &__header {
    display: flex;
    align-items: start;
    justify-content: space-between;
    gap: 20px;
    padding: 20px 22px;
    border-bottom: 1px solid rgb(24 48 43 / 8%);
  }

  &__time {
    color: var(--color-text-muted);
    font-size: 0.76rem;
    font-weight: 700;
    letter-spacing: 0.04em;
    text-transform: uppercase;
  }

  &__prompt {
    margin: 6px 0 0;
    color: var(--color-brand-strong);
    font-family: var(--font-display);
    font-size: 1.25rem;
    font-weight: 600;
    line-height: 1.35;
    overflow-wrap: anywhere;
  }

  &__status {
    flex: 0 0 auto;
    padding: 5px 9px;
    border-radius: 999px;
    background: #f2f0ea;
    color: var(--color-brand-strong);
    font-size: 0.72rem;
    font-weight: 800;

    &--completed {
      background: #e2f2e8;
      color: #23613c;
    }

    &--application_rate_limited,
    &--provider_rate_limited,
    &--response_rejected {
      background: #fff0d7;
      color: #845813;
    }

    &--provider_unavailable,
    &--search_failed {
      background: #fde8e5;
      color: #8b3028;
    }
  }

  &__summary {
    display: grid;
    grid-template-columns: 1fr 1.2fr minmax(150px, 0.5fr);
    gap: 16px;
    margin: 0;
    padding: 18px 22px;

    div {
      min-width: 0;
    }

    dt,
    dd {
      margin: 0;
    }

    dt {
      color: var(--color-text-muted);
      font-size: 0.72rem;
      font-weight: 800;
      text-transform: uppercase;
    }

    dd {
      margin-top: 5px;
      color: var(--color-brand-strong);
      font-size: 0.9rem;
      overflow-wrap: anywhere;
    }
  }

  &__count {
    font-size: 1.35rem !important;
    font-weight: 800;
  }

  &__message {
    margin: 0 22px 18px;
    padding: 13px 15px;
    border-radius: 11px;
    background: #f7f5ef;

    span {
      color: var(--color-text-muted);
      font-size: 0.72rem;
      font-weight: 800;
      text-transform: uppercase;
    }

    p {
      margin: 6px 0 0;
      color: var(--color-brand-strong);
      font-size: 0.9rem;
      line-height: 1.5;
      overflow-wrap: anywhere;
    }
  }

  &__details {
    margin: 0 22px 12px;
    border: 1px solid rgb(24 48 43 / 9%);
    border-radius: 10px;

    summary {
      padding: 11px 13px;
      color: var(--color-brand-strong);
      cursor: pointer;
      font-size: 0.82rem;
      font-weight: 800;
    }

    pre {
      max-height: 320px;
      margin: 0;
      padding: 14px;
      overflow: auto;
      border-top: 1px solid rgb(24 48 43 / 8%);
      background: #17322d;
      color: #eaf4f1;
      font-size: 0.76rem;
      line-height: 1.55;
      white-space: pre-wrap;
      overflow-wrap: anywhere;
    }
  }

  &__metadata {
    display: flex;
    flex-wrap: wrap;
    gap: 7px 16px;
    padding: 8px 22px 18px;
    color: var(--color-text-muted);
    font-size: 0.72rem;
  }
}

.audit-pagination {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  padding-top: 6px;

  span {
    color: var(--color-text-muted);
    font-size: 0.82rem;
    font-weight: 700;
  }
}

@media (width <= 760px) {
  .audit-card {
    &__header {
      display: grid;
      gap: 12px;
      padding: 17px;
    }

    &__status {
      justify-self: start;
    }

    &__summary {
      grid-template-columns: 1fr;
      padding: 16px 17px;
    }

    &__message,
    &__details {
      margin-right: 17px;
      margin-left: 17px;
    }

    &__metadata {
      display: grid;
      padding: 8px 17px 16px;
    }
  }

  .audit-pagination {
    justify-content: space-between;
    gap: 8px;
  }
}
</style>
