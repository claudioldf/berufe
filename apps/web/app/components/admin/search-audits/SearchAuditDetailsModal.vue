<script setup lang="ts">
import { formatDateTime } from "~/utils/formatters";
import {
  searchAuditLocationLabel,
  searchAuditOutcome,
  searchAuditOutcomeLabels,
  searchAuditParsedResponseLabel,
  searchAuditRawResponseLabel,
  searchAuditServiceLabel,
  searchAuditStatusLabels,
} from "~/utils/searchAudit";
import type { SearchAuditItem } from "~/types";

const open = defineModel<boolean>("open", { required: true });
defineProps<{ item: SearchAuditItem | null }>();
</script>

<template>
  <UModal
    v-model:open="open"
    title="Detalhes da busca"
    description="Entrada do usuário, interpretação controlada e rastreabilidade do LLM."
    :ui="{ content: 'sm:max-w-4xl' }"
  >
    <template #body>
      <div v-if="item" class="audit-detail">
        <section
          class="audit-detail__lead"
          aria-labelledby="audit-prompt-title"
        >
          <div class="audit-detail__badges">
            <span :class="`audit-detail__outcome--${searchAuditOutcome(item)}`">
              {{ searchAuditOutcomeLabels[searchAuditOutcome(item)] }}
            </span>
            <span>{{ searchAuditStatusLabels[item.status] }}</span>
          </div>
          <h3 id="audit-prompt-title">Prompt informado</h3>
          <p>{{ item.inputPrompt }}</p>
        </section>

        <dl class="audit-detail__summary">
          <div>
            <dt>Serviço interpretado</dt>
            <dd>{{ searchAuditServiceLabel(item) }}</dd>
          </div>
          <div>
            <dt>Localização</dt>
            <dd>{{ searchAuditLocationLabel(item) }}</dd>
          </div>
          <div>
            <dt>Profissionais encontrados</dt>
            <dd class="audit-detail__count">{{ item.resultCount }}</dd>
          </div>
          <div>
            <dt>Registrada em</dt>
            <dd>
              <time :datetime="item.createdAt">{{
                formatDateTime(item.createdAt)
              }}</time>
            </dd>
          </div>
        </dl>

        <section class="audit-detail__normalized">
          <h3>Mensagem normalizada para contato</h3>
          <p>
            {{ item.parsedResponse?.normalizedRequest ?? "Não disponível." }}
          </p>
        </section>

        <section class="audit-detail__trace">
          <h3>Resposta bruta do LLM</h3>
          <pre translate="no">{{ searchAuditRawResponseLabel(item) }}</pre>
        </section>

        <section class="audit-detail__trace">
          <h3>Resposta interpretada</h3>
          <pre translate="no">{{ searchAuditParsedResponseLabel(item) }}</pre>
        </section>

        <dl class="audit-detail__metadata">
          <div>
            <dt>Origem</dt>
            <dd>{{ item.responseSource ?? "—" }}</dd>
          </div>
          <div>
            <dt>Adaptador</dt>
            <dd>{{ item.adapter ?? "—" }}</dd>
          </div>
          <div>
            <dt>Modelo</dt>
            <dd>{{ item.model ?? "—" }}</dd>
          </div>
          <div>
            <dt>ID do provedor</dt>
            <dd>{{ item.providerRequestId ?? "—" }}</dd>
          </div>
          <div>
            <dt>Digest do prompt</dt>
            <dd>{{ item.promptDigest ?? "—" }}</dd>
          </div>
          <div>
            <dt>ID da auditoria</dt>
            <dd>{{ item.id }}</dd>
          </div>
        </dl>
      </div>
    </template>
    <template #footer>
      <UButton color="neutral" variant="outline" @click="open = false">
        Fechar
      </UButton>
    </template>
  </UModal>
</template>

<style scoped lang="scss">
.audit-detail {
  display: grid;
  gap: 18px;
  max-height: min(72vh, 760px);
  padding-right: 4px;
  overflow-y: auto;
  overscroll-behavior: contain;

  h3,
  p,
  dl,
  dd {
    margin: 0;
  }

  h3 {
    color: var(--color-brand-strong);
    font-size: 0.76rem;
    font-weight: 850;
    letter-spacing: 0.025em;
    text-transform: uppercase;
  }

  &__lead {
    display: grid;
    gap: 8px;

    p {
      color: var(--color-brand-strong);
      font-family: var(--font-display);
      font-size: 1.3rem;
      font-weight: 600;
      line-height: 1.35;
      overflow-wrap: anywhere;
    }
  }

  &__badges {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;

    span {
      padding: 4px 8px;
      border-radius: var(--radius-pill);
      background: var(--color-surface-muted);
      color: var(--color-text-muted);
      font-size: 0.68rem;
      font-weight: 850;
    }

    .audit-detail__outcome--zero_results,
    .audit-detail__outcome--operational_issue {
      background: var(--color-danger-tint);
      color: var(--color-danger);
    }

    .audit-detail__outcome--not_understood,
    .audit-detail__outcome--thin_results {
      background: var(--color-warning-tint);
      color: #815107;
    }

    .audit-detail__outcome--healthy {
      background: var(--color-success-tint);
      color: var(--color-success);
    }
  }

  &__summary {
    display: grid;
    grid-template-columns: 1fr 1.3fr 0.7fr 1fr;
    gap: 10px;

    div {
      min-width: 0;
      padding: 11px;
      border: 1px solid var(--color-border);
      border-radius: var(--radius-md);
      background: var(--color-surface-neutral);
    }

    dt {
      color: var(--color-text-muted);
      font-size: 0.65rem;
      font-weight: 800;
      text-transform: uppercase;
    }

    dd {
      margin-top: 4px;
      color: var(--color-text);
      font-size: 0.78rem;
      overflow-wrap: anywhere;
    }
  }

  &__count {
    font-size: 1.1rem !important;
    font-variant-numeric: tabular-nums;
    font-weight: 850;
  }

  &__normalized {
    padding: 13px 14px;
    border-radius: var(--radius-md);
    background: var(--color-brand-tint-subtle);

    p {
      margin-top: 6px;
      color: var(--color-text);
      font-size: 0.84rem;
      line-height: 1.5;
      overflow-wrap: anywhere;
    }
  }

  &__trace {
    overflow: hidden;
    border: 1px solid var(--color-border);
    border-radius: var(--radius-md);

    h3 {
      padding: 10px 12px;
      background: var(--color-surface-neutral);
    }

    pre {
      max-height: 280px;
      margin: 0;
      padding: 13px;
      overflow: auto;
      background: #17322d;
      color: #eaf4f1;
      font-size: 0.72rem;
      line-height: 1.5;
      white-space: pre-wrap;
      overflow-wrap: anywhere;
    }
  }

  &__metadata {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 8px 14px;
    padding-top: 2px;

    dt {
      color: var(--color-text-subtle);
      font-size: 0.63rem;
      font-weight: 800;
      text-transform: uppercase;
    }

    dd {
      margin-top: 2px;
      color: var(--color-text-muted);
      font-family: monospace;
      font-size: 0.68rem;
      overflow-wrap: anywhere;
    }
  }
}

@media (width <= 700px) {
  .audit-detail {
    &__summary,
    &__metadata {
      grid-template-columns: 1fr 1fr;
    }
  }
}
</style>
