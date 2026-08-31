<script setup lang="ts">
import { computed, shallowRef } from "vue";
import type {
  ProfessionalRelationship,
  ProfessionalRelationshipResponse,
} from "~/services/api/professional-relationships";
import RelationshipCard from "./relationship/RelationshipCard.vue";

const props = withDefaults(
  defineProps<{
    relationships: ProfessionalRelationship[];
    ownerId: string;
    respondingId?: string | null;
    removingId?: string | null;
    error?: string;
  }>(),
  {
    respondingId: null,
    removingId: null,
    error: "",
  },
);
const emit = defineEmits<{
  add: [];
  respond: [id: string, response: ProfessionalRelationshipResponse];
  remove: [id: string];
}>();

const removalOpen = shallowRef(false);
const selectedRelationship = shallowRef<ProfessionalRelationship | null>(null);
const mutationInProgress = computed(
  () => Boolean(props.respondingId) || Boolean(props.removingId),
);
const mutationBlockedReason = computed(() =>
  mutationInProgress.value ? "Aguarde a ação em andamento terminar" : null,
);
const selectedOtherProfessional = computed(() => {
  const relationship = selectedRelationship.value;
  if (!relationship) return null;
  return relationship.initiator.id === props.ownerId
    ? relationship.recipient
    : relationship.initiator;
});
const removalTitle = computed(() =>
  selectedRelationship.value?.status === "pending"
    ? "Cancelar solicitação de conexão"
    : "Remover conexão",
);
const removalDescription = computed(() => {
  const name =
    selectedOtherProfessional.value?.displayName ?? "este profissional";
  return selectedRelationship.value?.status === "pending"
    ? `A solicitação de conexão enviada para ${name} será cancelada. Você poderá se conectar novamente no futuro.`
    : `A conexão com ${name} deixará de aparecer nos perfis públicos. Você poderá se conectar novamente no futuro.`;
});
const emptyStateBenefits = [
  "Conexões confirmadas nos perfis públicos",
  "Recomendações baseadas em trabalho real",
  "Mais confiança para novos clientes",
];
const emptyStateVisual = {
  icon: "i-lucide-handshake",
  title: "Minha rede",
  caption: "Parcerias que geram confiança",
  metaLabel: "Resultado",
  metaValue: "Prova social real",
  badge: "Juntos, mais fortes",
  badgeIcon: "i-lucide-users-round",
};

function requestRemoval(relationship: ProfessionalRelationship) {
  selectedRelationship.value = relationship;
  removalOpen.value = true;
}

function forwardResponse(
  id: string,
  response: ProfessionalRelationshipResponse,
) {
  emit("respond", id, response);
}

function confirmRemoval() {
  const relationship = selectedRelationship.value;
  if (!relationship) return;

  removalOpen.value = false;
  emit("remove", relationship.id);
}
</script>

<template>
  <div class="relationship-manager">
    <DesignSystemSurfaceCard
      v-if="relationships.length"
      as="section"
      class="relationship-manager__intro"
    >
      <div>
        <DesignSystemEyebrow>Rede profissional</DesignSystemEyebrow>
        <h2>Minha rede</h2>
        <p>
          Encontre e conecte-se a profissionais que você conhece e recomenda.
        </p>
      </div>
      <UButton color="primary" icon="i-lucide-user-plus" @click="emit('add')"
        >Conectar</UButton
      >
    </DesignSystemSurfaceCard>

    <p
      v-if="error"
      class="relationship-manager__feedback relationship-manager__feedback--error"
      role="alert"
    >
      {{ error }}
    </p>

    <div v-if="relationships.length" class="relationship-manager__list">
      <RelationshipCard
        v-for="relationship in relationships"
        :key="relationship.id"
        :relationship="relationship"
        :owner-id="ownerId"
        :responding="respondingId === relationship.id"
        :removing="removingId === relationship.id"
        :disabled="mutationInProgress"
        :disabled-reason="mutationBlockedReason"
        @respond="forwardResponse"
        @request-removal="requestRemoval"
      />
    </div>

    <DesignSystemFeatureEmptyState
      v-else
      eyebrow="Confiança se constrói em rede"
      title="Transforme boas parcerias em prova social."
      description="Conecte-se a profissionais com quem você já trabalhou. Depois da confirmação, essa relação fortalece os dois perfis diante de novos clientes."
      :items="emptyStateBenefits"
      cta-label="Criar minha primeira conexão"
      cta-icon="i-lucide-user-plus"
      :visual="emptyStateVisual"
      @action="emit('add')"
    />

    <UModal
      v-model:open="removalOpen"
      :title="removalTitle"
      :description="removalDescription"
    >
      <template #footer>
        <DesignSystemDisabledTooltip :reason="mutationBlockedReason">
          <UButton
            color="neutral"
            variant="ghost"
            :disabled="mutationInProgress"
            @click="removalOpen = false"
            >Manter conexão</UButton
          >
        </DesignSystemDisabledTooltip>
        <UButton
          color="error"
          icon="i-lucide-trash-2"
          :loading="mutationInProgress"
          @click="confirmRemoval"
        >
          {{ removalTitle }}
        </UButton>
      </template>
    </UModal>
  </div>
</template>

<style scoped lang="scss">
.relationship-manager {
  display: grid;
  gap: 18px;

  &__intro {
    display: flex;
    justify-content: space-between;
    align-items: end;
    gap: 30px;
    padding: 26px;
  }

  &__intro h2 {
    margin: 0;
    font-family: var(--font-display);
    font-size: 2rem;
  }

  &__intro p {
    max-width: 580px;
    margin: 7px 0 0;
    color: var(--ink-soft);
    font-size: 0.82rem;
    line-height: 1.5;
  }

  &__list {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 12px;
  }

  &__feedback {
    margin: 0;
    font-size: 0.84rem;

    &--error {
      color: var(--color-danger);
      font-weight: 700;
    }
  }
}

@media (width <= 900px) {
  .relationship-manager__list {
    grid-template-columns: 1fr;
  }
}

@media (width <= 560px) {
  .relationship-manager__intro {
    display: grid;
  }
}
</style>
