<script setup lang="ts">
import { computed } from "vue";
import type { ProfessionalWorkspace } from "~/types";
import type { ProfessionalRelationshipResponse } from "~/services/api/professional-relationships";
import { formatDateTime } from "~/utils/formatters";

type ActivityItemType =
  "profile" | "photo" | "portfolio" | "verification" | "relationship" | "quote";

interface ActivityItem {
  id: string;
  type: ActivityItemType;
  title: string;
  status: string;
  detail: string;
  sortAt: string;
  responseRequired?: boolean;
  action?: {
    label: string;
    to: string;
  };
}

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
  }>(),
  {
    respondingId: null,
    relationshipError: "",
  },
);
const emit = defineEmits<{
  respond: [id: string, response: ProfessionalRelationshipResponse];
}>();

const sections = computed<ActivitySection[]>(() => {
  const attention: ActivityItem[] = [];
  const ongoing: ActivityItem[] = [];
  const profile = props.workspace.profile;

  for (const quote of props.workspace.dashboard.changeRequestedQuotes) {
    const request = quote.latestChangeRequest;
    attention.push({
      id: quote.id,
      type: "quote",
      title: `Orçamento #${quote.number} · ${quote.customerName}`,
      status: "Alteração solicitada",
      detail: `“${request.message}” · Solicitado em ${formatDateTime(request.requestedAt)}`,
      sortAt: request.requestedAt,
      action: {
        label: "Revisar orçamento",
        to: `/app/professional/quotes/new?quote=${quote.id}`,
      },
    });
  }

  if (profile.revisionStatus === "pending_review") {
    ongoing.push({
      id: `profile-${profile.id}`,
      type: "profile",
      title: "Perfil profissional",
      status: "Em análise",
      detail: profile.isPublic
        ? "As alterações já estão públicas e aguardam revisão."
        : "Perfil enviado para conferência da equipe.",
      sortAt: "",
    });
  } else if (profile.revisionStatus === "rejected") {
    attention.push({
      id: `profile-${profile.id}`,
      type: "profile",
      title: "Perfil profissional",
      status: "Precisa de ajustes",
      detail: `${profile.revisionRejectionReason ?? "Revise os dados informados."} Edite e envie novamente.`,
      sortAt: "",
      action: {
        label: "Corrigir perfil",
        to: "/app/professional/profile",
      },
    });
  }

  const photo = profile.photo.current;
  if (photo?.status === "pending_review") {
    ongoing.push({
      id: photo.id,
      type: "photo",
      title: "Foto do perfil",
      status: "Em análise",
      detail: `${profile.isPublic ? "Já está pública · " : ""}Enviada em ${formatDateTime(photo.submittedAt)}`,
      sortAt: photo.submittedAt,
    });
  } else if (photo?.status === "rejected" || photo?.status === "hidden") {
    attention.push({
      id: photo.id,
      type: "photo",
      title: "Foto do perfil",
      status: photo.status === "hidden" ? "Oculta" : "Precisa de ajustes",
      detail: `${photo.rejectionReason ?? "A foto não pode ser exibida."} Envie uma nova foto.`,
      sortAt: photo.submittedAt,
      action: {
        label: "Trocar foto",
        to: "/app/professional/profile#profile-photo",
      },
    });
  }

  for (const item of profile.portfolioItems) {
    if (item.status === "pending_review") {
      ongoing.push({
        id: item.id,
        type: "portfolio",
        title: item.title,
        status: "Em análise",
        detail: `${profile.isPublic ? "Já está público · " : ""}Enviado em ${formatDateTime(item.submittedAt)}`,
        sortAt: item.submittedAt,
      });
    } else if (item.status === "rejected" || item.status === "hidden") {
      attention.push({
        id: item.id,
        type: "portfolio",
        title: item.title,
        status: item.status === "hidden" ? "Oculto" : "Precisa de ajustes",
        detail: `${item.rejectionReason ?? "O trabalho não pode ser exibido."} Atualize e envie novamente.`,
        sortAt: item.submittedAt,
        action: {
          label: "Editar trabalho",
          to: `/app/professional/profile?tab=portfolio&edit=${item.id}`,
        },
      });
    }
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
    profile: "i-lucide-user-round",
    photo: "i-lucide-image",
    portfolio: "i-lucide-image",
    verification: "i-lucide-id-card",
    relationship: "i-lucide-handshake",
    quote: "i-lucide-message-square-warning",
  }[type];
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
              v-if="item.action"
              :to="item.action.to"
              size="sm"
              color="primary"
              variant="soft"
              trailing-icon="i-lucide-arrow-right"
            >
              {{ item.action.label }}
            </UButton>
            <UButton
              v-if="item.responseRequired"
              size="sm"
              color="neutral"
              variant="ghost"
              :loading="respondingId === item.id"
              :disabled="Boolean(respondingId)"
              @click="emit('respond', item.id, 'declined')"
            >
              Recusar
            </UButton>
            <UButton
              v-if="item.responseRequired"
              size="sm"
              color="primary"
              :loading="respondingId === item.id"
              :disabled="Boolean(respondingId)"
              @click="emit('respond', item.id, 'accepted')"
            >
              Conectar
            </UButton>
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
