<script setup lang="ts">
import { computed } from "vue";
import type { ProfessionalActionKind, ProfessionalWorkspace } from "~/types";
import type { ProfessionalRelationshipResponse } from "~/services/api/professional-relationships";
import { formatDateTime } from "~/utils/formatters";

type ActivityItemType = "verification" | "relationship" | "quote" | "service";

interface ActivityItem {
  id: string;
  type: ActivityItemType;
  title: string;
  status: string;
  detail: string;
  sortAt: string;
  responseRequired?: boolean;
  action?:
    | { kind: "link"; label: string; to: string }
    | { kind: "act"; label: string; intent: ProfessionalActionKind };
}

const ACTION_ITEM_PRESENTATION: Record<
  ProfessionalActionKind,
  { type: ActivityItemType; status: string; actionLabel: string }
> = {
  quote_unshared: {
    type: "quote",
    status: "Não enviado",
    actionLabel: "Enviar no WhatsApp",
  },
  quote_awaiting_response: {
    type: "quote",
    status: "Sem resposta",
    actionLabel: "Reenviar no WhatsApp",
  },
  quote_change_requested: {
    type: "quote",
    status: "Alteração solicitada",
    actionLabel: "Revisar orçamento",
  },
  service_open: {
    type: "service",
    status: "Aprovado",
    actionLabel: "Concluído",
  },
  recommendation_unsent: {
    type: "service",
    status: "Sem recomendação",
    actionLabel: "Pedir no WhatsApp",
  },
};

interface ActivitySection {
  id: "attention" | "ongoing";
  eyebrow: string;
  title: string;
  items: ActivityItem[];
}

const props = withDefaults(
  defineProps<{
    workspace: ProfessionalWorkspace;
    respondingId?: string | null;
    relationshipError?: string;
    actingId?: string | null;
    actionError?: string;
  }>(),
  {
    respondingId: null,
    relationshipError: "",
    actingId: null,
    actionError: "",
  },
);
const emit = defineEmits<{
  respond: [id: string, response: ProfessionalRelationshipResponse];
  act: [id: string, kind: ProfessionalActionKind];
}>();

const sections = computed<ActivitySection[]>(() => {
  const attention: ActivityItem[] = [];
  const ongoing: ActivityItem[] = [];
  const profile = props.workspace.profile;

  for (const item of props.workspace.dashboard.actionItems) {
    const presentation = ACTION_ITEM_PRESENTATION[item.kind];
    attention.push({
      id: item.id,
      type: presentation.type,
      title: item.title,
      status: presentation.status,
      detail: item.subtitle,
      sortAt: item.sortAt,
      action:
        item.kind === "quote_change_requested"
          ? {
              kind: "link",
              label: presentation.actionLabel,
              to: `/app/professional/quotes/new?quote=${item.id}`,
            }
          : {
              kind: "act",
              label: presentation.actionLabel,
              intent: item.kind,
            },
    });
  }

  const verification = profile.verification.current;
  if (verification?.status === "pending_review") {
    ongoing.push({
      id: verification.id,
      type: "verification",
      title: "Verificação de identidade",
      status: "Em análise",
      detail: `Enviada em ${formatDateTime(verification.submittedAt)}`,
      sortAt: verification.submittedAt,
    });
  } else if (
    verification?.status === "rejected" ||
    verification?.status === "expired"
  ) {
    attention.push({
      id: verification.id,
      type: "verification",
      title: "Verificação de identidade",
      status:
        verification.status === "expired" ? "Expirada" : "Precisa de ajustes",
      detail: `${verification.rejectionReason ?? "A evidência precisa ser substituída."} Envie uma nova evidência.`,
      sortAt: verification.submittedAt,
      action: {
        kind: "link",
        label: "Enviar evidência",
        to: "/app/professional/profile?tab=verificacoes",
      },
    });
  }

  for (const relationship of props.workspace.relationships) {
    if (relationship.status !== "pending") continue;

    const outgoing = relationship.initiator.id === profile.id;
    const otherProfessional = outgoing
      ? relationship.recipient
      : relationship.initiator;
    const item = {
      id: relationship.id,
      type: "relationship" as const,
      title:
        relationship.relationshipType === "worked_together"
          ? outgoing
            ? `Você trabalhou com ${otherProfessional.displayName}`
            : `${otherProfessional.displayName} trabalhou com você`
          : outgoing
            ? `Você recomendou ${otherProfessional.displayName}`
            : `${otherProfessional.displayName} recomendou você`,
      status: outgoing ? "Aguardando confirmação" : "Aguardando sua resposta",
      detail: `${outgoing ? "Enviado" : "Recebido"} em ${formatDateTime(relationship.createdAt)}`,
      sortAt: relationship.createdAt,
      responseRequired: !outgoing,
    };

    (outgoing ? ongoing : attention).push(item);
  }

  attention.sort((left, right) => right.sortAt.localeCompare(left.sortAt));
  ongoing.sort((left, right) => right.sortAt.localeCompare(left.sortAt));

  const allSections: ActivitySection[] = [
    {
      id: "attention",
      eyebrow: "Ação necessária",
      title: "Para resolver.",
      items: attention,
    },
    {
      id: "ongoing",
      eyebrow: "Avisos",
      title: "Para acompanhar.",
      items: ongoing,
    },
  ];

  return allSections.filter((section) => section.items.length > 0);
});

function activityIcon(type: ActivityItemType) {
  return {
    verification: "i-lucide-id-card",
    relationship: "i-lucide-handshake",
    quote: "i-lucide-message-square-warning",
    service: "i-lucide-clipboard-check",
  }[type];
}

const BUSY_ELSEWHERE_REASON = "Aguarde a outra ação do painel terminar.";

function actBlockedReason(itemId: string) {
  if (!props.actingId) return null;
  return props.actingId === itemId
    ? "Aguarde esta ação do painel terminar."
    : BUSY_ELSEWHERE_REASON;
}

function respondBlockedReason(itemId: string) {
  if (!props.respondingId) return null;
  return props.respondingId === itemId
    ? "Aguarde o envio da resposta à conexão terminar."
    : BUSY_ELSEWHERE_REASON;
}
</script>

<template>
  <div v-if="sections.length" class="dashboard-activity">
    <section
      v-for="section in sections"
      :key="section.id"
      class="activity-section"
      :class="`activity-section--${section.id}`"
      :aria-labelledby="`activity-section-${section.id}`"
    >
      <div class="activity-section__heading">
        <div>
          <DesignSystemEyebrow>{{ section.eyebrow }}</DesignSystemEyebrow>
          <h2 :id="`activity-section-${section.id}`">{{ section.title }}</h2>
        </div>
        <span>
          {{ section.items.length }}
          {{ section.items.length === 1 ? "item" : "itens" }}
        </span>
      </div>

      <p
        v-if="section.id === 'attention' && relationshipError"
        class="activity-list__feedback"
        role="alert"
      >
        {{ relationshipError }}
      </p>
      <p
        v-if="section.id === 'attention' && actionError"
        class="activity-list__feedback"
        role="alert"
      >
        {{ actionError }}
      </p>

      <div class="activity-list">
        <article
          v-for="item in section.items"
          :key="`${item.type}-${item.id}`"
          :class="{ 'activity-list__item--action': item.action }"
        >
          <span class="activity-list__icon">
            <UIcon :name="activityIcon(item.type)" aria-hidden="true" />
          </span>
          <div class="activity-list__content">
            <strong>{{ item.title }}</strong>
            <small>{{ item.detail }}</small>
          </div>
          <span v-if="section.id === 'ongoing'" class="activity-list__status">
            {{ item.status }}
          </span>
          <div
            v-if="item.responseRequired || item.action"
            class="activity-list__actions"
            :class="{ 'activity-list__actions--link': item.action }"
          >
            <UButton
              v-if="item.action?.kind === 'link'"
              :to="item.action.to"
              size="sm"
              color="primary"
              variant="soft"
              trailing-icon="i-lucide-arrow-right"
            >
              {{ item.action.label }}
            </UButton>
            <DesignSystemDisabledTooltip
              v-else-if="item.action?.kind === 'act'"
              :reason="actBlockedReason(item.id)"
              :loading="actingId === item.id"
            >
              <UButton
                size="sm"
                color="primary"
                variant="soft"
                :loading="actingId === item.id"
                :disabled="Boolean(actingId)"
                @click="emit('act', item.id, item.action.intent)"
              >
                {{ item.action.label }}
              </UButton>
            </DesignSystemDisabledTooltip>
            <DesignSystemDisabledTooltip
              v-if="item.responseRequired"
              :reason="respondBlockedReason(item.id)"
              :loading="respondingId === item.id"
            >
              <UButton
                size="sm"
                color="neutral"
                variant="ghost"
                :loading="respondingId === item.id"
                :disabled="Boolean(respondingId)"
                @click="emit('respond', item.id, 'declined')"
              >
                Recusar
              </UButton>
            </DesignSystemDisabledTooltip>
            <DesignSystemDisabledTooltip
              v-if="item.responseRequired"
              :reason="respondBlockedReason(item.id)"
              :loading="respondingId === item.id"
            >
              <UButton
                size="sm"
                color="primary"
                :loading="respondingId === item.id"
                :disabled="Boolean(respondingId)"
                @click="emit('respond', item.id, 'accepted')"
              >
                Conectar
              </UButton>
            </DesignSystemDisabledTooltip>
          </div>
        </article>
      </div>
    </section>
  </div>
</template>

<style scoped lang="scss">
.dashboard-activity {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 40px;
}

.activity-section {
  min-width: 0;

  &__heading {
    display: flex;
    justify-content: space-between;
    align-items: end;
    gap: 20px;
    margin-bottom: 20px;
  }

  &__heading .eyebrow {
    margin-bottom: 8px;
  }

  &__heading h2 {
    margin: 0;
    font-family: var(--font-display);
    font-size: 2rem;
    font-weight: 500;
    letter-spacing: -0.035em;
  }

  &__heading > span {
    color: var(--ink-soft);
    font-size: 0.86rem;
    white-space: nowrap;
  }
}

.activity-list {
  display: grid;
  gap: 8px;

  & article {
    display: grid;
    grid-template-columns: auto minmax(0, 1fr) auto;
    align-items: center;
    gap: 12px;
    padding: 13px 16px;
    border: 1px solid var(--line);
    border-radius: 14px;
    background: white;
  }

  &__icon {
    display: grid;
    place-items: center;
    width: 38px;
    height: 38px;
    border-radius: 11px;
    background: var(--color-accent-tint);
    color: #be553f;
  }

  &__content {
    min-width: 0;
  }

  & strong,
  & small {
    display: block;
  }

  & strong {
    font-size: 0.82rem;
  }

  & small {
    margin-top: 3px;
    color: var(--ink-soft);
    font-size: 0.82rem;
    overflow-wrap: anywhere;
  }

  &__status {
    padding: 5px 8px;
    border-radius: 7px;
    background: #fff7dd;
    color: #926916;
    font-size: 0.82rem;
    font-weight: 850;
    white-space: nowrap;
  }

  &__actions {
    grid-column: 2 / -1;
    display: flex;
    justify-content: flex-end;
    gap: 5px;
  }

  &__actions--link {
    grid-row: 1;
    grid-column: 3;
    place-self: center end;
  }

  &__feedback {
    margin: 0 0 12px;
    color: var(--color-danger);
    font-size: 0.86rem;
    font-weight: 700;
  }
}

.activity-section--ongoing {
  & .activity-list__icon {
    background: var(--mint);
    color: var(--color-brand);
  }

  & .activity-list__status {
    background: var(--color-brand-tint-subtle);
    color: var(--color-brand);
  }
}

@media (width <= 560px) {
  .activity-section__heading {
    display: grid;
  }

  .activity-list {
    & article {
      grid-template-columns: auto minmax(0, 1fr);
    }

    &__status,
    &__actions {
      grid-column: 2;
      justify-self: start;
    }

    &__item--action {
      grid-template-columns: auto minmax(0, 1fr) auto;
    }

    &__item--link &__actions--link {
      grid-row: 1;
      grid-column: 3;
      place-self: center end;
    }
  }
}
</style>
