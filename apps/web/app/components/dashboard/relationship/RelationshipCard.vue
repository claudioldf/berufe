<script setup lang="ts">
import { computed } from "vue";
import type {
  ProfessionalRelationship,
  ProfessionalRelationshipResponse,
} from "~/services/api/professional-relationships";

const props = defineProps<{
  relationship: ProfessionalRelationship;
  ownerId: string;
  responding?: boolean;
  removing?: boolean;
  disabled?: boolean;
  disabledReason?: string | null;
}>();
const emit = defineEmits<{
  respond: [id: string, response: ProfessionalRelationshipResponse];
  requestRemoval: [relationship: ProfessionalRelationship];
}>();

const outgoing = computed(
  () => props.relationship.initiator.id === props.ownerId,
);
const otherProfessional = computed(() =>
  outgoing.value ? props.relationship.recipient : props.relationship.initiator,
);
const statusLabel = computed(() => {
  if (props.relationship.status === "accepted") return "Vocês estão conectados";
  return outgoing.value ? "Aguardando confirmação" : "Aguardando sua resposta";
});
const relationshipLabel = computed(() => {
  if (props.relationship.relationshipType === "worked_together") {
    return "Vocês trabalharam juntos";
  }
  return outgoing.value
    ? `Você recomendou ${otherProfessional.value.displayName}`
    : `${otherProfessional.value.displayName} recomendou você`;
});
const removalLabel = computed(() =>
  props.relationship.status === "pending"
    ? "Cancelar solicitação de conexão"
    : "Remover conexão",
);
const blockedReason = computed(() => {
  if (!props.disabled) return null;
  if (props.responding) return "Aguarde o envio da resposta terminar.";
  if (props.removing) return "Aguarde a remoção da conexão terminar.";
  return (
    props.disabledReason?.trim() || "Aguarde a atualização da conexão terminar."
  );
});
</script>

<template>
  <article class="relationship-card" :data-status="relationship.status">
    <DesignSystemAvatar
      :name="otherProfessional.displayName"
      :src="otherProfessional.photoUrl ?? undefined"
      size="lg"
      shape="rounded"
    />
    <div class="relationship-card__content">
      <div class="relationship-card__heading">
        <div>
          <NuxtLink
            v-if="otherProfessional.profileAvailable"
            :to="buildPublicProfilePath(otherProfessional.publicSlug)"
          >
            {{ otherProfessional.displayName }}
            <UIcon name="i-lucide-arrow-up-right" aria-hidden="true" />
          </NuxtLink>
          <strong v-else>{{ otherProfessional.displayName }}</strong>
          <small v-if="!otherProfessional.profileAvailable"
            >Perfil público indisponível</small
          >
        </div>
        <span
          class="relationship-card__status"
          :class="{
            'relationship-card__status--pending':
              relationship.status === 'pending',
          }"
          >{{ statusLabel }}</span
        >
      </div>
      <p class="relationship-card__type">
        <UIcon
          :name="
            relationship.relationshipType === 'worked_together'
              ? 'i-lucide-handshake'
              : 'i-lucide-heart'
          "
          aria-hidden="true"
        />
        {{ relationshipLabel }}
      </p>
      <p v-if="relationship.contextNote" class="relationship-card__note">
        “{{ relationship.contextNote }}”
      </p>
      <div class="relationship-card__actions">
        <template v-if="relationship.status === 'pending' && !outgoing">
          <DesignSystemDisabledTooltip :reason="blockedReason">
            <UButton
              size="sm"
              color="neutral"
              variant="ghost"
              :loading="responding"
              :disabled="disabled"
              @click="emit('respond', relationship.id, 'declined')"
              >Recusar</UButton
            >
          </DesignSystemDisabledTooltip>
          <DesignSystemDisabledTooltip :reason="blockedReason">
            <UButton
              size="sm"
              color="primary"
              :loading="responding"
              :disabled="disabled"
              @click="emit('respond', relationship.id, 'accepted')"
              >Conectar</UButton
            >
          </DesignSystemDisabledTooltip>
        </template>
        <DesignSystemDisabledTooltip v-else :reason="blockedReason">
          <UButton
            size="sm"
            color="error"
            variant="ghost"
            icon="i-lucide-trash-2"
            :loading="removing"
            :disabled="disabled"
            @click="emit('requestRemoval', relationship)"
          >
            {{ removalLabel }}
          </UButton>
        </DesignSystemDisabledTooltip>
      </div>
    </div>
  </article>
</template>

<style scoped lang="scss">
.relationship-card {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr);
  gap: 14px;
  padding: 18px;
  border: 1px solid var(--line);
  border-radius: 16px;
  background: white;

  &__content {
    display: flex;
    flex-direction: column;
    min-width: 0;
  }

  &__heading {
    display: flex;
    justify-content: space-between;
    gap: 14px;
  }

  &__heading a,
  &__heading strong,
  &__heading small {
    display: block;
  }

  &__heading a,
  &__heading strong {
    color: var(--ink);
    font-size: 0.94rem;
    font-weight: 850;
    text-decoration: none;
  }

  &__heading a:hover {
    color: var(--color-brand);
  }

  &__heading small {
    margin-top: 3px;
    color: var(--ink-soft);
    font-size: 0.74rem;
  }

  &__status {
    align-self: start;
    padding: 5px 8px;
    border-radius: 7px;
    background: var(--color-success-tint);
    color: var(--color-success);
    font-size: 0.72rem;
    font-weight: 850;
    white-space: nowrap;

    &--pending {
      background: var(--color-warning-tint);
      color: var(--color-warning);
    }
  }

  &__type {
    display: flex;
    align-items: center;
    gap: 6px;
    margin: 10px 0 0;
    color: var(--color-brand);
    font-size: 0.8rem;
    font-weight: 800;
  }

  &__note {
    margin: 9px 0 0;
    color: var(--ink-soft);
    font-size: 0.84rem;
    line-height: 1.5;
  }

  &__actions {
    display: flex;
    justify-content: flex-end;
    gap: 6px;
    margin-top: auto;
    padding-top: 12px;
  }
}

@media (width <= 540px) {
  .relationship-card {
    grid-template-columns: 1fr;

    &__heading {
      align-items: start;
    }

    &__actions {
      justify-content: stretch;
    }

    &__actions :deep(button) {
      flex: 1;
      justify-content: center;
    }
  }
}
</style>
