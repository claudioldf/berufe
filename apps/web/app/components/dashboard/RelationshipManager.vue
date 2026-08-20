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
  respond: [id: string, response: ProfessionalRelationshipResponse];
  remove: [id: string];
}>();

const removalOpen = shallowRef(false);
const selectedRelationship = shallowRef<ProfessionalRelationship | null>(null);
const mutationInProgress = computed(
  () => Boolean(props.respondingId) || Boolean(props.removingId),
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
    ? "Cancelar solicitação"
    : "Remover relação",
);
const removalDescription = computed(() => {
  const name =
    selectedOtherProfessional.value?.displayName ?? "este profissional";
  return selectedRelationship.value?.status === "pending"
    ? `A solicitação enviada para ${name} será cancelada. Você poderá solicitar novamente no futuro.`
    : `A relação com ${name} deixará de aparecer nos perfis públicos. Você poderá solicitar novamente no futuro.`;
});

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
    <DesignSystemSurfaceCard as="section" class="relationship-manager__intro">
      <div>
        <DesignSystemEyebrow>Sua rede profissional</DesignSystemEyebrow>
        <h2>Relações</h2>
        <p>
          Gerencie solicitações e relações confirmadas com outros profissionais
          da Berufe.
        </p>
      </div>
      <UButton to="/encontrar" color="primary" icon="i-lucide-user-plus"
        >Adicionar relação</UButton
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
        @respond="forwardResponse"
        @request-removal="requestRemoval"
      />
    </div>

    <DesignSystemSurfaceCard
      v-else
      as="section"
      class="relationship-manager__empty"
    >
      <span><UIcon name="i-lucide-handshake" aria-hidden="true" /></span>
      <h3>Sua rede começa com uma colaboração.</h3>
      <p>
        Encontre um profissional já cadastrado e envie uma solicitação de
        relação.
      </p>
      <UButton to="/encontrar" color="primary">Encontrar profissionais</UButton>
    </DesignSystemSurfaceCard>

    <UModal
      v-model:open="removalOpen"
      :title="removalTitle"
      :description="removalDescription"
    >
      <template #footer>
        <UButton
          color="neutral"
          variant="ghost"
          :disabled="mutationInProgress"
          @click="removalOpen = false"
          >Manter relação</UButton
        >
        <UButton
          color="error"
          icon="i-lucide-trash-2"
          :disabled="mutationInProgress"
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

  &__empty {
    display: grid;
    justify-items: center;
    padding: 48px 24px;
    text-align: center;
  }

  &__empty > span {
    display: grid;
    place-items: center;
    width: 54px;
    height: 54px;
    border-radius: 16px;
    background: var(--mint);
    color: var(--color-brand);
    font-size: 1.5rem;
  }

  &__empty h3 {
    margin: 16px 0 0;
    font-family: var(--font-display);
    font-size: 1.45rem;
  }

  &__empty p {
    max-width: 420px;
    margin: 7px 0 18px;
    color: var(--ink-soft);
    font-size: 0.84rem;
    line-height: 1.5;
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
